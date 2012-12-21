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
import mx.core.*
import mx.utils.StringUtil;;

/**
 * This event is dispatched when the URL associated with a rule changes
 * in response to browser navigation.  It is not dispatched in response
 * to internal application state changes.
 */
[Event(name="change", type="flash.events.Event")]

/**
 * Interface for a general element of a URL rule tree.  Each element
 * of the tree represents a mapping between some component of the
 * application's current URL and some subset of the application's
 * state.
 */

public interface IUrlRule extends IUrlApplicationState
{
    /**
     * Get the active flag for a rule.  Rules that are not active do not
     * contribute components to the URL representation of the application state.
     */
    function get active():Boolean;

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
    function matchUrlPrefix(url:String):String;

    /**
     * Set the parent rule of this rule.  When a rule's application state is invalidated,
     * its parent rule is also invalidated.  This chain eventually reaches the top-level rule set,
     * where it requests the UrlBrowserManager to update itself from the top-level rule's
     * URL.
     * 
     * @param rule the IUrlRule instance to be used as this rule's parent, or null if no parent exists.
     */
    function set parent(rule:IUrlRule):void;

    /**
     * Invalidate the application state of this rule, which ultimately requests the browser
     * to update its location bar from the top-level rule's URL.
     */    
    function invalidateState():void;

}
}
