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
package {
	// ServiceManager.as gives us a place to store all the special things we do for
	// external partners & api users
	
	// UNDONE: document all these attributes and what effect they have on the application
	// service: Used to do AccountMgr.GetThirdPartyAccount lookups. This is a case-sensitive ID which
	// 		should match those found in AccountMgr and *StorageService. UNDONE: Define as constants in a ServiceId.as?
	// friendly_name: Displayed to humans but not localized. Sent along with feedback and used to say "Connecting to "...
	// show_welcome:
	//		"per-user" -- display a service-specific welcome dialog once for each user of that service. This presumes
	//				that before ShowWelcome is called the user has been logged into their Picnik account
	//		"per-install" -- display a service-specific welcome dialog the first time Picnik is launched per machine by a service
	//		"false" (default) -- don't display a service-specific welcome dialog
	// hide_watermark: this functionality has been removed
	// hide_fullscreen_ads:
	// freemium_model:
	// cobrand_image:
	// add_imports_to_recent_imports:
	// hide_upgrade_bar:
	// external_faq:
	// external_skin:
	// lite_ui:
	
	// These are all Picnik Service API parameters. See the public API documentation for their usage.
	// _apikey:
	// _page:
	// _default_in:
	// _default_out:
	// _noads:
	// _exclude:
	// _ss:
	// _ss_cmd:
	// _out_quality:
	// _host_name:
	// _export:
	// _close_target:
	
	import dialogs.DialogManager;
	
	import flash.display.Loader;
	import flash.net.URLRequest;
		
	public class ServiceManager {		

		private static const kApiAttributes:Array = [
			{	service: "Service Name",			
				_apikey: "api key number",
				hide_watermark: "true",
				hide_fullscreen_ads: "true",
				hide_banner_ads: "true",
				_noads: "true",
				_page: "/edit",
				_exclude: "home,in,out",

				friendly_name: "Friendly Service Name",
				hide_upgrade_bar: "true",
				lite_ui: "true",
				external_skin: "/apicontent/aki key here/service skin.swf",
				
				// these defaults should actually be set by photobox
				_out_quality: "10",
				_host_name: "used for messaging",
				_export: "http://www.example.com",
				_close_target: "http://www.example.com" }
		];

						
		public static function GetDefaultParameters(strApiKey:String): Object {
			return ServiceManager.ApiKeyToAttributes(strApiKey);
		}
		
		public static function GetFriendlyName(strService:String): String {
			if (!strService) return null;
			for (var i:int=0; i < ServiceManager.kApiAttributes.length; i++) {			
				if (ServiceManager.kApiAttributes[i].service.toLowerCase() == strService.toLowerCase())
					return ServiceManager.kApiAttributes[i].friendly_name;
			}
			return null;
		}
		
		public static function ApiKeyToService(strApiKey:String): String {
			var obAttr:Object = ServiceManager.ApiKeyToAttributes(strApiKey);
			if (obAttr)
				return obAttr.service;
			return null;
		}

		public static function HostToApiKey(strHost:String): String {
			for (var i:int = 0; i < ServiceManager.kApiAttributes.length; i++) {			
				if (strHost == ServiceManager.kApiAttributes[i].service.toLowerCase())
					return ServiceManager.kApiAttributes[i]._apikey;
			}
			return null;
		}

		public static function ServiceToApiKey(strHost:String): String {
			if (strHost == null)
				return null;
				
			for (var i:int=0; i < ServiceManager.kApiAttributes.length; i++) {			
				if (strHost.toLowerCase() == ServiceManager.kApiAttributes[i].service.toLowerCase())
					return ServiceManager.kApiAttributes[i]._apikey;
			}
			return null;
		}

		public static function GetAttribute(strApiKey:String, strAttribute:String, def:*=undefined): * {
			var obAttr:Object = ServiceManager.ApiKeyToAttributes(strApiKey);
			if (obAttr && (strAttribute in obAttr))
				return obAttr[strAttribute];	
				
			// try again, but use assume that strApiKey is actually the service name
			obAttr = ServiceManager.ApiKeyToAttributes(ServiceManager.ServiceToApiKey(strApiKey));
			if (obAttr && (strAttribute in obAttr))
				return obAttr[strAttribute];	
			return def;
		}
		
		public static function LoadCobrandImage(strApiKey:String): void {
			// Try to load a cobrand image associated with this apikey
			var url:String = ServiceManager.GetAttribute(strApiKey, "cobrand_image", null);
			if (url == null)
				return;

			var ldr:Loader = new Loader();
			ldr.load(new URLRequest(PicnikBase.StaticUrl(url)));
			var idl:ImageDownloadListener = new ImageDownloadListener(ldr, null,
				function (ldr:Loader, err:Number, strError:String=null, obData:Object=null): void {
					if (ldr == null || !ldr.content)
						return;
							
					PicnikBase.app._imgCobrand.source = ldr.content;
					idl.autoDispose = false;
				});
		}
		
		public static function GetExternalFAQ(strApiKey:String, strLocale:String): String {
			// Returns the URL of an external FAQ associated with this apikey
			var url:String = ServiceManager.GetAttribute(strApiKey, "external_faq", null);
			if (url == null)
				return null;
			
			url = url.replace(/{locale}/, strLocale);
			return PicnikBase.StaticUrl(url);
		}

		public static function ShowWelcomeDialog(strApiKey:String): void {
			var obAttr:Object = ServiceManager.ApiKeyToAttributes(strApiKey);
			if (obAttr == null) return;
			var strWelcome:String = obAttr.show_welcome;
			if (!PicnikConfig.freeForAll && strWelcome && strWelcome != "false") {
				var strWelcomeShown:String = null;
				var fSuppress:Boolean = false;
				if (strWelcome=="per-user") {
					var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount(obAttr.service);
					var strTpaUserId:String = tpa.GetUserId();
					if (strTpaUserId) {
						strWelcomeShown = "PicnikBase." + obAttr.service + "." + strTpaUserId + ".fWelcomeShown";
					} else {
						fSuppress = true;
					}
				} else if (strWelcome=="per-install") {
					strWelcomeShown = "PicnikBase." + obAttr.service + ".fWelcomeShown";
				}
				if (!fSuppress && (!strWelcomeShown || !PicnikBase.GetPersistentClientState(strWelcomeShown, false))) {
					DialogManager.ShowRegisterTab("Welcome");
					if (strWelcomeShown) {
						PicnikBase.SetPersistentClientState(strWelcomeShown, true);
					}
				}
			}
		}
		
		private static function ApiKeyToAttributes(strApiKey:String): Object {
			for (var i:int=0; i < ServiceManager.kApiAttributes.length; i++) {			
				if (ServiceManager.kApiAttributes[i]._apikey == strApiKey)
					return ServiceManager.kApiAttributes[i];
			}
			return null;
		}
	}
}
