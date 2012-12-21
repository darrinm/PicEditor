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
//  Internal Helper Class - MoveSegment
//
//--------------------------------------------------------------------------
import flash.display.Graphics;

/**
 *  The MoveSegment moves the pen to the x,y position. This class calls the <code>Graphics.moveTo()</code> method
 *  from the <code>draw()</code> method.
 *
 * 
 *  @see flash.display.Graphics
 * 
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class MoveSegment extends PathSegment
{

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor.
     * 
     *  @param x The target x-axis location in 2-d coordinate space.
     * 
     *  @param y The target y-axis location in 2-d coordinate space.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function MoveSegment(x:Number = 0, y:Number = 0)
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
     *  The MoveSegment class moves the pen to the position specified by the
     *  x and y properties.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    override public function draw(graphics:Graphics, dx:Number,dy:Number,sx:Number,sy:Number,prev:PathSegment):void
    {
        graphics.moveTo(dx+x*sx, dy+y*sy);
    }
}

}