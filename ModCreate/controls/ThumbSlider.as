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
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;

	/**
	 * Dispatched when a thumb value changes
	 */
	[Event(name="change", type="flash.events.Event")]
	[Event(name="edited", type="flash.events.Event")]

	public class ThumbSlider extends UIComponent
	{
		private var _nThumbWidth:Number = 13;
		private var _nThumbHeight:Number = 16;
		
		private var _nValMin:Number = 0;
		private var _nValMax:Number = 255;
		
		private var _nMaxOverlap:Number = 4;
		
		private var _fThumbPosValid:Boolean = false;
		
		protected var _aThumbs:Array = [];
		
		private var _nWidthDrawn:Number = 0;
		private var _nHeightDrawn:Number = 0;
		
		public function ThumbSlider(): void {
			_aThumbs.push(new Thumb(this, 0));
			_aThumbs.push(new Thumb(this, 1));
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
		}
		
		protected function OnMouseDown(evt:MouseEvent): void {
			// Find the nearest thumb and pass the event to it
			if (_aThumbs && _aThumbs.length) {
				var thNearest:Thumb = _aThumbs[0];
				var nNearestDist:Number = thNearest.DistFrom(evt);
				for each (var th:Thumb in _aThumbs) {
					var nDist:Number = th.DistFrom(evt);
					if (nDist < nNearestDist) {
						nNearestDist = nDist;
						thNearest = th;
					}
				}
				thNearest.OnMouseDown(evt);
			}
		}
		
		public function Reset(): void {
			for (var i:Number = 0; i < _aThumbs.length; i++) {
				var nVal:Number = _nValMin + i * (_nValMax - _nValMin) / (_aThumbs.length - 1);
				_aThumbs[i].x = valToX(nVal);
			}
		}
		
		// Given a thumb x position, return the value
		protected function xToVal(n:Number): Number {
			return _nValMin + (n * (_nValMax - _nValMin) / thumbSpace);
		}
		
		// Given a value, return a thumb x position
		protected function valToX(n:Number): Number {
			return Math.round(thumbSpace * (n - _nValMin) / (_nValMax - _nValMin));
		}
		
		[Bindable (event="change")]
		public function set leftVal(n:Number): void {
			leftThumb.x = valToX(n);
			invalidateThumbPosition();
		}

		public function get leftVal(): Number {
			return xToVal(leftThumb.x);
		}
		
		[Bindable (event="change")]
		public function set rightVal(n:Number): void {
			rightThumb.x = valToX(n);
			invalidateThumbPosition();
		}

		public function get rightVal(): Number {
			return xToVal(rightThumb.x);
		}
		
		
		public function get leftThumb():Thumb {
			return _aThumbs[0] as Thumb;
		}
		
		public function get rightThumb():Thumb {
			return _aThumbs[_aThumbs.length-1] as Thumb;
		}
		
		public function set rightThumbSource(str:String): void {
			rightThumb.source = str;
		}
		
		public function set leftThumbSource(str:String): void {
			leftThumb.source = str;
		}
		
	    override protected function createChildren():void {
	    	for (var i:Number = 0; i < _aThumbs.length; i++) {
		    	addChild(_aThumbs[i]);
		    	(_aThumbs[i] as Thumb).addEventListener("change", OnThumbMove);
		    	_aThumbs[i].x = i * thumbSpace / (_aThumbs.length-1);
		    }
	    }
		
		public override function set width(n:Number): void {
			super.width = n;
			invalidateThumbPosition();
		}
		
		protected function invalidateThumbPosition(): void {
			_fThumbPosValid = false;
			invalidateDisplayList();			
		}
		
		private function get thumbSpace(): Number {
			return width - _nThumbWidth;
		}
		
		override protected function measure():void {
			super.measure();
			measuredMinWidth = _nThumbWidth * 2;
			measuredHeight = measuredMinHeight = _nThumbHeight;
		}
		
		protected function OnThumbMove(evt:Event = null): void {
			// a thumb has moved
			invalidateThumbPosition();
			dispatchEvent(new Event("edited"));
		}
		
		private function positionThumbs(): void {
			if (!_aThumbs || _aThumbs.length < 1) return;
			// Size the thumbs
			var i:Number;
			var thPrev:Thumb = null;
			var th:Thumb = null;
			var thNext:Thumb = _aThumbs[0];
			for (i = 0; i < _aThumbs.length; i++) {
				// Shift thumbs
				thPrev = th;
				th = thNext;
				if ((i+1) < _aThumbs.length) thNext = _aThumbs[i+1];
				else thNext = null;

				th.width = _nThumbWidth;
				th.height = _nThumbHeight;
				if (thPrev == null) {
					th.xMin = 0;
				} else {
					th.xMin = thPrev.x + _nThumbWidth - _nMaxOverlap;
				}
				if (thNext == null) {
					th.xMax = thumbSpace;
				} else {
					th.xMax = thNext.x - _nThumbWidth + _nMaxOverlap;
				}
			}
			dispatchEvent(new Event("change"));
		}
		
		private function validateThumbPosition(): void {
			if (!_fThumbPosValid) {
				positionThumbs();
				_fThumbPosValid = true;
			}
		}
		
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number): void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (_nWidthDrawn != unscaledWidth || _nHeightDrawn != unscaledHeight) {
				graphics.clear();
				graphics.beginFill(0xffffff, 0);
				graphics.drawRect(0,0,unscaledWidth,unscaledHeight);
				_nWidthDrawn = unscaledWidth;
				_nHeightDrawn = unscaledHeight;
			}
			validateThumbPosition();
		}
		
	}
}