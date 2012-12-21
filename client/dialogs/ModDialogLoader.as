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
package dialogs {
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

	public class ModDialogLoader {
        private var _module:IModuleInfo;
        private var _aHandles:Array = [];
		private var _fnCallback:Function = null;
		private var _canLoadOp:Cancelable = null;
		private var _fCancelled:Boolean = false;
		private var _fCancelable:Boolean = false;
		private var _bsy:IBusyDialog = null;
       
		function ModDialogLoader( fnCallback:Function ) {
			_fnCallback = fnCallback;
		}
        public function LoadSWF(dlg:DialogHandle, fCancelable:Boolean = true): Boolean {
            try {
				_aHandles.push(dlg);

				if (null == _module) {
					_module = ModuleManager.getModule(PicnikBase.app.GetLocModuleName("ModDialog"));   
					_module.addEventListener("ready", OnReady);
					_module.load();
				}
				
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

			} catch(e:SecurityError) {
				PicnikService.LogException("SecureModLoader2:LoadSWF SecurityError", e );
                trace(e);
            }
            return true;
        }
		
		public function Cancel(dlg:DialogHandle): void {
			var nIndex:int = _aHandles.indexOf(dlg);
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
				var modDialog:Object = _module.factory.create();				
			} catch(e:SecurityError) {
				PicnikService.LogException("SecureModLoader2:OnReady SecurityError", e );
                trace(e);
            }           
			DoCallbacks(modDialog);
        }
		
		private function OnDialogCancel(obResult:Object): void {
			_fCancelled = true;
			_module.unload();
			_module.removeEventListener("ready", OnReady);
			_module = null;
			DoCallbacks(null);
		}
		
        private function OnError(evt:Event): void {
        	PicnikService.Log("ModDialogLoader:failed to load" + evt.toString(), PicnikService.knLogSeverityError);
			DoCallbacks(null);
        }
		
		private function DoCallbacks( obResult:Object ): void {
			if (_bsy) _bsy.Hide();
			_bsy = null;
			for each ( var dlg:DialogHandle in _aHandles ) {
				dlg.ProxyLoaded(obResult);
			}
			_aHandles = [];
			if (null != _fnCallback)
				_fnCallback(obResult);
		}
	}
}
