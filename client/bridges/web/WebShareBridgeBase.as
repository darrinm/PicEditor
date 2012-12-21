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
package bridges.web {
	import bridges.ShareBridge;
	import bridges.storageservice.StorageServiceError;
	
	import com.adobe.crypto.MD5;

	import controls.TextAreaPlus;
	import controls.TextInputPlus;

	import dialogs.BusyDialogBase;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	import dialogs.IBusyDialog;
	
	import events.ActiveDocumentEvent;
	
	import flash.events.*;
	import flash.system.*;
	import flash.geom.Point;
	
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	import mx.utils.StringUtil;
	
	import util.RenderHelper;
	
	public class WebShareBridgeBase extends ShareBridge {
		// MXML-defined variables
		[Bindable] public var _btnDone:Button;
		[Bindable] public var _taGalleryEmbedTag:TextAreaPlus;
		[Bindable] public var _tiGalleryUrl:TextInputPlus;

		private var _nDefaultPreviewSize:Number = 400;
		
   		[ResourceBundle("WebShareBridge")] private var _rb:ResourceBundle;
		
		public function WebShareBridgeBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}

		private function OnCreationComplete(evt:FlexEvent):void {
			_btnDone.addEventListener(MouseEvent.CLICK, OnDone);
		}		

		override public function OnActivate(strCmd:String=null): void {
			//trace("GalleryOutBridge.OnActivate!");
			SetEmbedSize(_nDefaultPreviewSize);
			super.OnActivate(strCmd);
		}			
		
		override protected function GetHeadline():String {
			return itemIsShow ? Resource.getString("WebShareBridge", "postThisShow") :
						Resource.getString("WebShareBridge", "postThisPhoto");			
		}
		
		private function OnDone(evt:MouseEvent): void {
			container.Hide();
		}

		private function OnCancel(dctResult:Object): void {
			container.Hide();
		}
		
		protected function SetEmbedSize( nWidth:Number ): void {
			if (!item) return; // this shouldn't happen, but it does :(

			// also shouldn't happen, but... if we find ourselves here 
			// but we're not yet published, bad things might happen
			if (!item.embedCode) return;
			
			var strEmbed:String = item.embedCode;
			strEmbed = strEmbed.replace( /WIDTH/g, nWidth );
			strEmbed = strEmbed.replace( /HEIGHT/g, nWidth*3/4 );
			_taGalleryEmbedTag.text = strEmbed;
		}
		
		protected function OnEmbedFocusIn():void {
			try {
				_taGalleryEmbedTag.setSelection(0,_taGalleryEmbedTag.text.length);
				System.setClipboard(_taGalleryEmbedTag.text);		
			} catch (e:Error) {
				// just ignore
			}
		}
		
		protected function OnUrlFocusIn():void {
			try {
				_tiGalleryUrl.setSelection(0,_tiGalleryUrl.text.length);
				System.setClipboard(_tiGalleryUrl.text);		
			} catch (e:Error) {
				// just ignore
			}
		}		
	}
}
