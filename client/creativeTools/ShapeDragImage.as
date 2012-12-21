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
package creativeTools
{
	import controls.UIDocumentObjectBase;
	
	import imagine.documentObjects.PShape;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.geom.Point;
	
	import imagine.ImageDocument;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.controls.Image;
	import mx.effects.AnimateProperty;
	import mx.effects.easing.Cubic;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	import mx.managers.dragClasses.DragProxy;
	
	import util.IDragImage;

	public class ShapeDragImage extends Image implements IDragImage
	{
		// The original dimensions are the dimensions of the dropped object - use these for calculating drop size
		// the thumb dimensions are the dimensions we should start at (without a zoom)
		// the real thumb dimensions are the actual thumb dimensions. Set our image to this size, then zoom to the thumb dims.
		public function ShapeDragImage(ptOriginalDimensions:Point, ptThumbDimensions:Point, ptRealThumbDimensions:Point, uidocoParent:UIDocumentObjectBase)
		{
			super();

			_uidocoParent = uidocoParent;
			blendMode = uidocoParent.GetChildProperty("blendMode", BlendMode.NORMAL);

			width = ptRealThumbDimensions.x;
			height = ptRealThumbDimensions.y;
			
			_ptOriginalDimensions = ptOriginalDimensions;
			_ptThumbDimensions = ptThumbDimensions;
			
			_nZoomOffset = ((ptThumbDimensions.x / ptRealThumbDimensions.x) + (ptThumbDimensions.y / ptRealThumbDimensions.y)) / 2;
			scaleX = scaleY = _nZoomOffset;
		}
		
		private var _uidocoParent:UIDocumentObjectBase;
		
		private var _nZoomOffset:Number = 1;
		
		private var _ptThumbDimensions:Point;
		
		private var _effZoom:AnimateProperty = null;
		private var _nZoom:Number = 1;
		private var _ptOriginalDimensions:Point = null;
		
		private var _ptParentOffset:Point = null;

		private var _fnGetDropScale:Function = null;

		private var _dpParent:DragProxy;
		private var _obParentVars:Object;
		private var _dctItemInfoPending:Object = null;
		
		public override function set owner(value:DisplayObjectContainer):void {
			super.owner = value;
			if (owner is IEventDispatcher) {
				IEventDispatcher(owner).addEventListener(DragEvent.DRAG_COMPLETE, OnDragComplete);
				IEventDispatcher(owner).addEventListener(DragEvent.DRAG_ENTER, UpdateProxyOffsets);
			}
		}
				
		public function get createType(): String {
			return _uidocoParent.childType;
		}
		
		public function DoAdd(imgd:ImageDocument, ptTargetSize:Point, imgvTarget:ImageView, nSnapLogic:Number, nViewZoom:Number, strParentId:String=null): DisplayObject {
			var ptd:Point = localToGlobal(new Point(0,0)); // top left, global coords

			// UNDONE: Why are PShapes different? figure this out and fix this in a better way.
			if (!(_uidocoParent.childIsPShape))
				ptd.offset(width/2, height/2);
			
			ptd = imgvTarget.globalToLocal(ptd); // top left, imgv local cords
			ptd = imgvTarget.PtdFromPtl(ptd); // top left, doc coords
			
			return _uidocoParent.DoAdd(imgd, ptTargetSize.x / _ptOriginalDimensions.x, ptd);
		}
		
		public function get aspectRatio(): Number {
			return _ptOriginalDimensions.x / _ptOriginalDimensions.y;
		}
		
		public function get isVector(): Boolean {
			return true;
		}
		
		public function get documentScale(): Number {
			return PicnikBase.app.zoomView.imageView.zoom;
		}

		// Returns 0.0 if the DocumentObject in question has no groupScale		
		public function get groupScale(): Number {
			return _uidocoParent.GetChildProperty("groupScale", 0.0);
		}
		
		private function OnDragComplete(evt:DragEvent): void {
			if (evt.action != DragManager.NONE) {
				// Drag was accepted. Try to prevent zoom down
				_obParentVars = {};
				const kastrParentKeys:Array = ["width", "height", "x", "y", "scaleX", "scaleY"];
				if (parentProxy) {
					for each (var strKey:String in kastrParentKeys) {
						ChangeWatcher.watch(parentProxy, strKey, OnParentZoomDown);
						_obParentVars[strKey] = parentProxy[strKey];
					}
				}
			}
		}
		
		private function OnParentZoomDown(evt:Event): void {
			for (var strKey:String in _obParentVars) {
				parentProxy[strKey] = _obParentVars[strKey];
			}
		}
		
		public function get parentProxy(): DragProxy {
			return _dpParent;
		}
		
		public function set parentProxy(dp:DragProxy): void {
			_dpParent = dp;
		}
		
		public function set getDropScaleFunction(fn:Function): void {
			if (_fnGetDropScale != fn) {
				_fnGetDropScale = fn;
				if (_ptOriginalDimensions)
					AnimateZoom(GetScaledDropSize());				
			}
		}
		
		private function GetScaledDropSize(): Point {
			if (_fnGetDropScale == null) return _ptThumbDimensions;
			var nDocScale:Number = groupScale != 0.0 ? groupScale * documentScale : documentScale;
			var ptDim:Point = _fnGetDropScale(aspectRatio, scaleWeight, groupScale != 0.0);
			return new Point(ptDim.x * nDocScale, ptDim.y * nDocScale);
		}

		//----------------------------------------
		// END: Override these in sub-classes
		//----------------------------------------
		
		private function UpdateProxyOffsets(evt:Event=null): void {
			if (!parent || !_ptParentOffset || !owner || !_effZoom) return;
			IEventDispatcher(owner).removeEventListener(DragEvent.DRAG_ENTER, UpdateProxyOffsets);
			if ("startX" in parent) parent["startX"] += _ptParentOffset.x;
			if ("startY" in parent) parent["startY"] += _ptParentOffset.y;

			_ptParentOffset = null;
		}

		private function GetUnscaledDropOffset(): Point {
			// UNDONE: Why are PShapes different? figure this out and fix this in a better way.
			// See also UIDocumentObjectBase.GetDragImageOffset
			if (_uidocoParent.child is PShape) return new Point(0,0);
			
			var nScale:Number = Math.max(_ptOriginalDimensions.x / _ptThumbDimensions.x, _ptOriginalDimensions.y / _ptThumbDimensions.y);
			return new Point(_ptThumbDimensions.x * nScale / 2, _ptThumbDimensions.y * nScale / 2);
		}

		private function AnimateZoom(ptTargetDim:Point): void {
			if (!_effZoom) {
				_effZoom = new AnimateProperty(this);
				_effZoom.property = "zoom";
				_effZoom.easingFunction = Cubic.easeOut;
			}
			var nDuration:Number = Math.min(200, Math.abs(width - ptTargetDim.x));
			if (nDuration > 0) {
				_effZoom.duration = nDuration;
				_effZoom.fromValue = zoom;
				_effZoom.toValue = zoom * Math.max(ptTargetDim.x / width, ptTargetDim.y/height);
				_effZoom.play();
			}
			UpdateProxyOffsets();
		}

		public function get scaleWeight(): Number {
			return 0.2;
		}
		
		public function set zoom(n:Number): void {
			if (_nZoom == n) return;
			_nZoom = n;

			var nScale:Number = _nZoom * _nZoomOffset;

			var xOffset:Number = width * (nScale / scaleX - 1) / 2;
			var yOffset:Number = height * (nScale / scaleY - 1) / 2;
			
			//x -= xOffset;
			//y -= yOffset;
			
			x = -_ptThumbDimensions.x * (nScale - 1) / 2;
			y = -_ptThumbDimensions.y * (nScale - 1) / 2;
			
			scaleX = scaleY = nScale;
		}
		
		public function get zoom(): Number {
			return _nZoom;
		}
	}
}