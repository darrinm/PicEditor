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
	import errors.InvalidBitmapError;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BevelFilter;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import util.VBitmapData;

	// Do not use this class directly - exceptions will result
	// Instead, use a subclass like HSBColorSwatch
	
	[Event(name="change", type="flash.events.Event")]
	
	public class ColorSwatchBase extends UIComponent
	{
		[Bindable] public var _imgThumb:Image;
		
		protected var _clr:Number;
		protected var _fMouseDown:Boolean = false;

		protected var _fMouseOver:Boolean = false;
		protected var _spr:Sprite = new Sprite();

		protected var _bm:Bitmap = null;
		protected var _bmd:BitmapData = null;

		// This is here instead of in an MXML file because of the @#$&*^! MXML compiler bug
		// that sometimes creeps up when .as inherits from .mxml
		private var _aflt:Array = [
			new DropShadowFilter(1, 90, 0, 0.4, 1.8, 1.8, 1, 3, true),
			new DropShadowFilter(1, 90, 0xffffff, 1, 1, 1, 1, 3)
		]

		public function ColorSwatchBase()  {
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			filters = _aflt;
		}
	
		// Override this in a child class
		// See HSBColorSwatch for an example
		protected function PointFromColor(clr:Number): Point {
			throw new Error("PointFromColor called in ColorSwatchBase. Use a child of ColorSwatch which overrides this method");
			return new Point(width/2, height/2);
		}
		
		// Override this in a child class
		// See HSBColorSwatch for an example
		protected function ColorFromPoint(x:Number, y:Number): Number {
			throw new Error("ColorFromPoint called in ColorSwatchBase. Use a child of ColorSwatch which overrides this method");
			return 0;
		}

		
		[Inspectable]
		[Bindable(event="changeColor")]
		public function get color(): Number {
			return _clr;
		}
		
		public function set color(clr:Number): void {
			if (_clr != clr) {
				_color = clr;
				updateThumb(clr, PointFromColor(_clr));
			}
		}

		protected function set _color(clr:Number): void {
			_clr = clr;
			dispatchEvent(new Event("changeColor"));
			dispatchEvent(new Event("change"));
		}

		protected function updateThumb(clr:Number, pt:Point): void {
			_spr.graphics.clear();
			_spr.graphics.beginFill(0xffffff);
			_spr.graphics.drawCircle(6,6,6);
			_spr.graphics.beginFill(clr);
			_spr.graphics.drawCircle(6,6,4);
			if (pt != null) {
				_spr.x = pt.x - 6;
				_spr.y = pt.y - 6;
			}
			var aflt:Array = new Array();
			aflt.push(new DropShadowFilter(1, 90, 0.0, 0.5));
			_spr.filters = aflt;
		}
		
		protected override function commitProperties():void {
			if (true) {
				if (_bmd != null) _bmd.dispose();
				try {
					_bmd = new VBitmapData(width, height, false, 0xffffffff, "Color Swatch");
				} catch (e:InvalidBitmapError) {
					// not much we can do ... bail
					return;	
				}			
				if (_bm == null) {
					_bm = new Bitmap();
					addChildAt(_bm, 0);
					_bm.x = 0;
					_bm.y = 0;
				}
				_bm.bitmapData = _bmd;
				_bm.width = width;
				_bm.height = height;
				
				// Update our graphics.
				for (var x:Number = 0; x < width; x++) {
					for (var y:Number = 0; y < height; y++) {
						_bmd.setPixel(x, y, ColorFromPoint(x,y));
					}
				}
			}
		}
		
		protected function OnInitialize(evt:FlexEvent): void {
			addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
			addEventListener(MouseEvent.ROLL_OVER, OnRollOver);
			updateThumb(_clr, PointFromColor(_clr));
			addChild(_spr);
		}
		
		protected function updateColorFromStagePoint(ptClicked:Point): void {
			var ptIn:Point = ptClicked;
			ptClicked = globalToLocal(ptClicked);
			var x:Number = ptClicked.x;
			var y:Number = ptClicked.y;
			if (x < 0) x = 0;
			if (y < 0) y = 0;
			if (x >= width) x = width-1;
			if (y >= height) y = height-1;
			_color = ColorFromPoint(x,y);
			updateThumb(color, new Point(x, y));
		}
		
		protected function OnMouseDown(evt:MouseEvent): void {
			_fMouseDown = true;
			updateColorFromStagePoint(new Point(evt.stageX, evt.stageY));
		}
		
		protected function OnMouseUp(evt:MouseEvent): void {
			_fMouseDown = false;
		}

		protected function OnRollOut(evt:MouseEvent): void {
			stage.addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
		}
		protected function OnRollOver(evt:MouseEvent): void {
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
		}
		
		protected function OnMouseMove(evt:MouseEvent): void {
			if (_fMouseDown) {
				updateColorFromStagePoint(new Point(evt.stageX, evt.stageY));
				evt.updateAfterEvent();
			}
		}
		
	}
}