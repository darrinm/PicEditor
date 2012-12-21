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
package util
{
	import flash.display.Sprite;
	
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	import mx.resources.ResourceBundle;

	public class PicnikAlert extends Alert
	{
		private var _fLocalized:Boolean = false;
		private var _aLocalizedKeys:Object = {
				        "okLabel":"okLabel",
				        "yesLabel":"yesLabel",
				        "noLabel":"noLabel",
				        "cancelLabel":"cancelLabel"};
		
		[ResourceBundle("controls")] static protected var _rb:ResourceBundle;  	
		
		public function PicnikAlert(): void {
			super();
			if (!_fLocalized) _Localize();
		}
		
		private function _Localize() : void {
			_fLocalized = true;
			for (var i:String in _aLocalizedKeys) {
				this[i] = Resource.getString("controls", _aLocalizedKeys[i]);
			}
		}

	    public static function show(text:String = "", title:String = "",
	                                flags:uint = 0x4 /* Alert.OK */,
	                                parent:Sprite = null,
	                                closeHandler:Function = null,
	                                iconClass:Class = null,
	                                defaultButtonFlag:uint = 0x4 /* Alert.OK */):Alert
	    {
	        var modal:Boolean = (flags & Alert.NONMODAL) ? false : true;
	
	        if (!parent)
	            parent = Sprite(Application.application);  
	       
	        var alert:Alert = new Alert();
	
	        if (flags & Alert.OK||
	            flags & Alert.CANCEL ||
	            flags & Alert.YES ||
	            flags & Alert.NO)
	        {
	            alert.buttonFlags = flags;
	        }
	       
	        if (defaultButtonFlag == Alert.OK ||
	            defaultButtonFlag == Alert.CANCEL ||
	            defaultButtonFlag == Alert.YES ||
	            defaultButtonFlag == Alert.NO)
	        {
	            alert.defaultButtonFlag = defaultButtonFlag;
	        }
	       
	        alert.text = text;
	        alert.title = title;
	        alert.iconClass = iconClass;
	           
	        if (closeHandler != null)
	            alert.addEventListener(CloseEvent.CLOSE, closeHandler);
	
	        PopUpManager.addPopUp(alert, parent, modal);
	
	        alert.setActualSize(alert.getExplicitOrMeasuredWidth(),
	                            alert.getExplicitOrMeasuredHeight());
			PopUpManager.centerPopUp(alert);
	        return alert;
	    }
	}
}
