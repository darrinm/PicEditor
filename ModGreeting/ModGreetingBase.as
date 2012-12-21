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
package {
	
	import containers.CoreDialog;
	import containers.ResizingDialog;
	
	import dialogs.*;
	
	import module.PicnikModule;
	
	import mx.core.UIComponent;

	public class ModGreetingBase extends PicnikModule {
		public function Show(strDialog:String, uicParent:UIComponent=null, fnComplete:Function=null, obParams:Object=null): DialogHandle {
			var dlg:Object = null;
			
			var dialogHandle:DialogHandle = new DialogHandle(strDialog, uicParent, fnComplete, obParams);

			// TODO (steveler) : move this over to a DialogRegistry class
			switch (strDialog) {
				case "SendGreetingDialog":
					dlg = new SendGreetingDialog();
					break;
			}

			var resizingDialog:ResizingDialog = dlg as ResizingDialog;
			if (null != resizingDialog) {
				if (uicParent == null) uicParent = PicnikBase.app;
				resizingDialog.Constructor(fnComplete, uicParent, obParams);
				ResizingDialog.Show(resizingDialog, uicParent);
			}		
			
			if (null != dlg) {
				dialogHandle.IsLoaded = true;
				dialogHandle.dialog = dlg;
			}
			
			return dialogHandle;
		} 		
	}
}
