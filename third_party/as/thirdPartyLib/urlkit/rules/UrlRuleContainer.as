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
import mx.core.*;
import mx.events.FlexEvent;

[Event(name="change", type="flash.events.Event")]

/**
 * This metadata causes the urlRules property of rule containers defined in MXML to be correctly
 * initialized from their inline MXML child rules.
 */
[DefaultProperty("urlRules")]

/**
 * UrlRuleContainer is an abstract class which provides useful
 * functionality for rules which contain child elements.
 */
public class UrlRuleContainer extends UrlBaseRule
{
    // Array of child rules.
    public var _urlRules:Array = [];

    public function UrlRuleContainer()
    {
    }

    /**
     * Set the child rules of this rule container, adjusting their
     * parent reference appropriately.
     * @param rules
     * 
     */
    public function set urlRules(rules:Array):void
    {
        for (var i:int = 0; i < _urlRules.length; ++i)
        {
            _urlRules[i].parent = null;
        }
        
        _urlRules = rules;

        for (i = 0; i < _urlRules.length; ++i)
        {
            _urlRules[i].parent = this;
        }
        
        checkReadiness(null);
    }

    public function get urlRules():Array
    {
        return _urlRules;
    }

    public function addChild(rule:IUrlRule):void
    {
        _urlRules.push(rule);
        rule.parent = this;
    }
}
}
