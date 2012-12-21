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
// The Target DocumentObject
// - accepts a child object
// - sizes/positions the child to fill the target
// - crops the child

package documentObjects {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class Target extends DocumentObjectBase {
		public static const kcFreePhotoLimit:int = 5;

		[Embed(source="/assets/bitmaps/drop_arrow.png")]
		private static var s_clsDropArrow:Class;
		private static var s_bmdDropArrow:BitmapData = null;
		
		private var _nContentXOffsetPercent:Number = 0; // values in the range of +/- 50
		private var _nContentYOffsetPercent:Number = 0; // values in the range of +/- 50
		private var _fCrop:Boolean = false;
		
		private var _fCircular:Boolean = false;
		
		private var _fDrawPlaceholder:Boolean = false;
		override public function get typeName(): String {
			return "Target";
		}
		
		[Bindable]
		public function set drawPlaceholder(f:Boolean): void {
			_fDrawPlaceholder = f;
			Invalidate();
		}
		
		public function get drawPlaceholder(): Boolean {
			return _fDrawPlaceholder;
		}
		
		public function get populated(): Boolean {
			var nMasks:Number = (getChildByName("$cropMask") == null) ? 0 : 1;
			return (content != null) && (numChildren > nMasks); // more children than masks
		}
		
		public override function get serializableProperties(): Array {
			return super.serializableProperties.concat(["crop", "contentXOffsetPercent",
				"contentYOffsetPercent", "circular", "drawPlaceholder"
//				"unscaledWidth", "unscaledHeight"
			]);
		}

		override public function hitTestPoint(x:Number, y:Number, fPixelTest:Boolean=false): Boolean {
			var fHit:Boolean = super.hitTestPoint(x, y, fPixelTest);
			if (!fHit) return fHit;
			if (fPixelTest) return fHit;
			if (!circular) return fHit;

			var ptp:Point = parent.globalToLocal(new Point(x, y));
			var mat:Matrix = new Matrix();
			mat.translate(-this.x, -this.y);
			mat.rotate(-rotation * Math.PI / 180);
			var ptl:Point = mat.transformPoint(ptp);
			
			// We scored a hit and this is not a pixel test
			// If we are circular, do a circular test.
			// Calculate radial distance from the center of the rectangle (e.g. a distance of 1 is one radius)
			var nRadialXDist:Number = (_rcBounds.x + _rcBounds.width / 2 - ptl.x) / (_rcBounds.width/2);
			var nRadialYDist:Number = (_rcBounds.y + _rcBounds.height / 2 - ptl.y) / (_rcBounds.height/2);
			var nRadialDistSquared:Number = nRadialXDist * nRadialXDist + nRadialYDist * nRadialYDist;
			fHit = nRadialDistSquared <= 1;
			return fHit;
		}
		
		[Bindable]
		public function get circular(): Boolean {
			return _fCircular;
		}
		
		public function set circular(f:Boolean): void {
			if (_fCircular == f) return;
			_fCircular = f;
			var dobCrop:DisplayObject = getChildByName("$cropMask");
			if (dobCrop) {
				removeChild(dobCrop);
			}
			CreateMask();

			Invalidate();
		}
		
		private function CreateMask(): void {
			var dobCrop:DisplayObject;
			if (_fCircular) {
				dobCrop = new Circle();
			} else {
				dobCrop = new PRectangle();
			}
			dobCrop.name = "$cropMask";
			addChildAt(dobCrop, 0); // Mask is always at index 0!
			mask = dobCrop;
		}
		
		public function get hasFixedAspectRatio(): Boolean {
			return circular;
		}
		
		override public function get content(): DisplayObject {
			if (numChildren <= 1)
				return null;
			return getChildAt(1);
		}
		
		// DEPRECATED: but documents exist with targetWidth/Height properties (in-house histories only)
		public function set targetWidth(cx:Number): void {}
		public function set targetHeight(cy:Number): void {}
		
		[Bindable]
		public function set contentXOffsetPercent(nXOffsetPercent:Number): void {
			if (_nContentXOffsetPercent == nXOffsetPercent)
				return;
			_nContentXOffsetPercent = nXOffsetPercent;
			
			// Optimize out the expensive redraw-causing invalidate if no real change has occured
			if (content != null) {
				var obRet:Object = CalcContentOffsetAndScale();
				if (obRet.dx != content.x)
					Invalidate();
			}
		}
		
		public function get contentXOffsetPercent(): Number {
			return _nContentXOffsetPercent;
		}

		[Bindable]
		public function set contentYOffsetPercent(nYOffsetPercent:Number): void {
			if (_nContentYOffsetPercent == nYOffsetPercent)
				return;
			_nContentYOffsetPercent = nYOffsetPercent;

			// Optimize out the expensive redraw-causing invalidate if no real change has occured
			if (content != null) {
				var obRet:Object = CalcContentOffsetAndScale();
				if (obRet.dy != content.y)
					Invalidate();
			}
		}
		
		public function get contentYOffsetPercent(): Number {
			return _nContentYOffsetPercent;
		}

		[Bindable]
		public function set crop(fCrop:Boolean): void {
			_fCrop = fCrop;
			Invalidate();
		}

		public function get crop(): Boolean {
			return _fCrop;
		}
		
		// Hide/show the child object so any StatusViewObjects associated with it will be
		// notified to hide/show themselves too.
		override public function set visible(fVisible:Boolean): void {
			super.visible = fVisible;
			if (populated)
				content.visible = fVisible;
		}
		
		private static function get arrowBitmapData(): BitmapData {
			if (s_bmdDropArrow == null) {
				var bm:Bitmap = new s_clsDropArrow();
				var bmdSource:BitmapData = bm.bitmapData;

				s_bmdDropArrow = bmdSource.clone();
				// s_bmdDropArrow.colorTransform(s_bmdNormalArrow.rect, new ColorTransform(1,1,1,knNormalArrowAlpha));
			}
			return s_bmdDropArrow;
		}
		
		// CONSIDER: This is essentially updateDisplayList -- why create something new?
		override protected function Redraw(): void {
			// Update the cropping rectangle if needed
			var dobCrop:DisplayObject = getChildByName("$cropMask");
			if (dobCrop != null) {
				if (!_fCrop) {
					mask = null;
					removeChild(dobCrop);
				}
			} else if (_fCrop) {
				CreateMask();
			}
			graphics.clear();
			
			// Layout the child DocumentObject (if any) to fill the Target
			if (populated) {
				var obRet:Object = CalcContentOffsetAndScale();
				
				// Apply content offsets to the child DocumentObject
				var dobChild:DisplayObject = content;
				dobChild.x = obRet.dx;
				dobChild.y = obRet.dy;
				
				// Apply scaling factors to the child DocumentObject
				dobChild.scaleX = obRet.nScaleX;
				dobChild.scaleY = obRet.nScaleY;
			} else if (drawPlaceholder) {
				var gr:Graphics = graphics;
				gr.beginFill(color);
				var rcTarget:Rectangle = new Rectangle(-unscaledWidth/2, -unscaledHeight/2, unscaledWidth, unscaledHeight);  
				gr.drawRect(rcTarget.x, rcTarget.y, rcTarget.width, rcTarget.height);
				gr.endFill();

				var rcArrow:Rectangle = arrowBitmapData.rect;
				rcArrow.offset(-rcArrow.width/2, -rcArrow.height/2);
				
				var matArrow:Matrix = new Matrix();
				matArrow.translate(rcArrow.x, rcArrow.y);
				
				gr.beginBitmapFill(arrowBitmapData, matArrow, true, true);
				// gr.beginFill(0xff0000, 1);
				gr.drawRect(rcArrow.x, rcArrow.y, rcArrow.width, rcArrow.height);
				gr.endFill();
			}
		}
		
		private function CalcContentOffsetAndScale(): Object {
			return { dx: 0, dy: 0, nScaleX: 1.0, nScaleY: 1.0 };
		}

		public static function GetPopulatedTargetCount(dobc:DisplayObjectContainer): int {
			var cPopulatedTargets:int = 0;
			
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var dob:DisplayObject = dobc.getChildAt(i);
				if (dob is Target) {
					var tgt:Target = Target(dob);
					if (tgt.populated)
						cPopulatedTargets++;
				}
				
				// Recurse to find all Targets
				if (dob is DisplayObjectContainer)
					cPopulatedTargets += GetPopulatedTargetCount(DisplayObjectContainer(dob));
			}
			
			return cPopulatedTargets;
		}
		
		static public function MoveOrSwapTargetContents(tgtSource:Target, tgtDest:Target): void {
		}
		
		public function DestroyContents(): void {
		}
								
		public function ResetContentOffsets(): void {
		}
	}
}
