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
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.containers.VBox;
	import mx.controls.LinkButton;
	import mx.controls.Text;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.FlexMouseEvent;
	import mx.events.ItemClickEvent;
	import mx.managers.PopUpManager;

	public class TipTextHeaderBase extends Text {
		
		private var _fSubstitutions:Boolean = false;
		private var _strRawHtmlText:String = null;
		
 		public function TipTextHeaderBase() {
			super();
			this.addEventListener(FlexEvent.ADD, _onAdded);
		}

		[Bindable]
		public function set substitutions( f:Boolean ): void {
			_fSubstitutions = f;
			htmlText = _strRawHtmlText;
		}
		
		public function get substitutions():Boolean {
			return _fSubstitutions;
		}

	    override public function set htmlText(value:String):void {
	    	_strRawHtmlText = value;
			super.htmlText = _doSubstitutions(value);
	    }
	    	   
	   	private function _onAdded(evt:Event ):void {
			htmlText = _strRawHtmlText;
	    }
	   
	    private function _doSubstitutions( str:String ): String {
	    	if (!_fSubstitutions || str == null)
	    		return str;
	    		
	    	var obParent:Object = parent;
	    	var dctSubs:Object = null;
	    	
	    	while (obParent != null) {
	    		if (obParent.hasOwnProperty("dctTipTextSubstitutions")) {
	    			dctSubs = obParent['dctTipTextSubstitutions'];
	    			break;
	    		}
	    		else if (obParent.hasOwnProperty("parent")) {
	    			obParent = obParent['parent'];
	    		}
	    		else {
	    			break;
	    		}
	    	}
	    	
	    	if (dctSubs != null) {
		    	for (var k:String in dctSubs) {
		    		str = str.replace("{" + k + "}", dctSubs[k]);
		    	}
		    }
	    	
	    	return str;
	    }
	}
}
