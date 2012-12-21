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
import flash.utils.*;
import mx.core.*;
import mx.states.*;
import mx.utils.*;
import mx.binding.*;
import mx.controls.*;
import mx.events.FlexEvent;

/**
 * This event is dispatched when the URL component for this value changes.
 */
[Event(name="change", type="flash.events.Event")]

/**
 * Base class for rule implementations.  This is a fat base class because there are
 * many generic rule features that are useful across a number of subclasses.
 */
public class UrlBaseRule extends EventDispatcher implements IUrlRule, IMXMLObject
{
    /** The current URL fragment associated with this rule. */
    private var _url:String = "";
    
    /** Flag indicating whether the current URL fragment reflects the application state. */
    private var _valid:Boolean = false;

    /** URL format string */
    private var _urlFormat:String;
    
    /** Allowable URL regexp pattern string, if not defaulted from format */
    private var _urlPattern:String;
    
    /** Compiled URL pattern regular expression as calculated from format or pattern. */
    private var _urlPatternRegEx:RegExp;

    /*
     * Flag indicating whether this rule is able to process browser updates.
     * If not, then updates are delayed and processed when the flag becomes true.
     */
    private var _ready:Boolean = true;

    /** Flag gating the activity of this rule, in addition to URL pattern criterion */
    private var _enabled:Boolean = true;

    /** Flag indicating that a browser change hasn't been applied because ready == false. */
    private var _browserChangePending:Boolean = false;
    
    /** ID captured by IMXMLObject.initialize() */
    private var _id:String;
    
    /** Document as passed in via IMXMLObject.initialize() */
    protected var _document:UIComponent;
    
    /** Storage property for parent rule. */
    private var _parentRule:IUrlRule;
    
    /** Flag indicating whether pattern/format for URL must occur at beginning */
    private var _matchUrlBeginning:Boolean = true;

    /** Storage property for title. */
    protected var _title:String;
    

    // Constant for stateChange event
    public static const STATE_CHANGE:String = "stateChange";
    
    /**
     * Construct a UrlBaseRule.
     */
    public function UrlBaseRule()
    {
    }

    // -----------------------------------------------------
    // KEY ABSTRACT METHODS: MUST BE OVERRIDDEN BY SUBCLASSES
    // -----------------------------------------------------

    /**
     * This method is responsible for updating the rule's <code>url</code> and <code>title</code>
     * properties from the application state.  Subclasses must override this method and
     * generally should invoke super.computeApplicationState().
     */
    protected function computeApplicationState():void
    {
    }

    /**
     * This method is responsible for updating the rule's application state, based on
     * the value of its <code>url</code> property.  Subclasses must override this method
     * and generally should invoke super.commitBrowserChange().
     */
    // override this method to push URL to app state from this rule
    protected function commitBrowserChange():void
    {
        //protect against bad urls being passed in
        //by the end-user with try/catch, however
        //this may also hide any possible coding errors
        try
        {
            dispatchEvent(new Event(Event.CHANGE));
        }
        catch (e:Error)
        {
            trace("error in handling browser change: " + e.message);
        }
    }

    // -----------------------------------------------------
    // IUrlRule INTERFACE IMPLEMENTATION
    // -----------------------------------------------------
    
    /**
     * Get the URL component associated with this rule, representing its
     * encoding of the current application state.
     *
     * @return a URL-encoded string that will be used as part of the state URL
     * representation verbatim, with no escaping.
     */
    public function get url():String
    {
        validateState();
        return _url;
    }

    public function set url(s:String):void
    {
        _url = s;
        if (_url == null)
        {
            // A null URL is construed as the empty string, to avoid
            // various data binding issues.
            _url = "";
        }
        
        // As soon as the URL is set by something, we can assume that
        // it's in sync with the application state, because it was either
        // set inside computeApplicationState() to reflect the app state,
        // or it's the future app state which will determine the
        // behavior of commitBrowserChange().
        _valid = true;
    }

    /**
     * Get the title component string associated with this rule, to be used
     * in determining the overall application window title.
     */
    public function get title():String
    {
        validateState();
        return _title;
    }
    
    public function set title(s:String):void
    {
        _title = s;
        invalidateState();
    }

    /**
     * @return true if this method is eligible to contribute towards the browser URL,
     * based on the current application state and any other rule-based restrictions.
     * The primary purpose for this property is to drive the conditional inclusion of child rules
     * in UrlRuleSets.
     */
    public function get active():Boolean
    {
        // Note: doesMatchUrl implicitly calls validateState() by accessing the url property.
        // Thus, getting the value of 'active' will consult the application state.
        return doesMatchUrl && enabled;
    }

    /**
     * Set the parent rule of this rule.  When a rule's application state is invalidated,
     * its parent rule is also invalidated.  This chain eventually reaches the top-level rule set,
     * where it requests the UrlBrowserManager to update itself from the top-level rule's
     * URL.
     * 
     * @param rule the IUrlRule instance to be used as this rule's parent, or null if no parent exists.
     */
    public function set parent(rule:IUrlRule):void
    {
        _parentRule = rule;
    }
    
    /**
     * Determine whether this rule is able to consume and interpret all or some prefix of a given URL as
     * a valid application state.  If it can do so, return the initial portion of the URL which can be
     * consumed by this rule.  If the rule is "not interested" in any prefix of the URL, return
     * the empty string.  Otherwise, the URL begins with a string that is known to be invalid,
     * in which case return null.
     * 
     * @param url the URL whose prefix is being matched.
     * 
     */
    public function matchUrlPrefix(url:String):String
    {
        var result:Array = exec(url);
        
        return result == null ? null : result[0];
    }
    
    /**
     * Invalidate the application state of this rule, which ultimately requests the browser
     * to update its location bar from the top-level rule's URL.
     */    
    public function invalidateState():void
    {
        if (_valid)
        {
            _valid = false;
            _browserChangePending = false;
            if (_parentRule != null)
            {
                _parentRule.invalidateState();
            }
            
            dispatchEvent(new Event(STATE_CHANGE));
        }
    }

    /**
     * Set the URL for this rule based on some or all of a URL passed in from the containing browser.
     * This is called after application initialization to process the initial app URL, as well as
     * for browser history navigation with the Back and Forward buttons.
     * 
     * @param s the URL component being applied to this rule and its descendants.
     */
    public function set containerUrl(s:String):void
    {
        if (_valid && _url == s)
        {
            return;
        }
        url = s;

        if (ready)
        {
            if (doesMatchUrl && enabled)
            {
                commitBrowserChange();
                _browserChangePending = false;
            }
            else
            {
            	// BST 6/9/07: When the gets into an invalid state (e.g. /in)
            	// if we set _valid to false, it will get stuck in this state.
            	// I haven't noticed any negative results of leaving _valid==true
                // _valid = false;
            }
        }
        else
        {
            _browserChangePending = true;
        }
    }

    // -----------------------------------------------------
    // IMXMLObject INTERFACE IMPLEMENTATION
    // -----------------------------------------------------
    
    /**
     * Notify this rule that it has been completely initialized by its owning document.
     * This function is used by UrlBaseRules that are defined in an MXML document,
     * to determine whether the owning document itself has been completely initialized.
     * If it hasn't, an event listener is set up to defer URL update processing until that time.
     * 
     * @see #ready
     */
    public function initialized(document:Object, id:String):void
    {
        _document = document as UIComponent;
        _id = id;
        if (_document != null)
        {
            // if there is an MXML document, we care about its initialization
            if (_document.initialized)
            {
                // It's initialized, run this rule's readiness check
                checkReadiness(null);
            }
            else
            {
                // It's not initialized, so force readiness to false and wait
                // for the creation of our owning document to complete.
                ready = false;
                _document.addEventListener(FlexEvent.CREATION_COMPLETE, checkReadiness);
            }
        }
    }

    // -----------------------------------------------------
    // UrlBaseRule PUBLIC METHODS
    // -----------------------------------------------------

    /**
     * Get a flag indicating whether this rule is sufficiently initialized
     * to propagate its browser-determined state to the application.
     */
    [Bindable("readyChange")]
    public function get ready():Boolean
    {
        return _ready;
    }
    
    /**
     * Set the browser-update readiness status of this rule.  If set to true
     * while an updating is pending due to this component formerly being
     * unready, the deferred update will be pushed out to the application.
     * 
     * @param flag the new value of the component readiness
     */
    public function set ready(flag:Boolean):void
    {
        if (_ready != flag)
        {
            _ready = flag;
            if (_ready)
            {
                if (_browserChangePending)
                {
                    //trace("committing browser change for ready: " + this + " " +  _id + ", url=" + url);
                    commitBrowserChange();
                    _browserChangePending = false;
                }
            }
    		dispatchEvent(new Event("readyChange"));
        }
    }

    /**
     * Get the value of the enabled flag, gating whether this rule is ever
     * capable of reflecting or contributing state in the application .
     */
    public function get enabled():Boolean
    {
        return _enabled;
    }    

    public function set enabled(b:Boolean):void
    {
        if (_enabled != b)
        {
            _enabled = b;
            // changing the enabled state implicitly requires some recomputation of this
            // part of the rule tree.
            invalidateState();
        }
    }    

    /**
     * A regular expression that will restrict this rule to only be active
     * for a URL that matches it.
     * 
     * <p>In the special case of rules that have a notion of an application state
     * to be extracted from the URL, the regular expression must contain a single
     * parenthesized group, whose matched contents yield this state.
     * 
     * <p>If not given or set to null this property is effectively defaulted
     * by the value of the <code>urlFormat</code> property.
     */
    [Bindable("patternFormatChange")]
    public function get urlPattern():String
    {
         return _urlPattern;
    }

    public function set urlPattern(value:String):void
    {
        _urlPattern = value;
        _urlPatternRegEx = null;   // invalidate any cached RegExp.
        dispatchEvent(new Event("patternFormatChange"));
    }

    /**
     * A string that determines the URL generated by this rule.
     *
     * <p>For rules that have a notion of application state embedded in the URL,
     * the format string must contain an asterisk "*" which will be substituted with the
     * that state
     * when the URL is generated.
     * 
     * <p>If urlPattern is not specified, it is defaulted from the urlFormat property,
     * and a default value-group regexp is substituted for the "*" character.  This
     * default regexp group will match all non-delimiting URL characters.
     */
    [Bindable("patternFormatChange")]
    public function get urlFormat():String
    {
        return _urlFormat;
    }

    public function set urlFormat(value:String):void
    {
        _urlFormat = value;
        _urlPatternRegEx = null;   // invalidate any cached RegExp.
        dispatchEvent(new Event("patternFormatChange"));
    }

    /**
     * A flag indicating that the urlPattern for this rule must occur at the beginning
     * of the URL matched by <code>matchUrlPrefix()</code>.  Its default value is true.
     */
    [Bindable("patternFormatChange")]
    public function set matchUrlBeginning(b:Boolean):void
    {
        _matchUrlBeginning = b;
        _urlPatternRegEx = null;
        dispatchEvent(new Event("patternFormatChange"));
    }

    public function get matchUrlBeginning():Boolean
    {
        return _matchUrlBeginning;
    }

    public function get urlPatternRegEx():RegExp
    {
        if (_urlPatternRegEx == null)
        {
            var pattern:String = urlPattern != null ? urlPattern : defaultPatternFromFormat(urlFormat);
            
            if (matchUrlBeginning && (pattern.length == 0 || pattern.charAt(0) != '^'))
            {
                pattern = "^" + pattern;
            }

            _urlPatternRegEx = new RegExp(pattern);
        }

        return _urlPatternRegEx;
    }
        
    public function get doesMatchUrl():Boolean
    {
        return urlPatternRegEx.test(this.url);
    }

    public function exec(url:String):Array
    {
        return urlPatternRegEx.exec(url);
    }

    // -----------------------------------------------------
    // OTHER PROTECTED AND PRIVATE METHODS
    // -----------------------------------------------------
    
    /**
     * Validate this rule such that its URL and title correspond to the
     * application state, as determined by whatever URL/state mapping
     * this rule defines.  Calls <code>computeApplicationState()</code>
     * to do the rule-specific work.
     * 
     * <p>If the rule is unable to validate its state, it throws a
     * <code>StateNotAvailableError</code> instance to indicate this failure.
     */
    protected function validateState():void
    {
        if (!_valid)
        {
            checkReadiness(null);
            if (!ready)
            {
                throw new StateNotAvailableError();
            }
            computeApplicationState();
        }
    }

    /**
     * Check this rule to determine whether it's ready, setting the
     * <code>ready</code> property to reflect this.  This function must be called
     * at any time that the readiness status of the rule may have changed.
     * 
     * <p>This method should be overridden by subclasses as needed, to impose
     * additional conditions on when the rule has been sufficiently initialized to run.
     * Overrides must set ready to false if their conditions are not met, otherwise
     * call <code>super.checkReadiness()</code>.
     */
    protected function checkReadiness(e:Event):void
    {
        ready = (_document == null || _document.initialized);
    }
    
    /**
     * Get a flag indicating 
     * @return 
     * 
     */
    protected function get valid():Boolean
    {
        return _valid;
    }
    
    protected function applyUrlFormat(stringValue:String):String
    {
        return _urlFormat != null ? _urlFormat.replace(/\*/, stringValue) : stringValue;
    }

    // regexp used for defaulted urlPattern groups; must cover all
    // legal non-meta URL characters (note that embedded ones will be
    // escaped to %NN notation and so will satisfy this regexp).
    //
    private static const DEFAULT_GROUP_REGEXP:String = "([a-zA-Z0-9%+\!\~\*\'\(\)\.\_\-]*)";
    public static function defaultPatternFromFormat(f:String):String
    {
        return f == null ? "(.*)" : f.replace(/\*/, DEFAULT_GROUP_REGEXP);
    }
}
}
