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
//  Internal Helper Class - QuadraticPoints 
//
//--------------------------------------------------------------------------
import flash.geom.Point;
   
/**
 *  Utility class to store the computed quadratic points.
 * 
 *  @langversion 3.0
 *  @playerversion Flash 10
 *  @playerversion AIR 1.5
 *  @productversion Flex 4
 */
public class QuadraticPoints
{
    public var control1:Point;
    public var anchor1:Point;
    public var control2:Point;
    public var anchor2:Point;
    public var control3:Point;
    public var anchor3:Point;
    public var control4:Point;
    public var anchor4:Point;
   
    /**
     * Constructor.
     * 
     *  @langversion 3.0
     *  @playerversion Flash 10
     *  @playerversion AIR 1.5
     *  @productversion Flex 4
     */
    public function QuadraticPoints()
    {
        super();
    }
}
}