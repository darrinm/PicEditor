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
package containers {
	import bridges.*;
	
	import mx.containers.ViewStack;
	import mx.core.Container;
	import mx.events.FlexEvent;
	
	public class OutBridgeContainer extends PageContainer {
		protected var _pgRecent:IActivatable = null;
		
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			
			if (!PicnikConfig.galleryVisible)	
				HidePage("show");
		}
		
		protected override function ServiceToPage(strService:String): String {
			switch (strService.toLowerCase()) {
			case "postsave":
				return OutBridge.POSTSAVE_SUB_TAB;			
			case "picasaweb":
				return OutBridge.PICASA_SUB_TAB;
			case "flickr":
				return OutBridge.FLICKR_SUB_TAB;
			case "photobucket":
				return OutBridge.PHOTOBUCKET_SUB_TAB;
			case "facebook":
				return OutBridge.FACEBOOK_SUB_TAB;
			case "mycomputer":
				return OutBridge.DOWNLOAD_SUB_TAB;
			case "email":
				return OutBridge.EMAIL_SUB_TAB;
			case "picnik":
				return OutBridge.PICNIK_SUB_TAB;
			case "print":
				return OutBridge.PRINT_SUB_TAB;
			case "sharing":
			case "show":
			case "gallery":
				return OutBridge.GALLERY_SUB_TAB;
			case "twitter":
				return OutBridge.TWITTER_SUB_TAB;
			}
			// Default
			return OutBridge.DOWNLOAD_SUB_TAB; // My computer
		}
		
		public override function get defaultTab(): String {
			return ServiceToPage(PicnikBase.app.GetPreferredOutBridge());
		}			
		
		// We want to keep track of the most recent non-PostSave bridge that was active,
		// so that we can return to it later.
		protected override function OnChildActivate(pg:IActivatable): void {
			if (pg != _vstk.getChildByName(OutBridge.POSTSAVE_SUB_TAB)) {
				_pgRecent = pg;
			}
		}
		
		public override function OnDeactivate(): void {
			// switch the active bridge off the postsave tab
			if (_pgActive && _pgActive == _vstk.getChildByName(OutBridge.POSTSAVE_SUB_TAB)) {
				if (_pgRecent)
					NavigateToChild(_pgRecent as Container);
				else
					NavigateTo(OutBridge.DOWNLOAD_SUB_TAB);
			}			
			super.OnDeactivate();
		}
	}
}
