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
	import flash.filters.ColorMatrixFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.registerClassAlias;
	
	[RemoteClass]
	public class Stroke {
		{ // static block
			// This alias is for backward compatibility with the pre-Imagine class packaging.
			// Yes, that '>' is unexpected but that's what RemoteClass prefixes them all with
			// so that's what we need to be backward-compatible with.
			// The [RemoteClass] above also registers ">imagine.imageOperations.paintMask.Stroke"
			registerClassAlias(">imageOperations.paintMask.Stroke", Stroke);
		}
		
		[Bindable] public var alpha:Number = 1;
		[Bindable] public var additive:Boolean = false;
		[Bindable] public var erase:Boolean = false;
		[Bindable] public var spacing:Number = 0.15;
		[Bindable] public var rotation:Number = 0;
		[Bindable] public var brush:Brush;
		
		private var _apts:Array = [];
		
		private static var _nErrorsToLog:Number = 2;
		
		private var _nDrawUnderflow:Number = 0;
		private var _nDrawPoint:Number = -1;
		
		public function Stroke(br:Brush=null) {
			brush = br;
		}

		public function Dispose(): void {
			if (brush)
				brush.dispose();
		}
		
		private static function IncludeOps(): void {
			var dstk:DoodleStroke;
		}

		[Bindable]
		public function set points(apts:Array): void {
			if (apts && apts.length > 0 && (apts[0] as Point) == null) {
				_apts = [];
				for each (var ob:Object in apts) {
					_apts.push(new Point(ob.x, ob.y));
				}
			} else {
				_apts = apts;
			}
		}
		public function get points(): Array {
			return _apts;
		}
		
		public function get drawFromPointIndex(): int {
			return _nDrawPoint;
		}

		public function push(ob:Object): uint {
			return points.push(ob);
		}
		
		public function get length(): Number {
			return points.length;
		}
		
		public function get directDraw(): Boolean {
			return (alpha >= 1) || additive;
		}
		
		// Current 'dab' (one step of the stroke) index
		private var _iptDab:int = 0;
		
		public function Draw(scv:IStrokeCanvas): Rectangle {
			InitStroke(scv);
			if (length == 0) {
				return new Rectangle();
			}
			var rcDirty:Rectangle = DrawPoint(scv, points[0], 0);
			_nDrawUnderflow = 0;
			_nDrawPoint = 0;
			_iptDab = 0;
			
			for (var i:Number = 1; i < length; i++) {
				rcDirty = rcDirty.union(DrawTo(scv, i));
			}
			return rcDirty;
		}
		
		public function DrawTo(scv:IStrokeCanvas, i:Number): Rectangle {
			var rcDirty:Rectangle = new Rectangle();
			
			if (i < 0 || i >= length) throw new Error("index out of bounds");
			if (_nDrawPoint == -1) throw new Error("Must be initialized first");
			if (_nDrawPoint != (i-1)) throw new Error("Must be called in order");
			
			if (_nDrawUnderflow < 0) {
				trace("draw underflow < 0: " + _nDrawUnderflow);
				_nDrawUnderflow = 0;
			}
			if (_nDrawUnderflow > spacing) {
				trace("draw underflow > spacing", _nDrawUnderflow, spacing);
				_nDrawUnderflow = spacing;
			}
			
			// Our previous point is _nDrawPoint.
			// _nDrawUnderflow > 0 means we didn't go far enough.
			// from last time - if this offset > 0, draw our first dot a bit away from the start point
			// if this is < 0, draw our first dot closer to the start point.
			// We are drawing to i
			var ptFrom:Point = points[_nDrawPoint];
			var ptTo:Point = points[i];
			
			// Calculate the total distance between our points in, "brushes"
			var ptDist:Point = ptTo.subtract(ptFrom);
			
			// Distance in brushes (accounts for 1:1 brushes)
			var ptBrushDist:Point = new Point(ptDist.x / brush.width, ptDist.y / brush.height);
			var nBrushDist:Number = ptBrushDist.length;
			
			// Each time we go one brush, this is how far it really is
			var ptDistPerBrush:Point = new Point(ptDist.x / nBrushDist, ptDist.y / nBrushDist);
			
			var nNextDotPos:Number = spacing - _nDrawUnderflow;
			while (nNextDotPos <= nBrushDist) {
				// Draw the pos
				var ptOffset:Point = new Point(nNextDotPos * ptDistPerBrush.x, nNextDotPos * ptDistPerBrush.y);
				var ptDraw:Point = ptFrom.add(ptOffset);
				
				rcDirty = rcDirty.union(DrawPoint(scv, ptDraw, _iptDab++));
				
				// Advance to next position
				nNextDotPos += spacing;
			}
			_nDrawUnderflow = nBrushDist - (nNextDotPos - spacing);
			if (_nDrawUnderflow < 0) {
				trace("draw underflow < 0?!?", _nDrawUnderflow, nBrushDist, nNextDotPos, spacing);
				_nDrawUnderflow = 0;
			}
			_nDrawPoint = i;
			return rcDirty;
		}
		
		private function InitStroke(scv:IStrokeCanvas): void {
			var bmdPrev:BitmapData = scv.strokeBmd;
			scv.InitForStroke(this);
		}
		
		// Draw a point. Updates the children of the stroke canvas as needed.
		// Mask is definitely updated, others are optional
		// Returns the dirty rectangle (part of Mask which was changed)
		protected function DrawPoint(scv:IStrokeCanvas, pt:Point, iptDab:int): Rectangle {
			var rcDirty:Rectangle;
			var ctr:ColorTransform = null;
			var e:Error = new Error();
			try {
				if (erase) {
					// Draw blue into the composite
					rcDirty = brush.DrawInto(scv.compositeBmd, scv.originalBmd, pt, alpha, NaN, NaN, NaN, rotation);
					// Copy blue to alpha
					var flt:ColorMatrixFilter = new ColorMatrixFilter(
						[ 0,0,0,0, 255,
						  0,0,0,0, 255,
						  0,0,0,0, 255,
						  0,0,1,0, 0
						  ]);
					scv.maskBmd.applyFilter(scv.compositeBmd, rcDirty, rcDirty.topLeft, flt);
				} else if (directDraw) {
					// Draw directly on the mask
					if (alpha != 1)
						ctr = new ColorTransform(1,1,1,alpha);
					// For efficiency, a brush should draw in Alpha and Red
					rcDirty = brush.DrawInto(scv.maskBmd, scv.originalBmd, pt, alpha, NaN, NaN, NaN, rotation);
				} else {
					// Alpha. Draw to our stroke, use the composite to update the mask
					rcDirty = brush.DrawInto(scv.strokeBmd, scv.originalBmd, pt, alpha, NaN, NaN, NaN, rotation);
					
					if (alpha < 1) ctr = new ColorTransform(1,1,1,alpha);
					
					scv.maskBmd.copyPixels(scv.compositeBmd, rcDirty, rcDirty.topLeft); // Start with our composite base
					scv.maskBmd.draw(scv.strokeBmd, null, ctr, null, rcDirty);
					//scv.maskBmd.copyPixels(scv.compositeBmd, scv.compositeBmd.rect, scv.compositeBmd.rect.topLeft); // Start with our composite base
					//scv.maskBmd.draw(scv.strokeBmd, null, ctr);
				}
			} catch (e:Error) {
				// Collect information about the effect being applied.
				var strError:String = "Error in Stroke.DrawPoint: ";
				var afState:Array = [];
				afState.push(erase, directDraw, scv != null);
				if (scv != null) {
					var abmd:Array = [scv.compositeBmd, scv.maskBmd, scv.strokeBmd, scv.originalBmd];
					var i:Number;
					var nWidth:Number = -1;
					var nHeight:Number = -1;
					for each (var bmd:BitmapData in abmd) {
						afState.push(bmd != null);
						if (bmd != null) {
							try {
								nWidth = bmd.width;
								nHeight = bmd.height;
							} catch (e:Error) {
								// Ignore invalid bitmap error
							}
						}
					}
					afState.push(nWidth);
					afState.push(nHeight);
				}
				strError += ": " + afState.join(", ");
				trace(strError, e);
				if (_nErrorsToLog > 0) {
					PicnikService.LogException(strError, e);
					_nErrorsToLog -= 1;
				}	
				throw new Error("Error in Stroke.DrawPoint: " + e.toString());
			}
			return rcDirty;
		}
	}
}