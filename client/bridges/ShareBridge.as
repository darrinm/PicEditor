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
package bridges {

	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceUtil;
	
	import com.adobe.utils.StringUtil;
	
	import controls.Gears;
	import controls.PicnikMenu;
	import controls.PicnikMenuItem;
	import controls.list.PicnikTileList;
	
	import dialogs.BusyDialog;
	import dialogs.DialogContent.IDialogContent;
	import dialogs.DialogContent.IDialogContentContainer;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	
	import events.ActiveDocumentEvent;
	
	import flash.events.Event;

	import imagine.ImageDocument;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ItemClickEvent;
	import mx.events.StateChangeEvent;
	import mx.resources.ResourceBundle;
	
	import util.GalleryItem;
	import util.IAssetSource;
	import util.ImagePropertiesUtil;
	import util.LocUtil;
	import util.RenderHelper;
	import util.UserBucketManager;
	
/**
 *  Dispatched when the this component becomse "active" as defined by IBridge
 *
 *  <p>The event is dispatched when the the component is selected/becomes visible
 *
 *  <p>This is different than the activate event which is triggered when
 *  the window is selected, whether or not the component is visible..</p>
 *
 *  @eventType mx.events.Event "activate2"
 */
	[Event(name="activate2", type="flash.events.Event")]	
	
	public class ShareBridge extends Canvas implements IBridge, IDialogContent {
		[Bindable] public var footerHeight:Number = 0;
		[Bindable] public var headline:String = "";
		[Bindable] public var publishFunction:Function = null;
		[Bindable] public var processing:Boolean = false;
		
   		[ResourceBundle("ShareBridge")] private var _rb:ResourceBundle;
		
		private var _item:ItemInfo;
		private var _imgd:ImageDocument;
		private var _fItemIsShow:Boolean = false;
		private var _fShareable:Boolean = false;
		private var _fActive:Boolean = false;
		
		private var _fRenderCancel:Boolean;
		private var _afnRenderCallbacks:Array = [];
		
		public var serviceid:String;	// identifies the service associated with this bridge
		
		public static const EMBED_SUB_TAB:String = "_brgEmbedOut";
		public static const EMAIL_SUB_TAB:String = "_brgEmailOut";
		
		[Bindable]
		public function get shareable():Boolean {
			return _fShareable;
		}
		
		public function set shareable( b:Boolean ):void {
			_fShareable = b;
		}

		[Bindable]
		public function set item( itemInfo:ItemInfo ):void  {
			_item = itemInfo;
			itemIsShow = ('species' in itemInfo && item.species == 'gallery');
			headline = GetHeadline();
		}
		
		public function get item():ItemInfo  {
			return _item;
		}
		
		[Bindable]
		public function set imgd( imgd:ImageDocument ):void  {
			_imgd = imgd;
		}
		
		public function get imgd():ImageDocument  {
			return _imgd;
		}		

		[Bindable]
		public function set itemIsShow( f:Boolean):void  {
			_fItemIsShow = f;
		}
		public function get itemIsShow():Boolean  {
			return _fItemIsShow;
		}

		protected function RenderAsNecessary( fnCallback:Function ): void {
			if (fnCallback != null) {
				_afnRenderCallbacks.push(fnCallback);
			}
			if (!processing) {
				processing = true;
				if (publishFunction != null) {
					publishFunction( onPublishDone );
				} else {
					onPublishDone(item);
				}
			}
		}
		
		private function onPublishDone(iinf:ItemInfo): void {
			processing = false;
			item = iinf;
			for each (var fnCallback:Function in _afnRenderCallbacks) {
				fnCallback();
			}
			_afnRenderCallbacks = [];
		}
		
		protected function CancelRender(): void {
			_fRenderCancel = true;
		}
						
		protected function GetHeadline():String {
			return itemIsShow ? Resource.getString("ShareBridge", "shareThisShow") :
						Resource.getString("ShareBridge", "shareThisPhoto");			
		}
		
		protected function chomp(strIn:String, strRemoveFromTail:String): String {
			if (StringUtil.endsWith(strIn, strRemoveFromTail))
				return strIn.substr(0, strIn.length - strRemoveFromTail.length);
			return strIn;
		}
		
		protected function get simpleBridgeName(): String {
			// Remove "Base" and "ShareBridge" from the class name, convert to all lower case.
			var strName:String = className.toLowerCase();
			strName = chomp(strName, 'base');
			strName = chomp(strName, 'sharebridge');
			return strName;
		}
		
		
		// strEvent has a preceeding slash, e.g. '/withperfectmemory'
		protected function ReportSuccess(strEvent:String=null, strTransferType:String="undefined"): void {
			if (strEvent == null)
				strEvent = "/done";
			if (strEvent.length > 0 && strEvent.charAt(0) != '/')
				strEvent = '/' + strEvent ;
			
			var strPath:String = "/sharecontent/" + simpleBridgeName + strEvent + "/" + (itemIsShow ? "show" : "image")
			Util.UrchinLogReport(strPath);
			UserBucketManager.GetInst().OnShare(simpleBridgeName);
		}
		
		protected function OnInitialize(evt:FlexEvent): void {
			//trace("Bridge.OnInitialize: " + id);
		}

		private function OnCreationComplete(evt:FlexEvent): void {
			//trace("Bridge.OnCreationComplete: " + id);
		}

		//
		// IBridge implementation
		//
		public function OnActivate(strCmd:String=null): void {
			Debug.Assert(!_fActive, "Bridge.OnActivate: active bridge being reactivated");
			active = true;		
			Util.UrchinLogReport("/sharecontent/" + simpleBridgeName + "/view/" + (itemIsShow ? "show" : "image"));			
		}
		
		public function OnDeactivate(): void {
			Debug.Assert(_fActive, "Bridge.OnDeactivate: inactive bridge being deactivated");
			active = false;
			HideBusy();
		}
		
		private function get busyGears(): Gears {
			var grs:Gears = null;
			grs = Gears(getChildByName("_grsBusy"));
			if (!grs && parent) {
				grs = Gears(parent.getChildByName("_grsBusy"));
				if (!grs && parent.parent) {
					grs = Gears(parent.parent.getChildByName("_grsBusy"));
					if (!grs && parent.parent.parent) {
						grs = Gears(parent.parent.parent.getChildByName("_grsBusy"));
					}
				}
			}
			return grs;
		}
		
		public function set busyShowing(fShowing:Boolean): void {
			if (fShowing)
				ShowBusy();
			else
				HideBusy();
		}
		
		private var _cBusy:int = 0;
		
		protected function ShowBusy(): void {
			// Multiple busy actions may be happening at once
			if (busyGears) {
				_cBusy++;
				if (_cBusy == 1)
					busyGears.visible = true;
			}
		}
		
		protected function HideBusy(): void {
			if (busyGears) {
				_cBusy--;
				if (_cBusy < 0)
					_cBusy = 0;
				if (_cBusy == 0)
 					busyGears.visible = false;
 			}
		}
		
		[Bindable]
		public function set active(fActive:Boolean): void {
			if (fActive && !_fActive) dispatchEvent(new Event("activate2"));
			_fActive = fActive;
		}
		public function get active(): Boolean {
			return _fActive;
		}

		//
		// IDialogContent implementation
		//		
		private var _dcc:IDialogContentContainer;
		[Bindable]		
		public function get container(): IDialogContentContainer {
			return _dcc;			
		}
		
		public function set container(dcc:IDialogContentContainer): void {
			_dcc = dcc;
		}
	}
}
