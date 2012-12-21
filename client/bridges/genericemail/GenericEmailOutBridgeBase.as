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
package bridges.genericemail {
	import bridges.OutBridge;
	import bridges.storageservice.StorageServiceError;
	
	import com.adobe.utils.StringUtil;

	import containers.PaletteWindow;
	
	import dialogs.BusyDialogBase;
	import dialogs.IBusyDialog;
	
	import events.AccountEvent;
	import events.ActiveDocumentEvent;
	
	import flash.events.*;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.containers.ViewStack;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.core.Container;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	
	import util.RenderHelper;
	
	public class GenericEmailOutBridgeBase extends OutBridge {
		// MXML-defined variables
		[Bindable] public var _btnSend:Button;
		[Bindable] public var _imgPreview:ImageView;

		[Bindable] public var _aobStackItems:Array = new Array();
		[Bindable] public var _vstkServices:ViewStack;

		[Bindable] public var _aobDefaultImageSizes:ArrayCollection = null;

   		[ResourceBundle("GenericEmailOutBridge")] private var _rb:ResourceBundle;

		public var _aobSizes:Array;
		
		public var _strEmailSentNotifyMessage:String;
		public var _strInvalidEmailText:String;

		public var _strLastUser:String;
		public var _bsy:IBusyDialog;
		
		public function GenericEmailOutBridgeBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		private function OnCreationComplete(evt:FlexEvent):void {
			_btnSend.addEventListener(MouseEvent.CLICK, OnSendClick);
			//InitServiceComboBox();
		}		

//		public function InitServiceComboBox(): void {
//			for each (var dobChild:Container in _vstkServices.getChildren()) {
//				var obIconSource:Object = (dobChild.getChildByName("_imgIcon") as Image).source;
//				_aobStackItems.push(new LabeledData(dobChild.label, dobChild, obIconSource));
//			}
//			_cmboService.selectedIndex = 0;
//		}
		
//		public function SetViewStackToServiceComboBox(): void {
//			_vstkServices.selectedChild = _cmboService.selectedItem.data as Container;
//		}

//		public function Chomp(str:String, strChop:String): String {
//			var i:Number = str.indexOf(strChop);
//			if (i >= 0) str = str.substr(0, i);
//			return str;
//		}

		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd)
			account.addEventListener(AccountEvent.USER_CHANGE, OnUserChange);
			
			var strUser:String = account.GetUserAttribute("name") as String;
			
			// This handles the case where the user logs out. This prevents us from
			// leaving in the last user's email address in the From field.
			if (strUser != _strLastUser) {
				_strLastUser = strUser;
			}
			
			// Initialize the ImageSize labels
			if (_imgd) InitImageSizeDropDown();
		}
		
		override public function OnDeactivate(): void {
			super.OnDeactivate();
			account.FlushUserAttributes();
			account.removeEventListener(AccountEvent.USER_CHANGE, OnUserChange);
		}

		protected override function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			super.OnActiveDocumentChange(evt);
			InitImageSizeDropDown();
			dispatchEvent(new Event("imgdChanged"));
		}

		[Bindable (event="imgdChanged")]
		public function GetImageSizesForMaxFileSize(nBytes:Number): ArrayCollection {
			var aobImageSizes:ArrayCollection = new ArrayCollection();
			if (_imgd) {
				var nMaxArea:Number = nBytes * 2; // Very conservative estimate
				aobImageSizes = new ArrayCollection();
				for each (var ob:Object in _aobSizes) {
					if (ob.data < Math.max(_imgd.width, _imgd.height)) {
						var pt:Point = GetConstrainedProportions(ob.data);
						if ((pt.x * pt.y) < nMaxArea) {
							var strLabel:String = ob.label + ": " + pt.x + "x" + pt.y;
							aobImageSizes.addItem(new LabeledData(strLabel, ob.data));
						}
					}
				}
			}
			return aobImageSizes;
		}
		
		[Bindable (event="imgdChanged")]
		public function GetImageSizesForMaxDim(cxyMax:Number): ArrayCollection {
			var aobImageSizes:ArrayCollection = new ArrayCollection();
			if (_imgd) {
				for each (var ob:Object in _aobSizes) {
					var nDim:Number = ob.data as Number;
					if (nDim == 0) nDim = Math.min(cxyMax, Math.max(_imgd.width, _imgd.height));
					if (nDim <= Math.max(_imgd.width, _imgd.height) && nDim <= cxyMax) {
						var pt:Point = GetConstrainedProportions(nDim);
						var strLabel:String = ob.label + ": " + pt.x + "x" + pt.y;
						aobImageSizes.addItem(new LabeledData(strLabel, nDim));
					}
				}
			}
			return aobImageSizes;
		}
		
		private function InitImageSizeDropDown(): void {
			if (_imgd) {
				_aobDefaultImageSizes = new ArrayCollection();
				for each (var ob:Object in _aobSizes) {
					if (ob.data < Math.max(_imgd.width, _imgd.height)) {
						var pt:Point = GetConstrainedProportions(ob.data);
						var strLabel:String = ob.label + ": " + pt.x + "x" + pt.y;
						_aobDefaultImageSizes.addItem(new LabeledData(strLabel, ob.data));
					}
				}
			}
		}
		
		private function OnSendClick(evt:MouseEvent): void {
			_bsy = BusyDialogBase.Show(this, "Sending", BusyDialogBase.EMAIL, "", 0.5, OnCancel);

			account.FlushUserAttributes();
			
			var contSelectedService:Container = _vstkServices.selectedChild;

			var strToEmail:String = (contSelectedService.getChildByName("_lblToEmail") as Label).text;
			var strFromEmail:String = (contSelectedService.getChildByName("_lblFromEmail") as Label).text;
			var strSubject:String = (contSelectedService.getChildByName("_lblSubject") as Label).text;
			var strBody:String = (contSelectedService.getChildByName("_lblMessage") as Label).text;
			var strImageName:String = (contSelectedService.getChildByName("_lblImageTitle") as Label).text;
			var nMaxImageDim:Number = Number((contSelectedService.getChildByName("_lblMaxImageDim") as Label).text);

			// We don't want to scale images down.
			// If our max dim is bigger than our image max dim, choose the image max dim			
			nMaxImageDim = Math.min(nMaxImageDim, Math.max(_imgd.width, _imgd.height));

			var cxDim:Number = nMaxImageDim;
			var cyDim:Number = cxDim;
			if (cxDim == 0) cxDim = _imgd.width;
			if (cyDim == 0) cyDim = _imgd.height;
			
			new RenderHelper(_imgd, OnEmailDone, _bsy).RawEmail(strToEmail, strFromEmail, strSubject, strBody, strImageName, cxDim, cyDim, "GenericEmail/");

			PicnikService.Log("GenericEmailOutBridge" +
					" sending " + strImageName + ", from: " + strFromEmail +
					", to: " + strToEmail + ", subject: " + strSubject +
					", body: " + strBody + ", width: " + cxDim + ", height: " + cyDim);
		}

		private function OnCancel(dctResult:Object): void {
			//UNDONE
		}

		private function OnEmailDone(err:Number, strError:String, strPikId:String=null): void {
			// We go with the indeterminate progress indicator for now
			if (_bsy != null) {
				_bsy.Hide()
				_bsy = null;
			}
			if (err == 0) {
				ReportSuccess("/Genericemail");
				PicnikBase.app.Notify(_strEmailSentNotifyMessage, 1000);
			} else if (err == StorageServiceError.ChildObjectFailedToLoad) {
					DisplayCouldNotProcessChildrenError();
			} else {
				Util.ShowAlert(Resource.getString("GenericEmailOutBridge", "unable_to_send"), Resource.getString("GenericEmailOutBridge", "Error"), Alert.OK,
						"ERROR:out.bridge.genericemail: " + err + ", " + strError);
			}
		}
		
		private function GetConstrainedProportions(cxyMax:Number): Point {
			if (cxyMax <= 0) return new Point(_imgd.width, _imgd.height);
			var xw:Number = _imgd.width;
			var yw:Number = _imgd.height;
			var cxy:Number = cxyMax;
			var nScaleFactor:Number = cxyMax/Math.max(_imgd.width, _imgd.height);
			if (nScaleFactor > 1) nScaleFactor = 1;
			var cy:Number = Math.floor(_imgd.height * nScaleFactor);
			var cx:Number = Math.floor(_imgd.width * nScaleFactor);
			if (cx < 1) cx = 1;
			if (cy < 1) cy = 1;
			return new Point(cx, cy);
		}
		
		[Bindable (event="accountChanged")]
		protected function get account(): AccountMgr {
			return AccountMgr.GetInstance();
		}

		private function OnUserChange(evt:Event): void {
			dispatchEvent(new Event("accountChanged"));
		}

		protected function SetUserAttribute(strAttr:String, strValue:String, strTail:String=null): void {
			if (strValue != strTail)
				account.SetUserAttribute(strAttr, strValue, false); // fFlush=false
		}
		
		
		protected function OnLink(evt:TextEvent): void {	
			if (StringUtil.beginsWith(evt.text.toLowerCase(), "navigate=")) {
				var strPage:String = evt.text.substr("navigate=".length);
				PicnikBase.app.NavigateToService(PicnikBase.OUT_BRIDGES_TAB, strPage);
			}
		}		
	}
}

// Private helper class for GenericEmailOutBridgeBase
[Bindable] class LabeledData
{
	public var label:String;
	public var data:Object;
	public var icon:Object;
	public function LabeledData(strLabel:String, obData:Object, obIconSource:Object=null) {
		label = strLabel;
		data = obData;
		icon = obIconSource;
	}
}
