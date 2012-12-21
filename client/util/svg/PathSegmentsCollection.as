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
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
//--------------------------------------------------------------------------
//
//  Internal Helper Class - PathSegmentsCollection
//
//--------------------------------------------------------------------------

/**
 *  Helper class that takes in a string and stores and generates a vector of
 *  Path segments.
 *  Provides methods for generating GraphicsPath and calculating bounds.
 */
public class PathSegmentsCollection
{
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

	/**
	 *  Constructor.
	 *
	 *  @param value
	 * 
	 *  @langversion 3.0
	 *  @playerversion Flash 10
	 *  @playerversion AIR 1.5
	 *  @productversion Flex 4
	 */
	public function PathSegmentsCollection(value:String)
	{
		if (!value)
		{
			_segments = [];
			return;
		}

		var newSegments:Array = [];
		var charCount:int = value.length;
		var c:Number; // current char code, String.charCodeAt() returns Number.
		var useRelative:Boolean;
		var prevIdentifier:Number = 0;
		var prevX:Number = 0;
		var prevY:Number = 0;
		var lastMoveX:Number = 0;
		var lastMoveY:Number = 0;
		var x:Number;
		var y:Number;
		var controlX:Number;
		var controlY:Number;
		var control2X:Number;
		var control2Y:Number;
        var lastMoveSegmentIndex:int = -1;

		_dataLength = charCount;
		_charPos = 0;
		while (true)
		{
			// Skip any whitespace or commas first
			skipWhiteSpace(value);

			// Are we done parsing?
			if (_charPos >= charCount)
				break;

			// Get the next character
			c = value.charCodeAt(_charPos++);

			// Is this a start of a number?
			// The RegExp for a float is /[+-]?\d*\.?\d+([Ee][+-]?\d+)?/
			if ((c >= 0x30 && c < 0x3A) ||   // A digit
				(c == 0x2B || c == 0x2D) ||	 // '+' & '-'
				(c == 0x2E)) 				 // '.'
			{
				c = prevIdentifier;
				_charPos--;
			}
			else if (c >= 0x41 && c <= 0x56) // Between 'C' and 'V'
				useRelative = false;
			else if (c >= 0x61 && c <= 0x7A) // Between 'c' and 'v'
				useRelative = true;

			switch(c)
			{
				case 0x63:	// c
				case 0x43:	// C
					controlX = getNumber(useRelative, prevX, value);
					controlY = getNumber(useRelative,  prevY, value);
					control2X = getNumber(useRelative, prevX, value);
					control2Y = getNumber(useRelative, prevY, value);
					x = getNumber(useRelative, prevX, value);
					y = getNumber(useRelative, prevY, value);
					newSegments.push(new CubicBezierSegment(controlX, controlY,
															control2X, control2Y,
															x, y));
					prevX = x;
					prevY = y;
					prevIdentifier = 0x63;
					
					break;

				case 0x6D:	// m
				case 0x4D:	// M
					x = getNumber(useRelative, prevX, value);
					y = getNumber(useRelative, prevY, value);
					newSegments.push(new MoveSegment(x, y));
					prevX = x;
					prevY = y;
					// If a moveto is followed by multiple pairs of coordinates,
					// the subsequent pairs are treated as implicit lineto commands.
					prevIdentifier = (c == 0x6D) ? 0x6C : 0x4C; // c == 'm' ? 'l' : 'L'
                   
                    // Fix for bug SDK-24457:
                    // If the Quadratic segment is isolated, the Player
                    // won't draw fill correctly. We need to generate
                    // a dummy line segment.
                    var curSegmentIndex:int = newSegments.length - 1;
                    if (lastMoveSegmentIndex + 2 == curSegmentIndex &&
                        newSegments[lastMoveSegmentIndex + 1] is QuadraticBezierSegment)
                    {
                        // Insert a dummy LineSegment
                        newSegments.splice(lastMoveSegmentIndex + 1, 0, new LineSegment(lastMoveX, lastMoveY));
                        curSegmentIndex++;
                    }
                   
                    lastMoveSegmentIndex = curSegmentIndex;
                    lastMoveX = x;
                    lastMoveY = y;
					break;

				case 0x6C:	// l
				case 0x4C:	// L
					x = getNumber(useRelative, prevX, value);
					y = getNumber(useRelative, prevY, value);
					newSegments.push(new LineSegment(x, y));
					prevX = x;
					prevY = y;
					prevIdentifier = 0x6C;
					break;

				case 0x68:	// h
				case 0x48:	// H
					x = getNumber(useRelative, prevX, value);
					y = prevY;
					newSegments.push(new LineSegment(x, y));
					prevX = x;
					prevY = y;
					prevIdentifier = 0x68;
					break;

				case 0x76:	// v
				case 0x56:	// V
					x = prevX;
					y = getNumber(useRelative, prevY, value);
					newSegments.push(new LineSegment(x, y));
					prevX = x;
					prevY = y;
					prevIdentifier = 0x76;
					break;

				case 0x71:	// q
				case 0x51:	// Q
                    controlX = getNumber(useRelative, prevX, value);
					controlY = getNumber(useRelative, prevY, value);
					x = getNumber(useRelative, prevX, value);
					y = getNumber(useRelative, prevY, value);
					newSegments.push(new QuadraticBezierSegment(controlX, controlY, x, y));
					prevX = x;
					prevY = y;
					prevIdentifier = 0x71;
					break;

				case 0x74:	// t
				case 0x54:	// T
					// control is a reflection of the previous control point
					if (prevIdentifier == 0x74 || prevIdentifier == 0x71) // 't' or 'q'
					{
						controlX = prevX + (prevX - controlX);
						controlY = prevY + (prevY - controlY);
					}
					else
					{
						controlX = prevX;
						controlY = prevY;
					}
					
					x = getNumber(useRelative, prevX, value);
					y = getNumber(useRelative, prevY, value);
					newSegments.push(new QuadraticBezierSegment(controlX, controlY, x, y));
					prevX = x;
					prevY = y;
					prevIdentifier = 0x74;
					
					break;

				case 0x73:	// s
				case 0x53:	// S
					if (prevIdentifier == 0x73 || prevIdentifier == 0x63) // s or c
					{
						controlX = prevX + (prevX - control2X);
						controlY = prevY + (prevY - control2Y);
					}
					else
					{
						controlX = prevX;
						controlY = prevY;
					}
					
					control2X = getNumber(useRelative, prevX, value);
					control2Y = getNumber(useRelative, prevY, value);
					x = getNumber(useRelative, prevX, value);
					y = getNumber(useRelative, prevY, value);
					newSegments.push(new CubicBezierSegment(controlX, controlY,
						control2X, control2Y, x, y));
					prevX = x;
					prevY = y;
					prevIdentifier = 0x73;
					
					break;

				case 0x7A:	// z
				case 0x5A:	// Z
					x = lastMoveX;
					y = lastMoveY;
					newSegments.push(new LineSegment(x, y));
					prevX = x;
					prevY = y;
					prevIdentifier = 0x7A;
					
					break;

				default:
					// unknown identifier, throw error?
					_segments = [];
					return;
			}
		}
       
        // Fix for bug SDK-24457:
        // If the Quadratic segment is isolated, the Player
        // won't draw fill correctly. We need to generate
        // a dummy line segment.
        curSegmentIndex = newSegments.length;
        if (lastMoveSegmentIndex + 2 == curSegmentIndex &&
            newSegments[lastMoveSegmentIndex + 1] is QuadraticBezierSegment)
        {
            // Insert a dummy LineSegment
            newSegments.splice(lastMoveSegmentIndex + 1, 0, new LineSegment(lastMoveX, lastMoveY));
            curSegmentIndex++;
        }
       
		_segments = newSegments;
	}
	
	// UNDONE: Support more complicated positioning?
	// Scale factor zooms up or down around the middle.
	public function DrawIntoBitmap(bmd:BitmapData, clr:uint = 0x000000, nAlpha:Number=1, nScaleFactor:Number=1): void {
		// UNDONE: Rotate?
		var spr:Sprite = new Sprite();
		spr.graphics.clear();
		spr.graphics.beginFill(clr, nAlpha);
		// UNDONE: Stroke?
		
		generateGraphicsPathInBox(spr.graphics, bmd.rect, nScaleFactor);
		spr.graphics.endFill();
		
		// Done drawing into the sprite. Now draw that into our bmd
		bmd.draw(spr, null, null, null, null, true);
	}
	
	public static function SVGDrawIntoBitmap(strSVG:String, bmd:BitmapData, clr:uint = 0x000000, nAlpha:Number=1, nScaleFactor:Number=1): void {
		var psgc:PathSegmentsCollection = new PathSegmentsCollection(strSVG);
		psgc.DrawIntoBitmap(bmd, clr, nAlpha, nScaleFactor);
	}

	public function generateGraphicsPathInBox(graphics:Graphics, rcBox:Rectangle, nScaleFactor:Number=1): void {
		// Draw to fit/fill the box
		var rcNativeBounds:Rectangle = getBounds();
		var xOff:Number = 0;
		var yOff:Number = 0;
		var nScale:Number = 1;
		
		nScale = Math.min(rcBox.width / rcNativeBounds.width, rcBox.height / rcNativeBounds.height);
		nScale *= nScaleFactor;
		
		var xNativeMid:Number = (rcNativeBounds.left + rcNativeBounds.right) / 2;
		var yNativeMid:Number = (rcNativeBounds.top + rcNativeBounds.bottom) / 2;
		
		var xScaledMid:Number = xNativeMid * nScale;
		var yScaledMid:Number = yNativeMid * nScale;
		
		var xBoxMid:Number = (rcBox.left + rcBox.right) / 2;
		var yBoxMid:Number = (rcBox.top + rcBox.bottom) / 2;
		
		// Position our scaled mid in the middle of our bitmap
		xOff = xBoxMid - xScaledMid;
		yOff = yBoxMid - yScaledMid;
		
		generateGraphicsPath(graphics, xOff, yOff, nScale, nScale);
	}

	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------
	
	//----------------------------------
	//  data
	//----------------------------------

	private var _segments:Array;

	/**
	 *  A Vector of the actual path segments. May be empty, but always non-null.
	 */
	public function get data():Array
	{
		return _segments;
	}
	
	//----------------------------------
	//  bounds
	//----------------------------------

	private var _bounds:Rectangle;

	/**
	 *  The bounds of the segments in local coordinates. 
	 */
	public function getBounds():Rectangle
	{
		if (_bounds)
			return _bounds;
		
		// First, allocate temporary bounds, as getBoundingBox() requires
		// natual bounds to calculate a scaling factor
		_bounds = new Rectangle(0, 0, 1, 1);
		
		// Pass in the same size to getBoundingBox
		// so that the scaling factor is (1, 1).
		_bounds = getBoundingBox(1, 1, null /*Matrix*/);
		return _bounds;
	}
	
	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
	
	/**
	 *  @return Returns the axis aligned bounding box of the segments stretched to
	 *  width, height and then transformed with transformation matrix m.
	 */
	public function getBoundingBox(width:Number, height:Number, m:Matrix):Rectangle
	{
		var naturalBounds:Rectangle = getBounds();
		var sx:Number = naturalBounds.width == 0 ? 1 : width / naturalBounds.width;
		var sy:Number = naturalBounds.height == 0 ? 1 : height / naturalBounds.height;
		
		var prevSegment:PathSegment;
		var pathBBox:Rectangle;
		var count:int = _segments.length;

		for (var i:int = 0; i < count; i++)
		{
			var segment:PathSegment = _segments[i];
			pathBBox = segment.getBoundingBox(prevSegment, sx, sy, m, pathBBox);
			prevSegment = segment;
		}
		
		// If path is empty, it's untransformed bounding box is (0,0), so we return transformed point (0,0)
		if (!pathBBox)
		{
			var x:Number = m ? m.tx : 0;
			var y:Number = m ? m.ty : 0;
			pathBBox = new Rectangle(x, y);
		}
		return pathBBox;
	}

	/**
     *  Workhorse method that iterates through the <code>segments</code>
     *  array and draws each path egment based on its control points.
     * 
     *  Segments are drawn from the x and y position of the path.
     *  Additionally, segments are drawn by taking into account the scale 
     *  applied to the path.
     *
     *  @param tx A Number representing the x position of where this
     *  path segment should be drawn
     * 
     *  @param ty A Number representing the y position of where this 
     *  path segment should be drawn
     *
     *  @param sx A Number representing the scaleX at which to draw
     *  this path segment
     *
     *  @param sy A Number representing the scaleY at which to draw this
     *  path segment
	 */
	public function generateGraphicsPath(graphics:Graphics,
										 tx:Number,
										 ty:Number,
										 sx:Number,
										 sy:Number):void
	{
		// graphics.commands = null;
		// graphics.data = null;
		
		// Always start by moving to drawX, drawY. Otherwise
		// the path will begin at the previous pen location
		// if it does not start with a MoveSegment.
		graphics.moveTo(tx, ty);
		
		var curSegment:PathSegment;
		var prevSegment:PathSegment;
		var count:int = _segments.length;
		for (var i:int = 0; i < count; i++)
		{
			prevSegment = curSegment;
			curSegment = _segments[i];
			curSegment.draw(graphics, tx, ty, sx, sy, prevSegment);
		}
	}
	
	//--------------------------------------------------------------------------
	//
	//  Private methods
	//
	//--------------------------------------------------------------------------

	private var _charPos:int = 0;
	private var _dataLength:int = 0;
	
	private function skipWhiteSpace(data:String):void
	{
		while (_charPos < _dataLength)
		{
			var c:Number = data.charCodeAt(_charPos);
			if (c != 0x20 && // Space
				c != 0x2C && // Comma
				c != 0xD  && // Carriage return
				c != 0x9  && // Tab
				c != 0xA)    // New line
			{
				break;
			}
			_charPos++;
		}
	}
   
    private function getNumber(useRelative:Boolean, offset:Number, value:String):Number
    {
        // Parse the string and find the first occurrance of the following RexExp
        // numberRegExp:RegExp = /[+-]?\d*\.?\d+([Ee][+-]?\d+)?/g;

        skipWhiteSpace(value); // updates _charPos
        if (_charPos >= _dataLength)
            return NaN;
       
        // Remember the start of the number
        var numberStart:int = _charPos;
        var hasSignCharacter:Boolean = false;
        var hasDigits:Boolean = false;

        // The number could start with '+' or '-' (the "[+-]?" part of the RegExp)
        var c:Number = value.charCodeAt(_charPos);
        if (c == 0x2B || c == 0x2D) // '+' or '-'
        {
            hasSignCharacter = true;
            _charPos++;
        }

        // The index of the '.' if any
        var dotIndex:int = -1;

        // First sequence of digits and optional dot in between (the "\d*\.?\d+" part of the RegExp)
        while (_charPos < _dataLength)
        {
            c = value.charCodeAt(_charPos);

            if (c >= 0x30 && c < 0x3A) // A digit
            {
                hasDigits = true;
            }
            else if (c == 0x2E && dotIndex == -1) // '.'
            {
                dotIndex = _charPos;
            }
            else
                break;
               
            _charPos++;
        }
       
        // Now check whether we had at least one digit.
        if (!hasDigits)
        {
            // Go to the end of the data
            _charPos = _dataLength;
            return NaN;
        }

        // 1. Was the last character a '.'? If so, rewind one character back.
        if (c == 0x2E)
            _charPos--;
       
        // So far we have a valid number, remember its end character index
        var numberEnd:int = _charPos;
       
        // Check to see if we have scientific notation (the "([Ee][+-]?\d+)?" part of the RegExp)
        if (c == 0x45 || c == 0x65)
        {
            _charPos++;
           
            // Check for '+' or '-'
            if (_charPos < _dataLength)
            {           
                c = value.charCodeAt(_charPos);
                if (c == 0x2B || c == 0x2D)
                    _charPos++;
            }
           
            // Find all the digits
            var digitStart:int = _charPos;
            while (_charPos < _dataLength)
            {
                c = value.charCodeAt(_charPos);
               
                // Not a digit?
                if (!(c >= 0x30 && c < 0x3A))
                {
                    break;
                }
               
                _charPos++;
            }
           
            // Do we have at least one digit?
            if (digitStart < _charPos)
                numberEnd = _charPos; // Scientific notation, update the end index of the number.
            else
                _charPos = numberEnd; // No scientific notation, rewind back to the end index of the number.
        }

        // Use parseFloat to get the actual number.
        // TODO (egeorgie): we could build the number while matching the RegExp which will save the substr and parseFloat
        var subString:String = value.substr(numberStart, numberEnd - numberStart);
        var result:Number = parseFloat(subString);
        if (isNaN(result))
        {
            // Go to the end of the data
            _charPos = _dataLength;
            return NaN;
        }
        _charPos = numberEnd;
        return useRelative ? result + offset : result;
    }
}

}