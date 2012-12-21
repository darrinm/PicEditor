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
	
	import mx.core.UIComponent;
	import util.IProxyHandle;
	import util.ModLoader;
	
	public class DialogHandle implements IProxyHandle {

		private var _strDialog:String;
		private var _uicParent:UIComponent;
		private var _fnComplete:Function;
		private var _obParams:Object;
		private var _ldr:ModLoader;

		public var IsLoaded:Boolean = false;
		public var dialog:Object = null;

		public function DialogHandle(strDialog:String, uicParent:UIComponent=null, fnComplete:Function=null, obParams:Object=null) {
			_strDialog = strDialog;
			_uicParent = uicParent;
			_fnComplete = fnComplete;
			_obParams = obParams;
		}
		
		public function ProxyLoad(ldr:ModLoader): void {
			_ldr = ldr;
			_ldr.LoadSWF( this );
			IsLoaded = false;	
		}
		
		public function ProxyLoaded(obModDialog:Object):void {
			if (obModDialog && 'Show' in obModDialog) {
				var handle:DialogHandle = obModDialog['Show'](_strDialog, _uicParent, _fnComplete, _obParams);
				dialog = handle.dialog;
				IsLoaded = true;
			} else if (null != _fnComplete) {
				_fnComplete({success:false, error: true});
			}
		}
		
		public function Hide(): void {	
			if (IsLoaded && dialog && ('Hide' in dialog)) {
				dialog['Hide']();
			} else if (!IsLoaded && _ldr) {
				_ldr.Cancel(this);
			}
		}
		
		public function get logText():String {
			return _strDialog;
		}
	}
}
