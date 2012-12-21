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
	import dialogs.BusyDialogBase;
	import dialogs.IBusyDialog;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	
	import mx.modules.*;
	import mx.rpc.*;
	import mx.utils.URLUtil;
	
	import util.Cancelable;
	import util.URLLoaderPlus;

	public class ModLoader {
        private var _module:IModuleInfo;
        private var _aHandles:Array = [];
		private var _fnCallback:Function = null;
		private var _strModName:String = null;
		private var _canLoadOp:Cancelable = null;
		private var _fCancelled:Boolean = false;
		private var _fCancelable:Boolean = false;
		private var _bsy:IBusyDialog = null;
		private var _strLogText:String = null;
       
		function ModLoader( strModName:String, fnCallback:Function ) {
			_strModName = strModName;
			_fnCallback = fnCallback;
		}
        public function LoadSWF(oProxy:IProxyHandle, fCancelable:Boolean = true): Boolean {
            try {
				_aHandles.push(oProxy);

				if (_bsy && _fCancelable && !fCancelable) {
					_bsy.Hide();
					_bsy = null;
				}
				
				if (null == _bsy) {
					_fCancelable = fCancelable;
					_bsy = BusyDialogBase.Show(PicnikBase.app, "",
						BusyDialogBase.OTHER, fCancelable ? null : "IndeterminateNoCancel",
						0, OnDialogCancel);
				}

				if (null == _module) {
					Util.UrchinLogReport("/modloader/" + _strModName + "/request/" + logText );					

					_module = ModuleManager.getModule(PicnikBase.app.GetLocModuleName(_strModName));   
					_module.addEventListener("ready", OnReady);
					_module.load();
				}

			} catch(e:SecurityError) {
				PicnikService.LogException("ModLoader:LoadSWF SecurityError loading " + _strModName, e );
				Util.UrchinLogReport("/modloader/" + _strModName + "/errorsec/" + logText );					
                trace(e);
            }
            return true;
        }
		
		public function Cancel(oProxy:IProxyHandle): void {
			Util.UrchinLogReport("/modloader/" + _strModName + "/progcancel/" + logText );					
			var nIndex:int = _aHandles.indexOf(oProxy);
			if (nIndex >= 0) {
				_aHandles.splice(nIndex,1);
			}
			if (_aHandles.length == 0 && _bsy) {
				_bsy.Hide();
				_bsy = null;
			}
		}

        private function OnReady(evt:Event): void {
            try {
				Util.UrchinLogReport("/modloader/" + _strModName + "/ready/" + logText );					
				var mod:Object = _module.factory.create();				
			} catch(e:SecurityError) {
				PicnikService.LogException("ModLoader:OnReady SecurityError " + _strModName, e );
                trace(e);
            }           
			DoCallbacks(mod);
        }
		
		private function OnDialogCancel(obResult:Object): void {
			Util.UrchinLogReport("/modloader/" + _strModName + "/usercancel/" + logText );					
			_fCancelled = true;
			_module.unload();
			_module.removeEventListener("ready", OnReady);
			_module = null;
			DoCallbacks(null);
		}
		
        private function OnError(evt:Event): void {
			Util.UrchinLogReport("/modloader/" + _strModName + "/error/" + logText );					
        	PicnikService.Log("ModLoader:failed to load " + _strModName + " " + evt.toString(), PicnikService.knLogSeverityError);
			DoCallbacks(null);
        }
		
		private function DoCallbacks( obResult:Object ): void {
			if (_bsy) _bsy.Hide();
			_bsy = null;
			for each ( var oProxy:IProxyHandle in _aHandles ) {
				oProxy.ProxyLoaded(obResult);
			}
			_aHandles = [];
			if (null != _fnCallback)
				_fnCallback(obResult);
		}
		
		private function get logText():String {
			if (_aHandles.length > 0) {
				return _aHandles[0].logText;
			}
			return "";
		}
	}
}
