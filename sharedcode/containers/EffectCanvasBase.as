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
	import controls.InspirationTipBase;
	
	import dialogs.EasyDialogBase;
	
	import errors.InvalidBitmapError;
	
	import events.GenericDocumentEvent;
	import events.ImageDocumentEvent;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import imagine.ImageDocument;
	import imagine.imageOperations.ImageOperation;
	import imagine.objectOperations.ObjectOperation;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.core.UIComponent;
	
	import util.Navigation;

	[Event(name="reset", type="flash.events.Event")]
	[Event(name="changeImage", type="flash.events.Event")]
	[Event(name="changeHeight", type="flash.events.Event")]
	public class EffectCanvasBase extends NestedControlCanvasBase
	{
		public static var s_obDebugger:Object = null;
		// public static var s_obDebugger:Object = new OpEngineDebugManager();
		
		protected var _imgv:ImageView;
		[Bindable] protected var _imgd:ImageDocument;
		protected var _imgdCleanup:ImageDocument;
		
		public var _strClassNamePrefix:String = ""; // Used for analytics logging
		
		[Bindable] public var flash10:Boolean=false; // Set to true if this control requires flash 10
		
		public var urlid:String = null;
		public var tags:String = null;
		private var _uicInspirationRegion:UIComponent = null;
		private var _fMouseOver:Boolean = false;
		
		public function EffectCanvasBase(): void {
			addEventListener(MouseEvent.ROLL_OVER, OnRollOver);
			addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
			addEventListener(MouseEvent.MOUSE_MOVE, UpdateButtonOver);
		}
		
		private function OnRollOver(evt:MouseEvent): void {
			if (!urlid)
				return;
			_fMouseOver = true;
			UpdateButtonOver(evt);
		}
		
		private function OnRollOut(evt:MouseEvent): void {
			if (!urlid)
				return;
			_fMouseOver = false;
			buttonOver = false;
		}
		
		private function UpdateButtonOver(evt:MouseEvent): void {
			if (!_fMouseOver)
				buttonOver = false;
			else {
				var ptLocal:Point = globalToLocal(new Point(evt.stageX, evt.stageY));
				buttonOver = (ptLocal.y < collapsedHeight);
			}
		}
		
		private var _fButtonOver:Boolean = false;
		private function set buttonOver(f:Boolean): void {
			if (_fButtonOver == f)
				return;
			_fButtonOver = f;
			if (_fButtonOver)
				OnButtonOver();
			else
				OnButtonOut();
		}
		
		override public function createComponentsFromDescriptors(fRecurse:Boolean = true):void
		{
			super.createComponentsFromDescriptors(fRecurse);
			// Create inspiration canvas
			_uicInspirationRegion = new InspirationTarget();
			_uicInspirationRegion.height = collapsedHeight;
			_uicInspirationRegion.percentWidth = 100;
			addChildAt(_uicInspirationRegion, 0); // Add at the bottom.
		}
		
		private function OnButtonOver(evt:Event=null): void {
			if (urlid)
				InspirationTipBase.ShowInspirationByTag("effect:" + urlid, _uicInspirationRegion);
		}
		
		private function OnButtonOut(evt:Event=null): void {
			InspirationTipBase.HideTip();
		}
		
		// Returns the width of the image, if any
		// otherwise returns a default of 1024
		[Bindable(event="changeImage")]
		public function get imagewidth():Number {
			return origImageWidth;
		}
		
		// Returns the height of the image, if any
		// otherwise returns a default of 1024
		[Bindable(event="changeImage")]
		public function get imageheight():Number {
			return origImageHeight;
		}

		// Returns the width of the image, if any
		// otherwise returns a default of 1024
		[Bindable(event="reset")]
		public function get origImageWidth():Number {
			if (_imgd) return _imgd.GetCommittedImageSize().x;
			else return 1024;
		}
		
		// Returns the height of the image, if any
		// otherwise returns a default of 1024
		[Bindable(event="reset")]
		public function get origImageHeight():Number {
			if (_imgd) return _imgd.GetCommittedImageSize().y;
			else return 1024;
		}

		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number): void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			UpdateBitmapData();
		}

		protected function set imageDocument(imgd:ImageDocument): void {
			if (imgd != _imgd) {
				if (_imgd != null) {
					_imgd.removeEventListener(ImageDocumentEvent.BITMAPDATA_CHANGE, OnImageDataChange);
				}
				_imgd = imgd;
				if (imgd != null) {
					imgd.addEventListener(ImageDocumentEvent.BITMAPDATA_CHANGE, OnImageDataChange);
				}
				dispatchEvent(new Event("changeImage"));
			}
		}

		private var _fUpdatingBitmapData:Boolean = false;

		protected function OnImageDataChange(evt:GenericDocumentEvent): void {
			if (_fUpdatingBitmapData)
				return;

			var fChanged:Boolean = false;
			if (evt.obNew != evt.obOld) {
				var bmdNew:BitmapData = evt.obNew as BitmapData;
				var bmdOld:BitmapData = evt.obOld as BitmapData;
				if (!bmdNew || !bmdOld) {
					fChanged = true;
				} else {
					// Neither are null. Now comare the sizes.
					try {
						fChanged = ((bmdNew.width != bmdOld.width) || (bmdNew.height != bmdOld.height));
					} catch (e:Error) {
						// If we can't look at the old one, assume it changed.
						fChanged = true;
					}
				}
			}
			if (fChanged) dispatchEvent(new Event("changeImage"));
		}

		protected function UpdateBitmapData(): void {
			if (s_obDebugger != null) {
				if (_imgd != null && operation != null)
					s_obDebugger['RequestToUpdate'](_imgd, operation);
			} else {
				DoUpdateBitmapData();
			}
		}
		
		private function DoUpdateBitmapData(): void {
			import flash.utils.getTimer;
			
			try {
				if (!_fUpdatingBitmapData && _imgd != null && operation != null && !_fSelectEffectPlaying && !_efDeselect.isPlaying) {
					_fUpdatingBitmapData = true;
					
					// An UndoTransaction may already be open for two reasons:
					// 1. This effect began it (see further down in this function)
					// 2. When transitioning from effect to effect the prior effect's
					//    UndoTransaction is left open for the new one to close immediately
					//    before beginning its own UndoTransaction. This way there is no in-
					//    between time where the original (neither effect) document state
					//    will be shown. That would be visually ugly.
					//    TODO(darrinm): However, code-wise this interdependency is also ugly.
					//    Ideally the view could be gracefully decoupled from the document
					//    and could hold the prior effect's result until the new one's result
					//    was available, possibly even transitioning between the two.
					
					// Handle case #2
					CleanupPriorEffect();
					
					// Handle case #1
					if (_imgd.undoTransactionPending)
						_imgd.EndUndoTransaction(false, false); // rollback, don't clear cache
					
					 var nStart:Number = getTimer();
					
					// BST: 11/12/09: Make sure we don't retain the background of an operation
					// that does not modify the background (i.e. an object operation)
					// Otherwise, we will create an undo transaction which "owns" the background.
					// If you apply two of these, then undo, then apply something else, the
					// history item getting popped off will dispose its background which happens
					// to still be in use. Zoiks!
					var fRetainBackground:Boolean = !(operation is ObjectOperation);
					var strName:String = tags ? name + ":" + tags : name;
					_imgd.BeginUndoTransaction(strName, true, fRetainBackground); // fCacheInUse == true
					
					 // Use caching - the final EndUndoTransaction will clear it
					if (!(operation as ImageOperation).Do(_imgd, true, true)) // fUseCache == true
						_imgd.AbortUndoTransaction();
					
					// Remember that we've altered this document so we can clean it up at Revert/Apply time.
					_imgdCleanup = _imgd;
					
					dispatchEvent(new NestedControlEvent(NestedControlEvent.SELECTED_EFFECT_UPDATED_BITMAPDATA, this));
					updateSpeed = getTimer() - nStart;
					_fUpdatingBitmapData = false;
				}
			} catch (e:InvalidBitmapError) {	
				PicnikBase.app.OnMemoryError();		
			}
		}
		
		// Clear the bitmap cache and start the operation anew
		protected function ResetOperation(): void {
			_imgd.EndUndoTransaction(false, true);
			UpdateBitmapData();
		}

		protected function UpdateZoomviewForSelected(fSelected:Boolean): void {
			if (fSelected) {
				_imgv.FilterSelection(ImageView.kNoSelection);
			} else {
				_imgv.FilterSelection(ImageView.kFreeSelection);
			}
		}
		
		static private function ShowRequiresNewerFlashPlayerDialog(strReason:String): void {
			var fnOnDialogResult:Function = function (obResult:Object): void {
				if (obResult.success)
					Navigation.NavigateToFlashUpgrade(strReason);							
			}
			
			var dlg:EasyDialogBase = EasyDialogBase.Show(PicnikBase.app,
					[Resource.getString("StorageServiceInBridgeBase", "upgrade"),
						Resource.getString("StorageServiceInBridgeBase", "cancel")],
					Resource.getString("StorageServiceInBridgeBase", "effect_requires_flash_player_10"),						
					Resource.getString("StorageServiceInBridgeBase", "requires_new_flash_player_message"),
					fnOnDialogResult);
		}

		// Differentiate between the same effect in multiple places
	    override public function get className():String {
	    	return _strClassNamePrefix + super.className;
	    }

		public override function Select(efcnvCleanup:NestedControlCanvasBase): Boolean {
			InspirationTipBase.HideTip(false); // Hide instantly for slow effects.
			InspirationTipBase.SetDelayMode(InspirationTipBase.LONG_DELAY);
			if (flash10 && !Util.DoesUserHaveGoodFlashPlayer10()) {
				ShowRequiresNewerFlashPlayerDialog("/effect/" + className);
				return false;
			}
			if (!IsSelected()) {
				_imgv = PicnikBase.app.zoomView._imgv;
				UpdateZoomviewForSelected(true);
				imageDocument = _imgv.imageDocument;
			}
	
			return super.Select(efcnvCleanup);
		}

		public override function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null): void {
			if (IsSelected()) {
				if (!efcvsNew) {
					UpdateZoomviewForSelected(false);
				}
				_imgv = null;
				imageDocument = null;
			}
			super.Deselect(fForceRollOutEffect, efcvsNew);
			if ((operation as ImageOperation) != null && ImageOperation(operation).opEngine != null)
				ImageOperation(operation).opEngine.Clear();
		}		

		public override function Revert(): void {
			// Undo the effect
			if (_imgdCleanup) {
				_imgdCleanup.EndUndoTransaction(false, true); // rollback, clear cache
				_imgdCleanup = null;
			}
			super.Revert();
		}
		
		public override function Apply(): void {
			Util.UrchinLogReport("/effect_applied/" + className);
			
			if (_imgdCleanup) {
				_imgdCleanup.EndUndoTransaction(true, true); // commit, clear cache
				_imgdCleanup = null;
			}
			
			super.Apply();
		}
	}
}
import flash.display.DisplayObject;
import flash.geom.Point;
import flash.geom.Rectangle;

import mx.core.UIComponent;

class InspirationTarget extends UIComponent {
	public override function getRect(targetCoordinateSpace:DisplayObject):Rectangle {
		var rc:Rectangle = super.getRect(targetCoordinateSpace);
		// For some reason, our uicomponent width and height are correct but $width and $hieght are zero which means we need to calculate our bounds manuall.
		if (rc.width == 0) {
			var ptUpperLeft:Point = targetCoordinateSpace.globalToLocal(this.localToGlobal(new Point(0, 0)));
			var ptLowerRight:Point = targetCoordinateSpace.globalToLocal(this.localToGlobal(new Point(width, height)));
			rc = new Rectangle(ptUpperLeft.x, ptUpperLeft.y, ptLowerRight.x - ptUpperLeft.x, ptLowerRight.y - ptUpperLeft.y);
		}
		return rc;
	}
}
