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
	import mx.controls.Button;
	import mx.core.mx_internal;
	import flash.text.TextLineMetrics;
	import mx.core.EdgeMetrics;
	import mx.skins.RectangularBorder;
	import mx.controls.ButtonLabelPlacement;
	import mx.core.UITextField;
	import flash.display.DisplayObject;

	use namespace mx_internal;

	[Style(name="offsetDown", type="Number", format="Length", inherit="no")]
	[Style(name="offsetRight", type="Number", format="Length", inherit="no")]

	public class ButtonPlus extends Button
	{
		[Bindable] public var snapIcon:Boolean = true;
		
	    mx_internal override function layoutContents(unscaledWidth:Number,
	                                        unscaledHeight:Number,
	                                        offset:Boolean):void
	    {
	        if (!snapIcon ||
	        	(labelPlacement != ButtonLabelPlacement.RIGHT && labelPlacement != ButtonLabelPlacement.LEFT)) {
	        	super.layoutContents(unscaledWidth, unscaledHeight, offset);    	
	        	return;
	        }

	        var textAlign:String = getStyle("textAlign");
	        if (textAlign == "left" || textAlign == "right") {
	        	super.layoutContents(unscaledWidth, unscaledHeight, offset);    	
	        	return;
	        }
	       
	        // Now we know we are positioning the label left or right and snapping an icon to the text

	        var labelWidth:Number = 0;
	        var labelHeight:Number = 0;
	
	        var labelX:Number = 0;
	        var labelY:Number = 0;
	
	        var iconWidth:Number = 0;
	        var iconHeight:Number = 0;
	
	        var iconX:Number = 0;
	        var iconY:Number = 0;
	
	        var horizontalGap:Number = 2;
	
	        var paddingLeft:Number = getStyle("paddingLeft");
	        var paddingRight:Number = getStyle("paddingRight");
	        var paddingTop:Number = getStyle("paddingTop");
	        var paddingBottom:Number = getStyle("paddingBottom");
	
	        var textWidth:Number = 0;
	        var textHeight:Number = 0;
	
	        var lineMetrics:TextLineMetrics;
	
			if (!label || label.length == 0) {
				textWidth = 0;
				textHeight = 0;
			} else {
	            lineMetrics = measureText(label);
	            if (lineMetrics.width > 0)
	            {
	                textWidth = getStyle("textIndent") +  lineMetrics.width;
	            }
	           
	            textHeight = lineMetrics.height;
			}
	
			var nOffsetDown:Number = 0;
			var nOffsetRight:Number = 0;
			var n:Number = 0;
			if (offset) {
				nOffsetRight = getStyle("offsetRight");
				if (isNaN(nOffsetRight)) nOffsetRight = 0;
				nOffsetDown = getStyle("offsetDown");
				if (isNaN(nOffsetDown)) nOffsetDown = 0;
			}
	
	        var bm:EdgeMetrics = currentSkin &&
	                             currentSkin is RectangularBorder ?
	                             RectangularBorder(currentSkin).borderMetrics :
	                             null;

			// View width is space for the label, icon, and padding
			// Negative padding increases the effective view width (to beyond the button edges)
	        var viewWidth:Number = unscaledWidth;
	        var viewHeight:Number = unscaledHeight - paddingTop - paddingBottom;
	
	        if (bm)
	        {
	            viewWidth -= bm.left + bm.right;
	            viewHeight -= bm.top + bm.bottom;
	        }

			if (currentIcon) {
	            iconWidth = currentIcon.width;
    	        iconHeight = currentIcon.height;
			}
	
            horizontalGap = getStyle("horizontalGap");

            if (iconWidth == 0 || textWidth == 0)
                horizontalGap = 0;

			// Now we have everything we need to size and position the icon and label
			
			// Contents is icon + horizontalGap + text
			var nElementX:Number = paddingLeft;
			var nElementWidth:Number = Math.max(viewWidth - paddingLeft - paddingRight, 0);
			
			// Now center the text and the icon in this space.
			labelWidth = Math.max(0,nElementWidth - horizontalGap - iconWidth);
			if (labelWidth <= 4) labelWidth = 0;
			if (labelWidth <= 0) horizontalGap = 0;
			var nLabelSpace:Number = Math.min(labelWidth, textWidth);
			var nCompressedElementWidth:Number = nLabelSpace + horizontalGap + iconWidth;
			var nExtraSpace:Number = nElementWidth - nCompressedElementWidth;
			
			
			// if (nExtraSpace < 0) nExtraSpace = 0;
			if (labelPlacement == ButtonLabelPlacement.RIGHT) {
				labelX = nElementX + iconWidth + horizontalGap;
				// icon first, then label
				iconX = nElementX + nExtraSpace / 2;
			} else {
				// label first, then icon
				labelX = nElementX;
				// label first, then icon
				iconX = nElementX + nElementWidth - (nExtraSpace / 2 + iconWidth);
				
			}
			
            textField.width = labelWidth;
            textField.height = labelHeight = Math.min(viewHeight + 2, textHeight + UITextField.TEXT_HEIGHT_PADDING);

            iconY  = labelY = 0;
            iconY  = Math.round((viewHeight - iconHeight) / 2) +
                paddingTop;
            labelY = Math.round((viewHeight - labelHeight) / 2) +
                paddingTop;

	        var buffX:Number = nOffsetRight;
	        var buffY:Number = nOffsetDown;
	
	        if (bm)
	        {
	            buffX += bm.left;
	            buffY += bm.top;
	        }
	
	        textField.x = Math.round(labelX + buffX);
	        textField.y = labelY + buffY;

            iconX += buffX;
            iconY += buffY;

			if (currentIcon) {
	            currentIcon.x = Math.round(iconX);
    	        currentIcon.y = Math.round(iconY);
   			}
	
	        // The skins and icons get created on demand as the user interacts
	        // with the Button, and as they are created they become the
	        // frontmost child.
	        // Here we ensure that the textField is the frontmost child,
	        // with the current icon behind it and the current skin behind that.
	        // Any other skins and icons are left behind these three,
	        // with arbitrary layering.
	        if (currentSkin)
	            setChildIndex(DisplayObject(currentSkin), numChildren - 1);
	        if (currentIcon)
	            setChildIndex(DisplayObject(currentIcon), numChildren - 1);
	        if (textField)
	            setChildIndex(DisplayObject(textField), numChildren - 1);
	    }
	}
}