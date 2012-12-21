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
	import flash.display.DisplayObject;
	import flash.text.TextLineMetrics;
	import mx.controls.Button;
	import mx.core.IFlexDisplayObject;
	import mx.core.mx_internal;
	use namespace mx_internal;
	public class MultiLineButton extends Button
	{
		public function MultiLineButton()
		{
			super();
		}
		override protected function createChildren():void
		{
			if (!textField)
			{
				textField = new NoTruncationUITextField();
				textField.styleName = this;
				addChild(DisplayObject(textField));
			}
			super.createChildren();
			textField.multiline = true;
			textField.wordWrap = true;
			textField.width = width;
		}
		override protected function measure():void
		{
			if (!isNaN(explicitWidth))
			{
				var tempIcon:IFlexDisplayObject = getCurrentIcon();
				var w:Number = explicitWidth;
				if (tempIcon)
					w -= tempIcon.width + getStyle("horizontalGap") + getStyle("paddingLeft") + getStyle("paddingRight");
				textField.width = w;
			}
			super.measure();
		}
		override public function measureText(s:String):TextLineMetrics
		{
			textField.text = s;
			var lineMetrics:TextLineMetrics = textField.getLineMetrics(0);
			lineMetrics.width = textField.textWidth + 4;
			lineMetrics.height = textField.textHeight + 4;
			return lineMetrics;
		}
	}
}
import mx.core.UITextField;
class NoTruncationUITextField extends UITextField
{
	public function NoTruncationUITextField()
	{
		super();
	}
	override public function truncateToFit(s:String = null):Boolean
	{
		return false;
	}
}
