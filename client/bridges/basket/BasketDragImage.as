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
package bridges.basket
{
	import controls.thumbnails.Thumbnail;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import imagine.ImageDocument;
	import imagine.documentObjects.Photo;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.controls.Image;
	import mx.core.Application;
	import mx.effects.AnimateProperty;
	import mx.effects.easing.Cubic;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	import mx.managers.dragClasses.DragProxy;
	
	import util.IAssetSource;
	import util.IDragImage;
	import util.ImagePropertiesUtil;
	import util.PhotoBasketVisibility;
	
	public class BasketDragImage extends Image implements IDragImage
	{
		public function BasketDragImage()
		{
			addEventListener(Event.COMPLETE, OnThumbnailLoaded);
			addEventListener(Event.ADDED, OnAdded);
			super();
		}
		
		private var _effZoom:AnimateProperty = null;
		private var _nZoom:Number = 1;
		protected var _ptZoomScale:Point = null;
		private var _nOriginalMouseOffset:Number = 0;
		
		private var _rcThumbnailRelativePos:Rectangle = null;
		
		private var _ptParentOffset:Point = null;

		private var _fnGetDropScale:Function = null;
		
		private var _itemInfo:ItemInfo = null;

		private var _dpParent:DragProxy;
		private var _obParentVars:Object;
		private var _itemInfoPending:ItemInfo = null;
		
		public function get createType(): String {
			return "Photo";
		}
		
		public function DoAdd(imgd:ImageDocument, ptTargetSize:Point, imgvTarget:ImageView, nSnapLogic:Number, nViewZoom:Number, strParentId:String=null): DisplayObject {
			var ptd:Point;
			
			if (imgvTarget) {
				ptd = localToGlobal(new Point(0,0)); // top left, global coords
				ptd = imgvTarget.globalToLocal(ptd); // top left, imgv local cords
				ptd = imgvTarget.PtdFromPtl(ptd); // top left, doc coords
				ptd.offset(ptTargetSize.x/2, ptTargetSize.y/2);
			} else {
				ptd = new Point(0,0);
			}
			
			var asrc:IAssetSource = ImagePropertiesUtil.GetAssetSource(primaryItemInfo.asImageProperties());

			var dob:DisplayObject = Photo.Create(imgd, asrc, ptTargetSize, ptd, nSnapLogic, nViewZoom, strParentId);
			PhotoBasketVisibility.ReportDragDrop();
			
			return dob;
		}
		
		public function get isVector(): Boolean {
			return false;
		}
		
		public function get scaleWeight(): Number {
			return 1;
		}
		
		public function get groupScale(): Number {
			return 0;
		}
		
		public override function set owner(value:DisplayObjectContainer):void {
			super.owner = value;
			if (owner is IEventDispatcher) {
				IEventDispatcher(owner).addEventListener(DragEvent.DRAG_COMPLETE, OnDragComplete);
				IEventDispatcher(owner).addEventListener(DragEvent.DRAG_ENTER, UpdateProxyOffsets);
			}
		}
		
		private function OnAdded(evt:Event): void {
			// We now have a parent proxy
			parentProxy = parent as DragProxy;
			// parentProxy.dragSource.addData(this, "dragImage");
			UpdateDragSourceItemInfo();
		}
		
		public function get aspectRatio(): Number {
			if (_ptZoomScale)
				return _ptZoomScale.x / _ptZoomScale.y;
			else
				return 1;
		}
		
		public function get documentScale(): Number {
			return PicnikBase.app.zoomView.imageView.zoom;
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
		
		public function get primaryItemInfo(): ItemInfo {
			return _itemInfo;
		}

		protected function SetUpSource(thumb:Thumbnail, rcRelativePos:Rectangle): void {
			source = thumb.source;
			width = rcRelativePos.width;
			height = rcRelativePos.height;
		}
		
		public function setThumbnail(thumb:Thumbnail, rcRelativePos:Rectangle, obData:Object): void {
			_itemInfo = (obData is ImageProperties) ?
							ItemInfo.FromImageProperties(obData as ImageProperties)
							: (obData as ItemInfo);

			_rcThumbnailRelativePos = rcRelativePos;
			_ptZoomScale = rcRelativePos.size;
			SetUpSource(thumb, rcRelativePos);
			x += rcRelativePos.x;
			y += rcRelativePos.y;
			_ptParentOffset = new Point(_ptZoomScale.x * .35 + rcRelativePos.x, _ptZoomScale.y * .35 + rcRelativePos.y);
		}
		
		public function set getDropScaleFunction(fn:Function): void {
			if (_fnGetDropScale != fn) {
				_fnGetDropScale = fn;
				AnimateZoom(GetScaledDropSize());
			}
		}
		
		private function GetScaledDropSize(): Point {
			if (_fnGetDropScale == null) return _ptZoomScale;
			var nDocScale:Number = documentScale;
			if (isNaN(nDocScale))
				nDocScale = 1;
			var ptDocSize:Point = _fnGetDropScale(aspectRatio, scaleWeight);
			return new Point(ptDocSize.x * nDocScale, ptDocSize.y * nDocScale);
		}

		private function UpdateDragSourceItemInfo(): void {
			if (parentProxy && _itemInfoPending) {
				_itemInfo = _itemInfoPending;
				_itemInfoPending = null;
			}
		}
		
		//----------------------------------------
		// END: Override these in sub-classes
		//----------------------------------------
		
		private function OnThumbnailLoaded(evt:Event): void {
			// Thumbnail loaded, now what? Might be a good time to fire off a request for the original.
		}
		
		private function UpdateProxyOffsets(evt:Event=null): void {
			if (!parent || !_ptParentOffset || !owner || !_effZoom) return;
			IEventDispatcher(owner).removeEventListener(DragEvent.DRAG_ENTER, UpdateProxyOffsets);
			if ("startX" in parent) parent["startX"] += _ptParentOffset.x;
			if ("startY" in parent) parent["startY"] += _ptParentOffset.y;

			_ptParentOffset = null;
		}
		
		private function AnimateZoom(ptTargetDim:Point): void {
			if (!_effZoom) {
				_effZoom = new AnimateProperty(this);
				_effZoom.property = "zoom";
				_effZoom.easingFunction = Cubic.easeOut;
			}
			var nDuration:Number = Math.min(200, Math.abs(width - ptTargetDim.x));
			if (nDuration > 0) {
				if (ptTargetDim.x < width) {
					nDuration *= 3;
					_nOriginalMouseOffset = GetMouseOffset().length;
				}
				_effZoom.duration = nDuration;
				_effZoom.fromValue = zoom;
				_effZoom.toValue = zoom * ptTargetDim.x / width;
				_effZoom.play();
			}
			UpdateProxyOffsets();
		}
		
		// Returns mouse position relative to the center of the drag image.
		// Positive values represent a position below and to the right of center
		private function GetMouseOffset(): Point {
			var ptCenter:Point = localToGlobal(new Point(width/2, height/2)); // This center
			var stg:Stage = stage;
			if (stg == null) stg = Application.application.stage;
			var ptMouse:Point = new Point(stg.mouseX, stg.mouseY);
			return ptMouse.subtract(ptCenter);
		}

		public function set zoom(n:Number): void {
			if (_nZoom == n) return;
			_nZoom = n;

			var nNewWidth:Number = _ptZoomScale.x * n;
			var nNewHeight:Number = _ptZoomScale.y * n;
			
			var nPrevWidth:Number = width;
			var nPrevHeight:Number = height;
			
			width = nNewWidth;
			height = nNewHeight;

			if (_effZoom != null && _effZoom.fromValue > _effZoom.toValue) {
				// Zooming down. Center on the mouse.
				var nPctZoomed:Number = (n - _effZoom.fromValue) / (_effZoom.toValue - _effZoom.fromValue);
				var nMaxMouseOffset:Number = (1-nPctZoomed) * _nOriginalMouseOffset;

				var ptMouseOffset:Point = GetMouseOffset();
				if (ptMouseOffset.length > nMaxMouseOffset) {
					var nMovePct:Number = (ptMouseOffset.length - nMaxMouseOffset) / ptMouseOffset.length;
					x += ptMouseOffset.x * nMovePct;
					y += ptMouseOffset.y * nMovePct;
				}
			} else {
				var xDelta:Number = (nNewWidth - nPrevWidth) / 2;
				var yDelta:Number = (nNewHeight - nPrevHeight) / 2;

				x -= xDelta;
				y -= yDelta;
			}
		}
		
		public function get zoom(): Number {
			return _nZoom;
		}
	}
}