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
package util.svg {
//--------------------------------------------------------------------------
//
//  Internal Helper Class - PathSegment
//
//--------------------------------------------------------------------------
import flash.display.Graphics;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
 *  The PathSegment class is the base class for a segment of a path.
 *  This class is not created directly. It is the base class for
 *  MoveSegment, LineSegment, CubicBezierSegment and QuadraticBezierSegment.
 * 
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class PathSegment extends Object
{

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor.
     *
     *  @param _x The x position of the pen in the current coordinate system.
     * 
     *  @param _y The y position of the pen in the current coordinate system.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function PathSegment(_x:Number = 0, _y:Number = 0)
    {
        super();
        x = _x; 
        y = _y;
    }  

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
   
    //----------------------------------
    //  x
    //----------------------------------
   
	/**
     *  The ending x position for this segment.
     *
     *  @default 0
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var x:Number = 0;
   
    //----------------------------------
    //  y
    //----------------------------------
   
	/**
     *  The ending y position for this segment.
     *
     *  @default 0
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public var y:Number = 0;
   
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
   
    /**
     *  Draws this path segment. You can determine the current pen position by
     *  reading the x and y values of the previous segment.
     *
     *  @param g The graphics context to draw into.
     *  @param prev The previous segment drawn, or null if this is the first segment.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function draw(graphics:Graphics, dx:Number,dy:Number,sx:Number,sy:Number,prev:PathSegment):void
    {
        // Override to draw your segment
    }

    /**
     *  @param prev The previous segment drawn, or null if this is the first segment.
     *  @param sx Pre-transform scale factor for x coordinates.
     *  @param sy Pre-transform scale factor for y coordinates.
     *  @param m Transformation matrix.
     *  @param rect If non-null, rect is expanded to include the bounding box of the segment.
     *  @return Returns the union of rect and the axis aligned bounding box of the post-transformed
     *  path segment.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */   
    public function getBoundingBox(prev:PathSegment, sx:Number, sy:Number, m:Matrix, rect:Rectangle):Rectangle
    {
        // Override to calculate your segment's bounding box.
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
    public function getTangent(prev:PathSegment, start:Boolean, sx:Number, sy:Number, m:Matrix, result:Point):void
    {
        result.x = 0;
        result.y = 0;
    }
}
}