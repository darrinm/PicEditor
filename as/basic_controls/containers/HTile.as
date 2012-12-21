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
	import mx.core.Container;
	import mx.core.EdgeMetrics;
	import mx.core.IUIComponent;

	[Style(name="horizontalGap", type="Number", format="Length", inherit="no")]
	[Style(name="paddingBottom", type="Number", format="Length", inherit="no")]
	[Style(name="paddingTop", type="Number", format="Length", inherit="no")]
	[Style(name="paddingRight", type="Number", format="Length", inherit="no")]
	[Style(name="paddingLeft", type="Number", format="Length", inherit="no")]

	
	public class HTile extends Container
	{
	    protected var cellWidth:Number;
	    protected var cellHeight:Number;
	    //protected var minCellWidth:Number;
	    //protected var minCellHeight:Number;

		public function HTile(): void {
			super();
		}
		
		private function get numChildrenInLayout(): Number {
	
	        // Don't count children that don't need their own layout space.
	        var nChildrenInLayout:int = numChildren;
	        for (var i:int = 0; i < numChildren; i++)
	        {
	            if (!IUIComponent(getChildAt(i)).includeInLayout)
	                nChildrenInLayout--;
	        }
	        return nChildrenInLayout;
		}

		
	    override protected function measure():void
	    {
	        super.measure();
	        var preferredWidth:Number;
	        var preferredHeight:Number;
	        //var minWidth:Number;
	        //var minHeight:Number;
	
	        // Determine the size of each tile cell and cache the values
	        // in cellWidth and cellHeight for later use by updateDisplayList().
	        findCellSize();
	
	        // Determine the width and height necessary to display the tiles
	        // in an N-by-N grid (with number of rows equal to number of columns).
	        var n:int = numChildrenInLayout;
	
            var horizontalGap:Number = getStyle("horizontalGap");
            preferredWidth = n * cellWidth;
            //minWidth = n * minCellWidth;
            if (n > 0) {
	            preferredWidth += (n - 1) * horizontalGap;
	            //minWidth += (n - 1) * horizontalGap;
           }
	           
            preferredHeight = cellHeight;
            //minHeight = minCellHeight;

	        var vm:EdgeMetrics = viewMetricsAndPadding;
	        var hPadding:Number = vm.left + vm.right;
	        var vPadding:Number = vm.top + vm.bottom;
	
	        //measuredMinWidth = Math.ceil(hPadding + minWidth );
	        //measuredMinHeight = Math.ceil(vPadding + minHeight);
	        measuredWidth = Math.ceil(hPadding + preferredWidth);
	        measuredHeight = Math.ceil(vPadding + preferredHeight);
	        measuredMinWidth = measuredWidth;
	        measuredMinHeight = measuredHeight;
	    }

	    protected function findCellSize():void
	    {
	        // Reset the max child width and height
	        var maxChildWidth:Number = 0;
	        var maxChildHeight:Number = 0;
	       
	        //var maxMinChildWidth:Number = 0;
	        //var maxMinChildHeight:Number = 0;
	       
	        // Loop over the children to find the max child width and height.
	        var n:int = numChildren;
	        for (var i:int = 0; i < n; i++)
	        {
	            var child:IUIComponent = IUIComponent(getChildAt(i));
	
	            if (!child.includeInLayout)
	                continue;
	           
	            var width:Number = child.getExplicitOrMeasuredWidth();
	            if (width > maxChildWidth)
	                maxChildWidth = width;
	           
	            //width = child.measuredMinWidth;
	            //if (width > maxMinChildWidth)
	            //    maxMinChildWidth = width;
	           
	            var height:Number = child.getExplicitOrMeasuredHeight();
	            if (height > maxChildHeight)
	                maxChildHeight = height;

	            //height = child.measuredMinHeight;
	            //if (height > maxMinChildHeight)
	            //    maxMinChildHeight = height;
	        }
	       
	        // If user explicitly specified either width or height, use the
	        // user-supplied value instead of the one we computed.
	        cellWidth = maxChildWidth;
	        cellHeight = maxChildHeight;
	       
	        //minCellWidth = maxMinChildWidth;
	        //minCellHeight = maxMinChildHeight;
	    }
	
	    /**
	     *  @private
	     *  Assigns the actual size of the specified child,
	     *  based on its measurement properties and the cell size.
	     */
	    private function setChildSize(child:IUIComponent, w:Number, h:Number):void
	    {
	        var childWidth:Number;
	        var childHeight:Number;
	        var childPref:Number;
	        var childMin:Number;
	
	        if (child.percentWidth > 0) {
	            // Set child width to be a percentage of the size of the cell.
	            childWidth = Math.min(w, w * child.percentWidth / 100);
	        } else {
	        	childWidth = w;
	        }
	        if (child.percentHeight > 0) {
	            childHeight = Math.min(h, h * child.percentHeight / 100);
	        } else {
	        	childHeight = h;
	        }
	        child.setActualSize(childWidth, childHeight);
	    }

	    override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	    {
	        super.updateDisplayList(unscaledWidth, unscaledHeight);
	
	        // The measure function isn't called if the width and height of
	        // the Tile are hard-coded. In that case, we compute the cellWidth
	        // and cellHeight now.
	        if (isNaN(cellWidth) || isNaN(cellHeight))
	            findCellSize();
	       
	        var vm:EdgeMetrics = viewMetricsAndPadding;
	       
	        var paddingLeft:Number = getStyle("paddingLeft");
	        var paddingRight:Number = getStyle("paddingRight");
	        var paddingTop:Number = getStyle("paddingTop");
	        var paddingBottom:Number = getStyle("paddingBottom");
	
	        var horizontalGap:Number = getStyle("horizontalGap");
	
	        var xPos:Number = paddingLeft;
	        var yPos:Number = paddingTop;
	
	        var n:int = numChildrenInLayout;
	        var i:int;
	        var child:IUIComponent;
	       
	        var wSpace:Number = width - paddingLeft - paddingRight;
	        if (n > 0) wSpace -= (n-1) * horizontalGap;
	        var w:Number = Math.floor(wSpace / n);
	        var h:Number = height - paddingTop - paddingBottom;
	       
            for (i = 0; i < n; i++)
            {
                child = IUIComponent(getChildAt(i));

                if (!child.includeInLayout)
                    continue;

                setChildSize(child, w, h); // calls child.setActualSize()

                // Calculate the offsets to align the child in the cell.
                child.move(xPos, yPos);

                xPos += (w + horizontalGap);
            }
	        cellWidth = NaN;
	        cellHeight = NaN;
	    }
	}
}