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
package imagine.imageOperations.paintMask
{
	import de.polygonal.math.PM_PRNG;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.registerClassAlias;
	
	import overlays.helpers.RGBColor;
	
	[RemoteClass]
	public class GlitterBrush extends Brush {
		{ // static block
			// This alias is for backward compatibility with the pre-Imagine class packaging.
			// Yes, that '>' is unexpected but that's what RemoteClass prefixes them all with
			// so that's what we need to be backward-compatible with.
			// The [RemoteClass] above also registers ">imagine.imageOperations.paintMask.GlitterBrush"
			registerClassAlias(">imageOperations.paintMask.GlitterBrush", GlitterBrush);
		}
		
		[Embed(source='../../../assets/bitmaps/glitter/g1.png')]
      	private static var s_clGlitter1:Class;
      	
		[Embed(source='../../../assets/bitmaps/glitter/g2.png')]
      	private static var s_clGlitter2:Class;
		
		[Embed(source='../../../assets/bitmaps/glitter/g3.png')]
      	private static var s_clGlitter3:Class;
		
		[Embed(source='../../../assets/bitmaps/glitter/g4.png')]
      	private static var s_clGlitter4:Class;
      	
		private static const kanWeights:Array = [1, 30, 30, 30];
		private static const kafRotate:Array = [false, true, true, true];

      	private static var _abmGlitter:Array = null;

		private static var _nTotalWeight:Number = 0;

		public function GlitterBrush(nDiameter:Number=100, nHardness:Number=0.5)
		{
			super();
			diameter = nDiameter;
			hardness = nHardness;
		}
		
		private static function GetGlitterBmd(n:Number): BitmapData {
			if (_abmGlitter == null) {
				_abmGlitter = [];
				_abmGlitter.push(new s_clGlitter1());
				_abmGlitter.push(new s_clGlitter2());
				_abmGlitter.push(new s_clGlitter3());
				_abmGlitter.push(new s_clGlitter4());
			}
			return Bitmap(_abmGlitter[n]).bitmapData;
		}
		
		private static function GetRandomGlitterBmd(rnd:PM_PRNG): Object {
			var nWeight:Number;
			if (_nTotalWeight == 0) {
				for each (nWeight in kanWeights) _nTotalWeight += nWeight;
			}
			
			var nRandomWeight:Number = rnd.nextIntRange(0, _nTotalWeight-1);
			nWeight = 0;
			var nGlitter:Number = 0;
			for (var i:Number = 0; i < kanWeights.length; i++) {
				nWeight += kanWeights[i];
				if (nWeight >= nRandomWeight) {
					nGlitter = i;
					break;
				}
			}
			var bmd:BitmapData = GetGlitterBmd(nGlitter);
			var nRotation:Number = GetRotation(rnd, nGlitter);
			return {bmd:bmd, nRotation:nRotation};
		}
		
		private static function GetRotation(rnd:PM_PRNG, nGlitter:Number): Number {
			var fRotate:Boolean = kafRotate[nGlitter];
			if (fRotate == false) return 0;
			return rnd.nextDoubleRange(0, Math.PI * 2);
		}
		
		override public function get width(): Number {
			return diameter;
		}

		override public function get height(): Number {
			return diameter;
		}

		// If we were to draw into a point, pt, return the dirty rect
		override public function GetDrawRect(ptCenter:Point, nColor:Number=NaN, nRot:Number=NaN): Rectangle {
			var nWidth:Number = width + 24;
			var nHeight:Number = height + 24;
			var rcBrush:Rectangle = new Rectangle(
					Math.round(ptCenter.x-nWidth/2),
					Math.round(ptCenter.y-nHeight/2),
					nWidth,
					nHeight);
			return rcBrush;
		}
		
		override public function DrawInto(bmdTarget:BitmapData, bmdOrig:BitmapData, ptCenter:Point, nAlpha:Number, nColor:Number=NaN, nScaleX:Number=NaN, nScaleY:Number=NaN, nRot:Number=NaN): Rectangle {
			var rnd:PM_PRNG = new PM_PRNG();
			rnd.seed = ptCenter.x + ptCenter.y;
			
			// UNDONE: Support scale, rotation
			var nWeight:Number = 0.003;
			var rcBrush:Rectangle;
			var nMaxRadius:Number = Math.floor(diameter/2);
			for (var i:Number = 1; i < nMaxRadius; i++) {
				var nCount:Number = rnd.nextDoubleRange(0, nWeight * i * (nMaxRadius - i)/nMaxRadius);
				var nFract:Number = nCount - Math.floor(nCount);
				nCount = Math.floor(nCount);
				if (rnd.nextDoubleRange(0,1) < nFract) nCount += 1;
				while (nCount > 0) {
					var nRads:Number = rnd.nextDoubleRange(0, Math.PI * 2);
					var nRadius:Number = i - rnd.nextDoubleRange(0,1);
					
					var xCenter:Number = ptCenter.x + Math.sin(nRads) * nRadius;
					var yCenter:Number = ptCenter.y + Math.cos(nRads) * nRadius;
					
					// Test our center point. If it is dark, pick a new one
					var nLoopsLeft:Number = 10;
					var nLumThreshold:Number = 120;
					while (nLoopsLeft > 0) {
						nLoopsLeft -= 1;
						var nLum:Number = RGBColor.LuminosityFromUint(bmdOrig.getPixel(Math.round(xCenter), Math.round(yCenter)));
						if ((nLum < nLumThreshold) || (nLum > (255-nLumThreshold/2))) {
							nRads = rnd.nextDoubleRange(0,Math.PI * 2);
							nRadius = i - rnd.nextDoubleRange(0,1);
							xCenter = ptCenter.x + Math.sin(nRads) * nRadius;
							yCenter = ptCenter.y + Math.cos(nRads) * nRadius;
							nLumThreshold *= 0.9;
						} else {
							break;
						}
					}
					
					var obBmdInfo:Object = GetRandomGlitterBmd(rnd);
					var bmd:BitmapData = obBmdInfo.bmd;
					var nRotation:Number = obBmdInfo.nRotation;
					
					var mat:Matrix = new Matrix();
					mat.translate(-bmd.width/2, -bmd.height/2);
					mat.rotate(nRotation);
					mat.translate(bmd.width/2, bmd.height/2);
					mat.translate(xCenter - bmd.width/2, yCenter - bmd.height/2);
					bmdTarget.draw(bmd, mat, null, null, null, true);

					var rcDraw:Rectangle = new Rectangle(xCenter - bmd.width/2, yCenter-bmd.height/2, bmd.width, bmd.height);
					if (rcBrush == null) rcBrush = rcDraw;
					else rcBrush = rcBrush.union(rcDraw);
					nCount -= 1;
				}
			}
			if (rcBrush == null) {
				rcBrush = new Rectangle();
			} else {
				rcBrush.left = Math.floor(rcBrush.left);
				rcBrush.top = Math.floor(rcBrush.top);
				rcBrush.width = Math.ceil(rcBrush.width);
				rcBrush.height = Math.ceil(rcBrush.height);
			}
			return rcBrush; // This will be impacted by scale/rotation
		}
	}
}