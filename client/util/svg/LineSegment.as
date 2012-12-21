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
package util.svg
{
//--------------------------------------------------------------------------
//
//  Internal Helper Class - LineSegment
//
//--------------------------------------------------------------------------

import flash.display.Graphics;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
 *  The LineSegment draws a line from the current pen position to the coordinate located at x, y.
 * 
 * 
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class LineSegment extends PathSegment
{

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor.
     * 
     *  @param x The current location of the pen along the x axis. The <code>draw()</code> method uses
     *  this value to determine where to draw to.
     *
     *  @param y The current location of the pen along the y axis. The <code>draw()</code> method uses
     *  this value to determine where to draw to.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function LineSegment(x:Number = 0, y:Number = 0)
    {
        super(x, y);
    }  
   
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
   
    /**
     *  @inheritDoc
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    override public function draw(graphics:Graphics, dx:Number,dy:Number,sx:Number,sy:Number,prev:PathSegment):void
    {
        graphics.lineTo(dx + x*sx, dy + y*sy);
    }
   
    /**
     *  @inheritDoc
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    override public function getBoundingBox(prev:PathSegment, sx:Number, sy:Number, m:Matrix, rect:Rectangle):Rectangle
    {
		pt = MatrixUtil.transformPoint(x * sx, y * sy, m);
		var x1:Number = pt.x;
		var y1:Number = pt.y;
		
		// If the previous segment actually draws, then only add the end point to the rectangle,
		// as the start point would have been added by the previous segment:
		if (prev != null && !(prev is MoveSegment))
			return MatrixUtil.rectUnion(x1, y1, x1, y1, rect);
		
		var pt:Point = MatrixUtil.transformPoint(prev ? prev.x * sx : 0, prev ? prev.y * sy : 0, m);
		var x2:Number = pt.x;
		var y2:Number = pt.y;

		return MatrixUtil.rectUnion(Math.min(x1, x2), Math.min(y1, y2),
									Math.max(x1, x2), Math.max(y1, y2), rect);
    }
   
    /**
     *  Returns the tangent for the segment.
     *  @param prev The previous segment drawn, or null if this is the first segment.
     *  @param start If true, returns the tangent to the start point, otherwise the tangend to the end point.
     *  @param sx Pre-transform scale factor for x coordinates.
     *  @param sy Pre-transform scale factor for y coordinates.
     *  @param m Transformation matrix.
     *  @param result The tangent is returned as vector (x, y) in result.
     */
    override public function getTangent(prev:PathSegment, start:Boolean, sx:Number, sy:Number, m:Matrix, result:Point):void
    {
        var pt0:Point = MatrixUtil.transformPoint(prev ? prev.x * sx : 0, prev ? prev.y * sy : 0, m).clone();
        var pt1:Point = MatrixUtil.transformPoint(x * sx, y * sy, m);

        result.x = pt1.x - pt0.x;
        result.y = pt1.y - pt0.y;
    }
}

}