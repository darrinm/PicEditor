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
	import mx.events.FlexEvent;

	public class InBridgeContainer extends PageContainer {
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);

			// Hide subtabs this user doesn't have permission to see
//			if (!(AccountMgr.GetInstance().perms & Permissions.PicnikStorage))
//				HideBridge("picnik");
		}
		
		protected override function ServiceToPage(strService:String): String {
			switch (strService.toLowerCase()) {
			case "picasaweb":
				return "_brgPicasaWebIn";
			case "photobucket":
				return "_brgPhotobucketIn";
			case "flickr":
				return "_brgFlickrIn";
			case "facebook":
				return "_brgFacebookIn";
			case "mycomputer":
				return "_brgMyComputerIn";
			case "webcam":
				return "_brgWebCamIn";
			case "flickrsearch":
				return "_brgFlickrSearchIn";
			case "url":
				return "_brgWebIn";
			case "picnik":
				return "_brgPicnikIn";
			case "history":
				return "_brgHistoryIn";
			case "show":
			case "gallery":
				return "_brgGalleryIn";
			case "projects":
				return "_brgProjects";
			case "twitter":
				return "_brgTwitterIn";
			case "yahoomail":
				return "_brgYahooMailIn";
				
			default:
				return "_brgMyComputerIn"; // My computer
			}
		}

		public override function get defaultTab(): String {
			return ServiceToPage(PicnikBase.app.GetPreferredInBridge());
		}
	}
}
