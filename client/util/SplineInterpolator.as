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
package util
{
	import flash.geom.Point;

	public class SplineInterpolator
	{
		private var _ax:Array = new Array();
		private var _ay:Array = new Array();
		
		private var _ay2:Array = null;
		private var _aReverse:Array = null;
		
		public function SplineInterpolator(aob:Array=null): void {
			if (aob) {
				for each (var ob:Object in aob) {
					add(ob.x, ob.y);
				}
			}
		}

		public function get length(): Number {
			return _ax.length;
		}
		
		public function add(x:Number, y:Number):void {
			_ax.push(x);
			_ay.push(y);
			_ay2 = null;
			_aReverse = null;
		}
		
		public function setPt(i:Number, x:Number, y:Number): void {
			_ax[i] = x;
			_ay[i] = y;
			_ay2 = null;
			_aReverse = null;
		}
		
        public function Invert(yIn:Number): Number
        {
        	if (length == 0) return yIn;
        	
        	var x:Number;
        	var y:Number;
        	var ptThis:Point = null;
        	var ptPrev:Point = null;
			if (_aReverse == null) {
				_aReverse = new Array();
				// Fill in our reverse array
				for (x = 0; x < 260; x++) {
					ptPrev = ptThis;
					ptThis = new Point(x, Interpolate(x));
					if (ptPrev) {
						// Fill in integer y values in our array between these two points
						var ptAhead:Point = ptThis;
						var ptBehind:Point = ptPrev;
						if (ptBehind.y > ptAhead.y) {
							ptAhead = ptPrev;
							ptBehind = ptThis;
						}
						// Now we know that ptAhead.y >= ptBehind.y
						for (y = Math.ceil(ptBehind.y); y <= ptAhead.y; y++) {
							_aReverse[y] = ptBehind.x + (ptAhead.x - ptBehind.x) * (y - ptBehind.y) / (ptAhead.y - ptBehind.y);
						}
					}
				}
			}
			if (yIn == Math.round(yIn)) {
				if (yIn in _aReverse) return _aReverse[yIn];
			} else {
				var y0:Number = Math.floor(yIn);
				var y1:Number = Math.ceil(yIn);
				if (y0 in _aReverse && y1 in _aReverse) {
					x = _aReverse[y0] + (_aReverse[y1] - _aReverse[y0]) * (yIn-y0);
					return x;
				}
			}
			if (yIn > 0) return 255;
			else return 0;
        }

		
        // Interpolate() and PreCompute() are adapted from:
        // NUMERICAL RECIPES IN C: THE ART OF SCIENTIFIC COMPUTING
        // ISBN 0-521-43108-5, page 113, section 3.3.
        // Based on C# implementation

        public function Interpolate(x:Number): Number
        {
        	if (length == 0) return x;
        	
            if (_ay2 == null)
            {
                PreCompute();
            }

            var n:Number = _ax.length;
            var klo:Number = 0;     // We will find the right place in the table by means of
            var khi:Number = n - 1; // bisection. This is optimal if sequential calls to this

            while (khi - klo > 1)
            {
                // routine are at random values of x. If sequential calls
                var k:Number = (khi + klo) >> 1;// are in order, and closely spaced, one would do better

                if (_ax[k] > x)
                {
                    khi = k; // to store previous values of klo and khi and test if
                }
                else
                {
                    klo = k;
                }
            }

            var h:Number = _ax[khi] - _ax[klo];
            var a:Number = (_ax[khi] - x) / h;
            var b:Number = (x - _ax[klo]) / h;
           
            // Cubic spline polynomial is now evaluated.
            return a * _ay[klo] + b * _ay[khi] +
                ((a * a * a - a) * _ay2[klo] + (b * b * b - b) * _ay2[khi]) * (h * h) / 6.0;
        }

        private function PreCompute(): void
        {
            var n:Number = _ax.length;
            var u:Array = new Array(n);
            var i:Number;
            _ay2 = new Array(n);

            u[0] = 0;
            _ay2[0] = 0;

            for (i = 1; i < n - 1; ++i)
            {
                // This is the decomposition loop of the tridiagonal algorithm.
                // _ay2 and u are used for temporary storage of the decomposed factors.
                var wx:Number = _ax[i + 1] - _ax[i - 1];
                var sig:Number = (_ax[i] - _ax[i - 1]) / wx;
                var p:Number = sig * _ay2[i - 1] + 2.0;

                _ay2[i] = (sig - 1.0) / p;

                var ddydx:Number =
                    (_ay[i + 1] - _ay[i]) / (_ax[i + 1] - _ax[i]) -
                    (_ay[i] - _ay[i - 1]) / (_ax[i] - _ax[i - 1]);

                u[i] = (6.0 * ddydx / wx - sig * u[i - 1]) / p;
            }

            _ay2[n - 1] = 0;

            // This is the backsubstitution loop of the tridiagonal algorithm
            for (i = n - 2; i >= 0; --i)
            {
                _ay2[i] = _ay2[i] * _ay2[i + 1] + u[i];
            }
        }
	}
}