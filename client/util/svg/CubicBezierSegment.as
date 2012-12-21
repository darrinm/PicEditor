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
//  Internal Helper Class - CubicBezierSegment
//
//--------------------------------------------------------------------------

import flash.display.Graphics;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;


/**
 *  The CubicBezierSegment draws a cubic bezier curve from the current pen position
 *  to x, y. The control1X and control1Y properties specify the first control point;
 *  the control2X and control2Y properties specify the second control point.
 *
 *  <p>Cubic bezier curves are not natively supported in Flash Player. This class does
 *  an approximation based on the fixed midpoint algorithm and uses 4 quadratic curves
 *  to simulate a cubic curve.</p>
 *
 *  <p>For details on the fixed midpoint algorithm, see:<br/>
 *  http://timotheegroleau.com/Flash/articles/cubic_bezier_in_flash.htm</p>
 * 
 * 
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class CubicBezierSegment extends PathSegment
{
  
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor.
     * 
     *  <p>For a CubicBezierSegment, there are two control points, each with x and y coordinates. Control points
     *  are points that define the direction and amount of curves of a Bezier curve.
     *  The curved line never reaches the control points; however, the line curves as though being drawn
     *  toward the control point.</p>
     * 
     *  @param _control1X The x-axis location in 2-d coordinate space of the first control point.
     * 
     *  @param _control1Y The y-axis location of the first control point.
     * 
     *  @param _control2X The x-axis location of the second control point.
     * 
     *  @param _control2Y The y-axis location of the second control point.
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
    public function CubicBezierSegment(
                _control1X:Number = 0, _control1Y:Number = 0,
                _control2X:Number = 0, _control2Y:Number = 0,
                x:Number = 0, y:Number = 0)
    {
        super(x, y);
       
        control1X = _control1X;
        control1Y = _control1Y;
        control2X = _control2X;
        control2Y = _control2Y;
    }  


    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
   
    private var _qPts:QuadraticPoints;
   
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
   
    //----------------------------------
    //  control1X
    //----------------------------------
   
	/**
     *  The first control point x position.
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
     *  The first control point y position.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var control1Y:Number = 0;
   
    //----------------------------------
    //  control2X
    //----------------------------------
   
	/**
     *  The second control point x position.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var control2X:Number = 0;
   
    //----------------------------------
    //  control2Y
    //----------------------------------
   
	/**
     *  The second control point y position.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var control2Y:Number = 0;
   
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
   
    /**
     *  Draws the segment.
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
    override public function draw(graphics:Graphics, dx:Number, dy:Number, sx:Number, sy:Number, prev:PathSegment):void
    {
        var qPts:QuadraticPoints = getQuadraticPoints(prev);
                   
        graphics.curveTo(dx + qPts.control1.x*sx, dy+qPts.control1.y*sy, dx+qPts.anchor1.x*sx, dy+qPts.anchor1.y*sy);
        graphics.curveTo(dx + qPts.control2.x*sx, dy+qPts.control2.y*sy, dx+qPts.anchor2.x*sx, dy+qPts.anchor2.y*sy);
        graphics.curveTo(dx + qPts.control3.x*sx, dy+qPts.control3.y*sy, dx+qPts.anchor3.x*sx, dy+qPts.anchor3.y*sy);
        graphics.curveTo(dx + qPts.control4.x*sx, dy+qPts.control4.y*sy, dx+qPts.anchor4.x*sx, dy+qPts.anchor4.y*sy);
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
        var qPts:QuadraticPoints = getQuadraticPoints(prev);
       
        rect = MatrixUtil.getQBezierSegmentBBox(prev ? prev.x : 0, prev ? prev.y : 0,
                                                qPts.control1.x, qPts.control1.y,
                                                qPts.anchor1.x, qPts.anchor1.y,
                                                sx, sy, m, rect);

        rect = MatrixUtil.getQBezierSegmentBBox(qPts.anchor1.x, qPts.anchor1.y,
                                                qPts.control2.x, qPts.control2.y,
                                                qPts.anchor2.x, qPts.anchor2.y,
                                                sx, sy, m, rect);

        rect = MatrixUtil.getQBezierSegmentBBox(qPts.anchor2.x, qPts.anchor2.y,
                                                qPts.control3.x, qPts.control3.y,
                                                qPts.anchor3.x, qPts.anchor3.y,
                                                sx, sy, m, rect);

        rect = MatrixUtil.getQBezierSegmentBBox(qPts.anchor3.x, qPts.anchor3.y,
                                                qPts.control4.x, qPts.control4.y,
                                                qPts.anchor4.x, qPts.anchor4.y,
                                                sx, sy, m, rect);
        return rect;
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
        // Get the approximation (we want the tangents to be the same as the ones we use to draw
        var qPts:QuadraticPoints = getQuadraticPoints(prev);

        var pt0:Point = MatrixUtil.transformPoint(prev ? prev.x * sx : 0, prev ? prev.y * sy : 0, m).clone();
        var pt1:Point = MatrixUtil.transformPoint(qPts.control1.x * sx, qPts.control1.y * sy, m).clone();
        var pt2:Point = MatrixUtil.transformPoint(qPts.anchor1.x * sx, qPts.anchor1.y * sy, m).clone();
        var pt3:Point = MatrixUtil.transformPoint(qPts.control2.x * sx, qPts.control2.y * sy, m).clone();
        var pt4:Point = MatrixUtil.transformPoint(qPts.anchor2.x * sx, qPts.anchor2.y * sy, m).clone();
        var pt5:Point = MatrixUtil.transformPoint(qPts.control3.x * sx, qPts.control3.y * sy, m).clone();
        var pt6:Point = MatrixUtil.transformPoint(qPts.anchor3.x * sx, qPts.anchor3.y * sy, m).clone();
        var pt7:Point = MatrixUtil.transformPoint(qPts.control4.x * sx, qPts.control4.y * sy, m).clone();
        var pt8:Point = MatrixUtil.transformPoint(qPts.anchor4.x * sx, qPts.anchor4.y * sy, m).clone();
       
        if (start)
        {
            QuadraticBezierSegment.getQTangent(pt0.x, pt0.y, pt1.x, pt1.y, pt2.x, pt2.y, start, result);
            // If there is no tangent
            if (result.x == 0 && result.y == 0)
            {
                // Try 3 & 4
                QuadraticBezierSegment.getQTangent(pt0.x, pt0.y, pt3.x, pt3.y, pt4.x, pt4.y, start, result);
               
                // If there is no tangent
                if (result.x == 0 && result.y == 0)
                {
                    // Try 5 & 6
                    QuadraticBezierSegment.getQTangent(pt0.x, pt0.y, pt5.x, pt5.y, pt6.x, pt6.y, start, result);

                    // If there is no tangent
                    if (result.x == 0 && result.y == 0)
                        // Try 7 & 8
                        QuadraticBezierSegment.getQTangent(pt0.x, pt0.y, pt7.x, pt7.y, pt8.x, pt8.y, start, result);
                }
            }
        }
        else
        {
            QuadraticBezierSegment.getQTangent(pt6.x, pt6.y, pt7.x, pt7.y, pt8.x, pt8.y, start, result);
            // If there is no tangent
            if (result.x == 0 && result.y == 0)
            {
                // Try 4 & 5
                QuadraticBezierSegment.getQTangent(pt4.x, pt4.y, pt5.x, pt5.y, pt8.x, pt8.y, start, result);
               
                // If there is no tangent
                if (result.x == 0 && result.y == 0)
                {
                    // Try 2 & 3
                    QuadraticBezierSegment.getQTangent(pt2.x, pt2.y, pt3.x, pt3.y, pt8.x, pt8.y, start, result);
                   
                    // If there is no tangent
                    if (result.x == 0 && result.y == 0)
                        // Try 0 & 1
                        QuadraticBezierSegment.getQTangent(pt0.x, pt0.y, pt1.x, pt1.y, pt8.x, pt8.y, start, result);
                }
            }
        }
    }   
   
    /**
     *  @private
     *  Tim Groleau's method to approximate a cubic bezier with 4 quadratic beziers,
     *  with endpoint and control point of each saved.
     */
    public function getQuadraticPoints(prev:PathSegment):QuadraticPoints
    {
        if (_qPts)
            return _qPts;

        var p1:Point = new Point(prev ? prev.x : 0, prev ? prev.y : 0);
        var p2:Point = new Point(x, y);
        var c1:Point = new Point(control1X, control1Y);    
        var c2:Point = new Point(control2X, control2Y);
           
        // calculates the useful base points
        var PA:Point = Point.interpolate(c1, p1, 3/4);
        var PB:Point = Point.interpolate(c2, p2, 3/4);
   
        // get 1/16 of the [p2, p1] segment
        var dx:Number = (p2.x - p1.x) / 16;
        var dy:Number = (p2.y - p1.y) / 16;

        _qPts = new QuadraticPoints;
       
        // calculates control point 1
        _qPts.control1 = Point.interpolate(c1, p1, 3/8);
   
        // calculates control point 2
        _qPts.control2 = Point.interpolate(PB, PA, 3/8);
        _qPts.control2.x -= dx;
        _qPts.control2.y -= dy;
   
        // calculates control point 3
        _qPts.control3 = Point.interpolate(PA, PB, 3/8);
        _qPts.control3.x += dx;
        _qPts.control3.y += dy;
   
        // calculates control point 4
        _qPts.control4 = Point.interpolate(c2, p2, 3/8);
   
        // calculates the 3 anchor points
        _qPts.anchor1 = Point.interpolate(_qPts.control1, _qPts.control2, 0.5);
        _qPts.anchor2 = Point.interpolate(PA, PB, 0.5);
        _qPts.anchor3 = Point.interpolate(_qPts.control3, _qPts.control4, 0.5);
   
        // the 4th anchor point is p2
        _qPts.anchor4 = p2;
       
        return _qPts;     
    }
}
}