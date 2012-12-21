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
 * This event is dispatched when the internal application state has changed,
 * requiring the application container to expose a new URL and title.
 */
[Event(name="stateChange", type="flash.events.Event")]

/**
 * Interface for a general representation of an application's state
 * in terms of a URL and a title.  The application state is exposed
 * via the url and title read-only properties, and may be set from
 * whatever container is managing the application by setting
 * the containerURL property (typically an instance of UrlBrowserManager).
 * 
 * <p>State changes initiated by the application will be signaled by
 * dispatching the stateChange event.
 *
 * @see UrlBrowserManager
 */

public interface IUrlApplicationState extends IEventDispatcher
{
    /**
     * Get the URL  associated with the overall application state.
     *
     * @return a URL-encoded string that will be used as the state URL
     * representation verbatim, with no escaping.
     */
    function get url():String;
    
    /**
     * Get the title string associated with the overall application state.
     */
    function get title():String;

    /**
     * Set the URL for this application state based on some or all of a URL passed in from the container.
     * This is called after application initialization to process the initial app URL, as well as
     * for history navigation with browser Back and Forward buttons.
     * 
     * @param s the URL component being applied to this rule and its descendants.
     */
    function set containerUrl(s:String):void;

}
}
