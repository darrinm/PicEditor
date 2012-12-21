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
package bridges.gallery {

	import bridges.Bridge;
	import bridges.picnik.*;
	import bridges.storageservice.*;
		
	import flash.events.*;
	
	import mx.resources.ResourceBundle;
	
	import util.Cancelable;
	import util.LocUtil;

	[Event(name="item_saved", type="flash.events.Event")]
	[Event(name="canceled", type="flash.events.Event")]
	
	public class GalleryOutBridgeBase extends StorageServiceOutBridgeBase {
   		[ResourceBundle("GalleryOutBridge")] private var _rb:ResourceBundle;
		
		public function GalleryOutBridgeBase() {
			super();
			_tpa = new ThirdPartyAccount("Show", new GalleryStorageService());
		}
		
		[Bindable] protected var canCreateSets:Boolean = true;

		override protected function UpdateState(): void {
			currentState = GetState();
		}

		override protected function GetState(): String {
			if (PicnikConfig.galleryUpgradeForAccess) {
				return "PremiumPreview"
			}
			return super.GetState();
		}	
		
		private var _imgpBefore:ImageProperties;
		
		override protected function ValidateBeforeSave(): Boolean {
			_imgpBefore = new ImageProperties();
			_imgd.properties.CopyTo(_imgpBefore);
			
			return super.ValidateBeforeSave();
		}
		
		override protected function OnUserInfoRefreshed(): void {
			super.OnUserInfoRefreshed();
			canCreateSets = CanCreateSets(null);
			RefreshSets();	// need to refresh sets because the "create set" item depends on user state
			UpdateState();
		}

		override protected function OnSetsRefreshed(): void {
			var strNew:String = Resource.getString("GalleryOutBridge", "New");
			if (_adctSetInfos.length == 0 || _adctSetInfos[0].title != strNew)
				_adctSetInfos.unshift( {title:strNew, thumbnailurl:null, id:null} );
			super.OnSetsRefreshed();
		}

		override protected function RefreshSets(): void {
			if (storeIsOff) return;
			// UNDONE: keep in and outbridge selected set synchronized and persisted
			ShowBusy();
			_nRefreshSetsOutstanding++;
			_ss.GetSets( _strSelectedFriendID, OnGetSets);
		}

		override protected function CanCreateSets(adctSetInfos:Array):Boolean {
			// update the "start a new photo set" item depending whether or not the user has sets remaining
			if (_dctUserInfo && "setsremaining" in _dctUserInfo && (_dctUserInfo.setsremaining > 0 || _dctUserInfo.setsremaining == "lots")) {
				return true;
			}
			return false;
		}

//		override protected function IsOverwriteable(itemInfo:ItemInfo=null): Boolean {
//			if (_dctUserInfo && _dctUserInfo.is_pro)
//				return super.IsOverwriteable(itemInfo);
//			return false;
//		}	
				
		override public function OnDeactivate(): void {
			super.OnDeactivate();
			if (_chkbPicnikTag)
				_tpa.SetAttribute("_fTagWithPicnik", _chkbPicnikTag.selected);
		}

		// Return a string that describes the selected show, including an upsell message when appropraite
		protected function GetShowDetails(i:int): String {
			// Special case for "Create a new show"
			if (i <= 0)
				return "";
				
			// [not full] This Show has {0} photos and can hold {1} more.
			// [free full] This Show has {0} photos which is your limit. Upgrade to add more photos.
			// [premium full] This Show has {0} photos which is the limit.

			var seti:Object = _cboxSets.dataProvider[i].setinfo;
			var cPhotosMax:int = GalleryDocument.maxAllowedImageCount;
			if (seti.itemcount == cPhotosMax)
				return LocUtil.rbSubst("GalleryOutBridge", AccountMgr.GetInstance().isPremium ?
						"premium_show_length_limit" : "free_show_length_limit", cPhotosMax);
			return LocUtil.zeroOneOrMany2("GalleryOutBridge", seti.itemcount, cPhotosMax - seti.itemcount, "show_length");
		}

		private var _canDownloadOp:Cancelable = null;		// move

		override protected function PostSaveAction(dctItemInfo:Object): void {
			
			var fnOnGetSetInfo:Function = function(err:Number, strError:String, itemInfo:ItemInfo=null): void {
				// ignore error -- show is already saved, user has already been alerted about this, we decide here
				// what to do next.  That's predicated on whether or not we have a valid itemInfo returned.
				if (itemInfo == null)
					return;
				if (_cboxSets.selectedIndex == 0) {
					// creating a new Show?  then after save, drop right into editing Show
					var gib:GalleryInBridge = PicnikBase.app._brgcIn._vstk.getChildByName("_brgGalleryIn") as GalleryInBridge;
					gib.DownloadItemDirect( itemInfo, Bridge.EDIT_GALLERY );
				} else {
					// save to existing show, go to share page.
					DialogManager.Show("ShareContentDialog", null, null, {item:itemInfo});
				}
			}

			var itemInfo:ItemInfo = ItemInfo(dctItemInfo);
			itemInfo.species = "gallery";
			_canDownloadOp = new Cancelable( this, fnOnGetSetInfo );
			_ss.GetSetInfo( itemInfo.setid, _canDownloadOp.callback );
		}
		

	}
}
