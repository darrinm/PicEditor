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
package com.darronschall.effects
{

import mx.effects.AnimateProperty;
import com.darronschall.effects.effectClasses.AnimateColorInstance;
import mx.effects.IEffectInstance;	

/**
 * 
 */
public class AnimateColor extends AnimateProperty
{

	/**
	 * Constructor
	 *
	 * @param target The Object to animate with this effect.
	 */
	public function AnimateColor(target:Object = null)
	{
		super(target);
		
		instanceClass = AnimateColorInstance;
	}
	
	/**
	 * @private
	 */
	override protected function initInstance( instance:IEffectInstance ):void
	{
		super.initInstance( instance );
		
		var animateColorInstance:AnimateColorInstance = AnimateColorInstance( instance );

		animateColorInstance.fromValue = fromValue;
		animateColorInstance.toValue = toValue;
		animateColorInstance.property = property;
		animateColorInstance.isStyle = isStyle;
		animateColorInstance.roundValue = roundValue;
	}
	
} // end class	
} // end package