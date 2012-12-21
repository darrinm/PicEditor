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
package controls.shapeList
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.effects.AnimateProperty;
	import mx.effects.easing.Linear;
	import mx.effects.easing.Sine;

	[Event(name="complete", type="flash.events.Event")]
	
	public class RotatingImageStack extends Canvas
	{
		private var _astrUrls:Array = [];
		private var _nTransitionDuration:Number = 500;
		private var _nTransitionDelay:Number = 500;
		
		private var _fPlaying:Boolean = false;
		private var _fInitialized:Boolean = false;
		
		private var _nComplete:Number = 0;
		private var _effPlay:AnimateProperty;
		private var _nPosition:Number = 0;
		
		public var easingFunction:Function = Sine.easeInOut;
		
		public function RotatingImageStack()
		{
			_effPlay = new AnimateProperty(this);
			_effPlay.fromValue = 0;
			_effPlay.toValue = 1;
			_effPlay.property = "position";
			_effPlay.repeatCount = 0;
			_effPlay.easingFunction = Linear.easeNone;
		}
		
		public function get loaded(): Boolean {
			return _fInitialized;
		}
		
		public function play(): void {
			if (_fPlaying) return;
			_fPlaying = true;
			
			if (_fInitialized == false) throw new Error("must be initialized to play");
			UpdateDuration();
			if (_effPlay.isPlaying)
				_effPlay.resume();
			else
				_effPlay.play();
		}
		
		public function resetPosition(): void {
			_effPlay.stop();
			position = 0;
			_fPlaying = false;
		}
		
		public function set position(n:Number): void {
			if (_nPosition == n) return;
			_nPosition = n;
			
			// n goes from 0 to 1. Set our alphas accordingly.
			var nTimePerImage:Number = _nTransitionDelay + _nTransitionDuration;
			var nTotalTime:Number = nTimePerImage * numChildren;
			var iPos:Number = _nPosition * numChildren;
			if (iPos == numChildren) iPos = 0;
			var iPrimary:Number = Math.floor(iPos);
			var iNext:Number = (iPrimary + 1) % numChildren;
			var nPctFromPrimaryToNext:Number = iPos - iPrimary;
			var nPctTransition:Number = ((nPctFromPrimaryToNext * (_nTransitionDelay + _nTransitionDuration))
					- _nTransitionDelay ) / _nTransitionDuration;
			if (nPctTransition < 0) nPctTransition = 0;
			
			// Apply an easing function
			nPctTransition = easingFunction(nPctTransition, 0, 1, 1);

			var nAlphaPrimary:Number = 1 - nPctTransition;
			var nAlphaNext:Number = nPctTransition;
			
			for (var i:Number = 0; i < numChildren; i++) {
				var nAlpha:Number;
				if (i == iNext) nAlpha = nAlphaNext;
				else if (i == iPrimary) nAlpha = nAlphaPrimary;
				else nAlpha = 0;
				getChildAt(i).alpha = nAlpha;
			}
		}
		
		private function UpdateDuration(): void {
			_effPlay.duration = numChildren * (_nTransitionDelay + _nTransitionDuration);
		}
		
		public function set transitionDelay(n:Number): void {
			_nTransitionDelay = n;
			UpdateDuration();
		}
		
		public function set transitionDuration(n:Number): void {
			_nTransitionDuration = n;
			UpdateDuration();
		}
		
		public function pause(): void {
			if (!_fPlaying) return;
			_fPlaying = false;
			_effPlay.pause();
		}
		
		private var _fSlices:Boolean = false;
		
		public function set urls(ob:Object): void {
			if (ob is String) {
				ob = String(ob).split(',');
			}
			_astrUrls = ob as Array;
			
			if (_astrUrls && _astrUrls.length > 0 && _astrUrls[0].indexOf('|') > 0) {
				var astrParts:Array = _astrUrls[0].split('|');
				width = Number(astrParts[0]);
				height = Number(astrParts[1]);
			}

			_fInitialized = false;
			_nPosition = 0;
			_fPlaying = false;
			_effPlay.stop();
			removeAllChildren();

			invalidateProperties();
		}
		
		private function OnImageComplete(evt:Event): void {
			_nComplete += 1;
			TestForComplete();
		}
		
		private function TestForComplete(): void {
			if (!_fInitialized && _nComplete == numChildren) {
				_fInitialized = true;			
				UpdateDuration();
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		private function StopListening(uic:UIComponent): void {
			uic.removeEventListener(Event.COMPLETE, OnImageComplete);
			uic.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, OnImageError);
			uic.removeEventListener(IOErrorEvent.IO_ERROR, OnImageError);
		}
		
		private function OnImageError(evt:Event): void {
			trace("image load error: " + evt);
			var uic:UIComponent = evt.target as UIComponent;
			removeChild(uic);
			StopListening(uic);
			
			TestForComplete(); // The rest might be complete
		}
		
		override public function removeAllChildren():void {
			// Stop listening to the children.
			while (numChildren > 0) {
				var uic:UIComponent = removeChildAt(0) as UIComponent;
				StopListening(uic);
			}
		}
		
		private function CreateChildren(): void {
			var uic:UIComponent;
			var nAlpha:Number = 1;
			for each (var strUrl:String in _astrUrls) {
				if (_fSlices)
					uic = new ImageSlice();
				else
					uic = new Image();
				addChild(uic);
				uic.percentWidth = 100;
				uic.percentHeight = 100;
				uic['source'] = strUrl;
				uic.alpha = nAlpha;
				nAlpha = 0;
				uic.addEventListener(Event.COMPLETE, OnImageComplete);
				uic.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnImageError);
				uic.addEventListener(IOErrorEvent.IO_ERROR, OnImageError);
			}
		}
		
		override protected function commitProperties():void {
			super.commitProperties();
			if (_astrUrls.length > 0 && numChildren == 0 && !_fSlices) {
				_nComplete = 0;
				_fSlices = false;
				
				if (_astrUrls.length == 1 && _astrUrls[0].indexOf('|') != -1) {
					var astrParts:Array = _astrUrls[0].split('|', 3);
					if (astrParts.length == 3) {
						// width, height, bundle url
						_astrUrls = [];
						_fSlices = true;
						ImageSlice.LoadSlices(astrParts[2], new Point(Number(astrParts[0]), Number(astrParts[1])),
							function(obInfo:Object, strError:String): void {
								if (strError) {
									trace("Load failure: " + strError);
								} else {
									// Loaded. Continue
									astrParts.push(astrParts[2]);
									_astrUrls = [];
									for (var i:Number = 0; i < obInfo.numSlices; i++) {
										astrParts[2] = i;
										_astrUrls.push(astrParts.join('|'));
									}
									CreateChildren();
								}
							});
					}
				}
				if (!_fSlices) {
					CreateChildren();
				}
			}
		}
	}
}