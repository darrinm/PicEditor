/* 
 * Copyright (c) 2006 Allurent, Inc.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished
 * to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
 * OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
 
package urlkit.rules
{

import flash.events.*;
import flash.external.*;
import flash.net.*;
import flash.system.*;
import flash.utils.Timer;

import mx.controls.*;
import mx.core.*;
import mx.events.*;

/**
 * This class is the interface interacts with an instance of IUrlApplicationState
 * on behalf of the containing HTML browser.  It changes the app state to
 * correspond to browser-initiated changes, and also updates the browser
 * location and history to correspond to application-initiated changes.
 */
public class UrlBrowserManager extends EventDispatcher implements IMXMLObject
{
    static private var installedJS:Boolean = false;

    // flag indicating that our owning application document is completely set up
    private var _complete:Boolean = false;
    
    // the latest browser URL that we know of
    private var _browserUrl:String;
    
    // our owning application document
    private var _document:Object;

    // flag indicating that the state of the application needs to be updated.
    private var _updateRequested:Boolean = false;
    
    // instance of IUrlApplicationState that is coupled to this browser manager.
    private var _applicationState:IUrlApplicationState;

    // flag indicating that the application state has been considered once after creationComplete
    private var _stateInitialized:Boolean = false;
    
    [Bindable]
    public var playerId:String;
    
    /**
     * Construct an instance of UrlBrowserManager and initialize the external interface to the browser.
     */    
    public function UrlBrowserManager()
    {
        // determine initial value of browser URL in fragment ID
        try {
	        _browserUrl = ExternalInterface.call("eval", "document.location.href");
	    } catch (e:Error) {
//			PicnikService.Log("Ignored Client Exception in in UrlBrowserManager.UrlBrowserManager: " + e + ", " + e.getStackTrace(), PicnikService.knLogSeverityInfo);
			_browserUrl = null;
	    }
	    if (_browserUrl == null) _browserUrl = "";
	    
        var pos:int = _browserUrl.indexOf("#");
        
        if (pos != -1)
        {
            _browserUrl = _browserUrl.substr(pos + 1);
      
            pos = _browserUrl.indexOf("?");
            if (pos != -1)
            {
                // trim off any attached query args
                _browserUrl = _browserUrl.substr(0, pos);
            }
            
            // put a leading / in if necessary so we don't loopily loop
            if (_browserUrl.length > 0 && _browserUrl.charAt(0) != "/")
            	_browserUrl = "/" + _browserUrl;
        }
        else
        {
            _browserUrl = "";
        }

        // initialize the containing document with the utility functions we'll be using
        if (installedJS == false)
        {
            installedJS = true;

            if (!playerId)
                playerId = Application.application.id;

			try {
	            ExternalInterface.addCallback("setPlayerUrl", setPlayerUrl);
		    } catch (e:Error) {
//				PicnikService.Log("Ignored Client Exception in in UrlBrowserManager.UrlBrowserManager:2: " + e + ", " + e.getStackTrace(), PicnikService.knLogSeverityInfo);
		    }

            var JS:String;

            JS = "window.getPlayerId = function()" +
                "{" +
                "    return '" + playerId + "';" +
                "};";

			try {
	            ExternalInterface.call("eval", JS);
		    } catch (e:Error) {
//				PicnikService.Log("Ignored Client Exception in in UrlBrowserManager.UrlBrowserManager:3: " + e + ", " + e.getStackTrace(), PicnikService.knLogSeverityInfo);
		    }
        }
    }

    /**
     * Callback in IMXMLObject letting us know what our owning document is.
     * @param document the owning document
     * @param id component ID, if any
     * 
     */    
    public function initialized(document:Object, id:String):void
    {
        _document = document;
        _document.addEventListener(FlexEvent.CREATION_COMPLETE, creationComplete);
    }

    /**
     * Handle the eventual completion of the owning application document
     * by updating the URL state.  This is done via the normal deferred call
     * in order to pick up any URL rule changes that occur in other listeners
     * for the same creationComplete event in the same event processing cycle.
     */
    // HACK: changed from private to public so PicnikBase can call it OnTabNavCreationComplete
    public function creationComplete(event:Event):void
    {
        _complete = true;

        updateState();
    }
    
    [Bindable("change")]
    /**
     * Set the URL to be exhibited by the browser.
     * @param newUrl the updated browser URL
     * 
     */
    public function set browserUrl(newUrl:String):void
    {
        // TODO: browser URL may need filtering here to remove query args, etc.
        // if so, largely the same as setPlayerUrl -- refactor?

        if (_browserUrl != newUrl)
        {
            _browserUrl = newUrl;
            
            dispatchEvent(new Event(Event.CHANGE));

            if (_complete)
            {
            	try {
	                ExternalInterface.call("setBrowserUrl", _browserUrl);
			    } catch (e:Error) {
//					PicnikService.Log("Ignored Client Exception in in UrlBrowserManager.set browserUrl: " + e + ", " + e.getStackTrace(), PicnikService.knLogSeverityInfo);
			    }
            }
        }
    }

    /**
     * @return the current URL exhibited by the browser.
     */
    public function get browserUrl():String
    {
        return _browserUrl;
    }

    /**
     * Event handler called in response to STATE_CHANGE events
     * dispatched by the applicationState object; schedules a deferred
     * synchronization of the browser state to the application if not
     * already scheduled.
     */
    private function updateState(e:Event=null):void
    {
        if (!_updateRequested)
        {
            UIComponent(_document).callLater(syncState, []);
            _updateRequested = true;
        }
    }
    
    /**
     * Synchronize the state of the browser to the application, if this was
     * requested.
     */
    private function syncState():void
    {
        if (_updateRequested && _complete && applicationState != null)
        {
            try
            {
                // If this browser manager has ever been initialized before,
                // just copy the browser URL and title out to the JS world.
                // Otherwise, initialize the default URL state.
                if (_stateInitialized)
                {
                    browserUrl = applicationState.url;
                    title = applicationState.title;
                    _updateRequested = false;
                }
                else
                {
                    _updateRequested = false;
                    initializeState();
                }
            }
            catch (e:StateNotAvailableError)
            {
                // the application state could not be computed yet;
                // try again later.
                var t:Timer = new Timer(100, 1);
                t.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { syncState(); });
                t.start();
            }
        }
    }

    /**    
     * Note the application state, taking it to be state for the default URL
     * to be navigated to if returning via the browser history to a URL with
     * no particular state embedded in it.
     */
    private function initializeState():void
    {
        if (browserUrl == "")
        {
            // We've been given no particular instruction on what URL to go to,
            // so grab the current state (synchronously) and set that as the
            // default URL to which to navigate
            _browserUrl = applicationState.url;
            title = applicationState.title;
        }
        else
        {
            // we've got a non-empty browser URL at start up, so navigate to it.
            applicationState.containerUrl = browserUrl;
        }

		try {
	        ExternalInterface.call("setDefaultUrl", browserUrl);
	    } catch (e:Error) {
//			PicnikService.Log("Ignored Client Exception in in UrlBrowserManager.initializeState: " + e + ", " + e.getStackTrace(), PicnikService.knLogSeverityInfo);
	    }
        _stateInitialized = true;
        
        Application.application.addEventListener(MouseEvent.MOUSE_DOWN, ieTitleBugWorkaround);
     }
     
     /**
      * Work around a bug in IE title handling by forcing the title back to what it should be as soon
      * as there is a mouse down in the application.
      */
     private function ieTitleBugWorkaround(event:Event):void
     {
         Application.application.removeEventListener(MouseEvent.MOUSE_DOWN, ieTitleBugWorkaround);
         try
         {
             title = applicationState.title;
         }
         catch (e:StateNotAvailableError) {
         }
     }
   
    /**
     * Set the URL of the application to the given URL.
     * @param newUrl a new URL originating from the browser.
     */
    private function setPlayerUrl(newUrl:String):void
    {
        if (_browserUrl != newUrl)
        {
            _browserUrl = newUrl;
            if (applicationState != null)
	            applicationState.containerUrl = browserUrl;
        }
    }

    /**
     * The instance of IUrlApplicationState representing the state of the
     * application, exposing a URL and window title.
     */
    public function get applicationState():IUrlApplicationState
    {
        return _applicationState;
    }
    
    /**
     * Set the app state, listening for events indicating that the browser
     * must expose a new URL.
     */
    public function set applicationState(state:IUrlApplicationState):void
    {
        if (_applicationState != null)
        {
            _applicationState.removeEventListener(UrlBaseRule.STATE_CHANGE, updateState);
        }

        _applicationState = state;

        if (_applicationState != null)
        {
            _applicationState.addEventListener(UrlBaseRule.STATE_CHANGE, updateState);
        }
    }

    /**
     * Explicitly set the window title.
     * @param s the title of the browser window
     */
    public function set title(s:String):void
    {
        if (s != null)
        {
        	try {
            	ExternalInterface.call("setTitle", s);
         	} catch (err:Error) {
         		// Ignore
         	}
        }
    }
}
}
