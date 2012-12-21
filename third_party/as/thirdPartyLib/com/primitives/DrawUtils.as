/**
 * DrawUtils is a static class that provides a number of functions
 * to draw shapes that are not part of the standard ActionScript Drawing
 * API.
 * 
 * based on source code found at:
 * http://www.macromedia.com/devnet/mx/flash/articles/adv_draw_methods.html
 * 
 * @author Ric Ewing - version 1.4 - 4.7.2002
 * @author Kevin Williams - version 2.0 - 4.7.2005
 * @author Jason Hawryluk - version 3.0 - 22.02.2007 
 *         -Modified for Flex 2.01
 */
package com.primitives
{
    import mx.core.UIComponent;
    import flash.display.Graphics;

    public class DrawUtils
    {
        /**
        * Star draws a star shaped polygon. 
        */
        public static function star(grTarget:Graphics, x:Number, y:Number, points:Number, innerRadius:Number, outerRadius:Number,angle:Number=0 ):void
        {
    
            var count:int = Math.abs(points);
            if (count>=2) 
            {
                
                // calculate distance between points
                var step:Number = (Math.PI*2)/points;
                var halfStep:Number = step/2;
                
                // calculate starting angle in radians
                var start:Number = (angle/180)*Math.PI;
                grTarget.moveTo(x+(Math.cos(start)*outerRadius), y-(Math.sin(start)*outerRadius));
                
                // draw lines
                for (var i:int=1; i<=count; i++) 
                {
                    grTarget.lineTo(x+Math.cos(start+(step*i)-halfStep)*innerRadius, 
                    y-Math.sin(start+(step*i)-halfStep)*innerRadius);

                    grTarget.lineTo(x+Math.cos(start+(step*i))*outerRadius, 
                    y-Math.sin(start+(step*i))*outerRadius);
                }
            }
        }

        // Burst is a method for drawing star bursts. 
        public static function burst(grTarget:Graphics, x:Number, y:Number,points:Number, innerRadius:Number, outerRadius:Number,angle:Number=0 ):void
        {
            
            if (points >=2) 
            {
                
                // calculate length of sides
                var step:Number = (Math.PI*2)/points;
                var halfStep:Number = step/2;
                var qtrStep:Number = step/4;
                
                // calculate starting angle in radians
                var start:Number = (angle/180)*Math.PI;
                
                grTarget.moveTo(x+(Math.cos(start)*outerRadius), y-(Math.sin(start)*outerRadius));
                
                // draw curves
                for (var i:int=1; i<=points; i++) 
                {
                    
                    grTarget.curveTo(x+Math.cos(start+(step*i)-(qtrStep*3))*(innerRadius/Math.cos(qtrStep)), 
                    y-Math.sin(start+(step*i)-(qtrStep*3))*(innerRadius/Math.cos(qtrStep)), 
                    x+Math.cos(start+(step*i)-halfStep)*innerRadius, 
                    y-Math.sin(start+(step*i)-halfStep)*innerRadius);
                    
                    
                    grTarget.curveTo(x+Math.cos(start+(step*i)-qtrStep)*(innerRadius/Math.cos(qtrStep)), 
                    y-Math.sin(start+(step*i)-qtrStep)*(innerRadius/Math.cos(qtrStep)), 
                    x+Math.cos(start+(step*i))*outerRadius, 
                    y-Math.sin(start+(step*i))*outerRadius);
                    
                }
                
            }
        }
        
        // A method for creating polygon shapes.
        public static function polygon(grTarget:Graphics, x:Number, y:Number, points:Number, radius:Number, angle:Number=0):void
        {
            
            // convert sides to positive value
            var count:int = Math.abs(points);
            
            if (count>=2) 
            {
                
                // calculate span of sides
                var step:Number = (Math.PI*2)/points;
                
                // calculate starting angle in radians
                var start:Number = (angle/180)*Math.PI;
                grTarget.moveTo(x+(Math.cos(start)*radius), y-(Math.sin(start)*radius));
                
                // draw the polygon
                for (var i:int=1; i<=count; i++) 
                {
                    grTarget.lineTo(x+Math.cos(start+(step*i))*radius, 
                    y-Math.sin(start+(step*i))*radius);
                }
                
            }
        }
        
        /*
        public static function dashLineToPattern(grTarget:Graphics, x1:Number, y1:Number,x2:Number, y2:Number,pattern:Array):void
        {
            
            var x:Number = x2 - x1;
            var y:Number = y2 - y1;
            var hyp:Number = Math.sqrt((x)*(x) + (y)*(y));
            
            var units:Number = hyp/(pattern[0]+pattern[1]);
            var dashSpaceRatio:Number = pattern[0]/(pattern[0]+pattern[1]);
            
            var dashX:Number = (x/units)*dashSpaceRatio;
            var spaceX:Number = (x/units)-dashX;
            var dashY:Number = (y/units)*dashSpaceRatio;
            var spaceY:Number = (y/units)-dashY;
            
            grTarget.moveTo(x1, y1);
            
            while (hyp > 0) 
            {
                x1 += dashX;
                y1 += dashY;
                hyp -= pattern[0];
                if (hyp < 0) 
                {
                   x1 = x2;
                   y1 = y2;
                }
                
                grTarget.lineTo(x1, y1);
                x1 += spaceX;
                y1 += spaceY;
                grTarget.moveTo(x1, y1);
                hyp -= pattern[1];
            }
            
            grTarget.moveTo(x2, y2);
        }
        */
        
        // Draws an arc from the starting position of x,y.
        public static function arcTo(grTarget:Graphics, x:Number, y:Number, startAngle:Number, arc:Number, radius:Number,yRadius:Number):void
        {
            
            var ax:Number;
            var ay:Number;
                        
            // Circumvent drawing more than is needed
            if (Math.abs(arc)>360) 
            {
                arc = 360;
            }
            
            // Draw in a maximum of 45 degree segments. First we calculate how many 
            // segments are needed for our arc.
            var segs:Number = Math.ceil(Math.abs(arc)/45);
            
            // Now calculate the sweep of each segment
            var segAngle:Number = arc/segs;
            
            // The math requires radians rather than degrees. To convert from degrees
            // use the formula (degrees/180)*Math.PI to get radians. 
            var theta:Number = -(segAngle/180)*Math.PI;
            
            // convert angle startAngle to radians
            var angle:Number = -(startAngle/180)*Math.PI;
            
            // find our starting points (ax,ay) relative to the secified x,y
            ax = x-Math.cos(angle)*radius;
            ay = y-Math.sin(angle)*yRadius;
            
            // Draw as 45 degree segments
            if (segs>0) 
            {
                grTarget.moveTo(x,y);
                
                // Loop for drawing arc segments
                for (var i:int = 0; i<segs; i++) 
                {
                    
                    // increment our angle
                    angle += theta;
                    
                    //find the angle halfway between the last angle and the new one,
                    //calculate our end point, our control point, and draw the arc segment
                    grTarget.curveTo(ax+Math.cos(angle-(theta/2))*(radius/Math.cos(theta/2)), 
                    ay+Math.sin(angle-(theta/2))*(yRadius/Math.cos(theta/2)), 
                    ax+Math.cos(angle)*radius, ay+Math.sin(angle)*yRadius);
                    
                }
            }
        }
        /*
        
        // Draws a gear shape on the target.  The gear position 
        // is indicated by the x and y arguments.
        public static function gear(grTarget:Graphics, x:Number, y:Number, points:Number, innerRadius:Number, outerRadius:Number,    angle:Number=0, holeSides:Number=0, holeRadius:Number=0 ):void
        {
    
            if (points>=2) 
            {
                
                // calculate length of sides
                var step:Number = (Math.PI*2)/points;
                var qtrStep:Number = step/4;
                
                // calculate starting angle in radians
                var start:Number = (angle/180)*Math.PI;
                grTarget.moveTo(x+(Math.cos(start)*outerRadius), y-(Math.sin(start)*outerRadius));
                
                // draw lines
                for (var i:int=1; i<=points; i++) 
                {
                    grTarget.lineTo(x+Math.cos(start+(step*i)-(qtrStep*3))*innerRadius, 
                    y-Math.sin(start+(step*i)-(qtrStep*3))*innerRadius);
                    
                    grTarget.lineTo(x+Math.cos(start+(step*i)-(qtrStep*2))*innerRadius, 
                    y-Math.sin(start+(step*i)-(qtrStep*2))*innerRadius);
                    
                    grTarget.lineTo(x+Math.cos(start+(step*i)-qtrStep)*outerRadius, 
                    y-Math.sin(start+(step*i)-qtrStep)*outerRadius);
                    
                    grTarget.lineTo(x+Math.cos(start+(step*i))*outerRadius, 
                    y-Math.sin(start+(step*i))*outerRadius);
                }
                                
                if (holeSides>=2) 
                {
                    if(holeRadius == 0) 
                    {
                        holeRadius = innerRadius/3;
                    }
                    
                    step = (Math.PI*2)/holeSides;
                    grTarget.moveTo(x+(Math.cos(start)*holeRadius), y-(Math.sin(start)*holeRadius));
                    
                    for (var j:int=1; j<=holeSides; j++) 
                    {
                        grTarget.lineTo(x+Math.cos(start+(step*j))*holeRadius, 
                        y-Math.sin(start+(step*j))*holeRadius);
                    }
                }
                
            }
        }    
        
        // draws pie shaped wedge.
        public static function wedge(grTarget:Graphics, x:Number, y:Number, startAngle:Number, arc:Number, radius:Number,yRadius:Number):void
        {
    
            // move into position
            grTarget.moveTo(x, y);
                        
            // limit sweep to reasonable numbers
            if (Math.abs(arc)>360) 
            {
                arc = 360;
            }
            
            // Draw in a maximum of 45 degree segments. First we calculate how 
            // many segments are needed for our arc.
            var segs:Number = Math.ceil(Math.abs(arc)/45);
            
            // Now calculate the sweep of each segment.
            var segAngle:Number = arc/segs;
            
            // The math requires radians rather than degrees. To convert from degrees
            // use the formula (degrees/180)*Math.PI to get radians.
            var theta:Number =-(segAngle/180)*Math.PI;
                                
            // convert angle startAngle to radians
            var angle:Number =-(startAngle/180)*Math.PI;
            
            // draw the curve in segments no larger than 45 degrees.
            if (segs>0) 
            {
                
                // draw a line from the center to the start of the curve
                grTarget.lineTo(x+Math.cos(startAngle/180*Math.PI)*radius, 
                y+Math.sin(-startAngle/180*Math.PI)*yRadius);
                
                //draw curve segments
                for (var i:int = 0; i<segs; i++) 
                {
                    angle += theta;
                    
                    var angleMid:Number = angle-(theta/2);
                    grTarget.curveTo(x+Math.cos(angleMid)*(radius/Math.cos(theta/2)), 
                    y+Math.sin(angleMid)*(yRadius/Math.cos(theta/2)), 
                    x+Math.cos(angle)*radius, y+Math.sin(angle)*yRadius);
                    
                }
                
                //close the wedge by drawing a line to the center
                grTarget.lineTo(x, y);
                
            }
        }
        */
    }
}
