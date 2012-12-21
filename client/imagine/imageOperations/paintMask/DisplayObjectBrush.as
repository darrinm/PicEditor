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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.registerClassAlias;
	
	import mx.core.MovieClipLoaderAsset;
	
	[RemoteClass]
	public class DisplayObjectBrush extends Brush {
		{ // static block
			// This alias is for backward compatibility with the pre-Imagine class packaging.
			// Yes, that '>' is unexpected but that's what RemoteClass prefixes them all with
			// so that's what we need to be backward-compatible with.
			// The [RemoteClass] above also registers ">imagine.imageOperations.paintMask.DisplayObjectBrush"
			registerClassAlias(">imageOperations.paintMask.DisplayObjectBrush", DisplayObjectBrush);
		}
		
		public static const kastrBrushes:Array = [
			"circle_hard", "circle_medium", "circle_soft", "square_hard", "square_rounded",
			"ellipse_hard", "ellipse_medium", "ellipse_soft", "bristles_soft", "picnik_logo",
			"gears", "star", "heart", "paw_print"		
		];

		[Embed(source='../../../assets/swfs/brushes/circle_hard.swf')]
      	private static var s_circle_hard:Class;
      	
		[Embed(source='../../../assets/swfs/brushes/circle_medium.swf')]
      	private static var s_circle_medium:Class;
		
		[Embed(source='../../../assets/swfs/brushes/circle_soft.swf')]
      	private static var s_circle_soft:Class;
		
		[Embed(source='../../../assets/swfs/brushes/square_hard.swf')]
      	private static var s_square_hard:Class;
      	
		[Embed(source='../../../assets/swfs/brushes/square_rounded.swf')]
      	private static var s_square_rounded:Class;
      	
		[Embed(source='../../../assets/swfs/brushes/ellipse_hard.swf')]
      	private static var s_ellipse_hard:Class;
      	
		[Embed(source='../../../assets/swfs/brushes/ellipse_medium.swf')]
      	private static var s_ellipse_medium:Class;
      	
		[Embed(source='../../../assets/swfs/brushes/ellipse_soft.swf')]
      	private static var s_ellipse_soft:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/random.png')]
      	private static var s_bristles_soft:Class;

		[Embed(source='../../../assets/swfs/brushes/picnik_logo.swf')]
      	private static var s_picnik_logo:Class;
      	
		[Embed(source='../../../assets/swfs/gears.swf')]
      	private static var s_gears:Class;
      	
		[Embed(source='../../../assets/swfs/brushes/star.swf')]
      	private static var s_star:Class;
      	
		[Embed(source='../../../assets/swfs/brushes/heart.swf')]
      	private static var s_heart:Class;
      	
		[Embed(source='../../../assets/swfs/brushes/paw_print.swf')]
      	private static var s_paw_print:Class;
      	
/*      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush0.png')]
      	private static var s_bristles_1:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush1.png')]
      	private static var s_bristles_2:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush2.png')]
      	private static var s_bristles_3:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush3.png')]
      	private static var s_bristles_4:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush4.png')]
      	private static var s_bristles_5:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush5.png')]
      	private static var s_bristles_6:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush6.png')]
      	private static var s_charcoal_1:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush7.png')]
      	private static var s_charcoal_2:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush8.png')]
      	private static var s_charcoal_3:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush9.png')]
      	private static var s_charcoal_4:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush10.png')]
      	private static var s_charcoal_5:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush11.png')]
      	private static var s_charcoal_6:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush12.png')]
      	private static var s_pastel_1:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush13.png')]
      	private static var s_pastel_2:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush14.png')]
      	private static var s_pastel_3:Class;
      	
		[Embed(source='../../../assets/bitmaps/brushes/nagel_series_41/brush15.png')]
      	private static var s_pastel_4:Class;
      	*/
      	
		public var brushId:String = null;
		
		private static var s_cdobInitializing:int = 0;

		public function DisplayObjectBrush(nDiameter:Number=100, nHardness:Number=0.5, strBrushId:String=null) {
			super();
			diameter = nDiameter;
			hardness = nHardness;
			brushId = strBrushId;
		}
		
		// Embedded SWFs initialize asynchronously.
		// fnOnComplete(err:Number, strError:String)		
		public static function Init(fnOnComplete:Function): void {
			// Already initialized?
			if (s_dctBrushes != null) {
				fnOnComplete(0, null);
				return;
			}
			
			s_cdobInitializing = 0;
			s_dctBrushes = {};
			
			for each (var strBrushId:String in kastrBrushes) {
				var cls:Class = GetBrushClass(strBrushId);
				var dob:DisplayObject = new cls();
					
				// We assume that the origin of SWF brushes is correct but Bitmaps need to
				// have theirs moved to their center.
				if (dob is Bitmap) {
					// DWM: this doesn't seem to have any effect! because the DisplayObject isn't on the display list and
					// therefore doesn't recalc its concatenated matrix?
//					var mat:Matrix = new Matrix();
//					mat.translate(-dob.width / 2, -dob.height / 2);
//					dob.transform.matrix = mat;
// or
//					dob.x = -dob.width / 2;
//					dob.y = -dob.height / 2;
				} else {
					var mcla:MovieClipLoaderAsset = dob as MovieClipLoaderAsset;
					if (mcla != null) {
						var fnOnSwfInit:Function = function (evt:Event): void {
							LoaderInfo(evt.target).removeEventListener(Event.INIT, fnOnSwfInit);
							s_cdobInitializing--;
							if (s_cdobInitializing == 0)
								// UNDONE: failure
								fnOnComplete(0, null);
						}
						Loader(mcla.getChildAt(0)).contentLoaderInfo.addEventListener(Event.INIT, fnOnSwfInit);
						s_cdobInitializing++;
					}
				}
				s_dctBrushes[strBrushId] = dob;
			}
			
			if (s_cdobInitializing == 0)
				fnOnComplete(0, null);
		}
		
		// Brush cache
		private static var s_dctBrushes:Object;
		
		public static function GetBrushClass(strBrushId:String): Class {
			return DisplayObjectBrush["s_" + strBrushId];
		}
		
		private static function GetBrush(strBrushId:String): DisplayObject {
			return s_dctBrushes[strBrushId];
		}
		
		// UNDONE: Who calls this and what do they expect to get when the brush is rotated?
		override public function get width(): Number {
			return diameter;
		}

		override public function get height(): Number {
			return diameter;
		}

		// If we were to draw into a point, pt, return the dirty rect
		override public function GetDrawRect(ptCenter:Point, nColor:Number=NaN, nRot:Number=NaN): Rectangle {
			return CalcTransformAndBounds(null, ptCenter, nRot);
		}
		
		private function CalcTransformAndBounds(mat:Matrix, ptCenter:Point, nRot:Number): Rectangle {
			if (mat == null)
				mat = new Matrix();
			if (isNaN(nRot))
				nRot = 0;
			var dobBrush:DisplayObject = GetBrush(brushId);
//			if (dobBrush is Bitmap)
				mat.translate(-dobBrush.width / 2, -dobBrush.height / 2);
			var cxyMax:int = Math.max(dobBrush.width, dobBrush.height);
			mat.scale(diameter / cxyMax, diameter / cxyMax);
			mat.rotate(Util.RadFromDeg(nRot));
			mat.translate(ptCenter.x, ptCenter.y);
			
			// UNDONE: there is a better way
			var ptTL:Point = mat.transformPoint(new Point(0, 0));
			var ptTR:Point = mat.transformPoint(new Point(dobBrush.width, 0));
			var ptBR:Point = mat.transformPoint(new Point(dobBrush.width, dobBrush.height));
			var ptBL:Point = mat.transformPoint(new Point(0, dobBrush.height));
			
			var rcBounds:Rectangle = new Rectangle();
			rcBounds.left = Math.floor(Math.min(ptTL.x, ptTR.x, ptBL.x, ptBR.x));
			rcBounds.top = Math.floor(Math.min(ptTL.y, ptTR.y, ptBL.y, ptBR.y));
			rcBounds.width = Math.ceil(Math.max(ptTL.x, ptTR.x, ptBL.x, ptBR.x) - rcBounds.left);
			rcBounds.height = Math.ceil(Math.max(ptTL.y, ptTR.y, ptBL.y, ptBR.y) - rcBounds.top);
			return rcBounds;
		}
		
		// UNDONE: Support scale
		override public function DrawInto(bmdTarget:BitmapData, bmdOrig:BitmapData, ptCenter:Point, nAlpha:Number, nColor:Number=NaN, nScaleX:Number=NaN, nScaleY:Number=NaN, nRot:Number=NaN): Rectangle {
			var dobBrush:DisplayObject = GetBrush(brushId);

			var mat:Matrix = new Matrix();
			var rcBounds:Rectangle = CalcTransformAndBounds(mat, ptCenter, nRot);
			var ctr:ColorTransform = new ColorTransform();
			ctr.color = uint(nColor);
			ctr.alphaMultiplier = nAlpha;
			bmdTarget.draw(dobBrush, mat, ctr);
			return rcBounds;
			
			/* UNDONE: seems like this could all be done by setting DisplayObject properties.
			If so then we could use its pixelBounds as the dirty rect
			// Scale the brush to fit within the diameter, but retain its proportions
			var cxyMax:int = Math.max(dobBrush.width, dobBrush.height);
			dobBrush.scaleX = dobBrush.scaleY = diameter / cxyMax;
			dobBrush.rotation = isNaN(nRot) ? 0 : nRot;
			dobBrush.x = xCenter;
			dobBrush.y = yCenter;
			
			var ctr:ColorTransform = new ColorTransform();
			ctr.color = co;
			ctr.alphaMultiplier = nAlpha;
			bmdTarget.draw(dobBrush, null, ctr);
			
			var rcBrush:Rectangle = dobBrush.transform.pixelBounds;
			return rcBrush;
			*/
		}
	}
}
