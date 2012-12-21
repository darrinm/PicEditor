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
	/** Try to load an image directly, if that fails, proxy it through our server.
	 * Use URLLoader to do a quick check of the presence of a crossdomain.xml file.
	 * Remember the domain so we do not have to check next time.
	 */
	
	import com.adobe.utils.StringUtil;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	
	import mx.controls.Image;
	import mx.core.Application;
	import mx.core.mx_internal;
	import mx.utils.URLUtil;

	use namespace mx_internal;

	public class ProxyImage extends Image
	{
		private var _fDoneChecking:Boolean = false;
		private var _urll:URLLoader = null;
		private var _fProxied:Boolean = false;
		
		public var offscreen:Boolean = true; // When true, setting the source will trigger a commit properties call

		/** As an optimization, we can add frequently accessed domains
		 * known to hvae crossdomain.xml files. This will need to be
		 * carefully maintained. If you prefer, leave it blank.
		 */
		private static const kastrAccessibleDomainSuffixes:Array =
			[".ggpht.com", // Picasa Web Albums
			"static.flickr.com", // Flickr
			];
		
		private static var _obDomainAccess:Object = {};

		//////////////////////////////////////////////////////////////////
		/** BEGIN: Site specific seciton. Edit these to match your site */
		
		private static const kstrLocalUrl:String = "http://www.mywebsite.com/"; // used to convert relative urls to local urls to get the domain
		private static const kstrLocalSuffix:String = "mywebsite.com";
		
		private function CreateProxyUrl(strUrl:String): String {
			// Do some magic
			strUrl = PicnikService.serverURL + "/proxy?method=get&url=" + encodeURIComponent(strUrl);
			return strUrl;
		}
		
		/** END: Site specific seciton. Edit these to match your site   */
		//////////////////////////////////////////////////////////////////
		
		public function ProxyImage()
		{
			super();
			loaderContext = new LoaderContext(true);
			
			addEventListener(Event.INIT, OnInit);
		}
		
		private function IsLocal(strDomain:String): Boolean {
			return StringUtil.endsWith(strDomain, "." + kstrLocalSuffix) || strDomain == kstrLocalSuffix;
		}
		
		override public function load(url:Object=null):void {
			try {
				super.load(url);
			} catch (e:Error) {
				// Ignore load errors.
			}
		}
		
		private function OnInit(evt:Event): void {
			var ldr:Loader = contentHolder as Loader;
			if (ldr && ldr.contentLoaderInfo) {
				try {
					var fHasAccess:Boolean = ldr.contentLoaderInfo.childAllowsParent;
					_obDomainAccess[UrlToDomain(ldr.contentLoaderInfo.url)] = fHasAccess;
					if (!fHasAccess) {
						// Oops, we need to proxy the domain
						SetSource(ldr.contentLoaderInfo.url, true);
					}
				} catch (e:Error) {
					// Not available? Strange... Assume we have access, but don't make a note of it.
				}
			}
		}
		
		private static function UrlToDomain(strUrl:String): String {
			return URLUtil.getServerName(URLUtil.getFullURL(kstrLocalUrl, strUrl)).toLowerCase();
		}
		
		private function SetSource(value:Object, fProxy:Boolean=false): void {
			if (fProxy) {
				value = CreateProxyUrl(String(value));
				_fProxied = true;
			}
			super.source = value;
			if (offscreen)
				Application.application.callLater(validateProperties);
		}
		
		private function Cleanup(): void {
			if (_urll) {
				try {
					_urll.close();
				} catch (e:Error) {
					
				}
				_urll = null;
			}
		}
		
		private function DomainWithAccess(strDomain:String): Boolean {
			for each (var strSuffix:String in kastrAccessibleDomainSuffixes) {
				if (StringUtil.endsWith(strDomain, strSuffix))
					return true;
			}
			return false;
		}
		
		override public function set source(value:Object):void {
			Cleanup();
			_fProxied = false;
			
			var fSetDirectly:Boolean = true;
			
			// UNDONE: Check for known sites, e.g. Picnik, Flickr, Picasa
			if (value is String && String(value).length > 0) {
				var strUrl:String = String(value);
				var strDomain:String = UrlToDomain(strUrl);
				if (IsLocal(strDomain)) {
					// Pass through
				} else if (strDomain in _obDomainAccess) {
					// We have seen this domain before
					if (!_obDomainAccess[strDomain])
						value = CreateProxyUrl(strUrl); // We need to proxy
				} else if (DomainWithAccess(strDomain)) {
					// Pass through
				} else {
					// Unknown domain. Check it.
					fSetDirectly = false;
					
					var fnOnSuccess:Function = function(evt:Event): void {
						// Found a cross domain. Just load it directly
						SetSource(strUrl);
						_obDomainAccess[strDomain] = true;
						Cleanup();
					}
					
					var fnOnError:Function = function(evt:Event): void {
						// Found a cross domain. Just load it directly
						SetSource(strUrl, true);
						_obDomainAccess[strDomain] = false;
						Cleanup();
					}
					
					var urll:URLLoader = new URLLoader();
					_urll = urll;
					urll.addEventListener(Event.COMPLETE, fnOnSuccess);
					urll.addEventListener(Event.OPEN, fnOnSuccess);
					urll.addEventListener(ProgressEvent.PROGRESS, fnOnSuccess);
					urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnOnError);
					urll.load(new URLRequest(String(value)));
				}
			}
			if (fSetDirectly) {
				SetSource(value);
			}
		}
	}
}
