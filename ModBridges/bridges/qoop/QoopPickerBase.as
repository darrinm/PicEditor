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
package bridges.qoop {
	import bridges.Bridge;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceUtil;
	
	import com.adobe.crypto.MD5;
	
	import dialogs.BusyDialogBase;
	import dialogs.DialogManager;
	import dialogs.IBusyDialog;
	
	import flash.events.Event;
	
	import imagine.ImageDocument;
	
	import mx.containers.Box;
	import mx.controls.Alert;
	import mx.controls.TileList;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.resources.ResourceBundle;
	
	import util.Cancelable;
	import util.KeyVault;
	import util.RenderHelper;
		
	public class QoopPickerBase extends Box {
   		[ResourceBundle("QoopPicker")] private var _rb:ResourceBundle;   				
		[Bindable] public var _tlQoop:TileList;
		[Bindable] public var imgd:ImageDocument;
		
		public var _bsy:IBusyDialog;
		
		private var _canPrintOp:Cancelable = null;

		public function QoopPickerBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}

		private function OnCreationComplete(evt:FlexEvent):void {
			_tlQoop.addEventListener(ListEvent.ITEM_CLICK, OnQoopItemClick);
		}
		
		public function GoToQoop(evt:Event): void {
			_tlQoop.selectedItem = null;
			OnQoopItemClick(null);
		}
		
		private function OnQoopItemClick( evt:ListEvent ): void {
			
			if (AccountMgr.GetInstance().isGuest) {
				if (imgd) {
					// Sadly, only registered users can print with QOOP right now.	
					DialogManager.ShowRegister( PicnikBase.app );
				} else {
					// redirect to QOOP with an empty photo list
					// (a sample image will be tossed in later)
					QoopConnection.LaunchPrintPartner( [], _tlQoop.selectedItem );
				}			
			} else {			
				// we need to:
				//	1. render the item if necessary
				//  2. commit the item to photo history
				//  3. retrieve the photo history and pass it on
				
				_bsy = BusyDialogBase.Show(this, Resource.getString("QoopPicker", "Rendering"), BusyDialogBase.SAVE_USER_IMAGE, "", 0.5, OnRenderCancel);
				
				if (imgd) {
					// render the current image before proceeding
					_canPrintOp = new Cancelable( this, OnImageDocumentRenderDone );
					new RenderHelper(imgd, _canPrintOp.callback, _bsy).Render({ history: true });
					PicnikService.Log("QoopPickerBase rendering " + imgd.properties.title );							
				} else {
					// Retrieve the user's photo history
					_canPrintOp = new Cancelable( this, OnGetPhotoHistory );
					PicnikService.GetFileList("strType=history", "dtModified", "desc", 0, 1000, null, false, _canPrintOp.callback, null);				
				}
			}
		}
				
		private function OnRenderCancel(dctResult:Object): void {
			_bsy.Hide();
			_bsy = null;
			_canPrintOp.Cancel();
		}		
		
		private function OnImageDocumentRenderDone(err:Number, strError:String, obResult:Object=null): void {
			if (err != PicnikService.errNone) {
	 			if (_bsy) {
		 			_bsy.Hide();	
					_bsy = null;
	 			}
	 			if (err == StorageServiceError.ChildObjectFailedToLoad) {
	 				Bridge.DisplayCouldNotProcessChildrenError();
	 			} else {
					Util.ShowAlert(Resource.getString("QoopPicker", "failed_to_render"), Resource.getString("QoopPicker", "Error"), Alert.OK,
							"qooppicker problem: failed to render: " + err + ", " + strError);
				}
			} else {	
				// Life is good! Retrieve the user's photo history
				_canPrintOp = new Cancelable( this, OnGetPhotoHistory );
				PicnikService.GetFileList("strType=history", "dtModified", "desc", 0, 1000, null, false, _canPrintOp.callback, null);
			}
		}
		
		private function OnGetPhotoHistory(err:Number, strError:String, adctProps:Array=null): void {
			if (err != PicnikService.errNone) {
	 			if (_bsy) {
		 			_bsy.Hide();	
					_bsy = null;
	 			}
				Util.ShowAlert(Resource.getString("QoopPicker", "photo_history_error"), Resource.getString("QoopPicker", "Error"), Alert.OK,
						"qooppicker problem: get photo history failed: " + err + ", " +strError);
				return;
			}

			var aitemInfos:Array = new Array();
			var fSeenTemp:Boolean = false;
			
			for each (var dctProps:Object in adctProps) {				
				// Don't show temporary files EXCEPT for the very first one,
				// which should be the one we just rendered.
				if ("fTemporary" in dctProps) {
					if (fSeenTemp)
						continue;
					fSeenTemp = true;
				}
					
				var itemInfo:ItemInfo = StorageServiceUtil.ItemInfoFromPicnikFileProps(dctProps,
					function( strPath:String ):String {
						// UNDONE: sign the URL with QOOP's public+private key
						var strAuth:String = "?_apikey=" + KeyVault.GetInstance().qoop.picnik.pub;
						var strToSign:String = strPath.split( "/" ).join( "" ) +
								KeyVault.GetInstance().qoop.picnik.pub +
								KeyVault.GetInstance().qoop.picnik.priv;
						strAuth += "&_sig=" + MD5.hash(strToSign);
						return strAuth;
					} ); 			
							
				aitemInfos.push(itemInfo);
			}
			
			// HACK: Don't send qoop any history for now - just the first item (the one you have open)
			if (imgd && aitemInfos.length > 0) {
				aitemInfos = [aitemInfos[0]]; // Send only the most recent (currently open) photo
			} else {
				aitemInfos = []; // No image open, no history. QoopConnection will send a sample photo
			}
			
			// redirect to QOOP with all our item infos
 			if (_bsy) {
	 			_bsy.Hide();	
				_bsy = null;
 			}
			QoopConnection.LaunchPrintPartner( aitemInfos, _tlQoop.selectedItem )
		}		
				
	}
}
