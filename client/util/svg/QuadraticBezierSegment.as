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
//  Internal Helper Class - QuadraticBezierSegment
//
//--------------------------------------------------------------------------
import flash.display.Graphics;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
 *  The QuadraticBezierSegment draws a quadratic curve from the current pen position
 *  to x, y.
 *
 *  Quadratic bezier is the native curve type
 *  in Flash Player.
 * 
 * 
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class QuadraticBezierSegment extends PathSegment
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor.
     * 
     *  <p>For a QuadraticBezierSegment, there is one control point. A control point
     *  is a point that defines the direction and amount of a Bezier curve.
     *  The curved line never reaches the control point; however, the line curves as though being drawn
     *  toward the control point.</p>
     *
     *  @param _control1X The x-axis location in 2-d coordinate space of the control point.
     * 
     *  @param _control1Y The y-axis location in 2-d coordinate space of the control point.
     * 
     *  @param x The x-axis location of the starting point of the curve.
     * 
     *  @param y The y-axis location of the starting point of the curve.
     *
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function QuadraticBezierSegment(
                _control1X:Number = 0, _control1Y:Number = 0,
                x:Number = 0, y:Number = 0)
    {
        super(x, y);
       
        control1X = _control1X;
        control1Y = _control1Y;
    }  

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
   
    //----------------------------------
    //  control1X
    //----------------------------------
	
	/**
     *  The control point's x position.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var control1X:Number = 0;
   
    //----------------------------------
    //  control1Y
    //----------------------------------
	
	/**
     *  The control point's y position.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var control1Y:Number = 0;
   
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
   
    /**
     *  Draws the segment using the control point location and the x and y coordinates.
     *  This method calls the <code>Graphics.curveTo()</code> method.
     * 
     *  @see flash.display.Graphics
     *
     *  @param g The graphics context where the segment is drawn.
     * 
     *  @param prev The previous location of the pen.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    override public function draw(graphics:Graphics, dx:Number,dy:Number,sx:Number,sy:Number,prev:PathSegment):void
    {
        graphics.curveTo(dx+control1X*sx, dy+control1Y*sy, dx+x*sx, dy+y*sy);
    }
   
    static public function getQTangent(x0:Number, y0:Number,
                                       x1:Number, y1:Number,
                                       x2:Number, y2:Number,
                                       start:Boolean,
                                       result:Point):void
    {
        if (start)
        {
            if (x0 == x1 && y0 == y1)
            {
                result.x = x2 - x0;
                result.y = y2 - y0;
            }
            else
            {
                result.x = x1 - x0;
                result.y = y1 - y0;
            }
        }
        else
        {
            if (x2 == x1 && y2 == y1)
            {
                result.x = x2 - x0;
                result.y = y2 - y0;
            }
            else
            {
                result.x = x2 - x1;
                result.y = y2 - y1;
            }
        }
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
        var pt1:Point = MatrixUtil.transformPoint(control1X * sx, control1Y * sy, m).clone();;
        var pt2:Point = MatrixUtil.transformPoint(x * sx, y * sy, m).clone();
       
        getQTangent(pt0.x, pt0.y, pt1.x, pt1.y, pt2.x, pt2.y, start, result);
    }

    /**
     *  @inheritDoc
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    override public function getBoundingBox(prev:PathSegment, sx:Number, sy:Number,
                                            m:Matrix, rect:Rectangle):Rectangle
    {
        return MatrixUtil.getQBezierSegmentBBox(prev ? prev.x : 0, prev ? prev.y : 0,
                                                control1X, control1Y, x, y, sx, sy, m, rect);
    }
}
}