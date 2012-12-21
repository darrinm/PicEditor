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
	
	import flash.external.ExternalInterface;
	
	// ExternalService.as manages the interface between the client and the containing page
	// TODO: consolidate all calls to ExternalInterface.call into here?
	
	public dynamic class ExternalService {		

		private static var s_instance:ExternalService = null;	// singletonia!
		private var _fnOnHideAlternate:Function = null;
		private var _strAlternateUrl:String = null;
		private var _fShowingAlternate:Boolean = false;
		private var _strStateCallback:String = null;

		public static function GetInstance(): ExternalService {
			if (!s_instance) {
				s_instance = new ExternalService;
			}
			return s_instance;
		}
		
		public function ExternalService() {
			try {
				ExternalInterface.addCallback("IsNavigateOk", OnIsNavigateOk);
				ExternalInterface.addCallback("LoadDocument", OnLoadDocument);
				ExternalInterface.addCallback("CloseDocument", OnCloseDocument);
				ExternalInterface.addCallback("OnHideAlternate", OnHideAlternate);
				ExternalInterface.addCallback("OnShowAlternate", OnShowAlternate);
			} catch (err:Error) {
				// Ignore
			}
		}
		
		[Bindable]
		public function set showingAlternate( f:Boolean ): void {
			_fShowingAlternate = f;
		}
		
		public function get showingAlternate(): Boolean {
			return _fShowingAlternate;
		}
		
		private function OnIsNavigateOk():Boolean {
			var doc:GenericDocument = PicnikBase.app.activeDocument;
			if (!doc || !doc.isDirty)
				return true;
			return false;
		}
		
		private function OnLoadDocument(oArgs:Object):Boolean {
			// validate oArgs
			
			// check if we need to close/save the currently open document
			
			// do other stuff
			return false;
		}				
		
		private function OnCloseDocument():Boolean {
			return false;
		}		

		private function OnHideAlternate( oArgs:Object ):Boolean {
			if (_fnOnHideAlternate != null && _strAlternateUrl) {
				_fnOnHideAlternate();
			}
			_fnOnHideAlternate = null;
			_strAlternateUrl = null;
			showingAlternate = false;
			return false;
		}
		
		private function OnShowAlternate( oArgs:Object ):Boolean {
			showingAlternate = true;
			return false;
		}
		
		public function ShowAlternate( strUrl:String, fnOnHide:Function ): void {
			_strAlternateUrl = strUrl;			
			_fnOnHideAlternate = fnOnHide;
			try {
				ExternalInterface.call("PicnikScript.ShowAlternate", { url: strUrl });
			} catch (err:Error) {
				// Ignore
			}			
		}
		
		public function HideAlternate(): void {
			_strAlternateUrl = null;
			try {
				ExternalInterface.call("PicnikScript.HideAlternate");
			} catch (err:Error) {
				// Ignore
			}			
		}
		
		public function SetStateCallback( strStateCb:String ): void {
			_strStateCallback = strStateCb;
		}
		
		public function ReportState( strState:String, obInfo:Object = null, strCallback:String = null ):void {
			try {
				if (null == strCallback) {
					strCallback = _strStateCallback;
				}
				if (_strStateCallback) {
					ExternalInterface.call(_strStateCallback, strState, PicnikBase.app.instanceId, obInfo);
				}
			} catch (err:Error) {
				// Ignore
			}
		}
	}
}
