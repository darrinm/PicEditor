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

[Event(name="ruleChanged", type="flash.events.Event")]
[Event(name="change", type="flash.events.Event")]

/**
 * A UrlDelegateRule is used to dynamically splice a child rule into a
 * parent rule tree, when the child rule's identity is computed.  The
 * parent tree contains a UrlDelegateRule whose 'rule' property is set
 * to the child rule to be spliced in at that point.
 *
 * <p>This is useful when the children of a navigation container such
 * as a ViewStack contain rule subtrees, and only the selected child's
 * subtree should participate in the URL/state mapping.
 */

public class UrlDelegateRule extends UrlBaseRule
{
    // The child rule to which this rule delegates.
    private var _rule:IUrlRule;
	
	public function UrlDelegateRule()
	{
	}
	
    /**
     * Compute a delegate rule's state by copying its child rule's state.
     * 
     */
    override protected function computeApplicationState():void
    {
        if (rule != null)
        {
            _title = rule.title;
            url = rule.url;      // note: url is set after title 
        }
        super.computeApplicationState();
    }
    
    /**
     * Commit a new delegate rule's state by propagating its URL to the child.
     * 
     */
    override protected function commitBrowserChange():void
    {
        if (rule != null)
        {
            rule.containerUrl = url;
        }
        super.commitBrowserChange();
    }

    /**
     * @return The child rule to which this UrlDelegateRule should delegate.
     */
    [Bindable("ruleChanged")]
    public function get rule():IUrlRule
    {
        return _rule;
    }
	
    /**
     * Set the child rule, setting its parent reference to this rule.
     * Also invalidate our state.
     * @param r
     * 
     */
    public function set rule(r:IUrlRule):void
    {
        if (_rule != null)
        {
            _rule.parent = null;
        }
	    
        _rule = r;

        if (_rule != null)
        {
            _rule.parent = this;
        }
		
		// re-check our readiness since child rules are often set up asynchronously
		// by bindings, at which point we'll want to re-commit a pending browser change.
		checkReadiness(null);
		
		// invalidate any computed state at this point, since we've got a new child.
		invalidateState();
		
        dispatchEvent(new Event("ruleChanged"));
    }
	
    /**
     * A delegate rule's active status is delegated to its child rule.
     * @see UrlBaseRule#active()
     * 
     */
    override public function get active():Boolean
    {
    	return (rule != null) ? rule.active : false;
    }

    /**
     * A delegate rule's URL prefix matching is delegated to its child rule.
     * @see UrlBaseRule#matchUrlPrefix()
     */    
    override public function matchUrlPrefix(url:String):String
    {
    	//if rule is null, return url instead of null
    	//to allow for a possible match, because when a
    	//delegate rule is used in combination with a navigator
    	//rule, the delegated rule may not get set until the
    	//navigator url is first set
    	return (rule != null) ? rule.matchUrlPrefix(url) : url;
    }

    /**
     * Check this rule to determine whether it's ready.  Readiness of a
     * delegate rule requires that it have a child rule to which it can delegate.
     */
    override protected function checkReadiness(e:Event):void
    {
        if (rule == null)
        {
            ready = false;
        }
        else
        {
            super.checkReadiness(e);
        }
    }
}
}
