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
// Browser type as detected by getBrowser()
/** @export */
var browser = '';

// Default app state URL to use when no fragment ID present
/** @export */
var defaultUrl = '';

// Last-known app state URL
/** @export */
var curUrl = document.location.href;

// Initial URL (used only by IE)
/** @export */
var initialUrl = document.location.href;

// used by safari code, 'cause it has some flickr issues
/** @export */
var flickr = false;

// History frame source URL prefix (used only by IE)
/** @export */
var historyFrameSourcePrefix = 'h.html?'; // Running from everywhere else

// do some flickr-specific hacking
if (initialUrl.indexOf('flickr.com/') != -1) {
	historyFrameSourcePrefix = '/picnik/hflickr.html?'; // Running from Flickr's server
	flickr = true;
} else if (initialUrl.indexOf('/flickr/') != -1) {
	historyFrameSourcePrefix = '/flickr/picnik/hflickr.html?'; // Running in our Flickr simulation
	flickr = true;
}

// History maintenance (used only by Safari)
/** @export */
var curHistoryLength = -1;
/** @export */
var historyHash = new Array();

/** @export */
var fCanUpdateHref = true;

/* Autodetect browser type; sets browser var to 'IE', 'Safari', 'Firefox' or empty string. */
/** @export */
function getBrowser()
{
    var name = navigator.appName;
    var agent = navigator.userAgent.toLowerCase();

    if (name.indexOf('Microsoft') != -1)
    {
        if (agent.indexOf('mac') == -1)
        {
            browser = 'IE';
            // note that Mac IE is considered to be uncategorized
        }
    }
    // 2010-04-27 steveler added chrome detection
    else if (agent.indexOf('chrome') != -1)
    {
        browser = 'Chrome';
    }
    else if (agent.indexOf('safari') != -1)
    {
        browser = 'Safari';
    }

    else if (agent.indexOf('firefox') != -1)
    {
        browser = 'Firefox';
    }
}

/* Get the Flash player object for performing ExternalInterface callbacks. */
/** @export */
function getPlayer()
{
    var player = document.getElementById(getPlayerId());
   
    if (player == null)
        player = document.getElementsByTagName('object')[0];
   
	// STL commented out -- SWFObject does slightly different embedding
	// and this code is not compatible with it.
	// see http://fbflex.wordpress.com/2008/07/05/getting-the-flex-browsermanager-working-with-swfobject/
    //if (player == null || player.object == null)
    //    player = document.getElementsByTagName('embed')[0];

    return player;
}

/* Get the current location hash excluding the '#' symbol. */
/** @export */
function getHash()
{
   // It would be nice if we could use document.location.hash here,
   // but it's faulty sometimes.
   var idx = document.location.href.indexOf('#');
   return (idx >= 0) ? document.location.href.substr(idx+1) : '';
}

/* Set the current browser URL; called from inside URLKit to propagate
 * the application state out to the container.
 */
/** @export */
function setBrowserUrl(flexAppUrl)
{
    if (!fCanUpdateHref) return;
   var pos = document.location.href.indexOf('#');
   var baseUrl = pos != -1 ? document.location.href.substr(0, pos) : document.location.href;
   var newUrl = baseUrl + '#' + flexAppUrl;
   if (document.location.href != newUrl && document.location.href + '#' != newUrl)
   {
       curUrl = newUrl;
       addHistoryEntry(baseUrl, newUrl, flexAppUrl);
       curHistoryLength = history.length;
   }
   return false;
}

/* Add a history entry to the browser.
 *   baseUrl: the portion of the location prior to the '#'
 *   newUrl: the entire new URL, including '#' and following fragment
 *   flexAppUrl: the portion of the location following the '#' only
 */
/** @export */
function addHistoryEntry(baseUrl, newUrl, flexAppUrl)
{
    if (!fCanUpdateHref) return;
    if (browser == 'IE')
    {
        if (document.location.href.indexOf('host=facebook') > 0) {
            fCanUpdateHref = false;
            return;
        }
        //Check to see if we are being asked to do a navigate for the first
        //history entry, and if so ignore, because it's coming from the creation
        //of the history iframe
        if (flexAppUrl == defaultUrl && document.location.href == initialUrl)
        {
            curUrl = initialUrl;
            return;
        }
        if (!flexAppUrl)
        {
            newUrl = baseUrl + '#' + defaultUrl;
        }
        else
        {
       	 	// for IE, tell the history frame to go somewhere without a '#'
       	 	// in order to get this entry into the browser history.
            getHistoryFrame().src = historyFrameSourcePrefix + flexAppUrl;
        }
        document.location.href = newUrl;
        fCanUpdateHref = (document.location.href == newUrl);
    }
    else
    {
	    if (browser == 'Safari')
	    {
            if (document.location.href.indexOf('host=facebook') > 0) {
                fCanUpdateHref = false;
                return;
            }
            var strSafari = 'safari/';
            var agent = navigator.userAgent.toLowerCase();
            var strVersion = agent.substr( agent.indexOf(strSafari) + strSafari.length );
            var nVersion = parseFloat(strVersion);
            if (nVersion > 500) {
                // Safari v3.0 or greater
                // put the location right in the url
                document.location.href = newUrl;
            } else {
                // Safari v2.0 or lesser
                // submit a form whose action points to the desired URL
                if (flickr && nVersion == 419.3) {
                    // don't do anything in this case because safari 3.0 misrepresents its
                    // version as 419.3 when loading flickr, and that breaks URLKit
				} else {
                    getFormElement().innerHTML = '<form name="historyForm" action="' + newUrl + '" method="GET"></form>';
                    document.forms.historyForm.submit();
                }
            }
	        // We also have to maintain the history by hand for Safari
            historyHash[history.length] = flexAppUrl;
	   }
	   else
	   {
	   		// Otherwise, write an anchor into the page and tell the browser to go there
		    addAnchor(flexAppUrl);
	        document.location.hash = flexAppUrl;
	   }
    }
}

/* Called periodically to poll to see if we need to detect navigation that has occurred */
/** @export */
function checkForUrlChange()
{
    if (!fCanUpdateHref) return;
    if (browser == 'IE')
    {
        if (curUrl != document.location.href)
        {
             //This occurs when the user has navigated to a specific URL
             //within the app, and didn't use browser back/forward
             //IE seems to have a bug where it stops updating the URL it
             //shows the end-user at this point, but programatically it
             //appears to be correct.  Do a full app reload to get around
             //this issue.
             curUrl = document.location.href;
             document.location.reload();
        }
    }
    else if (browser == 'Safari')
    {
    	// For Safari, we have to check to see if history.length changed.
        if (curHistoryLength >= 0 && history.length != curHistoryLength)
        {
        	// If it did change, then we have to look the old state up
        	// in our hand-maintained array since document.location.hash
        	// won't have changed, then call back into URLKit.
        	curHistoryLength = history.length;
            var flexAppUrl = historyHash[curHistoryLength];
            if (flexAppUrl == '')
                flexAppUrl = defaultUrl;
            getPlayer().setPlayerUrl(flexAppUrl);
        }
    }
    else
    {
        if (curUrl != document.location.href)
        {
        	// Firefox changed; do a callback into URLKit to tell it.
            curUrl = document.location.href;
            var flexAppUrl = getHash();
            if (flexAppUrl == '')
                flexAppUrl = defaultUrl;
            getPlayer().setPlayerUrl(flexAppUrl);
        }
    }
   setTimeout(checkForUrlChange, 250);
}

/** @export */
function setDefaultUrl(def)
{
   defaultUrl = def;
                    //trailing ? is important else an extra frame gets added to the history
                    //when navigating back to the first page.  Alternatively could check
                    //in history frame navigation to compare # and ?.
	if (browser == 'IE')
	{
	   getHistoryFrame().src = historyFrameSourcePrefix + defaultUrl;
    }
    else if (browser == 'Safari')
    {
    	curHistoryLength = history.length;
    	historyHash[curHistoryLength] = defaultUrl;
	}
}

/** @export */
function setTitle(title)
{
	document.title = title;
}
// Added for IE Fix
/** @export */
function getTitle()
{
       return document.title;
}

/* Write an anchor into the page to legitimize it as a URL for Firefox et al. */
/** @export */
function addAnchor(flexAppUrl)
{
   if (document.getElementsByName(flexAppUrl).length == 0)
   {
       getAnchorElement().innerHTML += "<a name='" + flexAppUrl + "'>" + flexAppUrl + "</a>";
   }
}

// Accessor functions for obtaining specific elements of the page.

/** @export */
function getHistoryFrame()
{
    return document.getElementById('historyFrame');
}

/** @export */
function getAnchorElement()
{
    return document.getElementById('anchorDiv');
}

/** @export */
function getFormElement()
{
    return document.getElementById('formDiv');
}

// Initialization

getBrowser();
setTimeout(checkForUrlChange, 250);
