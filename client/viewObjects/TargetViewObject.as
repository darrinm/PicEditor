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
package viewObjects {
	import bridges.basket.BasketDragImage;
	
	import controls.MouseFollowingPremiumNag;
	import controls.MouseFollowingPremiumNagBase;
	
	import imagine.documentObjects.DocumentObjectUtil;
	import imagine.documentObjects.DocumentStatus;
	import imagine.documentObjects.FitMethod;
	import imagine.documentObjects.IDocumentObject;
	import imagine.documentObjects.Target;
	
	import events.ViewDragEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import imagine.ImageDocument;
	
	import mx.core.DragSource;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	
	import imagine.objectOperations.DestroyObjectOperation;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import overlays.helpers.Cursor;
	
	import util.DashedLine;
	import util.IDragImage;
	import util.VBitmapData;

	public class TargetViewObject extends ViewObject {
		protected static const NORMAL:String = "normal";
		protected static const OVER:String = "over";
		protected static const ERROR:String = "error";

		private static const s_dctStyles:Object = {
			"normal": { color: 0xffffff, thickness: 2, blendMode: BlendMode.DIFFERENCE, dashon: 3, dashoff: 6, alpha: 0.6 },
			"over": { color: 0xffffff, thickness: 3, blendMode: BlendMode.DIFFERENCE, dashon: 100, dashoff: 0, alpha: 1.0 },
			"error": { color: 0xff2020, thickness: 4, blendMode: BlendMode.NORMAL, dashon: 100, dashoff: 0, alpha: 1.0 }
		}

		protected static const kcoOverBackground:uint = 0x305030;
		protected static const knOverBackgroundAlpha:Number = 0.7;
		
		private var _co:uint;
		private var _nThickness:int;
		private var _cxDropTarget:Number, _cyDropTarget:Number;
		protected var _strStyle:String;
//		private var _mnu:TargetMenu;
		private var _fDragDropEnabled:Boolean = true;
		
		private var _fMouseDown:Boolean;
		private var _xlMouseDown:Number;
		private var _ylMouseDown:Number;
		private var _nContentXOffsetPercentDown:Number;
		private var _nContentYOffsetPercentDown:Number;
		static private var s_evtMouseDown:MouseEvent;
		static private var s_fDropped:Boolean = false;
		
		public function TargetViewObject(imgv:ImageView, dob:DisplayObject) {
			super();
			_imgv = imgv;
			target = dob;
			style = NORMAL;
			addEventListener(ViewDragEvent.VIEW_DRAG_ENTER, OnDragEnter, false, 0, true);
			
			// OPT: add drag over, drag drop, drag exit inside OnDragEnter
			addEventListener(ViewDragEvent.VIEW_DRAG_OVER, OnDragOver, false, 0, true);
			addEventListener(ViewDragEvent.VIEW_DRAG_DROP, OnDragDrop, false, 0, true);
			addEventListener(ViewDragEvent.VIEW_DRAG_EXIT, OnDragExit, false, 0, true);
			
			addEventListener(MouseEvent.MOUSE_OVER, OnMouseOver, false, 0, true);
		}
		
		public override function set visible(value:Boolean):void {
			super.visible = value;
			InvalidateDisplayList();
			if (!visible) {
				x = -100000;
				y = -100000;
			}
		}
		
		protected override function get hide():Boolean {
			return !visible;
		}
		
		private var _nId:Number = -1;
		private static var _nNextId:Number = 0;
		override public function toString():String {
			if (_nId == -1) _nId = _nNextId++;
			return "[TargetViewObject " + _nId + ", " + visible + ", " + x + "]";
		}
		
		override public function UpdateDisplayList(): void {
			super.UpdateDisplayList();
			InitializeFromDisplayObjectState();
			var rcl:Rectangle = view.RcvFromRcd(docLocalRect);
			
			with (graphics) {
				clear();

				// Draw an alpha-zero hit area box
				lineStyle(0, 0, 0);
				beginFill(0xff00ff, 0.0);
				
				if (target && ("circular" in target) && target["circular"])
					drawEllipse(rcl.x, rcl.y, rcl.width, rcl.height);
				else
					drawRect(rcl.x, rcl.y, rcl.width, rcl.height);
				endFill();

				// Draw controller
				DrawController(graphics, rcl, _co, _nThickness, 1.0);
			}
		}

		protected function DrawController(gr:Graphics, rcl:Rectangle, co:Number, nThickness:Number, nAlpha:Number): void {
			if (targetPopulated && style == NORMAL && IDocumentObject(target).status != DocumentStatus.Error)
				return;
			
			rcl.inflate(-2, -2);
			var cxDashOn:int = s_dctStyles[_strStyle].dashon;
			var cxDashOff:int = s_dctStyles[_strStyle].dashoff;
			var nAlpha:Number = s_dctStyles[_strStyle].alpha;
			
			// var cxyCornerRadius:Number = Math.min(rcl.width / 10, rcl.height / 10);
			var dl:DashedLine = new DashedLine(this, cxDashOn, cxDashOff);
			dl.lineStyle(nThickness, co, nAlpha);
			if (target && ("circular" in target) && target["circular"] == true)
				dl.ellipse(rcl.left, rcl.top, rcl.width, rcl.height);
			else if (target && ("roundedPct" in target) && target["roundedPct"] != 0)
				dl.curvedBox(rcl.left, rcl.top, rcl.width, rcl.height, target["roundedPct"] * Math.min(rcl.width, rcl.height) / 2);
			else
				dl.curvedBox(rcl.left, rcl.top, rcl.width, rcl.height, 0);
		}
		
		private function set color(co:uint): void {
			_co = co;
			InvalidateDisplayList(true);
		}
		
		private function set thickness(nThickness:int): void {
			_nThickness = nThickness;
			InvalidateDisplayList(true);
		}
		
		protected function set style(strStyle:String): void {
			_strStyle = strStyle;
			color = s_dctStyles[_strStyle].color;
			thickness = s_dctStyles[_strStyle].thickness;
			blendMode = s_dctStyles[_strStyle].blendMode;
		}
		
		protected function get style(): String {
			return _strStyle;
		}
		
		protected function get targetPopulated(): Boolean {
			return Target(target).populated;
		}
		
		public function get dragDropEnabled(): Boolean {
			return _fDragDropEnabled;
		}
		
		public function set dragDropEnabled(f:Boolean): void {
			_fDragDropEnabled = f;
		}
		
		//
		// UI to manipulate the Target's contents (move, drag/drop)
		//
		
		protected function OnMouseOver(evt:MouseEvent): void {
			if (evt.target != this)
				return;
			
//			trace("Target mouseOver: " + evt.target + ", from: " + evt.relatedObject);
			
			if (!evt.buttonDown && targetPopulated) {
				addEventListener(MouseEvent.MOUSE_OUT, OnMouseOut);
				addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown, false, 10);
				
				// Show move cursor
				view.overlayCursor = Cursor.csrMove;
				
/*
				// Show menu
				if (_mnu == null || !_mnu.visible) {
					_mnu = new TargetMenu();
					_mnu.Show(this);
				}
*/
			}
		}
		
		protected function OnMouseOut(evt:MouseEvent): void {
			if (evt.target != this)
				return;
			
//			trace("Target mouseOut: " + evt.target + ", to: " + evt.relatedObject);
			removeEventListener(MouseEvent.MOUSE_OUT, OnMouseOut);
			removeEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			
			// Restore cursor
			if (!evt.buttonDown)
				view.overlayCursor = null;
			
/*
			// Hide menu unless the cursor has moved to it
			if (_mnu && evt.relatedObject != _mnu && !Util.IsChildOf(evt.relatedObject, _mnu)) {
				_mnu.Hide();
				_mnu = null;
			}
*/
		}
		
		protected function OnMouseDown(evt:MouseEvent): void {
			// We don't want anyone else acting on this down event
			evt.stopImmediatePropagation();
			
			_fMouseDown = true;
			stage.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp, false, 10);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove, false, 10);
			s_evtMouseDown = evt;
			
/*
			// Fade menu out if it is up
			if (_mnu) {
				_mnu.Hide();
				_mnu = null;
			}
*/			
			// Remember down location and content offset percentages
			_xlMouseDown = evt.localX / view.zoom;
			_ylMouseDown = evt.localY / view.zoom;
			_nContentXOffsetPercentDown = Target(target).contentXOffsetPercent;
			_nContentYOffsetPercentDown = Target(target).contentYOffsetPercent;
		}
		
		private var _uicDrag:UIComponent;
		
		private function GetDragImageSize(): Point {
			var tgt:Target = Target(target);
			var rc:Rectangle = _imgv.RcvFromRcd(tgt.localRect);
			return new Point(rc.width, rc.height);
		}
		
		private function OnDragImageRemoved(evt:Event): void {
			var uic:UIComponent = UIComponent(evt.target);
			uic.removeEventListener(Event.REMOVED_FROM_STAGE, OnDragImageRemoved);
			var bm:Bitmap = Bitmap(uic.getChildAt(0));
			uic.removeChildAt(0);
			bm.bitmapData.dispose();
		}
		
		private function GetDragImage(cx:Number, cy:Number): UIComponent {
			var tgt:Target = Target(target);
			var uic:UIComponent = new UIComponent();
			var bmd:BitmapData = new VBitmapData(cx, cy, true, 0, "TargetViewObject drag image");
			var mat:Matrix = new Matrix();
			mat.scale((cx / tgt.localRect.width) * tgt.scaleX, (cy / tgt.localRect.height) * tgt.scaleY);
			mat.translate(cx / 2, cy / 2);
			bmd.draw(tgt, mat);
			var bm:Bitmap = new Bitmap(bmd);
			uic.addChild(bm);
			
			// Listen for a remove event so we can dispose our extra bitmap
			uic.addEventListener(Event.REMOVED_FROM_STAGE, OnDragImageRemoved);
			return uic;
		}
		
		private function OnMouseMove(evt:MouseEvent): void {
			var tgt:Target = Target(target);
			
			var ptMouse:Point = globalToLocal(new Point(evt.stageX, evt.stageY));
			
			if (dragDropEnabled) {
				if (evt.target != this) {
					if (!DragManager.isDragging) {
						// If mouse has moved outside the source Target by more than 50 pixels
						// then we start drag/drop. This threshold is too large when tiles are
						// small so we also trigger drag when the mouse has moved more than 20%
						// outside the source.
						var ptImageSize:Point = GetDragImageSize();
						var cxThreshold:Number = Math.min((ptImageSize.x / 2) + 50, ptImageSize.x * (0.5 + 0.2));
						var cyThreshold:Number = Math.min((ptImageSize.y / 2) + 50, ptImageSize.y * (0.5 + 0.2));
						if (ptMouse.x < -cxThreshold || ptMouse.x > cxThreshold ||
								ptMouse.y < -cyThreshold || ptMouse.y > cyThreshold) {
							view.overlayCursor = null;
							
							// Restore content offsets to what they were when the button went down
							tgt.contentXOffsetPercent = _nContentXOffsetPercentDown;
							tgt.contentYOffsetPercent = _nContentYOffsetPercentDown;
							tgt.Validate();
							
							// start drag
					        var ds:DragSource = new DragSource();
					        ds.addData(this, "TargetViewObject");
					
							_uicDrag = new UIComponent();
							_imgv.addChild(_uicDrag);
							var uicImage:UIComponent = GetDragImage(ptImageSize.x, ptImageSize.y);
							var ptT:Point = new Point(-ptImageSize.x / 2, -ptImageSize.y / 2);
							var ptOffset:Point = _imgv.globalToLocal(localToGlobal(ptT));
		//					trace("evt.localX,Y: " + s_evtMouseDown.localX + "," + s_evtMouseDown.localY);
		//					trace("ptOffset.x,y: " + ptOffset.x + "," + ptOffset.y);
					        DragManager.doDrag(_uicDrag, ds, s_evtMouseDown, uicImage, -ptOffset.x, -ptOffset.y, 0.75, true);
					        _uicDrag.validateNow();
					   }
					}
				} else {
					if (DragManager.isDragging && _uicDrag) {
						view.overlayCursor = Cursor.csrMove;
						
						// abandon drag
						_imgv.removeChild(_uicDrag);
						_uicDrag = null;
	//					DragManager.endDrag(); // private!
					}
				}
				
				if (DragManager.isDragging)
					return;
			}
			
			// Calc delta between current and down location in object-local coordinates
			var dxl:Number = (ptMouse.x / view.zoom) - _xlMouseDown;
			var dyl:Number = (ptMouse.y / view.zoom) - _ylMouseDown;
			
			// What percent of the object's size does the delta represent?
			var doco:IDocumentObject = IDocumentObject(tgt.content);
			var ptScale:Point = DocumentObjectUtil.GetDocumentScale(doco);
			var cxContent:Number = (doco.unscaledWidth - 2) * ptScale.x;
			var cyContent:Number = (doco.unscaledHeight - 2) * ptScale.y;
			ptScale = DocumentObjectUtil.GetDocumentScale(tgt);
			var cxTarget:Number = tgt.unscaledWidth * ptScale.x;
			var cyTarget:Number = tgt.unscaledHeight * ptScale.y;
//			trace("dxl: " + dxl + ", dx%: " + (dxl / (cxContent - cxTarget) * 100) + ", cxContent: " + cxContent);
			
			// Move the Target's contents, while keeping it constrained to the Target
			var nXOffsetPercent:Number = _nContentXOffsetPercentDown - (dxl / (cxContent - cxTarget) * 100);
			if (nXOffsetPercent < -50)
				nXOffsetPercent = -50;
			else if (nXOffsetPercent > 50)
				nXOffsetPercent = 50;
			tgt.contentXOffsetPercent = nXOffsetPercent;
			
			var nYOffsetPercent:Number = _nContentYOffsetPercentDown - (dyl / (cyContent - cyTarget) * 100);
			if (nYOffsetPercent < -50)
				nYOffsetPercent = -50;
			else if (nYOffsetPercent > 50)
				nYOffsetPercent = 50;
			tgt.contentYOffsetPercent = nYOffsetPercent;
			
			// We don't want anyone else acting on this move event
			evt.stopImmediatePropagation();
		}
		
		protected function OnMouseUp(evt:MouseEvent): void {
			if (!_fMouseDown)
				return;
			s_evtMouseDown = null;
			
			// We don't want anyone else acting on this up event
			evt.stopImmediatePropagation();
			
			_fMouseDown = false;
			stage.removeEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			
			// UNDONE: Bring menu back if the mouse is over this TargetViewObject

			// Target dragging is modal and eats MOUSE_OVER events. After dragging we
			// must dispatch a MOUSE_OVER event to whatever the mouse is now over. This
			// is _almost_ enough to get the cursor updated but not quite. Hence we
			// clear it here and perhaps the MOUSE_OVER handler will change it too. 
			view.overlayCursor = null;
			evt.target.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
			
			if (!s_fDropped) {
				// If the target's content has changed then record it in the undo/redo-able way.
				var tgt:Target = Target(target);
				if (tgt.contentXOffsetPercent != _nContentXOffsetPercentDown ||
						tgt.contentYOffsetPercent != _nContentYOffsetPercentDown) {
					var dctProps:Object = {
						contentXOffsetPercent: tgt.contentXOffsetPercent,
						contentYOffsetPercent: tgt.contentYOffsetPercent
					}
					
					// Restore the original state so it can be recorded for undo
					tgt.contentXOffsetPercent = _nContentXOffsetPercentDown;
					tgt.contentYOffsetPercent = _nContentYOffsetPercentDown;
					
					var imgd:ImageDocument = tgt.document;
					imgd.BeginUndoTransaction("Reposition Photo", false, false);
					var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(tgt.name, dctProps);
					spop.Do(imgd);
					imgd.EndUndoTransaction();
				}
			}
		}
		
		//
		// Drag/Drop handling
		//
		
		private function OnDragEnter(evt:ViewDragEvent): void {
			s_fDropped = false;
			
			var dgimg:IDragImage = evt.dragSource.dataForFormat("dragImage") as IDragImage;
			if (dgimg != null) {
				// Don't let Shapes be dropped into a Target (someday...)
				if (!(dgimg is BasketDragImage))
					return;
			} else {
				var tvo:TargetViewObject = evt.dragSource.dataForFormat("TargetViewObject") as TargetViewObject;
				
				// Don't treat the drag source as a destination
				if (tvo == null || tvo == this) {
					DragManager.showFeedback(DragManager.NONE);
					return;
				}
			}
				
			// If dropping into this target would put the # of photos in the document over
			// the non-Premium limit, give the user feedback some indicating so and don't
			// allow dropping.
			if (tvo != null) {
				DragManager.showFeedback(DragManager.COPY); // UNDONE: should be MOVE?
				style = OVER;
				
			} else if (IsAtFreeLimit()) {
				DragManager.showFeedback(DragManager.NONE);
				
				// When DragManager is in feedback mode NONE it doesn't send a DRAG_DROP
				// event. We need to know when dragging is finished so we can clear out
				// the over appearance.
				evt.dragInitiator.addEventListener(DragEvent.DRAG_COMPLETE, OnDragComplete);
				style = ERROR;
				
				ShowPremiumNag();
			} else {
				DragManager.showFeedback(DragManager.COPY);
				style = OVER;
			}
			evt.AcceptDragDrop(this);
			evt.preventDefault();
		}
		
		private function OnDragExit(evt:ViewDragEvent): void {
			style = NORMAL;
			HidePremiumNag();
			DragManager.showFeedback(DragManager.NONE);
		}
		
		private function OnDragOver(evt:ViewDragEvent): void {
			var tvo:TargetViewObject = evt.dragSource.dataForFormat("TargetViewObject") as TargetViewObject;
			var strMode:String;
			if (tvo != null)
				strMode = DragManager.COPY;  // UNDONE: should be MOVE?
 			else
 				strMode = IsAtFreeLimit() ? DragManager.NONE : DragManager.COPY;
			DragManager.showFeedback(strMode);
		}
		
		private function OnDragDrop(evt:ViewDragEvent): void {
			s_fDropped = true;
			style = NORMAL;
			HidePremiumNag();
			
			var tgt:Target = Target(target);
			var imgd:ImageDocument = tgt.document;
			var spop:SetPropertiesObjectOperation;
			
			var tvoSource:TargetViewObject = evt.dragSource.dataForFormat("TargetViewObject") as TargetViewObject;
			if (tvoSource != null) {
				if (_uicDrag) {
					_imgv.removeChild(_uicDrag);
					_uicDrag = null;
				}
				
				imgd.BeginUndoTransaction(targetPopulated ? "Swap Photo" : "Move Photo", false, false);
				Target.MoveOrSwapTargetContents(Target(tvoSource.target), tgt);
				imgd.EndUndoTransaction();
			} else {
				// If the Target already has a child Photo, delete it
				if (targetPopulated) {
					var doop:DestroyObjectOperation = new DestroyObjectOperation(tgt.content.name);
					imgd.BeginUndoTransaction("Replace Photo", false, false);
					doop.Do(imgd);
				} else {
					imgd.BeginUndoTransaction("Create Photo", false, false);
				}
	
				var bdi:BasketDragImage = BasketDragImage(evt.dragSource.dataForFormat("dragImage"));
				bdi.DoAdd(imgd, new Point(100,100), null, FitMethod.SNAP_TO_MIN_WIDTH_HEIGHT, _imgv.zoom, target.name);

				tgt.ResetContentOffsets();				
				imgd.EndUndoTransaction();
			}
		}
		
		private function OnDragComplete(evt:DragEvent): void {
			evt.dragInitiator.removeEventListener(DragEvent.DRAG_COMPLETE, OnDragComplete);
			style = NORMAL;
			HidePremiumNag();
		}

		// Users hit the limit when they match ALL of the below criteria:
		// - they're not Premium
		// - they have already filled kcFreePhotoLimit (5) targets in the document
		// - they're not replacing an existing photo
		private function IsAtFreeLimit(): Boolean {
			// DWM: We now limit collages by what templates you can choose, not the total
			// number of photos you can place in them.
			return false;
			
			/*
			if (targetPopulated)
				return false;
				
			if (AccountMgr.GetInstance().isPremium)
				return false;
			
			var imgd:ImageDocument = _imgv.imageDocument;
			if (imgd) {
				var cPopulatedTargets:int = Target.GetPopulatedTargetCount(imgd.documentObjects);
				if (cPopulatedTargets >= Target.kcFreePhotoLimit)
					return true;
			}
			return false;
			*/
		}
		
		private var _mfn:MouseFollowingPremiumNag;
		
		private function ShowPremiumNag(): void {
			_mfn = MouseFollowingPremiumNagBase.Show();
		}
		
		private function HidePremiumNag(): void {
			if (_mfn == null)
				return;
			_mfn.Hide();
			_mfn = null;
		}
	}
}
