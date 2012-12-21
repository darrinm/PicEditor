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
	import mx.controls.TextInput;
	import mx.managers.IFocusManager;
	import flash.display.DisplayObject;
	import flash.events.Event;

	public class NoTipTextInputBase extends TextInputPlusBase
	{
	    private var _strError:String = "";
		private var _fErrorStringChanged:Boolean = false;
		private var _fSaveBorderColor:Boolean = true;
	    private var _clrOrigBorderColor:Number;
	
		[Bindable (event="errorStringChanged")]
		public override function get errorString():String {
			return _strError;
		}

		// Reimplement private methods of UIControl, minus the error tip part.
		public override function set errorString(value:String):void {
			if (value == null) value = "";
			_strError = value;
	        _fErrorStringChanged = true;
	        invalidateProperties();
	        dispatchEvent(new Event("errorStringChanged"));
		}
		
	    protected override function commitProperties():void {
	    	super.commitProperties();
	    	if (_fErrorStringChanged) {
	    		// SetBorderColorForErrorString();
	    	}
	    }
	
	    private function SetBorderColorForErrorString():void
	    {
	        if (!_strError || _strError.length == 0)
	        {
	            setStyle("borderColor", _clrOrigBorderColor);
	            _fSaveBorderColor = true;
	        }
	        else
	        {
	            // Remember the original border color
	            if (_fSaveBorderColor)
	            {
	                _fSaveBorderColor = false;
	                _clrOrigBorderColor = getStyle("borderColor");
	            }
	
	            setStyle("borderColor", getStyle("errorColor"));
	        }
	
	        styleChanged("themeColor");
	
	        var focusManager:IFocusManager = focusManager;
	        var focusObj:DisplayObject = focusManager ?
	                                     DisplayObject(focusManager.getFocus()) :
	                                     null;
	        if (focusManager && focusManager.showFocusIndicator &&
	            focusObj == this)
	        {
	            drawFocus(true);
	        }
	    }
	}
}