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
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceError;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.filters.DropShadowFilter;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.Security;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.utils.URLUtil;

	public class UserIcon extends ImagePlus
	{
		public static const knNone:Number = 0;
		public static const knWelcome:Number = 1;
		private var _nStyle:Number = 0;
		
		private static var fltWelcomeShadow:DropShadowFilter = new DropShadowFilter(1, 90, 0, 0.15, 3, 3, 1, 3);
		
		private var _acw:Array = [];
		
		private static var kstrDefaultIconUrl:String = "/graphics/user_tile_64.jpg";
		private static var kstrBlankGoogleIconUrl:String = "/graphics/BlankGoogleProfile_64.gif";
		
		public function UserIcon()
		{
			super();
			_acw.push(ChangeWatcher.watch(AccountMgr.GetInstance(), "isPremium", OnPremiumChange));
			
			// If and when we need to support other sources for user icons, we will want
			// to refactor this to be more account agnostic. Do the simple thing until this happens.
			_acw.push(ChangeWatcher.watch(AccountMgr.GetInstance(), "isGoogleAccount", OnThirdPartyChange));
			UpdateIconUrl();
			trustContent = true;
		}
		
		private static function get defaultIconUrl(): String {
			return PicnikBase.StaticUrl(AccountMgr.GetInstance().isGoogleAccount ? kstrBlankGoogleIconUrl : kstrDefaultIconUrl);
		}
		
		public function set iconStyle(n:Number): void {
			if (_nStyle == n)
				return;
			_nStyle = n;
			
			if (_nStyle == knNone) {
				borderThickness = 0;
				filters = [];
			} else if (_nStyle == knWelcome) {
				borderThickness = 1;
				filters = [fltWelcomeShadow];
			} else {
				throw new Error("Unknown icon style: ", n);
			}
			UpdateStylesForUser();
		}
		
		private function get isPremium(): Boolean {
			return AccountMgr.GetInstance().isPremium;
		}
		
		private function OnPremiumChange(evt:Event=null): void {
			UpdateStylesForUser();
		}
		
		private function OnThirdPartyChange(evt:Event=null): void {
			UpdateIconUrl();
		}
		
		private static var _obMapGoogleEmailToIconUrl:Object = {};
		private static function GetIconUrlByGoogleEmail(strEmail:String, fnUpdate:Function): String {
			try {
				if (strEmail in _obMapGoogleEmailToIconUrl) {
					return _obMapGoogleEmailToIconUrl[strEmail];
				} else {
					var ss:IStorageService = AccountMgr.GetStorageService("picasaweb");
					if (ss != null) {
						ss.GetUserInfo(function(err:Number, strError:String, dctUserInfo:Object=null): void {
							if (err == StorageServiceError.None) {
								_obMapGoogleEmailToIconUrl[strEmail] = dctUserInfo.thumbnailurl;
								PicnikBase.app.callLater(fnUpdate);
							}
						});
					}
				}
			} catch (e:Error) {
				// Ignore errors. Simply return null
				trace("Ignoring error in UserIcon.GetIconUrlByGoogleEmail", e);
			}
			return null;
		}
		
		private function LoadRemoteImage(strBaseImageURL:String): String {
			// load policy file just in case we need it for a direct load. Flash caches these.
			return strBaseImageURL;
		}
		
		private function UpdateIconUrl(): void {
			var strUrl:String = null;
			if (AccountMgr.GetInstance().isGoogleAccount)
				strUrl = GetIconUrlByGoogleEmail(AccountMgr.GetInstance().email, UpdateIconUrl);

			if (strUrl != null) {
				try {
					bundled = false;
					Security.loadPolicyFile(URLUtil.getProtocol(strUrl) + "://" + 
						URLUtil.getServerNameWithPort(strUrl) +  "/crossdomain.xml");
				} catch (e:Error) {
					strUrl = null; // Failed to parse url
				}
			}
			
			if (strUrl == null) {
				bundled = true;
				strUrl = defaultIconUrl;
			}
			
			source = strUrl;
		}
		
		private function UpdateStylesForUser(): void {
			if (_nStyle == knWelcome) {
				borderColor = (isPremium) ? 0xffe100 : 0xffffff
			}
		}
	}
}