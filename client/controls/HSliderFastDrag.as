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
// HSliderPlus is exactly the same as Flex's mx.controls.HSlider except that it
// forces the thumb to use SliderThumb subclass that hardwires the dimensions
// needed by the PicnikTheme. It also makes sure the thumbs are above the tick
// marks.

package controls {
	import mx.events.SliderEvent;
	import mx.controls.sliderClasses.SliderThumb;
	import mx.core.UIComponent;
	import mx.events.SliderEventClickTarget;
	import flash.events.MouseEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.Event;
	import mx.events.FlexEvent;
	import mx.core.mx_internal;

	use namespace mx_internal;
	
	public class HSliderFastDrag extends HSliderPlus {
		private var _fFastLiveDragging:Boolean = true;
		private var _tmr:Timer;
		private var _nSliderDelay:Number = 20; // miliseconds
		private var _nPrevValue:Number = 0;
		private var _nPrevPrevValue:Number = 0;
		private const knUpdateThresholdVariance:Number = 20; // Ignore this much variance in the update speed
		private var _nUpdateThreshold:Number = 250; // Ignore this much variance in the update speed
		private var _nUpdateSpeed:Number = -1;
		private var _nLiveValue:Number = 0;
		
		public function HSliderFastDrag() {
			super();
			liveValue = value;
			_tmr = new Timer(200, 0);
			_tmr.addEventListener(TimerEvent.TIMER, OnTimer);
			liveDragging = true;

			addEventListener(SliderEvent.THUMB_DRAG, OnThumbDrag);
			addEventListener(SliderEvent.THUMB_PRESS, OnThumbPress);
			addEventListener(SliderEvent.THUMB_RELEASE, OnThumbRelease);
			addEventListener(SliderEvent.CHANGE, OnChange);
			addEventListener(FlexEvent.VALUE_COMMIT, OnChange);

		}
		
		[Bindable (event="liveValueChange")]
		public function get liveValue(): Number {
			return _nLiveValue;
		}
		
		public function set liveValue(nLiveValue:Number): void {
			if (_nLiveValue != nLiveValue) {
				_nLiveValue = nLiveValue;
				dispatchEvent(new Event("liveValueChange"));
			}
		}
		
		public function OnChange(evt:Event): void {
			liveValue = value;
		}
		
		public function set timerDelay(nTimerDelay:Number): void {
			_tmr.delay = nTimerDelay;
		}
		
		public function set updateSpeed(nUpdateSpeed:Number): void {
			_nUpdateSpeed = nUpdateSpeed;
		}
		
		public function set sliderDelay(nSliderDelay:Number): void {
			_nSliderDelay = nSliderDelay;
		}
		
		public function set fastLiveDragging(fFastLiveDragging:Boolean): void {
			_fFastLiveDragging = fFastLiveDragging;
		}

		public function get fastLiveDragging(): Boolean {
			return _fFastLiveDragging;
		}
		
		public function set updateThreshold(nUpdateThreshold:Number): void {
			_nUpdateThreshold = nUpdateThreshold;
		}

	    protected function OnThumbPress(evt:SliderEvent):void {
	    	// Start the timer
	    	_tmr.start()
	    }
	   
	    protected function OnThumbRelease(evt:SliderEvent):void {
	    	// Stop the timer
	    	_tmr.stop();
	    }
	   
	    protected function OnTimer(evt:TimerEvent):void {
	    	// Timer event.
	    	if (!liveDragging) {
	    		var nVal:Number = GetThumbVal(0);
	    		if (nVal != _nPrevValue || nVal != _nPrevPrevValue ) {
	    			_nPrevPrevValue = _nPrevValue;
	    			_nPrevValue = nVal;
	    		} else {
	    			// Thumb pause. Update
	    			UpdateValueToThumb();
	    		}
	    	}
	    }
	   
	    protected function GetThumbVal(nPos:Number): Number {
	    	return getValueFromX(getThumbAt(0).xPosition);
	    }
	   
	    protected function UpdateValueToThumb(): void {
	        var nVal:Number = GetThumbVal(0);
        	if (value != nVal) {
        		value = nVal;

	            var evt2:SliderEvent = new SliderEvent(SliderEvent.CHANGE);
	            evt2.value = value;
	            evt2.thumbIndex = 0;
	            evt2.clickTarget = SliderEventClickTarget.THUMB;
	            evt2.triggerEvent = new MouseEvent(MouseEvent.CLICK);
	           
                dispatchEvent(evt2);
		        invalidateDisplayList();
	    		adjustLiveDragging();
        	}
	    }
	   
	    protected function adjustLiveDragging(): void {
	    	if (_nUpdateSpeed != -1) {
	    		// UNDONE: Add a threshold to keep it from flip-flopping
	    		var nDif:Number = _nUpdateSpeed - _nUpdateThreshold; // Positive means slow enough for live dragging.
	    		if (Math.abs(nDif) > knUpdateThresholdVariance) {
	    			// Avoid flip-flopping
	    			liveDragging = nDif < 0; // Negative numbers mean high speed (low update time), so live dragging is OK
	    		}
	    	}
	    }
	   
	    protected function OnThumbDrag(evt:SliderEvent):void {
			liveValue = GetThumbVal(0);
	    	if (liveDragging) {
	    		adjustLiveDragging();
	    	}
	    }
	}
}
