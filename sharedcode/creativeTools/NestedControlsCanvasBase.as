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
package creativeTools {
	import containers.IncrementalInitVBox;
	import containers.NestedControlCanvasBase;
	import containers.NestedControlEvent;
	
	import dialogs.DialogManager;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.VBox;
	import mx.events.FlexEvent;
	
	import util.BitmapCache;
	import util.IPaintEffect;
	import util.ITabContainer;
	import util.IUndoRedoSaver;
	import util.MinorAction;

	public class NestedControlsCanvasBase extends CreativeToolCanvas implements ITabContainer {
		private var _efcnv:NestedControlCanvasBase = null;
		
		[Bindable] public var undoRedoSave:UndoRedoSave = null;
		
		[Bindable] public var _vb:VBox;
		
		private var _iursrPrev:IUndoRedoSaver = null;
		
		private var _strPendingTab:String = null;
		private var _fWatchingVBox:Boolean = false;

		//
		// ICreativeTool implementation
		//
		
		private function OnVBoxCreationComplete(evt:Event): void {
			if (_strPendingTab != null) LoadTab(_strPendingTab);
		}
		
		public function LoadTab(strTab:String): void {
			if (active) {
				if (_vb.numChildren > 0) {
					var dob:DisplayObject = _vb.getChildByName(strTab);
					var ecb:NestedControlCanvasBase = dob as NestedControlCanvasBase;
					if (ecb) ecb.Select(null);
					_strPendingTab = null;
				} else {
					_strPendingTab = strTab;
					if (!_fWatchingVBox) {
						_fWatchingVBox = true;
						if (_vb is IncrementalInitVBox) {
							_vb.addEventListener("allChildrenCreated", OnVBoxCreationComplete);
						} else {
							_vb.addEventListener(FlexEvent.CREATION_COMPLETE, OnVBoxCreationComplete);
						}
					}
				}
			} else {
				_strPendingTab = strTab;
			}
		}
		
		override public function HelpStateChange(fVisible:Boolean): void {
			if (_efcnv) _efcnv.SetHelpState(fVisible);
		}
		
		override public function OnActivate(ctrlPrev:ICreativeTool): void {
			super.OnActivate(ctrlPrev);
			
			addEventListener(NestedControlEvent.SELECTED, OnEffectSelected, true);
			addEventListener(NestedControlEvent.DESELECTED, OnEffectDeselected, true);
			addEventListener(NestedControlEvent.SELECT_NICELY, OnEffectSelectNicely, true);
			addEventListener(NestedControlEvent.DESELECT_NICELY, OnEffectDeselectNicely, true);
			addEventListener(NestedControlEvent.SELECTED_EFFECT_BEGIN, OnSelectedEffectBegin, true);
			addEventListener(NestedControlEvent.SELECTED_EFFECT_END, OnSelectedEffectEnd, true);
			addEventListener(NestedControlEvent.SELECTED_EFFECT_UPDATED_BITMAPDATA, OnSelectEffectComplete, true);
			if (_strPendingTab) LoadTab(_strPendingTab);
		}
		
		
		override public function OnDeactivate(ctrlNext:ICreativeTool): void {
			// Close any open effect
			DeselectEffect(false);
			removeEventListener(NestedControlEvent.SELECTED, OnEffectSelected, true);
			removeEventListener(NestedControlEvent.DESELECTED, OnEffectDeselected, true);
			removeEventListener(NestedControlEvent.SELECTED_EFFECT_BEGIN, OnSelectedEffectBegin, true);
			removeEventListener(NestedControlEvent.SELECTED_EFFECT_END, OnSelectedEffectEnd, true);
			removeEventListener(NestedControlEvent.SELECTED_EFFECT_UPDATED_BITMAPDATA, OnSelectEffectComplete, true);
			super.OnDeactivate(ctrlNext);
		}

		protected function OnSelectedEffectBegin(evt:NestedControlEvent): void {
			evt.NestedControlCanvas.addEventListener(Event.RESIZE, OnResizeEffect, false);
		}
		
		protected function OnSelectedEffectEnd(evt:NestedControlEvent): void {
			evt.NestedControlCanvas.removeEventListener(Event.RESIZE, OnResizeEffect, false);
			ScrollToShow(evt.NestedControlCanvas);
		}
		
		public override function set verticalScrollPosition(value:Number): void {
			// Fix bug - sometimes the scroll wasn't working
			// This is because the maximum scroll position needs to increase (to reflect
			// the new height of the contents) before we set the scroll position to the max value.
			if (value > maxVerticalScrollPosition)
				validateNow();
			super.verticalScrollPosition = value;
		}
		
		protected function ScrollToShow(efcnv:NestedControlCanvasBase): void {
			// The Effect may be nested a number of levels deep within the scrolling container.
			// Calculate its position in container coordinates.
			var yT:int = efcnv.y;
			var dob:DisplayObject = efcnv.parent;
			while (dob.parent != this) {
				yT += dob.y;
				dob = dob.parent;
			}
			
			// First check the top.
			if (yT < verticalScrollPosition || efcnv.height >= height) {
				verticalScrollPosition = yT; // Scroll to the top of the effect
			} else if ((yT + efcnv.height) > (height + verticalScrollPosition)) {
				verticalScrollPosition = (yT + efcnv.height) - height;
			}
			if (yT < verticalScrollPosition || efcnv.height >= height) {
				verticalScrollPosition = yT; // Scroll to the top of the effect
			}
		}
		
		protected function OnResizeEffect(evt:Event): void {
			if (evt.target is NestedControlCanvasBase) {
				ScrollToShow(evt.target as NestedControlCanvasBase);
			}
		}
		
		protected function OnEffectSelected(evt:NestedControlEvent): void {
			if (_efcnv != evt.NestedControlCanvas) {
				if (_efcnv) {
					DeselectEffect(true, true, evt.NestedControlCanvas);
				}
				_efcnv = evt.NestedControlCanvas;
			}
			if (undoRedoSave != null) {
				_iursrPrev = undoRedoSave.undoRedoSaver;
				var iursr:IUndoRedoSaver = null;
				if (_efcnv && _efcnv is IPaintEffect)
					iursr = IPaintEffect(_efcnv).paintMaskController;
				
				undoRedoSave.undoRedoSaver = iursr;			
			}
		}
		
		protected function PostEffectCleanup(efcnv:NestedControlCanvasBase): void {
			if (efcnv) efcnv.Revert();

			// Try to do this after the next display update
			stage.addEventListener(Event.ENTER_FRAME, OnEnterFrame);
		}
		
		private function OnEnterFrame(evt:Event): void {
			stage.removeEventListener(Event.ENTER_FRAME, OnEnterFrame);
			callLater(PicnikBase.ForceGC);
		}
		
		protected function DeselectEffect(fShowTransition:Boolean, fForceRollOutEffect:Boolean=true,
				efcnvNew:NestedControlCanvasBase=null): void {
			if (_efcnv != null) {
				// Calling deselect on _efcnv will cause it to be set to null in OnEffectDeselected,
				// so we must stash away a copy for the call to PostEffectCleanup.
				var deselectedEffect:NestedControlCanvasBase = _efcnv;
				_efcnv.Deselect(fForceRollOutEffect, efcnvNew);
				if (!fShowTransition) {
					PostEffectCleanup(deselectedEffect);
				} else {
					BitmapCache.MarkForDelayedClear();
				}
			}
		}
		
		protected function OnSelectEffectComplete(evt:Event): void {
			BitmapCache.DelayedClear();
			// ClearCache();
		}

		protected function OnDeselectedEffectEnd(evt:NestedControlEvent): void {
			evt.target.removeEventListener(NestedControlEvent.DESELECTED_EFFECT_END, OnDeselectedEffectEnd);
			// We are done deselecting our effect.
			// if there is no selected effect and the effect wasn't applied, reset to the original bitmapdata.
			if (!_efcnv && imgd && imgd.undoTransactionPending)
				PostEffectCleanup(evt.NestedControlCanvas);
		}
		
		override public function Deselect(): Boolean {
			if (_efcnv != null) {
				DeselectEffect(false);
				return true; // Something was deselected
			}
			return false; // Nothing to deselect
		}

		protected function OnEffectDeselected(evt:NestedControlEvent): void {
			evt.NestedControlCanvas.addEventListener(NestedControlEvent.DESELECTED_EFFECT_END, OnDeselectedEffectEnd);
			if (_efcnv == evt.NestedControlCanvas) {
				_efcnv = null;
			}
			if (undoRedoSave != null) undoRedoSave.undoRedoSaver = _iursrPrev;
		}
		
		private var _efcnvLocalAction:NestedControlCanvasBase = null;
		
		// Call this before going from one effect to another
		// so we can handle changing effects different from going from an effect to a different tab
		private function PrepareForLocalAction(): void {
			// Remember that we are doing a local change so we know how to handle "dirty"
			// See HasDirtyEffect
			_efcnvLocalAction = _efcnv;
		}

		// Call this when we are done with an action so we can
		// clear out any local action state.
		private function HandledAction(): void {
			_efcnvLocalAction = null;
		}

		// An effect is dirty if it is open and you made changes to it
		private function HasDirtyEffect(): Boolean {
			return (_efcnv && _efcnv.IsDirty());
		}
		
		override public function PerformActionIfSafe(act:IAction): void {
			// Confirm a selected effect unless you are selecting another effect and you did not make changes to the selected effect:
			// confirm changes if the effect is dirty OR this is a major action (e.g. navigating away)
			if (PicnikBase.app.activeDocument && (HasDirtyEffect() || (_efcnv && !(act is MinorAction)))) {
				var strEffectName:String = _efcnv ? _efcnv.effectName : "No effect";
				var strEffectClass:String = _efcnv ? _efcnv.className: "NoEffect";
				var fPremium:Boolean = _efcnv ? _efcnv.premium : false;
				DialogManager.Show("ConfirmApplyEffectDialog", _imgv, PerformActionCallback,
					{args:{act:act}, fPremiumEffect:fPremium, strEffectName:strEffectName, strEffectClass:strEffectClass});
			} else {
				act.Do();
			}
			HandledAction();
		}
		
		override public function PerformAction(act:IAction): void {
			if (PicnikBase.app.activeDocument && HasDirtyEffect()) {
				PerformActionCallback({success:true, act: act});
			} else {
				act.Do();
			}
			HandledAction();
		}
		
		public function PerformActionCallback(obResult:Object): void {
			if (obResult.success) {
				_efcnv.Apply();
			} else {
				_efcnv.Revert();
			}
			DeselectEffect(true);
			obResult.act.Do();
		}

		protected function OnEffectSelectNicely(evt:NestedControlEvent): void {
			PrepareForLocalAction(); // Going from one effect to another
			PerformActionIfSafe(new MinorAction(evt.NestedControlCanvas.Select, _efcnv));
		}

		protected function OnEffectDeselectNicely(evt:NestedControlEvent): void {
			// The user is deselecting an effect, in effect navigating back to the base state.
			PicnikBase.app.LogNav();
			PrepareForLocalAction(); // Going from one effect to another
			PerformActionIfSafe(new MinorAction(evt.NestedControlCanvas.Deselect, !evt.effectButtonClick));
		}
	}
}
