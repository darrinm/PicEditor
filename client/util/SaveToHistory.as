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
package util {
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
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.resources.ResourceBundle;
		
	public class SaveToHistory {
   		[ResourceBundle("SaveToHistory")] private var _rb:ResourceBundle;
   		   				
		private var _imgd:ImageDocument;		
		private var _fnDone:Function;
		private var _uicParent:UIComponent;
		private var _bsy:IBusyDialog;		
		private var _canPrintOp:Cancelable = null;

		public function SaveToHistory( uicParent:UIComponent, imgd:ImageDocument, fnDone:Function ) {
			_uicParent = uicParent;
			_imgd = imgd;
			_fnDone = fnDone;
		}
		
		// fnDone: function( nErr:int ): void {}
		static public function Save(uicParent:UIComponent, imgd:ImageDocument, fnDone:Function ): void {
			var _sth:SaveToHistory = new SaveToHistory( uicParent, imgd, fnDone );
			_sth._save();
		}
				
		private function _save(): void {
			if (null == _imgd) {
				if (null != _fnDone) {
					_fnDone( ImageDocument.errDocumentError );
				}
				return;
			}
			
			if (AccountMgr.GetInstance().isGuest) {
				_askForRegister();
			} else {
				_renderImage();				
			}
		}
		
		private function _askForRegister(): void {
			DialogManager.ShowRegister( PicnikBase.app );
		}
				
		private function _renderImage(): void {
			_bsy = BusyDialogBase.Show(	_uicParent,
										Resource.getString("SaveToHistory", "Rendering"),
										BusyDialogBase.SAVE_USER_IMAGE,
										"", 0.5, _onRenderCancel);
			
			// render the current image before proceeding
			_canPrintOp = new Cancelable( this, _onRenderDone );
			new RenderHelper(_imgd, _canPrintOp.callback, _bsy).Render({ history: true });
			PicnikService.Log("SaveToHistory rendering " + _imgd.properties.title );							
		}
		
		private function _onRenderCancel(dctResult:Object): void {
			_bsy.Hide();
			_bsy = null;
			_canPrintOp.Cancel();
		}		
		
		
		private function _onRenderDone(err:Number, strError:String, obResult:Object=null): void {
			if (err != PicnikService.errNone) {
	 			if (_bsy) {
		 			_bsy.Hide();	
					_bsy = null;
	 			}
	 			if (err == StorageServiceError.ChildObjectFailedToLoad) {
	 				Bridge.DisplayCouldNotProcessChildrenError();
	 			} else {
					Util.ShowAlert( Resource.getString("SaveToHistory", "failed_to_render"),
									Resource.getString("SaveToHistory", "Error"),
									Alert.OK,
	  								"SaveToHistory problem: failed to render: " + err + ", " + strError);
				}
			} else {	
				
				var fnOnCommitRenderHistory:Function = function (err:Number, strError:String): void {
		 			if (_bsy) {
			 			_bsy.Hide();	
						_bsy = null;
		 			}				
					if (null != _fnDone) {
						_fnDone( err, obResult );
					}
				}
				
				var itemInfo:ItemInfo = StorageServiceUtil.GetLastingItemInfo(ItemInfo.FromImageProperties(_imgd.properties));
				PicnikService.CommitRenderHistory(obResult.strPikId, itemInfo, 'Picnik', fnOnCommitRenderHistory);				
			}
		}
	}
}
