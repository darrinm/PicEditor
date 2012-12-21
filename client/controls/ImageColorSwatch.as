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
package controls
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import mx.controls.Image;
	import mx.events.FlexEvent;

	public class ImageColorSwatch extends ColorSwatchBase
	{
		private var _strSource:String;
		private var _img:Image;

		protected var _xStartThumb:Number = 0;
		protected var _yStartThumb:Number = 0;
		
		public function ImageColorSwatch(): void {
			_img = new Image();
			addChildAt(_img, 0);
			_img.width = width;
			_img.height = height;
		}
		
		protected override function commitProperties():void {
			_img.width = width;
			_img.height = height;
		}
		
		[Bindable]
		public function set source(value:Object): void {
			_img.source = value;
		}
		public function get source(): Object {
			return _img.source;
		}
		
		[Bindable (event="thumbChange")]
		public function set startThumbX(x:Number): void {
			_xStartThumb = x;
			updateThumb(_clr, new Point(_xStartThumb, _yStartThumb));
			dispatchEvent(new Event("thumbChange"));
		}
		public function get startThumbX(): Number {
			return _xStartThumb;
		}
		
		[Bindable (event="thumbChange")]
		public function set startThumbY(y:Number): void {
			_yStartThumb = y;
			updateThumb(_clr, new Point(_xStartThumb, _yStartThumb));
			dispatchEvent(new Event("thumbChange"));
		}
		public function get startThumbY(): Number {
			return _yStartThumb;
		}
		
		protected override function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			updateThumb(_clr, new Point(_xStartThumb, _yStartThumb));
		}

		// Override this in a child class
		// See HSBColorSwatch for an example
		protected override function PointFromColor(clr:Number): Point {
			return null;
		}
		
		// Override this in a child class
		// See HSBColorSwatch for an example
		protected override function ColorFromPoint(x:Number, y:Number): Number {
			var bm:Bitmap = _img.getChildAt(0) as Bitmap;
			/*
			trace("_img.numchildren = " + _img.numChildren);
			for (var i:Number = 0; i < _img.numChildren; i++) {
				trace("img[" + i + "] = " + _img.getChildAt(i));
			}
			*/
			
			var bmd:BitmapData = bm.bitmapData;
			var clr:uint = bmd.getPixel(x, y);
			return clr;
		}
	}
}
