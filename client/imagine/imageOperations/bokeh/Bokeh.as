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
package imagine.imageOperations.bokeh {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import imagine.imageOperations.ShapeImageOperation;
	import imagine.imageOperations.bokeh.customShapes.*;
	
	public class Bokeh extends Sprite {
		private static const HEART2:String = "M98.586,0c-20.6,0-32.371,23.854-32.371,23.854S54.444,0,33.843,0C11.22,0,0,21.465,0,35.338c0,44.725,62.715,79.787,66.215,79.787s66.215-35.062,66.215-79.787C132.43,21.465,121.211,0,98.586,0z";
		
		private var image:DisplayObject;
		private var pic:Sprite;
		private var bd_original:BitmapData;
		private var bd_noise:BitmapData;
		private var bd1:BitmapData;
		private var bd2:BitmapData;
		private var bd2b:BitmapData;
		private var bd3:BitmapData;
		private var bd3_blurred:BitmapData;
		private var bd_temp:BitmapData;
		private var bmp:Bitmap;
		private var origin:Point=new Point(0,0);
		private var rectOriginal:Rectangle;
		private var rect:Rectangle;
		
		private var _threshold:uint=0x999999;
		private var _radius:uint=30;
		private var _lensType:uint=BokehLensType.CIRCULAR;
		private var _style:uint=BokehStyle.VIVID;
		private var _intensity:Number=.3;
		private var _lensRotation:Number=0;
		
		private var reflectionBlurSize:Number;
		
		private var w:uint;
		private var h:uint;
		private var w2:uint;
		private var h2:uint;
		
		public static const REAL:String="real";
		public static const HIGHLIGHTS_ONLY:String="highlights_only";
		
		private var _mode:String=REAL;
		private var brush:Shape;
		private var brushMask:Shape;
		private var brushBD:BitmapData;
		
		private var scaleFactor:Number;
		private var scaleFactorX:Number;
		private var scaleFactorY:Number;
		private const MAX_PIXEL_COUNT:uint=1 * 300000;
		private const FIXED_SAMPLED_COLOR1:uint=0xff0000;
		private const FIXED_SAMPLED_COLOR2:uint=0xffff00;
		
		private var items_x:Array, items_y:Array;
				
		public function Bokeh($bitmapData:BitmapData=null)	{
			if ($bitmapData)
				prepareBitmapDatas($bitmapData);
		}
		
		private function prepareBitmapDatas(bd_source:BitmapData): void {
			bd_original=bd_source;
			w=bd_original.width;
			h=bd_original.height;
			
			var realPixelCount:uint=w*h;
			scaleFactor=realPixelCount/MAX_PIXEL_COUNT;
			if(scaleFactor<1) scaleFactor=1;
			
			w2=w/Math.sqrt(scaleFactor);
			h2=h/Math.sqrt(scaleFactor);
			
			scaleFactorX=w/w2;
			scaleFactorY=h/h2;

			rectOriginal=bd_original.rect;
			
			bd1=new BitmapData(w2, h2, false, 0xffff99);
			rect=bd1.rect;
			bd2=new BitmapData(w2, h2, false, 0xffff99);
			bd2b=new BitmapData(w2, h2, false, 0xffff99);
			bd_noise=new BitmapData(w2, h2, false, 0xffff99);
			bd_noise.noise(1,0,255,7,true);
		
			brush=new Shape();
			brushMask=new Shape();
			
			items_x = null;
		}
		
		public function Dispose(): void {
			if (bd1)
				bd1.dispose();
			if (bd2)
				bd2.dispose();
			if (bd2b)
				bd2b.dispose();
			if (bd3_blurred)
				bd3_blurred.dispose();
			if (bd_noise)
				bd_noise.dispose();
			bd_original = null;
		}
		
		private function prepareBalloonsCalculations():void {
			var msT:int = getTimer();

			items_x=new Array();
			items_y=new Array();
			
			var matrix:Matrix=new Matrix();
			matrix.scale(1/scaleFactorX, 1/scaleFactorY);
			bd1.draw(bd_original, matrix);
			
			bd2.lock();
			bd2b.lock();
			
			bd2b.fillRect(rect, 0x00000000);
			bd2.fillRect(rect, 0x00000000);
			bd2b.threshold(bd1, rect, origin, ">", threshold, 0xffffffff, 0x00ffffff, false);
			
			bd2b.draw(bd_noise, null, null, BlendMode.DARKEN);
			bd2b.applyFilter(bd2b, rect, origin, new BlurFilter(2,2,3));
			bd2.threshold(bd2b, rect, origin, ">", 0x909090, 0xff000000 | FIXED_SAMPLED_COLOR1, 0x00ffffff, false);
			
			var color:uint;
			for(var i:int=0; i<h2; i++) {
				for(var j:int=0; j<w2; j++) {
					color=bd2.getPixel(j,i);
					if(color==FIXED_SAMPLED_COLOR1) {
						items_x.push(j);
						items_y.push(i);
						bd2.floodFill(j,i,FIXED_SAMPLED_COLOR2);
					}
				}
			}
			bd2.unlock();
			bd2b.unlock();	
//			trace("balloon calc time: " + (getTimer() - msT));
		}
		private function prepareBlurred():void {
			// Don't blur if we already have done so OR we aren't meant to do so
			if (bd3_blurred != null || _mode != REAL)
				return;

			var msT:int = getTimer();
			bd3_blurred=new BitmapData(w, h, false, 0xffff99);
			bd3_blurred.applyFilter(bd_original,rectOriginal,origin,new BlurFilter(radius,radius,2));
//			trace("blur time: " + (getTimer() - msT));
		}

		public function Render(bd_source:BitmapData, bd_dest:BitmapData, threshold:uint=0x999999, radius:uint=30, lensType:uint=BokehLensType.CIRCULAR,
				style:uint=BokehStyle.VIVID, intensity:Number=0.3, lensRotation:Number=0.0, mode:String=REAL):BitmapData {
			// Clear out the blurred source bitmap if it is no longer valid
			if ((_radius != radius || _mode != mode) && bd3_blurred != null) {
				bd3_blurred.dispose();
				bd3_blurred = null;
			}
			
			// Clear out all other bitmaps if the source they're dependent on has changed
			if (bd_original != bd_source) {
				Dispose();
				prepareBitmapDatas(bd_source);
			}
			
			if (_threshold != threshold)
				items_x = null;
			
			// Retain the 'last rendered' state
			_threshold = threshold;
			_radius = radius;
			_lensType = lensType;
			_style = style;
			_intensity = intensity;
			_lensRotation = lensRotation;
			_mode = mode;
			bd3 = bd_dest;
			
			return render();
		}
		
		public function render():BitmapData {
			var msT:int = getTimer();
			prepareBlurred();
			if(!items_x)
				prepareBalloonsCalculations();
			
			bd3.lock();
			if(mode==REAL) {
				bd3.draw(bd3_blurred);	
			} else {
				bd3.draw(bd_original);
			}

			var msT3:int = getTimer();
			brush.graphics.clear();
			brushMask.graphics.clear();
			
			prepareBrush(brush);
				
			if(style==BokehStyle.VIVID) {
				prepareBrush(brushMask, true);
				brush.mask=brushMask;	
			} else {
				brush.mask=null;
			}
			
			switch(style) {
				case BokehStyle.VIVID:
					reflectionBlurSize=radius/10;
					break;
				case BokehStyle.SHARP:
					reflectionBlurSize=0;
					break;
				case BokehStyle.CREAMY:
					reflectionBlurSize=radius/5;
					break;
			}

			// OPT: applyFilter this blur instead of attaching it to the brush to improve memory usage
			/*	
			brush.filters=[new BlurFilter(reflectionBlurSize, reflectionBlurSize, 3)];
			var maxSide:Number=brush.width>brush.height? brush.width : brush.height;
			brushBD=new BitmapData(maxSide+reflectionBlurSize*2, maxSide+reflectionBlurSize*2, true, 0);
			var matrixBrush:Matrix=new Matrix();
			matrixBrush.rotate(lensRotation/180*Math.PI);
			matrixBrush.translate(maxSide/2+reflectionBlurSize, maxSide/2+reflectionBlurSize);
			brushBD.draw(brush, matrixBrush);
			*/
			// This method of producing the brush bitmap has two advantages:
			// 1. the brush bitmap is exactly size it should be (never bigger, no guessing)
			// 2. the filter is drawn via applyFilter, rather than the filter property which has GC issues
			brush.rotation = lensRotation;
			var flt:BlurFilter = new BlurFilter(reflectionBlurSize, reflectionBlurSize, 3);
			var rc:Rectangle = brush.transform.pixelBounds;
			rc = bd3.generateFilterRect(rc, flt);
			brushBD = new BitmapData(rc.width, rc.height, true, 0);
			var matrixBrush:Matrix = new Matrix();
			matrixBrush.rotate(lensRotation/180*Math.PI);
			matrixBrush.translate(brushBD.width / 2, brushBD.height / 2);
			brushBD.draw(brush, matrixBrush);
			brushBD.applyFilter(brushBD, brushBD.rect, new Point(0, 0), flt);
//			trace("prepare brush time: " + (getTimer() - msT3));
			
			var msT2:int = getTimer();
			for(var i:int=0; i<items_x.length; i++) {
				drawBrush(items_x[i], items_y[i]);
			}
//			trace("drawBrush time: " + (getTimer() - msT2) + ", " + brushBD.width + "x" + brushBD.height);
			
			bd3.unlock();

//			trace("items_x.length: " + items_x.length);
//			trace("render time: " + (getTimer() - msT));
			return bd3;
		}
		private function drawBrush(x:uint, y:uint):void {
			var color:uint=bd1.getPixel(x,y);
			var localIntensity:Number=intensity*getColorLuminosity(color);
			var ct:ColorTransform=new ColorTransform(0,0,0,localIntensity,(0xFF0000 & color) >> 16, (0x00FF00 & color) >> 8, (0x0000FF & color));
			
			var matrix:Matrix=new Matrix();
			matrix.translate(int(x*scaleFactorX-brushBD.width/2),int(y*scaleFactorY-brushBD.height/2));
			bd3.draw(brushBD,matrix,ct, BlendMode.ADD);
		}
		private function prepareBrush(target:Shape, isMask:Boolean=false):void {
			if(!isMask) {
				if(style==BokehStyle.VIVID) target.graphics.lineStyle(radius/4, 0xffffff, 1);
				target.graphics.beginFill(0xffffff, .7);
			} else {
				target.graphics.beginFill(0xff0000, 1);
			}
			var sides:uint=lensType;
			
			switch(lensType) {
				case BokehLensType.CIRCULAR:
					target.graphics.drawCircle(0,0,radius);
					break;
				case BokehLensType.SHAPE_HEART:
					Heart.draw(target, radius);
					break;
				case BokehLensType.SHAPE_DIAMOND:
					Diamond.draw(target, radius);
					break;
				case BokehLensType.SHAPE_STAR:
					Star.draw(target, radius);
					break;
				case BokehLensType.SHAPE_STAR2:
					Star2.draw(target, radius);
					break;
				case BokehLensType.SHAPE_SPARKLE:
					Sparkle.draw(target, radius);
					break;
				case BokehLensType.SHAPE_SPARKLE2:
					Sparkle2.draw(target, radius);
					break;
				case BokehLensType.SHAPE_HEART2:
					ShapeImageOperation.DrawSVGShape(HEART2, target, 0, 0, radius * 2, radius * 2, true);
					break;
				default:
					var arad:Number;
					var px:Number, py:Number;
					var aspan:Number=360/sides;
					var a:Number=0;
					
					for(var i:uint=0; i<sides; i++) {
						arad=a/180*Math.PI;
						px=Math.cos(arad)*radius;
						py=Math.sin(arad)*radius;
						i==0 ? target.graphics.moveTo(px, py) : target.graphics.lineTo(px, py);
						a+=aspan;
					}
					break;
			}
			target.graphics.endFill();
		}
		private function getColorLuminosity(hex:uint):Number {
			var sum:uint=(0xFF0000 & hex) >> 16 + (0x00FF00 & hex) >> 8 + (0x0000FF & hex);
			var avg:Number=sum/3;
			var l:Number=.03+(avg/255)*.97;
			return l;
		}
		
		// Setters & getters
		
		public function set threshold(n:uint):void {
			_threshold=n;
			prepareBalloonsCalculations()
			render();
		}
		public function get threshold():uint {
			return _threshold;
		}
		public function set radius(n:uint):void {
			_radius=n;
			if(mode==REAL) prepareBlurred();
			render();
		}
		public function get radius():uint {
			return _radius;
		}
		public function set lensType(n:uint):void {
			_lensType=n;
			render();
		}
		public function get lensType():uint {
			return _lensType;
		}
		public function set style(n:uint):void {
			_style=n;
			render();
		}
		public function get style():uint {
			return _style;
		}
		public function set intensity(n:Number):void {
			_intensity=n;
			render();
		}
		public function get intensity():Number {
			return _intensity;
		}
		public function set lensRotation(n:Number):void {
			_lensRotation=n;
			render();
		}
		public function get lensRotation():Number {
			return _lensRotation;
		}
		public function set mode(mode:String):void {
			_mode=mode;
			render();
		}
		public function get mode():String {
			return _mode
		}
	}
}