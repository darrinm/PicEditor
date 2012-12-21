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

/**
 * UrlRuleSet is a general container for a set of rules that act in
 * parallel (although not necessarily at the same time).  It computes
 * a URL by concatenating the URLs provided by each of its active
 * children, ignoring inactive rules.  It parses a URL by letting each
 * child interpret the URL as it sees fit.
 *
 * <p>There are three types of UrlRuleSet behavior, distinguished by the setting
 * of the type property:
 * <ul>
 * <li>The ALL type maps its URL to the concatenation of each of its child rule's URLs.
 * Every child rule must be active with its pattern restrictions satisfied, for this
 * mapping to be valid.  This is the default type of UrlRuleSet.  The application-generated
 * URL for an unsatisfied ALL-type UrlRuleSet (in which one or more child rules are inactive)
 * is the empty string.
 * <li>The ANY type maps its URL to the concatenation of each child rule's URLs, with
 * the difference that inactive children are simply ignored.  This is handy for a URL with optional
 * elements corresponding to child rules that may or may not apply.
 * <li>The ONE type maps its URL to a single active child rule.  The first applicable child rule
 * processes an entire browser-supplied URL, and the first active child rule determines the entire
 * application-supplied URL.
 * </ul>
 * 
 * <p>A top-level rule element is usually a UrlRuleSet, but
 * UrlRuleSets can also be used in the interior of a rule tree.
 */
public class UrlRuleSet extends UrlRuleContainer
{
    public static const ALL:String = "all";
    public static const ANY:String = "any";
    public static const ONE:String = "one";
        
    [Bindable]
    public var type:String = ALL;
    
    public function UrlRuleSet()
    {
    }

    /**
     * Commit a browser-supplied URL to this rule set.  Overridden
     * to implement rule-set-specific policies.
     */
    override protected function commitBrowserChange():void
    {
        var matchedUrlPrefixes:Array = getMatchPrefixes(url);
        if (matchedUrlPrefixes.length > 0)
        {
            if (urlRules)
            {
                for (var i:int = 0; i < urlRules.length; i++)
                {
                    var rule:IUrlRule = urlRules[i];
                    rule.containerUrl = matchedUrlPrefixes[i];
                    
                    if (type == ONE && matchedUrlPrefixes[i] != null)
                    {
                        break;
                    }
                }
            }
            super.commitBrowserChange();
        }
    }

    /**
     *  Refresh the rule set's URL based on the application state.
     *  Overridden to apply ALL, ANY and ONE policies.
     */
    override protected function computeApplicationState():void
    {
        var newUrl:String = "";
        var newTitle:String = "";
        var ruleApplied:Boolean = false;
        
        for (var i:int = 0; urlRules != null && i < urlRules.length; i++)
        {
            var rule:IUrlRule = urlRules[i];
            if (rule.active)
            {
                ruleApplied = true;
                newUrl += rule.url;
                var childTitle:String = rule.title;
                if (childTitle)
                {
                    newTitle += childTitle;
                }
                
                if (type == ONE)
                {
                    break;
                }
            }
            else if (type == ALL)
            {
                // If anything below us is inactive in an ALL rule,
                // then the URL is blank.
                ruleApplied = false;
                break;
            }
        }
        
        if (ruleApplied)
        {
            url = applyUrlFormat(newUrl);
            _title = newTitle;
        }
        else
        {
            url = "";
            title = "";
        }
        
        super.computeApplicationState();        
    }
    
    private function getMatchPrefixes(s:String):Array
    {
        var matchedUrlPrefixes:Array = [];
        
        // start matching based on whatever this rule admits
        var tempUrl:String = super.matchUrlPrefix(s);
        
        // now look at all children and let them bite off the chunks they can work with
        for (var i:int = 0; i < urlRules.length; i++)
        {
            var matchUrl:String = urlRules[i].matchUrlPrefix(tempUrl);
            matchedUrlPrefixes[i] = matchUrl;
            
            var startPos:int = (matchUrl != null) ? tempUrl.indexOf(matchUrl) : -1;

            if (startPos != -1)
            {
                if (type == ONE)
                {
                    break;
                }
                tempUrl = tempUrl.substring(0, startPos) + tempUrl.substring(startPos + matchUrl.length);
            }
            else if (type == ALL)
            {
                matchedUrlPrefixes = [];
                break;  // failure to match means we blow outta here
            }
        }

        return matchedUrlPrefixes;
    }
}
}
