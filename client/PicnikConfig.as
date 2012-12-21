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
	import api.PicnikRpc;
	import api.RpcResponse;
	
	import flash.events.EventDispatcher;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.events.PropertyChangeEvent;
	
	import util.KeyVault;
	
	public class PicnikConfig extends EventDispatcher {
		// If true, this user is permitted to create galleries
		// Either all users have access or this user is premium and we are in premim preview.
		// Note that this will be false whenever visible is false.
		[Bindable] public static var galleryAccess:Boolean = false;
		
		// If false, show no signs that galleries exist. Hide all gallery UI
		[Bindable] public static var galleryVisible:Boolean = false;
		[Bindable] public static var galleryCreate:Boolean = false;
		[Bindable] public static var galleryUpdate:Boolean = false;
		[Bindable] public static var galleryView:Boolean = false;
		
		[Bindable] public static var autoResizeEnabled:Boolean = false;
		
		// If true, we are in premium preview mode - show "premium preview" upsell content
		// In other words, if the current user upgrades, they will get access
		// Set to false when galleryVisible is false
		[Bindable] public static var galleryPremiumPreview:Boolean = true;
		
		// Helpers calculated from above values
		
		// premium preview and user does not have access (upgrade to get access)
		[Bindable] public static var galleryUpgradeForAccess:Boolean = true;

		// premium preview and user has access (paid to get access)
		[Bindable] public static var galleryExclusiveAccess:Boolean = false;
		
		// if we're in "free For All" mode -- everything free for everyone
		[Bindable] public static var freeForAll:Boolean = false;
		[Bindable] public static var freeForAllTeaser:Boolean = false;
		[Bindable] public static var freePremium:Boolean = false; 	// just a generic everything-is-free mode, with no messaging
	
		// some misc config values	
		[Bindable] public static var uploadsUseAsyncIO:Boolean = true; 	// Use async upload download for remote uploads?
		[Bindable] public static var facebookEnabled:Boolean = true; 	// When false, only admins can use the FB bridges. Others see an error
		[Bindable] public static var feedbackDelayed:Boolean = false;	// True when the client.feedback.delayed serverAttr is set to 100
		[Bindable] public static var googleLoginEnabled:Boolean = false; // True if users see a "sign in with google" button where appropriate
		[Bindable] public static var geoIpLocale:String = null;			// Locale as determined by GeoIP on the server
		[Bindable] public static var geoIpCountry:String = null;		// Country as determined by GeoIP on the server
		[Bindable] public static var secureApi:Boolean = false;		    // True if api calls are made via https
		
		static private var cwUserAccount:ChangeWatcher;
		static private var cwUserStatus:ChangeWatcher;
		static private var cwUserAdmin:ChangeWatcher;
		
		static public function Init(): void {
			//
			cwUserAccount = ChangeWatcher.watch( AccountMgr.GetInstance(), "name", onUserNameChange );
			cwUserStatus = ChangeWatcher.watch( AccountMgr.GetInstance(), "isPremium", onUserStatusChange );
			cwUserAdmin = ChangeWatcher.watch( AccountMgr.GetInstance(), "isAdmin", onUserStatusChange );
			
			updateUserBasedAccess();

			var nEnabledPercent:Number;
			
			nEnabledPercent = Number(KeyVault.GetInstance().gallery.create.enabledPercent);			
			galleryCreate = nEnabledPercent == 100 ? true : Math.random() * 100 < nEnabledPercent;

			nEnabledPercent = Number(KeyVault.GetInstance().gallery.update.enabledPercent);			
			galleryUpdate = nEnabledPercent == 100 ? true : Math.random() * 100 < nEnabledPercent;

			nEnabledPercent = Number(KeyVault.GetInstance().gallery.view.enabledPercent);			
			galleryView = nEnabledPercent == 100 ? true : Math.random() * 100 < nEnabledPercent;

			nEnabledPercent = Number(KeyVault.GetInstance().client.upload.asyncIOPercent);			
			uploadsUseAsyncIO = nEnabledPercent == 100 ? true : Math.random() * 100 < nEnabledPercent;

			// BST: Removed test for flickr lite: !PicnikBase.app.flickrlite &&
			autoResizeEnabled = 	String(KeyVault.GetInstance().client.document.autoResize).toLowerCase() != 'false' &&
									PicnikBase.app.AsService().GetServiceParameter("_autoshrink","true") == "true";
									
			// STL: just turned all freeForAll off
			freeForAll = false;//!PicnikBase.app.liteUI && String(KeyVault.GetInstance().client.premium.freeForAll).toLowerCase() != 'false';								
			freeForAllTeaser = false;//!PicnikBase.app.liteUI && String(KeyVault.GetInstance().client.premium.freeForAllTeaser).toLowerCase() != 'false';					
			
			feedbackDelayed = String(KeyVault.GetInstance().client.feedback.delayed).toLowerCase() == 'true';		
			
			googleLoginEnabled = String(KeyVault.GetInstance().client.googlelogin.enabled).toLowerCase() == 'true';
				
			secureApi = String(KeyVault.GetInstance().client.secure_api.enabled).toLowerCase() == 'true';

			geoIpLocale = String(KeyVault.GetInstance().geoip.locale);
			geoIpCountry = String(KeyVault.GetInstance().geoip.country);
			
		}
		
		static private function onUserNameChange( evt:PropertyChangeEvent ): void {
			updateUserBasedAccess();	
		}
		
		static private function onUserStatusChange( evt:PropertyChangeEvent ): void {
			updateUserBasedAccess();	
		}

		static private function updateUserBasedAccess() : void {
			var fIsApiWithExportMode:Boolean = (PicnikBase.app.AsService().apikey != null
				&& PicnikBase.app.AsService().GetServiceParameter( "_export" ).length > 0);
			
			if (!fIsApiWithExportMode) {
				galleryVisible = true;
			} else {
				galleryVisible = false;
			}

			var fAllowAll:Boolean = String(KeyVault.GetInstance().gallery.access.allowAll).toLowerCase() == 'true';
			galleryAccess = galleryVisible && (AccountMgr.GetInstance().isPremium || fAllowAll);
			galleryPremiumPreview = galleryVisible && !fAllowAll;
			
			// Calcultaed values:
			galleryUpgradeForAccess = galleryPremiumPreview && !galleryAccess;
			galleryExclusiveAccess = galleryPremiumPreview && galleryAccess;
			
			var nEnabledPercent:Number = Number(KeyVault.GetInstance().client.bridge.fb.enabledPct);
			if (AccountMgr.GetInstance().isAdmin)
				nEnabledPercent = 100;
			facebookEnabled = nEnabledPercent >= 100 ? true : Math.random() * 100 < nEnabledPercent;			
		}			
	}
}
