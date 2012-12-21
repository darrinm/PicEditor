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
// STATE SAVE/RESTORE POLICIES
// - Classes that desire to save/restore state implement GetState and RestoreState
// - Properties of the Object returned by GetState must be SharedObject-compatible
// - GetState implementations call GetState recursively on their non-primitive child objects
// - RestoreState implementations must recurse depth-first, restoring child object state
// - RestoreState implementations must save/restore all exposed state, although some state might
//   be temporary while waiting for state to restore asynchronously
// - Exposed state that restores async must generate notifications as it completes
// - Errors that occur during state restoration (incl. async) must throw "state restoration failed" exceptions
// - by convention a class's GetState/RestoreState methods follow its constructor
// UNDONE: can a user abort state restoration? if so, how? and how to halt async restorations in progress?

package {
	import dialogs.BusyDialogBase;
	import dialogs.IBusyDialog;
	
	import mx.core.Application;
	import mx.resources.ResourceBundle;
	
	public class RestoreMgr {
		private static var s_fnDone:Function;
		private static var s_bsy:IBusyDialog;
		
   		[ResourceBundle("RestoreMgr")] static protected var rb:ResourceBundle;
		
		public static function RestoreState(sto:Object, fnDone:Function=null): void {
			s_fnDone = fnDone;
			// we add a 100ms delay to this dlg so that we avoid a brief flash of double-dialog-ness
			// if there's really nothing that needs to be loaded.
			s_bsy = BusyDialogBase.Show(Application(Application.application),
					Resource.getString("RestoreMgr", "restoring"), BusyDialogBase.RESTORE, "ProgressWithCancel", 100, OnBusyDialogCancel);
			if (!s_bsy)
				return;
				
			PicnikBase.app.RestoreStateAsync(sto, OnProgress, OnDone);
		}
		
		private static function OnProgress(nPercent:Number, strMessage:String): void {
//			trace("RestoreMgr.OnProgress: nPercent: " + nPercent + ", strMessage: " + strMessage);
			try {
				if (s_bsy) {
					s_bsy.progress = nPercent;
					s_bsy.message = strMessage;
				}
			} catch (e:Error) {
				PicnikService.Log("Ignored Client Exception: in RestoreMgr.OnProgress: strMessage=" + strMessage + ", s_bsy = " + s_bsy + ":" + e + ", "  +e.getStackTrace(), PicnikService.knLogSeverityInfo);
			}
		}
		
		private static function OnDone(err:Number, strError:String): void {
	//		trace("RestoreMgr.OnDone: err: " + err + ", strError: " + strError);
			if (s_bsy) s_bsy.Hide();
			s_bsy = null;
			
			if (err != 0) {
	//			Alert(...);
				PicnikService.Log("Problem restoring state. " + strError + " (" + err + ")");
				if (s_fnDone != null)
					s_fnDone();
			} else {
				if (s_fnDone != null)
					s_fnDone();
			}
		}
		
		private static function OnBusyDialogCancel(dctResult:Object): void {
			trace("RestoreMgr.OnCancel");
			// UNDONE: What to do?
			if (s_bsy) s_bsy.Hide();
			s_bsy = null;
			if (s_fnDone != null)
				s_fnDone();
		}
		
		private static function OnAlertDone(): void {
			trace("RestoreMgr.OnAlertDone");
			if (s_fnDone != null)
				s_fnDone();
		}
	}
}
