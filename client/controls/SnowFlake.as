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
package controls {

	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.system.*;
	import flash.utils.Timer;
		
		
	public class SnowFlake extends Sprite {
		public var gravity:Number;
		public var wind:Number;
		
		private var _nWidth:Number;
		private var _nHeight:Number;
		
		private var _tmrReset:Timer = null;
		
		public function SnowFlake(ptParentSize:Point) {
			gravity = Math.random() * 2 + 1;
			wind = Math.random() * 4 - 1.5;
		
			// draw the snowflake
			var mat:Matrix = new Matrix();
			mat.createGradientBox(10, 10);
			graphics.beginGradientFill(GradientType.RADIAL,
										[0xFFFFFF, 0xFFFFFF],
										[1.0, 0],
										[0, 255],
										mat );
			graphics.drawEllipse( 0, 0, 10, 10 );
			graphics.endFill();
			parentSize = ptParentSize;
			Reset();
		}	
		
		public function set parentSize(ptParentSize:Point): void {
			_nWidth = ptParentSize.x;
			_nHeight = ptParentSize.y;
		}	
		
		public function ResetSoon(msMaxDelay:Number): void {
			if (_tmrReset == null) {
				var msDelay:Number = Math.random() * msMaxDelay;
				_msResetFadeTime = Math.random() * msDelay;
				_msStartToFadeTime = new Date().time + msDelay - _msResetFadeTime;
				_tmrReset = new Timer(msDelay, 1);
				_tmrReset.start();
				_tmrReset.addEventListener(TimerEvent.TIMER, OnResetTimer);
				_nStartAlpha = this.alpha;
//				trace("fade time: ", _nStartAlpha, _msStartToFadeTime, _msResetFadeTime);
			}
		}
		
		private var _msResetFadeTime:Number = 0;
		private var _msStartToFadeTime:Number = 0;
		private var _nStartAlpha:Number = 0;
		
		private function OnResetTimer(evt:Event=null): void {
			_tmrReset.stop();
			_tmrReset.removeEventListener(TimerEvent.TIMER, OnResetTimer);
			_tmrReset = null;
			_msResetFadeTime = 0;
			_msStartToFadeTime = 0;
			Reset();
		}

		public function Reset():void {	
			this.alpha = (40+Math.random()*40)/100;
			this.x = -(_nWidth/2)+Math.random()*(1.5*_nWidth); 	
			this.y = -(_nHeight/2)+Math.random()*(1.5*_nHeight);
			this.scaleX = this.scaleY = Math.random() * 0.5 + 0.5;
		}
		
		public function Move():void {
			this.y += this.gravity;
			this.x += this.wind;
			
			this.gravity += Math.random() * 0.4 - 0.2;
			this.gravity = Math.min(Math.max(this.gravity, 1),3);
			
			this.wind += Math.random() * 0.8 - 0.4;
			this.wind = Math.min(Math.max(this.wind, -0.5),3);
			
			if (this.y > _nHeight + 10) {
				this.x = Math.random()*(2*_nWidth) - _nWidth;
				this.y = -20;
			}
			
			if (_msResetFadeTime != 0) {
				var msNow:Number = new Date().time;
				if (msNow > _msStartToFadeTime) {
					this.alpha = _nStartAlpha * (_msStartToFadeTime + _msResetFadeTime - msNow) / _msResetFadeTime;
				} 
			}
		}
	}
}
