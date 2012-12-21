// Copyright 2011 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS-IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package controls
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	
	import mx.core.FlexLoader;

	public class ImageSprite extends Sprite
	{
		//--------------------------------------
		//  Events (copied from SWFLoader)
		//--------------------------------------
		
		/**
		 *  Dispatched when content loading is complete.
		 *
		 *  <p>This event is dispatched regardless of whether the load was triggered
		 *  by an autoload or an explicit call to the <code>load()</code> method.</p>
		 *
		 *  @eventType flash.events.Event.COMPLETE
		 */
		[Event(name="complete", type="flash.events.Event")]
		
		/**
		 *  Dispatched when a network request is made over HTTP
		 *  and Flash Player or AIR can detect the HTTP status code.
		 *
		 *  @eventType flash.events.HTTPStatusEvent.HTTP_STATUS
		 */
		[Event(name="httpStatus", type="flash.events.HTTPStatusEvent")]
		
		/**
		 *  Dispatched when the properties and methods of a loaded SWF file
		 *  are accessible. The following two conditions must exist
		 *  for this event to be dispatched:
		 *
		 *  <ul>
		 *    <li>All properties and methods associated with the loaded
		 *    object and those associated with the control are accessible.</li>
		 *    <li>The constructors for all child objects have completed.</li>
		 *  </ul>
		 *
		 *  @eventType flash.events.Event.INIT
		 */
		[Event(name="init", type="flash.events.Event")]
		
		/**
		 *  Dispatched when an input/output error occurs.
		 *  @see flash.events.IOErrorEvent
		 *
		 *  @eventType flash.events.IOErrorEvent.IO_ERROR
		 */
		[Event(name="ioError", type="flash.events.IOErrorEvent")]
		
		/**
		 *  Dispatched when a network operation starts.
		 *
		 *  @eventType flash.events.Event.OPEN
		 */
		[Event(name="open", type="flash.events.Event")]
		
		/**
		 *  Dispatched when content is loading.
		 *
		 *  <p>This event is dispatched regardless of whether the load was triggered
		 *  by an autoload or an explicit call to the <code>load()</code> method.</p>
		 *
		 *  <p><strong>Note:</strong>
		 *  The <code>progress</code> event is not guaranteed to be dispatched.
		 *  The <code>complete</code> event may be received, without any
		 *  <code>progress</code> events being dispatched.
		 *  This can happen when the loaded content is a local file.</p>
		 *
		 *  @eventType flash.events.ProgressEvent.PROGRESS
		 */
		[Event(name="progress", type="flash.events.ProgressEvent")]
		
		/**
		 *  Dispatched when a security error occurs while content is loading.
		 *  For more information, see the SecurityErrorEvent class.
		 *
		 *  @eventType flash.events.SecurityErrorEvent.SECURITY_ERROR
		 */
		[Event(name="securityError", type="flash.events.SecurityErrorEvent")]
		
		/**
		 *  Dispatched when a loaded object is removed,
		 *  or when a second load is performed by the same SWFLoader control
		 *  and the original content is removed prior to the new load beginning.
		 *
		 *  @eventType flash.events.Event.UNLOAD
		 */
		[Event(name="unload", type="flash.events.Event")]
		
		private var _ldr:FlexLoader = null;
		private var _strSourceUrl:String = null;
		
		private var _nExplicitWidth:Number = NaN;
		private var _nExplicitHeight:Number = NaN;
		
		private var _nContentWidth:Number = 0;
		private var _nContentHeight:Number = 0;

		private static const kastrPassthroughEvents:Array = [Event.COMPLETE, HTTPStatusEvent.HTTP_STATUS,
			Event.INIT, IOErrorEvent.IO_ERROR, Event.OPEN, ProgressEvent.PROGRESS,
			SecurityErrorEvent.SECURITY_ERROR, Event.UNLOAD];
	
		public function ImageSprite()
		{
			super();
		}
		
		public override function set width(n:Number): void {
			if (_ldr) super.width = n;
			_nExplicitWidth = n;
			RescaleChild();
		}
		
		public override function set height(n:Number): void {
			if (_ldr) super.height = n;
			_nExplicitHeight = n;
			RescaleChild();
		}
		
		private function RescaleChild(): void {
			if (_ldr == null) return;
			if (contentWidth == 0 || contentHeight == 0) return;
			
			_ldr.width = _nExplicitWidth;
			_ldr.height = _nExplicitHeight;
			super.width = _nExplicitWidth;
			super.height = _nExplicitHeight;
		}
		
		public function get contentWidth(): Number {
			if (!_ldr) return 0;
			return _nContentWidth;
		}
		
		public function get contentHeight(): Number {
			if (!_ldr) return 0;
			return _nContentHeight;
		}
		
		public function set source(strUrl:String): void {
			if (_strSourceUrl != strUrl) {
				load(strUrl);
			}
		}
		
		public function get source(): String {
			return _strSourceUrl;
		}
		
		public function load(strUrl:String): void {
			if (_ldr) unload();
			_strSourceUrl = strUrl;
			if (strUrl == null || strUrl.length == 0) return;
			
			_ldr = new FlexLoader();
			addChild(_ldr);
			_ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, OnImageLoaded);
			_ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, OnImageLoadIOError);
					
			for each (var strEvent:String in kastrPassthroughEvents) {
				_ldr.contentLoaderInfo.addEventListener(strEvent, OnLoaderPassthroughEvent);
			}
			
			/* We do not support loading debug swfs
			// are we in a debug player and this was a debug=true request
			if ( (Capabilities.isDebugger == true) &&
				(url.indexOf(".jpg") == -1) &&
				(LoaderUtil.normalizeURL(Application.application.systemManager.loaderInfo).indexOf("debug=true") > -1) )
			url = url + ( (url.indexOf("?") > -1) ? "&debug=true" : "?debug=true" );
			*/

			/* We do not support relative paths
			// make relative paths relative to the SWF loading it, not the top-level SWF
			if (!(url.indexOf(":") > -1 || url.indexOf("/") == 0 || url.indexOf("\\") == 0)) {
				var rootURL:String;
				if (SystemManagerGlobals.bootstrapLoaderInfoURL != null && SystemManagerGlobals.bootstrapLoaderInfoURL != "")
					rootURL = SystemManagerGlobals.bootstrapLoaderInfoURL;
				else if (root)
					rootURL = LoaderUtil.normalizeURL(root.loaderInfo);
				else if (systemManager)
					rootURL = LoaderUtil.normalizeURL(DisplayObject(systemManager).loaderInfo);
			
				if (rootURL) {
					var lastIndex:int = Math.max(rootURL.lastIndexOf("\\"), rootURL.lastIndexOf("/"));
					if (lastIndex != -1)
						url = rootURL.substr(0, lastIndex + 1) + url;
				}
			}
			*/

            var requestedURL:URLRequest = new URLRequest(strUrl);
                       
            var lc:LoaderContext = new LoaderContext();
			// assume the best, which is that it is in the same domain and
			// we can make it a child app domain.
			lc.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);

            _ldr.load(requestedURL, lc);
		}
		
		public function unload(): void {
			if (_ldr) {
				_ldr.unload();
				_ldr.contentLoaderInfo.removeEventListener(Event.COMPLETE, OnImageLoaded);
				_ldr.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, OnImageLoadIOError);
						
				for each (var strEvent:String in kastrPassthroughEvents) {
					_ldr.contentLoaderInfo.removeEventListener(strEvent, OnLoaderPassthroughEvent);
				}
				_ldr = null;
				_strSourceUrl = null;
				removeChild(_ldr);
			}
		}
		
		private function OnLoaderPassthroughEvent(evt:Event): void {
			dispatchEvent(evt);
		}
		
		private function OnImageLoaded(evt:Event): void {
			_nContentWidth = _ldr.width;
			_nContentHeight = _ldr.height;
			RescaleChild();
		}
		
		// We don't need to act on errors but we don't want the debug Flash Player complaining
		// about us not handling them so here is a handler.
		private function OnImageLoadIOError(evt:IOErrorEvent): void {
		}
	}
}
