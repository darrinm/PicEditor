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
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;

	public class Snow extends UIComponent
	{
		private var _ptSize:Point = null;
		private static const knFlakes:Number = 100;
		private static const kmsFrameDuration:Number = 35;
		private var _tmrAnimate:Timer = null;
		
		public var playing:Boolean = true;
		
		public function Snow()
		{
			super();
			addEventListener(ResizeEvent.RESIZE, OnResize);
			_tmrAnimate = new Timer(kmsFrameDuration);
			_tmrAnimate.start();
			_tmrAnimate.addEventListener( TimerEvent.TIMER, function(evt:TimerEvent):void { _moveSnow() } );
			mouseEnabled = false;
			mouseChildren = false;
			mouseFocusEnabled = false;
		}
		
		public override function set width(value:Number):void {
			super.width = value;
			invalidateProperties();
		}

		public override function set height(value:Number):void {
			super.height = value;
			invalidateProperties();
		}
		
		private function OnResize(evt:Event=null): void {
			invalidateProperties();
		}
		
		protected override function commitProperties():void {
			super.commitProperties();
			if (!sizeValid) {
				UpdateSize();
			}
		}
		
		private function GetSize(): Point {
			return new Point(width, height);
		}
		
		private function get sizeValid(): Boolean {
			if (_ptSize == null)
				return false;
			return _ptSize.equals(GetSize());
		}
		
		private function CreateFlakes(): void {
			for (var i:Number = 0; i < knFlakes; i++) {
				var flk:SnowFlake = new SnowFlake(_ptSize);
				this.addChild(flk);
			}
		}
		
		private function UpdateSize(): void {
			_ptSize = GetSize();
			if (_ptSize.x <= 0 || _ptSize.y <= 0)
				return;
			if (numChildren == 0) {
				CreateFlakes();
			} else {
				for (var i:Number = 0; i < numChildren; i++) {
					var flk:SnowFlake = getChildAt(i) as SnowFlake;
					flk.parentSize = _ptSize;
					flk.ResetSoon(4000);
				}
			}
		}

		private function _moveSnow():void {
			if (!playing) return;
			for (var i:Number = 0; i < numChildren; i++) {
				var flk:SnowFlake = getChildAt(i) as SnowFlake;
				flk.Move();			
			}
		}
	}
}