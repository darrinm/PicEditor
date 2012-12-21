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
package containers
{
	import controls.EffectButtonBase;
	import controls.Tip;
	
	import dialogs.DialogManager;
	
	import events.HelpEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import imagine.serialization.SerializationUtil;
	
	import mx.controls.Button;
	import mx.core.ComponentDescriptor;
	import mx.core.ScrollPolicy;
	import mx.effects.Effect;
	import mx.effects.Resize;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	
	import util.ISerializable;
	import util.LocUtil;
	import util.TipManager;
	import util.TipState;

	[Event(name="reset", type="flash.events.Event")]
	[Event(name="changeImage", type="flash.events.Event")]
	[Event(name="changeHeight", type="flash.events.Event")]
	public class NestedControlCanvasBase extends DelayedInitCanvas
	{
		[Bindable] public var _efbtn:EffectButtonBase;
   		[Bindable] [ResourceBundle("NestedControlCanvas")] private var rb:ResourceBundle;
		
		[Bindable] public var _btnCancel:Button;
		[Bindable] public var _btnApply:Button;
		[Bindable] public var _efSelect:Effect;
		[Bindable] public var _efDeselect:Effect;
		[Bindable] public var premium:Boolean = false;
		[Bindable] public var _nCollapsedHeight:Number = 73;
				
  		[Bindable] [ResourceBundle("EffectCanvas")] private var _rb:ResourceBundle;
		
		public static const APPLY_CLICK:String = "ApplyClick";
		public static const CANCEL_CLICK:String = "CancelClick";

		protected var _fRecordedDefaults:Boolean = false;
		
		[Bindable] protected var _fSelected:Boolean = false;
		
		protected var _fSelectEffectPlaying:Boolean = false;
		protected var _nUpdateSpeed:Number = 0;

		// Use xmlOrig to calculate our "dirty" bit.
		// It is the XML for the image operation when the effect was selected.
		protected var _strOrigState:String = null;

		public function NestedControlCanvasBase()  {
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			percentWidth = 100;
			verticalScrollPolicy =  ScrollPolicy.OFF;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			cacheAsBitmap = true;
		}
		
		[Bindable(event="updateSpeedChange")]
		public function get updateSpeed(): Number {
			return _nUpdateSpeed;
		}
		
		public function set updateSpeed(nUpdateSpeed: Number): void  {
			if (nUpdateSpeed > 30 && Math.abs(_nUpdateSpeed - nUpdateSpeed) > 20) {
				_nUpdateSpeed = nUpdateSpeed;
				dispatchEvent(new Event("updateSpeedChange"));
			}
		}
		
		public function IsDirty(): Boolean {
			if (!_strOrigState) return false;
			if (!operation) return false;
			return _strOrigState != SerializationUtil.WriteToString(operation);
		}

		// Default beahvior - look in the MXML
		// Override to customize
		protected function get operation(): ISerializable {
			if ("_op" in this) return this["_op"];
			return null;
		}
		
		protected function get resetValues(): Array {
			if ("_resetValues" in this) return this["_resetValues"];
			return null;
		}
		
		[Bindable(event="changeHeight")]
		public function get fullHeight(): Number {
			validateSize(true);
			return measuredHeight + 10;
		}
		
		public function get isOpen(): Boolean {
			return height == fullHeight;
		}
		
		protected function UpdateHeight(): void {
			var cy:int = fullHeight;
			if (_efSelect)
				Resize(_efSelect).heightTo = cy;
			if (_efDeselect)
				Resize(_efDeselect).heightFrom = cy;
		}
		
		[Bindable(event="changeHeight")]
		public function get collapsedHeight(): Number {
			if ("_nCollapsedHeight" in this) return this["_nCollapsedHeight"];
			return 73; // Default height
		}
		
		protected function OnInitialize(evt:Event): void {
			if (_efbtn) {
				// Do this before we add the effect button click listener. This one overrides the other.
				_efbtn._btnInfo.addEventListener(MouseEvent.CLICK, OnInfoClick);
			}
			if (_efbtn) _efbtn.addEventListener(MouseEvent.CLICK, OnEffectButtonClick);
			addEventListener(APPLY_CLICK, OnApplyClick);
			addEventListener(CANCEL_CLICK, OnCancelClick, true);
			if (_btnCancel) _btnCancel.addEventListener(MouseEvent.CLICK, OnCancelClick);
			if (_btnApply) _btnApply.addEventListener(MouseEvent.CLICK, OnApplyClick);
			height = collapsedHeight;
		}
			
		override protected function OnAllStagesCreated(): void {
			super.OnAllStagesCreated();
			
			dispatchEvent(new Event("changeHeight"));
			var efResize:Resize;
			efResize = new Resize(this);
			efResize.heightTo = fullHeight;
			efResize.heightFrom = collapsedHeight + 15;
			efResize.duration = 200;
			_efSelect = efResize;

			efResize = new Resize(this);
			efResize.heightTo = collapsedHeight;
			efResize.heightFrom = fullHeight;
			efResize.duration = 200;
			_efDeselect = efResize;
		}
		
		public function SetHelpState(fVisible:Boolean): void {
			if (_efbtn) _efbtn._btnInfo.selected = fVisible;
			var strEventType:String;
			if (fVisible) {
				strEventType = HelpEvent.SHOW_HELP;
			} else {
				strEventType = HelpEvent.HIDE_HELP;
			}
			DispatchHelpEvent(strEventType);
		}
		
		protected function DispatchHelpEvent(strEventType:String): void {
			var obExtraData:Object = null;
			
			if ('beforeAfterSettings' in this) {
				obExtraData = {};
				obExtraData.beforeAfterSettings = this['beforeAfterSettings'];
				Debug.Assert('sizes' in obExtraData.beforeAfterSettings);
				Debug.Assert('sourceSuffix' in obExtraData.beforeAfterSettings);
				Debug.Assert('sourcePrefix' in obExtraData.beforeAfterSettings);
			}
			
			dispatchEvent(new HelpEvent(strEventType, helpText, helpTitle, obExtraData));
		}
		
		public function UpdateHelpText(): void {
			DispatchHelpEvent(HelpEvent.SET_HELP_TEXT);
		}
		
		public function get effectName(): String {
			if (_efbtn) {
				return _efbtn.strTitle;
			} else {
				return "Effect";
			}
		}

		protected function get helpText():String {
			if ("_strHelpText" in this) return this["_strHelpText"];
			return "No help text? Make sure you set _strHelpText for your effect.";
		}
		
		protected function get helpTitle():String {
			return LocUtil.rbSubst('EffectCanvas', 'about_title', effectName);
		}
		
		protected function get canvasTipId(): String {
			import flash.utils.getQualifiedClassName;
			var strClassName:String = getQualifiedClassName(this);
			return strClassName.slice(strClassName.lastIndexOf(":") + 1);
		}
		
		protected function get canvasTip(): String {
			var strKey:String = "canvasTip";
			if (_strCanvasTipIDSuffix && _strCanvasTipIDSuffix.length > 0)
				strKey += "_" + _strCanvasTipIDSuffix;
			
			var strTip:String = Resource.getString(canvasTipId, strKey);
			return strTip;
		}
		
		private function get canvasTipXML(): XML {
			return <Tip position="canvasTip"><CanvasTipText><p align="center">{canvasTip}</p></CanvasTipText></Tip>
		}
		
		protected function set canvasTipIDSuffix(str:String): void {
			if (_strCanvasTipIDSuffix != str) {
				_strCanvasTipIDSuffix = str;
				if (_tipCanvas != null) _tipCanvas.content = canvasTipXML;
			}
		}
		
		private var _strCanvasTipIDSuffix:String = "";
		private var _tipCanvas:Tip;
		
		public function ShowCanvasTip(): void {
			var strTip:String = canvasTip;
			if (strTip == null)
				return;
				
			var fnOnGetTipState:Function = function (strTipId:String, nTipState:Number): void {
				if (nTipState == TipState.knClosed)
					return;
			
				_tipCanvas = new Tip();
				_tipCanvas.addEventListener(Event.CLOSE, OnCanvasTipClose);
				_tipCanvas.Show(null, null, canvasTipXML);
				TipManager.GetInstance().UpdateTipState(canvasTipId, TipState.knShown);
			}
			TipManager.GetInstance().GetTipState(canvasTipId, fnOnGetTipState);
		}
		
		public function HideCanvasTip(): void {
			if (_tipCanvas) {
				_tipCanvas.removeEventListener(Event.CLOSE, OnCanvasTipClose);
				_tipCanvas.Hide();
				_tipCanvas = null;
			}
		}
		
		private function OnCanvasTipClose(evt:Event): void {
			TipManager.GetInstance().UpdateTipState(canvasTipId, TipState.knClosed);
			_tipCanvas.removeEventListener(Event.CLOSE, OnCanvasTipClose);
			_tipCanvas = null;
		}
		
		protected function OnInfoClick(evt:MouseEvent): void {
			if (IsSelected()) {
				// Only respond to the event if the effect is selected.
				evt.stopPropagation(); // Make sure we don't deselect the effect
				// Select or deselect. Should be a toggle button.
				SetHelpState(_efbtn._btnInfo.selected);
				PicnikBase.SetPersistentClientState(helpPersistentStateKey, _efbtn._btnInfo.selected);
			} else {
				// Not selected. Keep toggle button in old state.
				_efbtn._btnInfo.selected = !_efbtn._btnInfo.selected;
			}
		}

		protected function allowDeselect(): Boolean { return true; }
				
		protected function OnEffectButtonClick(evt:MouseEvent): void {
			if (evt.localY <= collapsedHeight) {
				var strEventType:String;
				
				if (!IsSelected()) strEventType = NestedControlEvent.SELECT_NICELY;
				else if (allowDeselect()) strEventType = NestedControlEvent.DESELECT_NICELY;
				else return;
				dispatchEvent(new NestedControlEvent(strEventType, this, true));
			}
		}
		
		public function OpenEffect(): void {
			dispatchEvent(new NestedControlEvent(NestedControlEvent.SELECT_NICELY, this, true));
		}
		
		public function OnOpChange(): void {
			// Reflect a new operation state
			dispatchEvent(new NestedControlEvent(NestedControlEvent.OP_CHANGED, this));
			
			// OPT: this kind of sucks because it invalidates the whole NestedControlCanvasBase and
			// its children when the idea is really to cause a lazy UpdateBitmapData to occur.
			invalidateDisplayList();
		}
		
		// CONSIDER: using updateSpeed stuff
		private var _tmrOpChange:Timer;
		
		public function OnBufferedOpChange(): void {
			// If no additional op changes occur in the next 200 milliseconds then fire off the change
			if (_tmrOpChange == null) {
				_tmrOpChange = new Timer(100, 1);
				_tmrOpChange.addEventListener(TimerEvent.TIMER_COMPLETE, OnOpChangeTimerComplete);
			}
			
			_tmrOpChange.reset();
			_tmrOpChange.start();
		}
		
		private function OnOpChangeTimerComplete(evt:TimerEvent): void {
			if (IsSelected())
				OnOpChange();
		}

		[Bindable(event="reset")]
		public function get zeroR(): Number {
			return 0;
		}
		
		protected function IsSelected(): Boolean {
			return _fSelected;
		}
		
		protected function UpdateStateForSelected(fSelected:Boolean): void {
			PicnikBase.app.basket.disabled = fSelected;
			if (fSelected) PicnikBase.SetPremiumPreview(premium);
		}
		
		protected function get helpPersistentStateKey(): String {
			return "CreativeTools.Effects.InfoVisible";
		}
		
		protected function get showHelpDefault(): Boolean {
			return false;
		}
		
		private var _efcnvCleanup:NestedControlCanvasBase;
		
		public function CleanupPriorEffect(): void {
			if (_efcnvCleanup) {
				_efcnvCleanup.Revert();
				_efcnvCleanup = null;
			}
		}
		
		public function Select(efcnvCleanup:NestedControlCanvasBase): Boolean {
			_efcnvCleanup = efcnvCleanup;
			
			createComponentsIfNeeded();
			
			if (!IsSelected()) {
				UpdateStateForSelected(true);
				
				_fSelected = true;
				OnSelectedEffectBegin(null);
				_efSelect.addEventListener(EffectEvent.EFFECT_END, OnSelectedEffectEnd);
				_fSelectEffectPlaying = true;
				_efSelect.suspendBackgroundProcessing = true;
//				cacheAsBitmap = false;
				_efSelect.play();
				if (_efbtn) _efbtn._efSelect.play();
				if (_efbtn) {
				 	ShowCanvasTip();
					_efbtn._btnInfo.selected = PicnikBase.GetPersistentClientState(helpPersistentStateKey, showHelpDefault);
					if (_efbtn._btnInfo.selected) {
					 	SetHelpState(true);
					} else {
						UpdateHelpText(); // State isn't changing, but text is.
					}
				}
				if (_efbtn) _efbtn.currentState = "Selected";
				dispatchEvent(new NestedControlEvent(NestedControlEvent.SELECTED, this));

				if (resetValues) {
					if (!_fRecordedDefaults) {
						StoredValue.readUninitializedValues(resetValues, this);
						_fRecordedDefaults = true;
					} else {
						StoredValue.applyValues(resetValues, this);
					}
				}
				dispatchEvent(new Event("reset")); // Reset any values depending on the reset vars
				_strOrigState = null; // Reset our "default" image operation

				// Sub-classes can/should override this to show the effect and set up defaults
				invalidateDisplayList();
			}
			return true; // Selected
		}
		
		protected function OnApplyClick(evt:Event): void {
			if (premium && !AccountMgr.GetInstance().isPremium) {
				// UNDONE: upgrade support...
				if (PicnikConfig.freeForAll && AccountMgr.GetInstance().isGuest) {
					DialogManager.ShowFreeForAllSignIn("/effect_" + className + "/inline");
				} else {
					DialogManager.ShowUpgrade("/effect_" + className + "/inline");
				}
			} else {
				Apply();
				Deselect();
			}
		}
		
		protected function OnCancelClick(evt:Event): void {
			Deselect();
		}
		
		public function OnSelectedEffectBegin(evt:Event): void {
			dispatchEvent(new NestedControlEvent(NestedControlEvent.SELECTED_EFFECT_BEGIN, this));
		}
		
		protected function StoreOriginalState(): void {
			if (operation) _strOrigState = SerializationUtil.WriteToString(operation);
		}
		
		public function OnSelectedEffectReallyDone(): void {
			_fSelectEffectPlaying = false;
//			cacheAsBitmap = true;
			invalidateDisplayList();
			dispatchEvent(new Event("changeImage")); // Make sure we are set up for the correct image.
			PicnikBase.app.LogNav(className);
			callLater(StoreOriginalState);
		}

		public function OnSelectedEffectEnd(evt:Event): void {
			evt.target.removeEventListener(EffectEvent.EFFECT_END, OnSelectedEffectEnd);
			dispatchEvent(new NestedControlEvent(NestedControlEvent.SELECTED_EFFECT_END, this));
			callLater(OnSelectedEffectReallyDone);
		}
		
		public function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null): void {
			if (IsSelected()) {
				if (!efcvsNew) {
					UpdateStateForSelected(false);
				}
				if (!efcvsNew || !efcvsNew.premium)  
					PicnikBase.app.zoomView.premiumPreview = false;
				
				if (_efbtn) {
					HideCanvasTip();
					if (!efcvsNew && _efbtn._btnInfo.selected) SetHelpState(false);
				}
				_fSelected = false;
				_fSelectEffectPlaying = false;
//				cacheAsBitmap = true;
				if (_efbtn) _efbtn.currentState = "";
				
				_efDeselect.addEventListener(EffectEvent.EFFECT_END, OnDeselectedEffectEnd);
				_efDeselect.play();
				if (_efbtn && fForceRollOutEffect) _efbtn._efRollOut.play();
				if (_efbtn) _efbtn._efDeselect.play();
				dispatchEvent(new NestedControlEvent(NestedControlEvent.DESELECTED, this));

			} else {
				// Not currently selected. Go ahead and play the deselect effect anyway, just in case.
				_efDeselect.play();
			}
		}
		
		// Only called when we are not swapping effects.
		protected function OnDeselectedEffectEnd(evt:Event): void {
			evt.target.removeEventListener(EffectEvent.EFFECT_END, OnDeselectedEffectEnd);
			// Let the caller handle changing the bitmapdata and calling ClearCache()
			dispatchEvent(new NestedControlEvent(NestedControlEvent.DESELECTED_EFFECT_END, this));
		}

		public function Revert(): void {
			// Undo the effect
		}

		public function Apply(): void {
			// Commit the effect
			// UNDONE: similar code should be done in GalleryStyleCanvasBase.Apply()
			Util.UrchinLogReport("/effect_applied/" + className);
		}

		protected override function initStageForComponent(cd:ComponentDescriptor): Number {
			return (cd.id == "_efbtn") ? 0 : 1;
		}
	}
}
