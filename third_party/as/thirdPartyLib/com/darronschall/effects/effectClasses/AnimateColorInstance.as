/*
 * Copyright (c) 2006 Darron Schall <darron@darronschall.com>
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
package com.darronschall.effects.effectClasses
{

import mx.effects.effectClasses.AnimatePropertyInstance;
import com.darronschall.util.ColorUtil;
	
/**
 * 
 */
public class AnimateColorInstance extends AnimatePropertyInstance
{
	/** The start color values for each of the r, g, and b channels */
	protected var startValues:Object;;
	
	/** The change in color value for each of the r, g, and b channels. */
	protected var delta:Object;
	
	/**
	 * Constructor
	 *
	 * @param target The Object to animate with this effect.
	 */
	public function AnimateColorInstance( target:Object )
	{
		super( target );
	}
	
	/**
	 * @private
	 */
	override public function play():void
	{
		// We need to call play first so that the fromValue is
		// correctly set, but this has the side effect of calling
		// onTweenUpdate before startValues or delta can be set,
		// so we need to check for that in onTweenUpdate to avoid
		// run time errors.
		super.play();
		
		// Calculate the delta for each of the color values
		startValues = ColorUtil.intToRgb( fromValue );
		var stopValues:Object = ColorUtil.intToRgb( toValue );
		delta = {
					r: ( startValues.r - stopValues.r ) / duration,
					g: ( startValues.g - stopValues.g ) / duration,
					b: ( startValues.b - stopValues.b ) / duration
				};
		
	}
	
	/**
	 * @private
	 */
	override public function onTweenUpdate( value:Object ):void
	{
		// Bail out if delta hasn't been set yet
		if ( delta == null )
		{
			return;
		}
		
		// Catch the situation in which the playheadTime is actually more
		// than duration, which causes incorrect colors to appear at the 
		// end of the animation.
		var playheadTime:int = this.playheadTime;
		if ( playheadTime > duration )
		{
			// Fix the local playhead time to avoid going past the end color
			playheadTime = duration;
		}
		
		// Calculate the new color value based on the elapased time and the change
		// in color values
		var colorValue:int = ( ( startValues.r - playheadTime * delta.r ) << 16 )
							+ ( (startValues.g - playheadTime * delta.g ) << 8 )
							+ ( startValues.b - playheadTime * delta.b );
		
		// Either set the property directly, or set it as a style
		if ( !isStyle )
		{
			target[ property ] = colorValue;
		}
		else
		{
			target.setStyle( property, colorValue );
		}
	}
	
} // end class
} // end package