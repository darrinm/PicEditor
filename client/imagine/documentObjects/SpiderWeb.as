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
	import com.primitives.DrawUtils;
	
	import de.polygonal.math.PM_PRNG;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	[RemoteClass]
	public class SpiderWeb extends DocumentObjectBase {
		private var _coGlow:uint = 0xffffff;
		private var _nThickness:Number = 3;
		private var _nSeed:uint = 1;
		private var _cxyGlowBlur:uint = 10;
		private var _nGlowStrength:uint = 4;
		private var _cRadials:int = 10;
		private var _nSpacing:Number = 10;
		private var _nKookiness:Number = 0.5;
		private var _nDecay:Number = 0.0;
		private var _fDrawFrame:Boolean = false;
		private var _fHFlip:Boolean = false;
		private var _strStyle:String = "standard";

		override public function get typeName(): String {
			return "Spider Web";
		}
		
		override public function get serializableProperties(): Array {
			return super.serializableProperties.concat(["seed", "thickness", "radials", "spacing",
					"glowColor", "glowBlur", "glowStrength", "kookiness", "drawFrame", "hflip",
					"style", "decay", "unscaledWidth", "unscaledHeight"]);
		}
		
		override public function FilterMenuItems(aobItems:Array): Array {
			return [];
		}
		
		//
		// Spider web properties
		//
		
		override public function set color(co:uint): void {
			super.color = co;
			Invalidate();
		}
		
		public function get seed(): uint {
			return _nSeed;
		}
		
		public function set seed(n:uint): void {
			// DWM: go ahead and accept 0 because data-bound UIs have a hard time not passing it
			//			Debug.Assert(n != 0, "random seed cannot be 0!");
			if (n == 0)
				n = 1;
			_nSeed = n;
			Invalidate();
		}
		
		public function get thickness(): Number {
			return _nThickness;
		}
		
		public function set thickness(nThickness:Number): void {
			_nThickness = nThickness;
			Invalidate();
		}
		
		public function get radials(): uint {
			return _cRadials;
		}
		
		public function set radials(c:uint): void {
			_cRadials = c;
			Invalidate();
		}
		
		public function get glowColor(): uint {
			return _coGlow;
		}
		
		public function set glowColor(co:uint): void {
			_coGlow = co;
			Invalidate();
		}
		
		public function get glowBlur(): uint {
			return _cxyGlowBlur;
		}
		
		public function set glowBlur(cxy:uint): void {
			_cxyGlowBlur = cxy;
			Invalidate();
		}
		
		public function get glowStrength(): uint {
			return _nGlowStrength;
		}
		
		public function set glowStrength(n:uint): void {
			_nGlowStrength = n;
			Invalidate();
		}
		
		public function get spacing(): Number {
			return _nSpacing;
		}
		
		public function set spacing(n:Number): void {
			_nSpacing = n;
			Invalidate();
		}
		
		public function get kookiness(): Number {
			return _nKookiness;
		}
		
		// Range from 0-1
		public function set kookiness(n:Number): void {
			_nKookiness = n;
			Invalidate();
		}
		
		public function get decay(): Number {
			return _nDecay;
		}
		
		// Range from 0-1
		public function set decay(n:Number): void {
			_nDecay = n;
			Invalidate();
		}
		
		public function get drawFrame(): Boolean {
			return _fDrawFrame;
		}
		
		public function set drawFrame(f:Boolean): void {
			_fDrawFrame = f;
			Invalidate();
		}
		
		public function get hflip(): Boolean {
			return _fHFlip;
		}
		
		public function set hflip(f:Boolean): void {
			_fHFlip = f;
			Invalidate();
		}
		
		public function get style(): String {
			return _strStyle;
		}
		
		public function set style(strStyle:String): void {
			_strStyle = strStyle;
			Invalidate();
		}
		
		//
		//
		//
		
		override protected function Redraw(): void {
			// Create the spiderweb.
			var web:DisplayObject = CreateSpiderWeb(
					-unscaledWidth / 2, -unscaledHeight / 2, unscaledWidth, unscaledHeight, color, _nThickness, _nSeed,
					_cRadials, _nSpacing, _nKookiness, _nDecay, _fDrawFrame, _strStyle, _fHFlip);
			
			// Apply a glow filter to the DisplayObject.
			if (_cxyGlowBlur > 0 && _nGlowStrength > 0) {
				var fltGlow:GlowFilter = new GlowFilter();
				fltGlow.color = _coGlow;
				fltGlow.strength = _nGlowStrength;
				fltGlow.quality = 3;
				fltGlow.blurX = fltGlow.blurY = _cxyGlowBlur;
				web.filters = [ fltGlow ];
			}
			
			// TODO(darrinm): hack to eliminate extra redraw. Come up with a better way for all DisplayObjects.
			var ff:Number = _ffInvalid;
			content = web;
			_ffInvalid = ff;
		}
		
		// style: standard, corner
		private static function CreateSpiderWeb(x:Number, y:Number, cx:Number, cy:Number, co:uint=0xffffff,
				nThickness:Number=3.0, nSeed:uint=1, cRadials:int=10, nSpacing:Number=10,
	   			nKookiness:Number=0, nDecay:Number=0, fDrawFrame:Boolean=false,
				strStyle:String="standard", fHFlip:Boolean=false): DisplayObject {
			var rnd:PM_PRNG = new PM_PRNG();
			rnd.seed = nSeed * 16805;
			var shp:Shape = new Shape();
			
			if (fHFlip)
				shp.scaleX = -1;
			
			var gr:Graphics = shp.graphics;
			gr.lineStyle(nThickness, co);
			
			var rcBounds:Rectangle = new Rectangle(x, y, cx, cy);
			var ptCenter:Point;
			var nRadiusMax:Number;
			if (strStyle == "corner") {
				nRadiusMax = Math.min(cx, cy);
				ptCenter = new Point(x, y);
			} else {
				nRadiusMax = Math.min(cx / 2, cy / 2);
				ptCenter = new Point(rcBounds.x + rcBounds.width / 2, rcBounds.y + rcBounds.height / 2);
			}
			var cRadials:int = cRadials;
			var aptRadialEnds:Array = new Array(cRadials);
			var aradRadialAngles:Array = new Array(cRadials);
			var anRadialLength:Array = new Array(cRadials);
			var anSpiralRadius:Array = new Array(cRadials);
			var anSpiralSteps:Array = new Array(cRadials);
			var i:int;
			
			// Create an array of line segments the radials will radiate out to.
			var aaptBoundaryLines:Array = [];
			
			if (fDrawFrame) {
				// Randomly generate interesting frame lines.
				aaptBoundaryLines.push([ new Point(rcBounds.left, rnd.nextDoubleRange(rcBounds.top + rcBounds.height / 10, (rcBounds.top + rcBounds.bottom) / 2)),
						new Point(rnd.nextDoubleRange(rcBounds.left + rcBounds.width / 10, (rcBounds.left + rcBounds.right) / 2), rcBounds.top) ]);
				aaptBoundaryLines.push([ new Point(rnd.nextDoubleRange((rcBounds.left + rcBounds.right) / 2, rcBounds.right - rcBounds.width / 10), rcBounds.top),
						new Point(rcBounds.right, rnd.nextDoubleRange(rcBounds.top + rcBounds.height / 10, (rcBounds.top + rcBounds.bottom) / 2))]);
				aaptBoundaryLines.push([ new Point(rcBounds.left, rnd.nextDoubleRange((rcBounds.top + rcBounds.bottom) / 2, rcBounds.bottom - rcBounds.height / 10)),
						new Point(rnd.nextDoubleRange(rcBounds.left + rcBounds.width / 10, (rcBounds.left + rcBounds.right) / 2), rcBounds.bottom) ]);
				aaptBoundaryLines.push([ new Point(rnd.nextDoubleRange((rcBounds.left + rcBounds.right) / 2, rcBounds.right - rcBounds.width / 10), rcBounds.bottom),
						new Point(rcBounds.right, rnd.nextDoubleRange((rcBounds.top + rcBounds.bottom) / 2, rcBounds.bottom - rcBounds.height / 10))]);
				
				// Draw the frame lines
				for (i = 0; i < aaptBoundaryLines.length; i++) {
					var ptA:Point = aaptBoundaryLines[i][0];
					var ptB:Point = aaptBoundaryLines[i][1];
					gr.moveTo(ptA.x, ptA.y);
					gr.lineTo(ptB.x, ptB.y);
				}
			}
			
			// Finish a bounding box around the whole web
			if (strStyle != "corner") {			
				aaptBoundaryLines.push([ new Point(rcBounds.left, rcBounds.top), new Point(rcBounds.right, rcBounds.top) ]);
				aaptBoundaryLines.push([ new Point(rcBounds.left, rcBounds.bottom), new Point(rcBounds.left, rcBounds.top) ]);
			}
			aaptBoundaryLines.push([ new Point(rcBounds.right, rcBounds.top), new Point(rcBounds.right, rcBounds.bottom) ]);
			aaptBoundaryLines.push([ new Point(rcBounds.right, rcBounds.bottom), new Point(rcBounds.left, rcBounds.bottom) ]);

			var radRadialOffset:Number;
			var radSlice:Number;
			if (strStyle == "corner") {
				radSlice = Math.PI / 2 / (cRadials - 1);
				radRadialOffset = 0;
			} else {
				radSlice = Math.PI * 2 / cRadials;
				radRadialOffset = Math.PI * rnd.nextDouble();
			}
			
			for (i = 0; i < cRadials; i++) {
				var radRandomRadialOffset:Number;
				if (strStyle == "corner" && (i == 0 || i == cRadials - 1))
					radRandomRadialOffset = 0;
				else
					radRandomRadialOffset = radSlice * 2 * (rnd.nextDouble() - 0.5);
				aradRadialAngles[i] = (radSlice * i) + radRadialOffset + (radRandomRadialOffset * nKookiness);
				
				// Intersection of ray from center along radial angle and the bounds
				var ptDir:Point = new Point(ptCenter.x + Math.cos(aradRadialAngles[i]),
						ptCenter.y + Math.sin(aradRadialAngles[i]));
				for (var j:int = 0; j < aaptBoundaryLines.length; j++) {
					var ptRadialEnd:Point = Util.GetRaySegmentIntersection(ptCenter, ptDir,
							aaptBoundaryLines[j][0], aaptBoundaryLines[j][1]);
					if (ptRadialEnd != null) {
						aptRadialEnds[i] = ptRadialEnd;
						break;
					}
				}
				
				var dx:Number = aptRadialEnds[i].x - ptCenter.x;
				var dy:Number = aptRadialEnds[i].y - ptCenter.y;
				var nRadialLength:Number = Math.sqrt(dx * dx + dy * dy);
				
				if (!fDrawFrame) {
					if (nRadialLength > nRadiusMax) {
						nRadialLength = nRadiusMax;
						aptRadialEnds[i] = new Point(ptCenter.x + nRadialLength * Math.cos(aradRadialAngles[i]),
								ptCenter.y + nRadialLength * Math.sin(aradRadialAngles[i]));
					}
				}
				anRadialLength[i] = nRadialLength;
				
				// Draw a radial line
				gr.moveTo(ptCenter.x, ptCenter.y);
				gr.lineTo(aptRadialEnds[i].x, aptRadialEnds[i].y);
			}
			
			var nDir:int = 1;	// Start by spiraling clockwise
			var iRadial:int = 0;
			
			gr.moveTo(ptCenter.x, ptCenter.y);
			
			while (true) {
				var nSpiralSteps:int = anSpiralSteps[iRadial];
				if (nSpiralSteps == 0)
					nSpiralSteps = strStyle == "corner" ? 1 : 2;
				var nSpiralRadius:Number = nSpiralSteps * nSpacing;
				var radRadialAngle:Number = aradRadialAngles[iRadial];
				var nKookyOffset:Number = 2 * nSpacing * nKookiness * (rnd.nextDouble() - 0.5);
				
				// Dampen kookiness for inner radii
				nKookyOffset *= Math.min(1.0, nSpiralRadius / 500); // TODO(darrinm): should be nRadiusMax
				
				var nKookySpiralRadius:Number = nSpiralRadius + nKookyOffset + nSpacing * (iRadial / cRadials);
				if (nKookySpiralRadius > anRadialLength[iRadial])
					break;
				anSpiralRadius[iRadial] = nKookySpiralRadius;
				anSpiralSteps[iRadial] = nSpiralSteps + 1;
				
				dx = Math.cos(radRadialAngle) * nKookySpiralRadius;
				dy = Math.sin(radRadialAngle) * nKookySpiralRadius;
				var ptSpiral:Point = new Point(ptCenter.x + dx, ptCenter.y + dy);
				
				// Draw a spiral segment (or skip it if decayed)
				if (rnd.nextDouble() < nDecay)
					gr.moveTo(ptSpiral.x ,ptSpiral.y);
				else
					gr.lineTo(ptSpiral.x, ptSpiral.y);

				if (strStyle == "corner") {
					// When 'spiraling' a corner and we come to the edge, in two iterations:
					// 1. step out along the edge
					// 2. reverse spiraling direction
					iRadial += nDir;
					if (iRadial >= cRadials - 1) {
						if (nDir == 0)
							nDir = -1;
						else
							nDir = 0;
					} else if (iRadial <= 0) {
						if (nDir == 0)
							nDir = 1;
						else
							nDir = 0;
					}
				} else {
					iRadial = (iRadial + nDir + cRadials) % cRadials;
				}
			}
			
			return shp;
		}
	}
}
