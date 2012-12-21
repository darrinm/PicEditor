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
package containers
{
	import mx.controls.tabBarClasses.Tab;
	import mx.core.mx_internal;
	import flash.text.TextLineMetrics;
	import mx.core.EdgeMetrics;
	import mx.skins.RectangularBorder;
	import mx.core.UITextField;
	import mx.controls.ButtonLabelPlacement;
	import flash.display.DisplayObject;
	import flash.text.TextField;
	
	use namespace mx_internal;

	// Tab is an internal class. We could override Button instead, and copy
	// over all of the code from Tab, but that would be a waste.
	public class TabPlus extends Tab
	{
		public function TabPlus() {
			super();
			maxWidth = 230; // UNDONE: style paramaterize this
		}
		
		override protected function measure():void {
			super.measure();
			// By setting a fixed measured width, we can prevent the tab
			// buttons from assuming different default sizes (based on the label).
			// This is the maximum tab size. If there isn't enough space, all
			// tabs resizes equally. Labels will be clipped (with ...)
	        measuredWidth = 230; // UNDONE: style parameterize this
		}
		
		// UNDONE: add logic for clipping text at the right place on small buttons

		public var fCenterIconWithText:Boolean = true; // CONFIG? Style?
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
	        var textAlign:String = getStyle("textAlign");
	        var fRelayout:Boolean = fCenterIconWithText;
	        fRelayout = fRelayout && textAlign == "center";
	        fRelayout = fRelayout && (labelPlacement == ButtonLabelPlacement.LEFT || labelPlacement == ButtonLabelPlacement.RIGHT);
	        fRelayout = fRelayout && label && label.length > 0;
	        fRelayout = fRelayout && currentIcon && currentIcon.width > 0;
	        fRelayout = fRelayout && centerContent;
	        if (label) {
		        var lineMetrics:TextLineMetrics;
	            lineMetrics = measureText(label);
	            fRelayout = fRelayout && lineMetrics.width > 0;
	        }
	        if (fRelayout) reLayoutContents(unscaledWidth, unscaledHeight, phase == "down");
		}
		

	    protected function reLayoutContents(unscaledWidth:Number,
	                                        unscaledHeight:Number,
	                                        offset:Boolean):void
	    {
	        var labelX:Number = 0;
	        var iconX:Number = 0;
	        var horizontalGap:Number = 2;
	        var paddingLeft:Number = getStyle("paddingLeft");
	        var paddingRight:Number = getStyle("paddingRight");
	        var textWidth:Number = 0;
	        var lineMetrics:TextLineMetrics;
	
            lineMetrics = measureText(label);
            textWidth = paddingLeft + paddingRight +
                        getStyle("textIndent") +  lineMetrics.width;
	
	        var viewWidth:Number = unscaledWidth;

	        var bm:EdgeMetrics = currentSkin &&
	                             currentSkin is RectangularBorder ?
	                             RectangularBorder(currentSkin).borderMetrics :
	                             null;
	
	
	        if (bm)
	        {
	            viewWidth -= bm.left + bm.right;
	        }
	
	        if (labelPlacement == ButtonLabelPlacement.LEFT ||
	            labelPlacement == ButtonLabelPlacement.RIGHT)
	        {
	            horizontalGap = getStyle("horizontalGap");
	
            	textField.width = textWidth;
            	
            	var space:Number = Math.round((viewWidth - textField.width - currentIcon.width - horizontalGap) / 2);

	            if (labelPlacement == ButtonLabelPlacement.RIGHT)
	            {
	            	iconX = space;
	                labelX = iconX + currentIcon.width + horizontalGap;
	            }
	            else
	            {
	            	labelX = space;
	                iconX = labelX + textWidth + horizontalGap;
	            }
	        }
	        var buffX:Number = offset ? buttonOffset : 0;
	
	        if (bm)
	        {
	            buffX += bm.left;
	        }
	
	        textField.x = labelX + buffX;
	
            iconX += buffX;

            currentIcon.x = iconX;
	    }

	}
}