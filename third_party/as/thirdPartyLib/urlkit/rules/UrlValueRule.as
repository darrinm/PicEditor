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
import mx.binding.utils.*;
import mx.controls.*;

/**
 * This event is dispatched when the URL component for this value changes.
 */
[Event(name="change", type="flash.events.Event")]

/**
 * A type of rule element that exposes a value mapped to a specific
 * portion of its URL as determined by its urlFormat and/or urlPattern.  When that URL portion changes,
 * the value properties of the associated UrlValueRule also change.  Conversely,
 * if a value property of a UrlValueRule is changed by the application, this causes the browser
 * to recalculate the overall URL based on the new value.
 * 
 * <p>Ultimately UrlValueRules (or their subclasses such as UrlNavigatorRules)
 * are the places where parts of the URL are connected
 * to specific pieces of state in the application.
 * 
 * <p>This may be done by setting this rule's stringValue property and listening
 * for "change" events indicating that the browser has changed this property, or
 * more conveniently by specifying the sourceValue property as a dot-delimited
 * binding expression for a scalar String, Number or Boolean property of the current
 * MXML document to be bidirectionally bound to this rule.
 */
public class UrlValueRule extends UrlBaseRule
{
    // Representation of the string form of the value-related portion of this URL, with all URL-encoding
    // of escaped characters translated into the corresponding Unicode.
    private var _stringValue:String = "";
    
    // A default application value to be used for an unset value rule.
    private var _defaultValue:Object = null;
    
    // A ChangeWatcher monitoring this rule and adjusting the sourceValue property
    private var _sourceValueLHS:ChangeWatcher;

    // A ChangeWatcher monitoring the sourceValue property and adjusting this rule
    private var _sourceValueRHS:ChangeWatcher;
    
    // A ChangeWatcher monitoring the object off of which the terminal sourceValue property is accessed
    private var _sourceValueRHSUpdater:ChangeWatcher;
    
    // Cached value for the dot-delimited sourceValue property
    private var _sourceValueExpression:String;

    // Cached parsed array of sourceValue property components suitable for passing to BindingUtils
    private var _sourceValueProps:Array;
    
    public function UrlValueRule()
    {
    }

    /**
     * Compute the application state by encoding this rule's string value as this rule's URL
     * subject to formatting determined by the rule's urlFormat property.
     * If the string value equals the defaultStringValue for this rule, then that URL
     * is always computed as the empty string (so that defaulted values do not take up space
     * in the URL).
     */    
    override protected function computeApplicationState():void
    {
        if (_stringValue != defaultStringValue)
        {
            url = applyUrlFormat(encodeURIComponent(_stringValue));
        }
        else
        {
            url = "";
        }
    }

    /**
     * Commit a browser change to this rule by altering its string value, subject to
     * parsing determined by the rule's urlFormat and urlPattern properties.  If no value
     * was explicitly supplied in the URL then the default value for this rule is used.
     */
    override protected function commitBrowserChange():void
    {
        var result:Array = exec(url);
        var newValue:String = decodeURIComponent(result != null ? result[1] : "");
        if (newValue == null || newValue == "")
        {
            newValue = defaultStringValue;
        }

        if (_stringValue != newValue)
        {
            _stringValue = newValue;
            super.commitBrowserChange();
        }
    }

    override public function get doesMatchUrl():Boolean
    {
        //if we have a defaultStringValue, then an empty string matches
        return (!url && _defaultValue != null) || super.doesMatchUrl;
    }

    override public function matchUrlPrefix(url:String):String
    {
        var result:String = super.matchUrlPrefix(url);
        
        //return an empty string if there's no match, but we have a default value
        //so that we match, but won't eat anything up
        if (result == null && _defaultValue != null)
        {
            result = "";
        }
        
        return result; 
    }

    /**
     * A default value for this rule which is to be mapped to an absent or empty URL value.
     */
    public function get defaultValue():Object
    {
        return _defaultValue;
    }
    
    public function set defaultValue(s:Object):void
    {
        _defaultValue = s;
    }

    protected function get defaultStringValue():String
    {
        if (_defaultValue is Boolean)
            return Boolean(_defaultValue) == true ? "t" : "f";

        if (_defaultValue != null)
            return _defaultValue.toString();

        return "";
    }

    /**
     * An application state property that is bidirectionally coupled to the value-related
     * portion of this rule's URL, as determined by its urlPattern and urlFormat properties.
     */
    [Bindable("change")]
    public function get stringValue():String
    {
        return _stringValue;
    }
    
    public function set stringValue(s:String):void
    {
        if (s == null || s == "")
        {
            s = defaultStringValue;
        }

        // NOTE: the invalidation of our state is not conditional
        // on whether _stringValue has actually changed, because
        // the fact that the property was set at all signifies that
        // there should be some kind of recalculation (perhaps involving
        // alternative possible child rules of a ONE-type UrlRuleSet).
        _stringValue = s;
        invalidateState();
    }

    /**
     * Numeric property providing transparent URL encoding of values
     */
    [Bindable("change")]
    public function get numberValue():Number
    {
        return Number(stringValue);
    }
    
    public function set numberValue(n:Number):void
    {
        stringValue = n.toString();
    }
        
    /**
     * Boolean property providing transparent URL encoding of values.
     * Note that for brevity in the URL, the characters 't' and 'f'
     * are used to represent the constants true and false.
     */
    [Bindable("change")]
    public function get booleanValue():Boolean
    {
        return (stringValue == "t");
    }
    
    public function set booleanValue(b:Boolean):void
    {
        stringValue = b ? "t" : "f";
    }

    /**
     * Provides this rule with a dot-delimited binding expression
     * that references a Bindable property accessible from the containing MXML document.
     * If provided, this rule will automatically listen for change events on that property
     * and trigger the appropriate browser URL changes; it will also apply browser-initiated URL changes
     * by setting this property when necessary.
     * 
     * @param s a binding expression containing one or more property name components.
     * Array indices and functions may not be used.
     */
    public function set sourceValue(s:String):void
    {
        if (_sourceValueExpression != s)
        {
            _sourceValueExpression = s;
            _sourceValueProps = s.split(".");
            setupWatcher();
        }
    }

    protected function setObjectValue(o:Object):void
    {
        if (o is Boolean)
            booleanValue = o as Boolean;
        else
        if (o is Number)
            numberValue = o as Number;
        else
        if (o != null)
            stringValue = o.toString();
        else
            stringValue = "";
    }

    override public function initialized(document:Object, id:String):void
    {
        super.initialized(document, id);
        
        setupWatcher();
    }

    protected function setRhsSite(o:Object):void
    {
        if (_sourceValueRHS != null)
        {
            _sourceValueRHS.unwatch();
            _sourceValueRHS = null;
        }

        if (o != null)
        {
            var propName:String = _sourceValueProps[_sourceValueProps.length - 1];
            var propValue:Object = (propName in o) ? o[propName] : null;
            var propSource:String = propValue is Boolean
                                        ? "booleanValue"
                                        : propValue is Number
                                            ? "numberValue"
                                            : "stringValue";
    
            _sourceValueRHS = BindingUtils.bindProperty(o, propName, this, propSource);
        }
    }

    protected function setupWatcher():void
    {
        if (_document)
        {
            if (_sourceValueLHS != null)
            {
                _sourceValueLHS.unwatch();
                _sourceValueLHS = null;
            }

            if (_sourceValueRHSUpdater != null)
            {
                _sourceValueRHSUpdater.unwatch();
                _sourceValueRHSUpdater = null;
            }

            if (_sourceValueProps)
            {
                _sourceValueLHS = BindingUtils.bindSetter(setObjectValue, _document, _sourceValueProps);

                if (_sourceValueProps.length > 1)
                {
                    _sourceValueRHSUpdater = BindingUtils.bindSetter(setRhsSite, _document, _sourceValueProps.slice(0, _sourceValueProps.length - 1));
                }
                else
                {
                    setRhsSite(_document);
                }
            }
        }
    }

    override public function get active():Boolean
    {
        return super.active && (_defaultValue != null || _stringValue);
    }
}
}
