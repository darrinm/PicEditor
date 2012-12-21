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
package imagine.documentObjects {
	import controllers.DocoController;
	
	import errors.InvalidBitmapError;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.serialization.SerializationInfo;
	
	import mx.events.PropertyChangeEvent;
	
	import util.VBitmapData;
	
	[Bindable]
	[RemoteClass]
	public class DocumentObjectBase extends DocumentObjectContainer implements IDocumentObject {
		private var _clr:uint = 0; // Default color is black
		protected var _nScaleX:Number = 1.0, _nScaleY:Number = 1.0;
		protected var _rcBounds:Rectangle;
		private var _dobContent:DisplayObject;
		private var _cyUnscaled:Number = 100;
		private var _cxUnscaled:Number = 100;
		private var _nFractionLoaded:Number = 0;
		private var _strMaskId:String = null;
		private var _clsDococ:Class; // preferred controller, if any
		private var _fShowObjectPalette:Boolean = true;

		//
		// IDocumentObject interface
		//
		
		public function Dispose(): void {
			// This object was just removed from the document.
			// Override in sub-classes to clean up memory
			for (var i:Number = 0; i < numChildren; i++)
				if (getChildAt(i) is IDocumentObject)
					IDocumentObject(getChildAt(i)).Dispose();
		}
		
		public function set controller(clsDococ:Class): void {
			_clsDococ = clsDococ;
		}
		
		public function get controller(): Class {
			return _clsDococ;
		}
		
		public function FilterMenuItems(aobItems:Array):Array {
			return aobItems;
		}
		
		public function get isFixed(): Boolean {
			return false;
		}
		
		public function get showObjectPalette(): Boolean {
			return _fShowObjectPalette;
		}
		
		public function set showObjectPalette(f:Boolean): void {
			_fShowObjectPalette = f;
		}
		
		public function get content(): DisplayObject {
			return _dobContent;
		}
		
		public function get typeSubTab(): String {
			return "_ctShape"; // Default is shape
		}
		
		public function get objectPaletteName(): String {
			return "Shape"; // Default is shape
		}
		
		public function set content(dobContent:DisplayObject): void {
			SetContent(dobContent);
		}
		
		protected function SetContent(dobContent:DisplayObject, fInvalidate:Boolean=true): void {
			if (dobContent is Bitmap)
				Debug.Assert(dobContent.width > 0 && dobContent.height > 0);
			if (_dobContent != dobContent) {
				if (_dobContent != null) removeChild(_dobContent);
				_dobContent = dobContent;
				if (_dobContent != null) {
					addChild(_dobContent);
					SizeNewContent(_dobContent);
				}
				if (fInvalidate)
					Invalidate();
			}
		}
		
		protected function SizeNewContent(dobContent:DisplayObject): void {
			return; // Do nothing. Override in sub classes for custom behavior
		}
		
		// Override this in child classes
		public function get serializableProperties(): Array {
			return [ "x", "y", "alpha", "rotation", "name", "scaleX", "scaleY", "color", "blendMode", "maskId", "visible"
					/* , "rotationX", "rotationY" */ ]; // UNDONE: 3D objects
		}
		
		private var _srzInfo:SerializationInfo = null;
		
		private function get serializationInfo():SerializationInfo {
			if (_srzInfo == null)
				_srzInfo = new SerializationInfo(serializableProperties);
			return _srzInfo;
		}
		
		public function writeExternal(output:IDataOutput):void {
			output.writeObject(serializationInfo.GetSerializationValues(this));
		}
		
		public function readExternal(input:IDataInput):void {
			serializationInfo.SetSerializationValues(input.readObject(), this);
		}

		override public function Validate(): void {		
			// Some objects are dependent on their children so make sure they're valid.
			super.Validate();
			
			if (_ffInvalid) {
				_ffInvalid = 0;
				UpdateTransform();
				Redraw();
			
				// Some objects alter their children (e.g. layout) when they validate
				// so the children may be invalid again.
				super.Validate();
			}
		}
		
		public function GetProperty(strProp:String): * {
			return this[strProp];
		}
		
		// Override to change redraw behavior
		protected function Redraw(): void {
			// Default is do nothing
		}

		// The scaled, un-rotated bounds of the DocumentObject, in origin-relative coordinates
		public function get localRect(): Rectangle {
			if (status < DocumentStatus.Preview) {
				var cx:Number = unscaledWidth * _nScaleX;
				var cy:Number = unscaledHeight * _nScaleY;
				return new Rectangle(-cx / 2, -cy / 2, cx, cy);	
			}
			return _rcBounds.clone();
		}
		
		public function set localRect(rc:Rectangle): void {
			scaleX = (scaleX < 0 ? -1 : 1) * rc.width / unscaledWidth;
			scaleY = (scaleY < 0 ? -1 : 1) * rc.height / unscaledHeight;
			Invalidate();
		}

		// Override this in child classes
		public function get typeName(): String {
			return "Shape";
		}
		
		public function set fractionLoaded(nFraction:Number): void {
			_nFractionLoaded = nFraction;
		}
		
		public function get fractionLoaded(): Number {
			return _nFractionLoaded;
		}
		
		//
		//
		//
		
		public function DocumentObjectBase() {
			super();
			_rcBounds = new Rectangle();
			name = Util.GetUniqueId();
		}
		
		// We override these to make them bindable (send PropertyChangeEvents).
		// They must send PropertyChangeEvents so the ImageDocument can monitor them.
		
		override public function set x(x:Number): void {
			super.x = x;
			Invalidate();
		}
		
		override public function set y(y:Number): void {
			super.y = y;
			Invalidate();
		}
		
		override public function get alpha(): Number {
			return super.alpha;
		}
		
		override public function set alpha(alpha:Number): void {
			super.alpha = alpha;
		}
		
		override public function set blendMode(str:String): void {
			super.blendMode = str;
		}
		
		override public function get blendMode(): String {
			return super.blendMode;
		}

		override public function set rotation(deg:Number): void {
			super.rotation = deg;
			Invalidate();
		}
		
		/* UNDONE: 3D objects
		override public function set rotationX(deg:Number): void {
			super.rotationX = deg;
			Invalidate();
		}
		
		override public function set rotationY(deg:Number): void {
			super.rotationY = deg;
			Invalidate();
		}
		*/
		
		public function set color(clr:uint): void {
			_clr = clr;
			// Override this in children to do something fun
		}
			
		public function get color(): uint {
			return _clr;
		}

		override public function get scaleX(): Number {
			return _nScaleX;
		}
		
		override public function set scaleX(n:Number): void {
			_nScaleX = n;
			Invalidate(); // because the scale affects the localRect bounds
		}
		
		override public function get scaleY(): Number {
			return _nScaleY;
		}
		
		override public function set scaleY(n:Number): void {
			_nScaleY = n;
			Invalidate(); // because the scale affects the localRect bounds
		}
		
		override public function get visible(): Boolean {
			return super.visible;
		}
		
		override public function set visible(fVisible:Boolean): void {
			super.visible = fVisible;
			Invalidate();
		}
		
		public function set maskId(strMaskId:String): void {
			_strMaskId = strMaskId;
			if (strMaskId == null) {
				mask = null;
			} else {
				var dobMask:DisplayObject = document.getChildByName(strMaskId);
				mask = dobMask;
			}
			Invalidate();
		}
		
		public function get maskId(): String {
			return _strMaskId;
		}
		
		public function set unscaledWidth(cx:Number): void {
			if (_cxUnscaled == cx) return;
			Debug.Assert(!isNaN(cx));
			_cxUnscaled = cx;
//			if (_dobContent) _dobContent.width = cx;
			Invalidate();
			if (parent is IDocumentObject)
				IDocumentObject(parent).Invalidate();
		}
		
		public function get unscaledWidth(): Number {
			return _cxUnscaled;
		}
		
		public function set unscaledHeight(cy:Number): void {
			if (_cyUnscaled == cy) return;
			Debug.Assert(!isNaN(cy));
			_cyUnscaled = cy;
//			if (_dobContent) _dobContent.height = cy;
			Invalidate();
			if (parent is IDocumentObject)
				IDocumentObject(parent).Invalidate();
		}
		
		public function get unscaledHeight(): Number {
			return _cyUnscaled;
		}

		// Set the unscaled size to 100x??? or ???x100 where ??? <= 100.
		// This is called when a SWF has completed loading. Photo overrides it so
		// no resizing occurs.
		protected function SetUnscaledSize(cx:Number, cy:Number): void {
			unscaledWidth = 100 * cx / Math.max(cx, cy);
			unscaledHeight = 100 * cy / Math.max(cx, cy);
		}
		
		// Override this if needed (cx/y unscaledHeight/Width might be enough)
		protected function UpdateTransform(): void {
			// The DocumentObject's bounds are defined by its scaled width and height,
			// centered around its origin.
			var cx:Number = Math.abs(unscaledWidth * _nScaleX);
			var cy:Number = Math.abs(unscaledHeight * _nScaleY);
			
			var rcBoundsNew:Rectangle = new Rectangle(-(cx / 2), -(cy / 2), cx, cy);
			if (!rcBoundsNew.equals(_rcBounds)) {
				var rcBoundsOld:Rectangle = _rcBounds.clone();
				_rcBounds = rcBoundsNew;
				dispatchEvent(PropertyChangeEvent.createUpdateEvent(
						this, "localRect", _rcBounds.clone(), rcBoundsNew.clone()));
			}
			
			// We assume that content DisplayObjects have 0,0 as their upper-left origin
			if (_dobContent) {
				var dx:Number = Math.round(unscaledWidth / 2);
				var dy:Number = Math.round(unscaledHeight / 2);
				_dobContent.x = -dx;
				_dobContent.y = -dy;
			}
			
			super.scaleX = _nScaleX;
			super.scaleY = _nScaleY;
		}

		// UNDONE: This code is copied from Text but most DisplayObjects don't have the same
		// hit-testing issues so we can probably prune it WAY down.
		// Flash TextFields can't do pixel-level hit testing but that's what need so we
		// do it ourselves. NOTE: x, y are in Stage-relative coordinates
		override public function hitTestPoint(x:Number, y:Number, fPixelTest:Boolean=false): Boolean {
//			if (status < DocumentStatus.Preview ) return false;
			Validate();
			
			// Transform the stage coord into a local coord. Can't use this.globalToLocal because it
			// will take scaling into account.
			var ptp:Point = parent.globalToLocal(new Point(x, y));
			var mat:Matrix = new Matrix();
			mat.translate(-this.x, -this.y);
			mat.rotate(Util.RadFromDeg(-rotation));
			var ptl:Point = mat.transformPoint(ptp);
			
			// Do a bounding box test
			var fHit:Boolean = _rcBounds.containsPoint(ptl);
			if (!fPixelTest || !fHit)
				return fHit;
			
			// It's up to us to check the pixels. Draw the TextField into a single-pixel BitmapData,
			// offset so the point we want to test ends up being drawn as the single pixel.
			// Hopefully Flash's rendering optimizes clipped drawing well and this is fast.
			var bmd:BitmapData = null;
			
			try {
				bmd = new VBitmapData(1, 1, true, 0x000000ff, "hit test temp");
			} catch (e:InvalidBitmapError) {
				return false;
			}
			
			// Get a translated/scaled/rotated point to match what bmd.draw() will do below
			ptl = globalToLocal(new Point(x, y));
			mat = new Matrix();
			mat.tx = -ptl.x;
			mat.ty = -ptl.y;
			
			// Speed things up and eliminate undesired side effects by turning off filters
			// before drawing the TextField into the BitmapData
			var afltSav:Array = filters;
			filters = null; // clear out filters
			
			// Disregard transparency
			var nAlphaSav:Number = alpha;
			alpha = 1.0;
			
			bmd.draw(this, mat);
			
			// Restore all the stuff we had to tweak to make the hit testing work
			alpha = nAlphaSav;
			filters = afltSav;

			fHit = (bmd.getPixel32(0, 0) & 0xff000000) != 0; // Not transparent?
			bmd.dispose();
			
			return fHit;
		}
	}
}
