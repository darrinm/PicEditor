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
package bridges
{
	import mx.controls.TextInput;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import mx.events.FlexEvent;
	import controls.TextInputPlus;

	// A text input box optimized for URLs
	// This means that it understands CTRL-ENTER (add http://www. and .com)
	// Eventually, we may want to add more smarts (such as autocomplete)
	public class URLTextInput extends TextInputPlus
	{
		public function URLTextInput()
		{
			super();
		}
		
	    override protected function keyDownHandler(event:KeyboardEvent):void
	    {
	    	if (event.keyCode == Keyboard.ENTER && (event.ctrlKey || event.shiftKey)) {
	        	// from firefox:
	        	//   ctrl -> .com
	        	//   shift -> .net
	        	//   ctrl+shift -> org
	        	text = "http://www." + text;
	        	if (event.ctrlKey && event.shiftKey)
	        		text += ".org";
	        	else if (event.ctrlKey)
	        		text += ".com";
	        	else if (event.shiftKey)
	        		text += ".net";
	        	selectionBeginIndex = selectionEndIndex = text.length;
		 	}
		 	super.keyDownHandler(event);
	    }
		
	}
}