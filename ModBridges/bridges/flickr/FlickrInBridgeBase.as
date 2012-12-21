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
package bridges.flickr {
	import bridges.storageservice.*;
	
	import dialogs.*;
	
	import flash.events.*;
	
	import mx.containers.VBox;
	import mx.controls.Image;
	import mx.events.ResizeEvent;
	import mx.resources.ResourceBundle;

	public class FlickrInBridgeBase extends StorageServiceInBridgeBase {
		// MXML-specified variables
		[Bindable] public var _imgBuddyIcon:Image;
		[Bindable] public var _vbxSearch:VBox;
		
  		[Bindable] [ResourceBundle("FlickrInBridgeBase")] private var rb:ResourceBundle;

				
		public function FlickrInBridgeBase() {
			super();
			_tpa = AccountMgr.GetThirdPartyAccount("Flickr");
		}
				
		// Hide the search box if there isn't room for it
		private function OnResize(evt:ResizeEvent): void {
			var fShow:Boolean = width > 790;
			if (_vbxSearch) {
				_vbxSearch.includeInLayout = fShow;
				_vbxSearch.visible = fShow;
			}
		}
		
		override protected function OnSetsRefreshed(): void {
			_adctSetInfos.unshift( {title:Resource.getString("FlickrInBridgeBase", "yer_photostream"), thumbnailurl:null, id:null} );
			super.OnSetsRefreshed();
		}
	}
}
