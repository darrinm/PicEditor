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
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.registerClassAlias;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class DoodleStroke extends Stroke {
		{ // static block
			// This alias is for backward compatibility with the pre-Imagine class packaging.
			// Yes, that '>' is unexpected but that's what RemoteClass prefixes them all with
			// so that's what we need to be backward-compatible with.
			// The [RemoteClass] above also registers ">imagine.imageOperations.paintMask.DoodleStroke"
			registerClassAlias(">imageOperations.paintMask.DoodleStroke", DoodleStroke);
		}
		
		[Bindable] public var color:Number = 0;
		[Bindable] public var blendMode:String = BlendMode.NORMAL;
		[Bindable] public var autoRotate:Boolean = false;
		[Bindable] public var autoRotateStartAngle:Number = 0.0;
//		[Bindable] public var smear:int = 0;
//		[Bindable] public var mix:Number = 0.0;
		
		private var _bmdEraseMask:BitmapData = null;
//		private var _acoSmear:Array = null;
		
		public function DoodleStroke(br:Brush=null) {
			super(br);
		}
		
		override public function Dispose(): void {
			if (_bmdEraseMask) _bmdEraseMask.dispose();
			_bmdEraseMask = null;
			super.Dispose();
		}
		
		override public function get directDraw(): Boolean {
			return (alpha >= 1) && (blendMode == BlendMode.NORMAL || blendMode == "impression");
		}

		// Draw a point. Updates the children of the stroke canvas as needed.
		// Mask is definitely updated, others are optional
		// Returns the dirty rectangle (part of Mask which was changed)
		override protected function DrawPoint(scv:IStrokeCanvas, pt:Point, iptDab:int): Rectangle {
//			smear = 5;
//			mix = 0.5;
			
			if (!erase) {
				var co:uint = color;
				if (blendMode == "impression") {
					// Clamp the sample at the image boundary otherwise it will pull in black
					var xSample:int = Math.round(pt.x);
					if (xSample < 0)
						xSample = 0;
					else if (xSample >= scv.originalBmd.width)
						xSample = scv.originalBmd.width - 1;
					var ySample:int = Math.round(pt.y);
					if (ySample < 0)
						ySample = 0;
					else if (ySample >= scv.originalBmd.height)
						ySample = scv.originalBmd.height - 1;
					co = scv.originalBmd.getPixel(xSample, ySample);
					/*
					// Smearing means carry a sampled color forward N points
					if (smear != 0) {
						if (iptDab == 0) {
							_acoSmear = [];
							for (var i:int = 0; i < smear; i++)
								_acoSmear.push(co);
						}
						var coSmeared:uint = _acoSmear.shift();
						_acoSmear.push(co);
						co = RGBColor.Blend(coSmeared, co, mix);
					}
					*/
				}
			}
			
			var degRotation:Number = rotation;
			if (autoRotate) {
				if (drawFromPointIndex != -1 && iptDab != 0) {
					var i:int = Math.max(drawFromPointIndex - 10, 0);
					var ptDelta:Point = new Point();
					for (; i < drawFromPointIndex + 1; i++)
						ptDelta = ptDelta.add(points[i + 1].subtract(points[i]));
					degRotation += Util.GetOrientation(new Point(0, 0), ptDelta);
				} else {
					degRotation = autoRotateStartAngle;
				}
			}
			
			var rcDirty:Rectangle;
			if (erase) {
				var rcBase:Rectangle = brush.GetDrawRect(new Point(0,0), color, degRotation);
				rcBase = new Rectangle(Math.round(rcBase.x), Math.round(rcBase.y), Math.round(rcBase.width), Math.round(rcBase.height));
				
				// This will be a negative offset such that when we move our base rect this ammount
				// we are targeting 0,0
				if (_bmdEraseMask == null) {
					_bmdEraseMask = VBitmapData.Construct(rcBase.width, rcBase.height, true, 0, "doodle erase mask");
					
					// Draw into the rect such that the top left is 0,0
					// If our rcBase top left is -100, -50, draw at 100,50
					brush.DrawInto(_bmdEraseMask, scv.originalBmd, new Point(-rcBase.top, -rcBase.left), alpha, NaN, NaN, NaN, degRotation); 				
				}
				// Now _bmdEraseMask is our alpha mask offset rcBase.topLeft from 0,0

				// Draw our bmdOrig into our "mask"
				rcDirty = rcBase.clone();
				pt = new Point(Math.round(pt.x), Math.round(pt.y));
				rcDirty.offsetPoint(pt);
				
				// This is where we want to draw
				scv.maskBmd.copyPixels(scv.originalBmd, rcDirty, rcDirty.topLeft, _bmdEraseMask, new Point(0,0), true);
			} else if (directDraw) {
				// Draw our color
				rcDirty = brush.DrawInto(scv.maskBmd, scv.originalBmd, pt, alpha, co, NaN, NaN, degRotation);
			} else {
				// not direct draw
				rcDirty = brush.DrawInto(scv.strokeBmd, scv.originalBmd, pt, 1, co, NaN, NaN, degRotation);
				scv.maskBmd.copyPixels(scv.compositeBmd, rcDirty, rcDirty.topLeft);
				var ctr:ColorTransform = null;
				if (alpha < 1)
					ctr = new ColorTransform(1,1,1,alpha);
				scv.maskBmd.draw(scv.strokeBmd, null, ctr, blendMode == "impression" ? BlendMode.NORMAL : blendMode, rcDirty);
			}
			return rcDirty;
		}
	}
}
