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
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.text.TextLineMetrics;
	
	import mx.controls.listClasses.ListBase;
	import mx.events.FlexEvent;

	public class StaticTitleComboBox extends ComboBoxPlus
	{
	    private var _fLeftAlignedDropDown:Boolean = true;
		private var _strStaticLabel:String = null;

		public function StaticTitleComboBox()
		{
			super();
		}
		
		[Bindable]
		public function set staticLabel(str:String): void {
			_strStaticLabel = str;
		}
		
		public function get staticLabel(): String {
			return _strStaticLabel;
		}
		
		[Bindable]
		public function set dropDownLeftAligned(f:Boolean): void {
			_fLeftAlignedDropDown = f;
			setStyle("textAlign", f ? "left" : "right");
		}
		
		public function get dropDownLeftAligned(): Boolean {
			return _fLeftAlignedDropDown;
		}
		
		public override function get selectedLabel():String {
			if (_strStaticLabel != null) {
				return _strStaticLabel;
			} else {
				return super.selectedLabel;
			}
		}
		
	    override public function open():void
	    {
	    	super.open();
	    	UpdateDropdownPosition();
	    }

	    override protected function downArrowButton_buttonDownHandler(event:FlexEvent):void {
	    	UpdateDropdownPosition();
	    	super.downArrowButton_buttonDownHandler(event);
	    	UpdateDropdownPosition();
	    }

	    override protected function keyDownHandler(event:KeyboardEvent):void
	    {
	    	super.keyDownHandler(event);
	    	UpdateDropdownPosition();
	    }
	   
	    private function UpdateDropdownPosition(): void {
	    	if (_fLeftAlignedDropDown) return;
	    	if (!initialized) return;
	    	var lstDropDown:ListBase = this.dropdown;
	    	if (!lstDropDown) return;

        	var ptCombo:Point = new Point(0, 0);
        	ptCombo = localToGlobal(ptCombo);
        	ptCombo = lstDropDown.parent.globalToLocal(ptCombo);
        	
	    	if (_fLeftAlignedDropDown) {
	        	lstDropDown.x = ptCombo.x;
	        } else {
	        	lstDropDown.x = ptCombo.x + width - lstDropDown.width;
	        }
	    }
	   
	    override protected function calculatePreferredSizeFromData(count:int):Object
	    {
	    	UpdateDropdownPosition();
	    	if (count == 0 || _strStaticLabel == null) return super.calculatePreferredSizeFromData(count);
	    	
	    	dropdownWidth = super.calculatePreferredSizeFromData(count).width + 2; 
	    	
	        var lineMetrics:TextLineMetrics;
            var txt:String = _strStaticLabel;
	
            lineMetrics = measureText(txt);
	
	        var maxW:Number = 0;
	        var maxH:Number = 0;
            maxW = Math.max(maxW, lineMetrics.width);
            maxH = Math.max(maxH, lineMetrics.height);
	
	        maxW += getStyle("paddingLeft") + getStyle("paddingRight");

	        return { width: maxW, height: maxH };
	    }
	}
}