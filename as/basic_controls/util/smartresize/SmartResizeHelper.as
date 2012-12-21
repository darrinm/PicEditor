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
package util.smartresize
{
	import flash.events.Event;
	import flash.text.TextLineMetrics;
	import controls.ResizingButtonBarButton;
	
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.core.UITextFormat;
	import mx.events.FlexEvent;
	import mx.states.IOverride;
	import mx.states.SetProperty;
	import mx.states.SetStyle;
	import mx.states.State;
	
	import picnik.util.LocaleInfo;

	public class SmartResizeHelper
	{
		public var measuring:Boolean = false;
		
		private var _isrTarget:ISmartResizeComponent = null;
		private var _uicTarget:UIComponent = null;
		private var _fMeasuredSizeIsMinSize:Boolean = false;
		
		private var _nForcedSize:Number = NaN; // No forced size by default
		
		private var _nCurrentSize:Number = -1; // Default is largest size
		private var _nLargestSize:Number = -1;
		private var _nSmallestSize:Number = 10;
		private var _fInitialized:Boolean = false;
		private var _obStates:Object = null;
		
		private var _nMeasuredWidth:Number;
		private var _nMeasuredHeight:Number;
		public var measuredMinWidth:Number;
		public var measuredMinHeight:Number;
		
		private var _nPrevWidth:Number = -1;
		private var _nPrevHeight:Number = -1;

		private const kastrOptionalPropertyFields:Array = ['text','width','label','iconVisible'];
		private const kastrOptionalStyleFields:Array = ['paddingLeft','paddingRight','horizontalGap','fontSize'];
		
		private var _aobPendingStyleChanges:Array = [];

		private var _nStateSet:Number = -1;
		private var _fDisplayInvalid:Boolean = false;
		public var ignoreHeight:Boolean = false;
		
		public function SmartResizeHelper(isrTarget:ISmartResizeComponent): void {
			_isrTarget = isrTarget;
			_uicTarget = isrTarget as UIComponent;
            if (_uicTarget.initialized)
            	init();
            else
                _uicTarget.addEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
		}
		
		public function invalidateDisplay(): void {
			_fDisplayInvalid = true;
		}
		
		public function validateDisplayList(): void {
			if (_fDisplayInvalid) {
				_fDisplayInvalid = false;
				measureChildren();
			}
		}
		
		private function testFontLoad(): void {
			if (_fFontLoaded == true) return;
			
			var lm:TextLineMetrics = getDefaultLineMetrics();
			if (_lmPrev != null) {
				if ((_lmPrev.width != lm.width) || (_lmPrev.height != lm.height)) {
					_fFontLoaded = true;
					obCache = {};
					obCache2 = {};
					return;
				}
			}
			_lmPrev = lm;
		}
		
		private static var _fFontLoaded:Boolean = false;
		private var _lmPrev:TextLineMetrics = null;
		
		private function getDefaultLineMetrics(): TextLineMetrics {
			var uitf:UITextFormat = _uicTarget.determineTextFormatFromStyles();
			uitf.align = null;
			uitf.bold = false;
			uitf.indent = null;
			uitf.italic = null;
			uitf.kerning = null;
			uitf.leading = null;
			uitf.letterSpacing = null;
			uitf.leftMargin = null;
			uitf.rightMargin = null;
			uitf.size = 21;
			uitf.tabStops = null;
			uitf.underline = null;
			return uitf.measureText('');
		}
		
		public function set measuredWidth(n:Number): void {
			_nMeasuredWidth = n;
		}
		
		public function get measuredWidth(): Number {
			if (isNaN(_uicTarget.percentWidth)) {
				return Math.min(_uicTarget.maxWidth, Math.max(_uicTarget.minWidth, _nMeasuredWidth));
			}
			return _nMeasuredWidth;
		}
		
		public function set measuredHeight(n:Number): void {
			_nMeasuredHeight = n;
		}
		
		public function get measuredHeight(): Number {
			if (isNaN(_uicTarget.percentHeight)) {
				return Math.min(_uicTarget.maxHeight, Math.max(_uicTarget.minHeight, _nMeasuredHeight));
			}
			return _nMeasuredHeight;
		}
		
		public function setAutoStyleChange(strStyle:String, nChange:Number): void {
			if (_fInitialized) {
				createStyleChange(strStyle, nChange);
			} else {
				_aobPendingStyleChanges.push({strStyle:strStyle, nChange:nChange});
			}
		}

		private function createStyleChange(strStyle:String, nChange:Number): void {
			var nStyleVal:Number = _uicTarget.getStyle(strStyle);
			for (var i:Number = _nLargestSize; i < _nSmallestSize; i++) {
				if (strStyle == "fontSize" && LocaleInfo.SmallFontSize(nStyleVal) > nStyleVal) break;
				addOverride(i, new SetStyle(null, strStyle, nStyleVal));
				nStyleVal += nChange;
			}
		}
		
		public function set measuredSizeIsMinSize(f:Boolean): void {
			if (_fMeasuredSizeIsMinSize != f) {
				_fMeasuredSizeIsMinSize = f;
				_uicTarget.invalidateSize();
			}
		}
		
		private var _fStateChanging:Boolean = false;
		
		public function invalidateSize(): void {
			if (!_fStateChanging) {
				obCache = null;
				obCache2 = null;
			}
			/* _nPrevWidth = -1;
			_nPrevHeight = -1; */
		}
		
		public function get isContainer(): Boolean {
			return _uicTarget is Container;
		}
		
		public function set currentSize(n:Number): void {
			_nCurrentSize = n;
			if (_fInitialized) setStateForSize(n);
		}
		
		public function get currentSize(): Number {
			return _nCurrentSize;
		}
		
		
		private function setStateForSize(n:Number): void {
			_fStateChanging = true;
			
			// First, set child states (force them to this size)
			var i:Number;
			if (isContainer) {
				for (i = 0; i < _uicTarget.numChildren; i++) {
					var isrChild:ISmartResizeComponent = _uicTarget.getChildAt(i) as ISmartResizeComponent;
					if (isrChild) {
						isrChild.smartResizeHelper.forcedSize = n;
					}
				}
			}
			_nStateSet = n;
			
			// Choose the target size if it exists. Otherwise,
			// find the next largest size for which we have a state.
			for (i = n; i >= _nLargestSize; i--) {
				if (i in _obStates) {
					_uicTarget.currentState = _obStates[i];
					_fStateChanging = false;
					return;
				}
			}
			_fStateChanging = false;
			throw new Error("State not found: " + n);
		}
		
		private function creationCompleteHandler(evt:Event): void {
			init();
		}
		
		private function init(): void {
			_obStates = {};
			_obStates[-1] = '';
			var st:State;
			
			// Insert size states for auto style changes
			for each (var obStyleChange:Object in _aobPendingStyleChanges) {
				createStyleChange(obStyleChange.strStyle, obStyleChange.nChange);
			}
			_aobPendingStyleChanges.length = 0;
			
			
			for each (st in _uicTarget.states) {
				_obStates[Number(st.name)] = st.name;
			}
			
			// Make sure states are based on eachother in linear order
			var strPrevState:String = "";
			for (var i:Number = 0; i <= _nSmallestSize; i++) {
				st = getStateByNum(i);
				if (st) {
					st.basedOn = strPrevState;
					strPrevState = st.name;
				}
			}
			
			// adjustStateForSize(_uicTarget.width, _uicTarget.height);
			_fInitialized = true;
			if (_uicTarget.parent as UIComponent) {
				(_uicTarget.parent as UIComponent).invalidateDisplayList();
				(_uicTarget.parent as UIComponent).invalidateSize();
			}

			_uicTarget.invalidateSize();
		}
		
		public function set forcedSize(nSize:Number): void {
			_nForcedSize = nSize;
			
			// If this size is smaller than the max width/height, choose a smaller size.
			currentSize = _nForcedSize;
			var msCurrentMeasurements:Measurements = getStateMeasurements();
 			// State doesn't fit. Go as small as we can until we fit
			while (msCurrentMeasurements.minWidth > _uicTarget.maxWidth || msCurrentMeasurements.minHeight > _uicTarget.maxHeight ) {
				if (!chooseNextSmallerState()) break; // No smaller states exist
				msCurrentMeasurements = getStateMeasurements();
			}
		}

		private function get sizeIsForced(): Boolean {
			return !isNaN(_nForcedSize);
		}

		// Returns null if state is not defined.
		protected function getStateByNum(n:Number, fCreateIfNotFound:Boolean=false): State {
			var st:State = null;
			for each (st in _uicTarget.states) {
				if (st.name == n.toString()) {
					return st;
				}
			}
			if (fCreateIfNotFound) {
				st = new State();
				st.name = n.toString();
				return st;
			}
			return null; // Not found
		}
		
		public function addOverride(nState:Number, iovr:IOverride): void {
			var st:State = getStateByNum(nState);
			if (st == null) {
				st = new State();
				st.name = nState.toString();
				if (nState > 0) {
					for (var i:Number = nState-1; i >= 0; i--) {
						var stPrev:State = getStateByNum(i);
						if (stPrev) {
							st.basedOn = stPrev.name;
							break;
						}
					}
				}
				_uicTarget.states.push(st);
			}
			
			// Now we have a state. Add our text set prop to the overrides
			st.overrides.push(iovr);
		}
		
		public function adjustStateForSize(w:Number, h:Number): void {
			if (!_fInitialized) return;
			if (_fInitialized && !sizeIsForced && (w != _nPrevWidth || h != _nPrevHeight)) {
				_nPrevWidth = w;
				_nPrevHeight = h;
				var msCurrentMeasurements:Measurements = getStateMeasurements();
  				if (msCurrentMeasurements.minWidth > w || (!ignoreHeight && msCurrentMeasurements.minHeight > h)) {

 					// State doesn't fit. Go as small as we can until we fit
					while (msCurrentMeasurements.minWidth > w || (!ignoreHeight && msCurrentMeasurements.minHeight > h)) {
						if (!chooseNextSmallerState()) break; // No smaller states exist
						msCurrentMeasurements = getStateMeasurements();
					}
				} else {
					// Try a larger size to see if it fits
					var nLargestStateWhichFits:Number = currentSize;
					
					// Loop while it fits
					while (msCurrentMeasurements.minWidth <= w && (ignoreHeight || msCurrentMeasurements.minHeight <= h)) {
						nLargestStateWhichFits = currentSize;
						if (!chooseNextLargerState()) break; // No larger states exist
						msCurrentMeasurements = getStateMeasurements();
					}
					if (currentSize != nLargestStateWhichFits) {
						currentSize = nLargestStateWhichFits;
					}
				}
			}
		}
		
		protected var obCache:Object = null;
		private var obCache2:Object = null;
		
		protected function getCacheKey(): String {
			var strKey:String = "";
			if (isContainer) {
				strKey = _nStateSet.toString();
			} else {
				strKey = _uicTarget.currentState;
			}
			if (!strKey || strKey.length == 0)
				strKey = "-1";
			return strKey;
		}
		
		
		protected function getStateMeasurements(): Measurements {
			// testFontLoad();
			if (!_fInitialized) {
				var msDefault:Measurements = new Measurements();
				msDefault = _isrTarget.getMeasurementsForCurrentState();
				//msDefault.width = 10;
				//msDefault.height = 10;
				msDefault.minWidth = 2;
				msDefault.minHeight = 2;
				return msDefault;
			}
			
			var strKey:String = getCacheKey();
			
			// Cached version
			if (obCache && strKey in obCache) {
				return obCache[strKey] as Measurements;
			}
			var ms:Measurements = _isrTarget.getMeasurementsForCurrentState();
			if (!obCache) obCache = new Object();
			obCache[strKey] = ms;
			
			return ms;
			
			// DEBUG: This version tests the cache but does not use it.
			/*
			var ms:Measurements = _isrTarget.getMeasurementsForCurrentState();
			
			var fSetCache:Boolean = true;
			if (obCache && strKey in obCache) {
				// Compare the previous version
				var ms2:Measurements = obCache[strKey] as Measurements;
				if ((ms2.height != ms.height) ||
					    (ms2.width != ms.width) ||
					    (ms2.minHeight != ms.minHeight) ||
					    (ms2.minWidth != ms.minWidth)) {
				    // Found an unexpected change.
				    trace("******* ERROR *********");
				    trace(_uicTarget + ": measured widths changed for state " + _nCurrentSize + ", " + _uicTarget.currentState);
				    trace("old: " + ms2.width + ", " + ms2.height + ", " + ms2.minWidth + ", " + ms2.minHeight);
				    trace("new: " + ms.width + ", " + ms.height + ", " + ms.minWidth + ", " + ms.minHeight);
				    trace(obCache2[strKey]);
					ms = _isrTarget.getMeasurementsForCurrentState();
				    try {
				    	throw new Error();
				    } catch (e2:Error) {
				    	var strOut:String = "new stack {";
				    	if (_uicTarget is Label) strOut += "'" + (_uicTarget as Label).text + "'";
				    	strOut += "}" + e2.getStackTrace();
				    	trace(strOut);
				    }
				} else {
					fSetCache = false; // same values, don't update the cache.
				}
			}
			if (fSetCache) {
				// Not yet in cache. Add it.
				if (!obCache) {
					obCache = new Object();
					obCache2 = new Object();
				}
				try {
					throw new Error();
				} catch (e:Error) {
			    	var strOut2:String = "old stack {";
			    	if (_uicTarget is Label) strOut2 += "'" + (_uicTarget as Label).text + "'";
			    	strOut2 += "}" + e.getStackTrace();
					obCache2[strKey] = strOut2;
				}
				obCache[strKey] = ms;
			}
			return ms;
			*/
		}
		
		// Returns false if we are at the smallest state.
		public function chooseNextSmallerState(): Boolean {
			var nSmallerSize:Number = getNextSmallerState(currentSize);
			if (nSmallerSize == -10) return false;
			currentSize = nSmallerSize;
			return true; // Found a smaller size
		}
		
		// Returns -10 if there is none.
		public function getNextSmallerState(nState:Number): Number {
			if (nState >= _nSmallestSize) return -10; // No smaller sizes
			for (var i:Number = nState+1; i <= _nSmallestSize; i++) {
				if (i in _obStates || isContainer) {
					return i;
				}
			}
			return -10; // No size found
		}
		
		// Returns false if we are at the smallest state.
		public function chooseNextLargerState(): Boolean {
			if (currentSize <= _nLargestSize) return false; // No larger sizes
			for (var i:Number = currentSize-1; i >= _nLargestSize; i--) {
				if (i in _obStates || isContainer) {
					currentSize = i;
					return true; // Found a larger size
				}
			}
			return false; // No size found
		}

	    public function measureChildren():void {
	    	if (!_fInitialized) return;
	    	
	    	if (isContainer) {
				for (var i:Number = 0; i < _uicTarget.numChildren; i++) {
					var isrChild:ISmartResizeComponent = _uicTarget.getChildAt(i) as ISmartResizeComponent;
					if (isrChild) {
						isrChild.smartResizeHelper.measure();
					}
				}
	    	}
	    }
	   
		public function measure(): void {
			// Measure sets:
			// measuredWidth = preferred width (measuredWidth at largest size or target size
			// measuredMinWidth = measuredMinWidth at smallest size or target size
			// normally for labels, measuredWidth == measuredMinWidth
			var ms:Measurements;
			if (sizeIsForced || !_fInitialized) {
				ms = getStateMeasurements();
				measuredHeight = ms.height;
				measuredWidth = ms.width;
				measuredMinHeight = ms.minHeight;
				measuredMinWidth = ms.minWidth;
			} else {
				// Combine the smallest size with the largest size.
				// UNDONE: Do we need to optimize this for cases where
				// smallest == current, largest == current, or all three are the same?
				setStateForSize(_nLargestSize);
				
				// We need a way to fource our states to "update" their sizes
				ms = getStateMeasurements();
				measuredWidth = ms.width;
				measuredHeight = ms.height;
				
				var nLargestSizeBelowMaxSize:Number = _nLargestSize;

				while ((_uicTarget.maxWidth < ms.width) || (_uicTarget.maxHeight < ms.height)) {
					// Try a smaller state until we find one which fits.
					var nNextSmallerSize:Number = getNextSmallerState(nLargestSizeBelowMaxSize);
					if (nNextSmallerSize == -10) break;
					nLargestSizeBelowMaxSize = nNextSmallerSize;
					setStateForSize(nNextSmallerSize);
					
					// We need a way to fource our states to "update" their sizes
					ms = getStateMeasurements();
					measuredWidth = ms.width;
					measuredHeight = ms.height;
				}

				setStateForSize(_nSmallestSize);
				ms = getStateMeasurements();
				measuredMinWidth = ms.minWidth;
				measuredMinHeight = ms.minHeight;
				
				setStateForSize(_nCurrentSize);
			}
			if (_fMeasuredSizeIsMinSize) {
				measuredMinWidth = measuredWidth;
				measuredMinHeight = measuredHeight;
			}
		}
		
		// Add our text_ properties as state overrides	   
		public function initialize():void
		{
			if (_uicTarget.initialized)
				return;
			
			// 	create extra set property calls based on the value of text_0, text_1, etc.
			for (var i:Number = 0; i < 10; i++) {
				var strType:String;
				for each (strType in kastrOptionalPropertyFields) {
					if (("has_" + strType + "_property") in _uicTarget) {
						if (_uicTarget[strType + "_" + i] != null) {
							// INDONE: This does not support binding. We have two options:
							// 1: find this and set it again when it changes
							// 2: Keep the set property locally and set it whenever our text changes.
							addOverride(i, new SetProperty(null, strType, _uicTarget[strType + "_" + i]));
						}
					}
				}
				for each (strType in kastrOptionalStyleFields) {
					if (("has_" + strType + "_style") in _uicTarget) {
						if (_uicTarget[strType + "_" + i] != null) {
							// INDONE: This does not support binding. We have two options:
							// 1: find this and set it again when it changes
							// 2: Keep the set property locally and set it whenever our text changes.
							addOverride(i, new SetStyle(null, strType, _uicTarget[strType + "_" + i]));
						}
					}
				}
			}
		}
	}
}
