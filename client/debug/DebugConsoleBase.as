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
package debug {
	import dialogs.Purchase.Balloons;
	
	import imagine.documentObjects.DocumentObjectBase;
	import imagine.documentObjects.DocumentObjectContainer;
	import imagine.documentObjects.IDocumentObject;
	import imagine.documentObjects.Photo;
	import imagine.documentObjects.Text;
	import imagine.documentObjects.TextSizingLogic;
	
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.system.System;
	import flash.utils.ByteArray;
	
	import imageUtils.PNGEnc;
	
	import imagine.ImageDocument;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	import mx.styles.StyleManager;
	
	import imagine.objectOperations.CenterObjectOperation;
	import imagine.objectOperations.CreateObjectOperation;
	import imagine.objectOperations.NormalScaleObjectOperation;
	
	import util.LocUtil;
	import util.TargetColors;
	import util.TipManager;
	import util.URLLogger;

	public class DebugConsoleBase extends Canvas {
		[Bindable] public var _taOutput:TextArea;
		[Bindable] public var _btnClearFlickrAuthToken:Button;
		[Bindable] public var _btnResetTips:Button;
		[Bindable] public var _btnCopyPikToClipboard:Button;
		[Bindable] public var _btnCopyUrlLogToClipboard:Button;		
		[Bindable] public var _btnSetPassword:Button;
		[Bindable] public var _btnCollectGarbage:Button;
		[Bindable] public var _btnLoadPik:Button;
		
		[Bindable] public var _tiPassword:TextInput;
		[Bindable] public var _chkbHistory:CheckBox;
		
		private var _fShowHistory:Boolean = false;
		static private var s_inst:DebugConsoleBase;
		
		public function DebugConsoleBase() {
			StyleManager.getStyleDeclaration("TextArea").setStyle("backgroundColor", undefined);
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			s_inst = this;
		}
		
		static public function Log(strText:String): void {
			if (s_inst)
				s_inst._Log(strText);
		}
		
		protected function AddTarget(fCircular:Boolean=false): void {
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			if (!imgd) return;
			
			var nScaleX:Number = 3;
			var nScaleY:Number = fCircular ? 3 : 2;
			
			var nColor:Number = TargetColors.GetNextColor(imgd);
			
			var dctProperties:Object = {
				x: imgd.width/2, y: imgd.height/2, scaleX: nScaleX, scaleY: nScaleY,
				circular:fCircular, crop:true, drawPlaceholder:true, alpha:0.5, color:nColor,
				name: Util.GetUniqueId()
			};
			
			// Create a Photo DocumentObject
			var coop:CreateObjectOperation = new CreateObjectOperation("Target", dctProperties);
			coop.Do(imgd);
			
			PicnikBase.app.zoomView.imageView.targetsEnabled = true;
		}
		
		private function OnInitialize(evt:FlexEvent): void {
//			_btnClearFlickrAuthToken.addEventListener(MouseEvent.CLICK, OnClearFlickrAuthTokenClick);
			_btnResetTips.addEventListener(MouseEvent.CLICK, OnResetTipsClick);
			_btnCopyPikToClipboard.addEventListener(MouseEvent.CLICK, OnCopyPikToClipboardClick);
			_btnLoadPik.addEventListener(MouseEvent.CLICK, OnLoadPikClick);
			_btnCopyUrlLogToClipboard.addEventListener(MouseEvent.CLICK, OnCopyUrlLogToClipboardClick);
			_btnCollectGarbage.addEventListener(MouseEvent.CLICK, OnCollectGarbageClick);
		}
		
		private function OnClearFlickrAuthTokenClick(evt:MouseEvent): void {
			var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount("Flickr");
			tpa.SetUserId("");
			tpa.SetToken("");
			tpa.storageService.LogOut();
			Log("Flickr account cleared");
		}
		
		private function OnResetTipsClick(evt:MouseEvent): void {
			TipManager.GetInstance().ResetTips();
			Log("Tips reset");
		}
		
		private function OnCopyPikToClipboardClick(evt:MouseEvent): void {
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			if (imgd == null)
				return;
				
			var strAssetMap:String = imgd.GetSerializedAssetMap(false);
			var xml:XML = imgd.Serialize(false);
			System.setClipboard("assetMap: " + strAssetMap + "\n" + xml.toXMLString());
		}
		
		// Create a new ImageDocument that reuses the base image from the current ImageDocument
		// but initializes its operations from the .pik data in a file.
		private function OnLoadPikClick(evt:MouseEvent): void {
			var fr:FileReference = new FileReference();
			
			var fnOnFileSelect:Function = function (evt:Event): void {
				fr.removeEventListener(Event.SELECT, fnOnFileSelect);
				
				var fnOnLoadComplete:Function = function (evt:Event): void {
					fr.removeEventListener(Event.COMPLETE, fnOnLoadComplete);
					
					var xmlDocument:XML = new XML(fr.data);
					if (!xmlDocument.hasOwnProperty("@baseImageAsset"))
						xmlDocument.@baseImageAsset = "0";

					var imgdOld:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
					var imgdNew:ImageDocument = new ImageDocument();
					imgdNew.Init(xmlDocument.@width, xmlDocument.@height);
					
					var fnOnDeserializeDone:Function = function (err:Number, strError:String): void {
						if (err != ImageDocument.errNone)
							return;
							
						PicnikBase.app.activeDocument = imgdNew;
					}
					
					imgdNew.assets = imgdOld.assets;
					imgdNew.Deserialize(imgdOld.id, xmlDocument, null, fnOnDeserializeDone);
				}
				
				fr.addEventListener(Event.COMPLETE, fnOnLoadComplete);
				fr.load();
			}

			fr.addEventListener(Event.SELECT, fnOnFileSelect);
			fr.browse([ new FileFilter("Picnik Documents (*.PIK)", "*.pik;", "PIK") ]);
		}
		
		private function OnCopyUrlLogToClipboardClick(evt:MouseEvent): void {
			var xml:XML = URLLogger.Dump();
			System.setClipboard(xml.toXMLString());
		}		
		
		private function OnCollectGarbageClick(evt:MouseEvent): void {
			PicnikBase.ForceGC();
		}
		
		// TODO(darrinm): Add this to the edit gear menu (Admin only).
		[ResourceBundle("templatesXmlText")] static protected var _rbTemplatesXmlText:ResourceBundle;
		protected function PrepareFancyCollage(): void {
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			if (!imgd) return;
			
			var adob:Array = [];
			
			// Find the template image.
			GetPhotoDocumentObjects(imgd.documentObjects, adob);
			if (adob.length > 0) {
				var pob:Photo = adob[0] as Photo;
				// Resize it to its original size.
				new NormalScaleObjectOperation(pob).Do(imgd);
				// Center it.
				new CenterObjectOperation(pob).Do(imgd);
			}

			// TODO(darrinm): create the Text objects rather than seeking them out
			adob = [];
			var tob:Text;
			GetTextDocumentObjects(imgd.documentObjects, adob);
			
			if (adob.length > 0) {
				tob = adob[0] as Text;
				tob.sizingLogic = TextSizingLogic.FIXED_BOX_DYNAMIC_FONT;
				tob.text = Resource.getString("templatesXmlText", "happy_valentines_day");
			}
			if (adob.length > 1) {
				tob = adob[1] as Text;
				tob.sizingLogic = TextSizingLogic.FIXED_BOX_FIXED_FONT;
				tob.wordWrap = true;
				tob.unscaledWidth = tob.unscaledWidth * tob.scaleX;
				tob.unscaledHeight = tob.unscaledHeight * tob.scaleY;
				tob.scaleX = 1.0;
				tob.scaleY = 1.0;
				tob.text = Resource.getString("templatesXmlText", "lorem_ipsum_dolor_sit_amet_consectetur_adipiscing_elit_donec_et");
			}
		}

		private function GetPhotoDocumentObjects(dobc:DocumentObjectContainer, adob:Array): void {
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var dob:IDocumentObject = dobc.getChildAt(i) as IDocumentObject;
				if (!dob)
					continue;
				if (dob is DocumentObjectContainer)
					GetPhotoDocumentObjects(dob as DocumentObjectContainer, adob);
				if (dob is Photo)
					adob.push(dob);
			}
		}

		private function GetTextDocumentObjects(dobc:DocumentObjectContainer, adob:Array): void {
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var dob:IDocumentObject = dobc.getChildAt(i) as IDocumentObject;
				if (!dob)
					continue;
				if (dob is DocumentObjectContainer)
					GetTextDocumentObjects(dob as DocumentObjectContainer, adob);
				if (dob is Text)
					adob.push(dob);
			}
		}
		
		//
		//
		//
		private function OnOptimizeImageDocumentClick(evt:MouseEvent): void {
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			if (imgd)
				Log("History fully cleared: " + imgd.Optimize());
		}
		
		protected function EmbedText(): void {
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			if (imgd) {
				if (imgd.selectedItems.length > 0) {
					var dob:imagine.documentObjects.Text = imgd.selectedItems[0] as imagine.documentObjects.Text;
					if (dob) {
						if (dob in s_dctToggled) {
							delete s_dctToggled[dob];
							dob.ClearContentSnapshot();
						} else {
							var ob:Object = dob.GetContentSnapshot();
							dob.UseContentSnapshot({ data: ob.data, metadata: ob.metadata });
							s_dctToggled[dob] = true;
						}
						imgd.InvalidateComposite();
					}
				}
			}
		}
		
		protected function DumpFeatureUsageString(): void {
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			Log("Feature Usage: " + (imgd ? imgd.GetFeatureUsageString() : ""));
		}
		
		static private var s_dctToggled:Object = {};
		
		protected function SaveObjects(): void {
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			var bmd:BitmapData = new BitmapData(imgd.width, imgd.height, true, 0);
			bmd.draw(imgd.documentObjects);
			
			var abImageData:ByteArray = imageUtils.PNGEnc.encode(bmd, 1);
			bmd.dispose();
			
			var fr:FileReference = new FileReference();
			if ("save" in fr) fr["save"](abImageData, "PicnikObjects.png");
		}
		
		private function _Log(strText:String): void {
			var fAtBottom:Boolean = _taOutput.verticalScrollPosition >= _taOutput.maxVerticalScrollPosition;
			_taOutput.text += strText + "\n";
			_taOutput.validateNow(); // Force the verticalScrollPosition to be updated
			if (fAtBottom)
				_taOutput.verticalScrollPosition = _taOutput.maxVerticalScrollPosition;
		}
	}
}
