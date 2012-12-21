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
package controls
{
	import containers.NestedControlCanvasBase;
	import flash.events.Event;
	import containers.ResizingHBox;
	import mx.events.FlexEvent;
	import flash.display.DisplayObject;
	import containers.NestedControlEvent;

	public class ApplyCancelEffectButtonsBase extends ResizingHBox
	{
		[Bindable] public var actm:AccountMgr = AccountMgr.GetInstance();
		[Bindable] public var premium:Boolean = false;
		[Bindable] public var addBoxPadding:Boolean = false;
		[Bindable] public var upgradeNeeded:Boolean = false;
		
		public function ApplyCancelEffectButtonsBase(): void {
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		private function GetEffectParent(): NestedControlCanvasBase {
			var dob:DisplayObject = this;
			while (dob != null && !(dob is NestedControlCanvasBase))
				dob = dob.parent;

			return dob as NestedControlCanvasBase;
		}
		
		private function OnCreationComplete(evt:Event): void {
			// Walk up the tree and see what we can find. If we find an effect canvas, listen for effect events.
			try {
				var nccb:NestedControlCanvasBase = GetEffectParent();
				if (nccb == null)
					return;
				
				nccb.addEventListener(NestedControlEvent.SELECTED_EFFECT_END, DoubleCheckUpgradeNeeded);
			} catch (e:Error) {
				trace("ignoring error: " + e);
			}
		}
		
		private function DoubleCheckUpgradeNeeded(evt:Event=null): void {
			try {
				if (upgradeNeeded && actm.isPaid) {
					actm.DispatchDummyIsPaidChangeEvent();
				}
			} catch (e:Error) {
				trace("ignoring error: " + e);
			}
		}
		
		public function ApplyClick(): void {
			dispatchEvent(new Event(NestedControlCanvasBase.APPLY_CLICK, true));
		}
		
		public function CancelClick(): void {
			dispatchEvent(new Event(NestedControlCanvasBase.CANCEL_CLICK, true));
		}
	}
}