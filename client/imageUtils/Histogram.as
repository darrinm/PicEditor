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
package imageUtils
{
	import imageUtils.Channel;
	import flash.geom.Point;
	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.utils.clearInterval;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import com.gskinner.geom.ColorMatrix;
	import util.VBitmapData;
	
	public class Histogram {


		private static var kcxyQuick:Number = 200;
		
		// Cloned
		private var _cx:Number, _cy:Number;
		private var _achnl:Array;
		private var _ichnl:Number;
		
		// Not Cloned
		private var _bmd:BitmapData;
		private var _cmsStart:Number;
		private var _fnDone:Function;
		private var _iid:Number;
		private var _y:Number;
		
		public function Clone():Histogram {
			var hg:Histogram = new Histogram();
			hg._ichnl = _ichnl;
			hg._cx = _cx;
			hg._cy = _cy;
			
			hg._achnl = new Array();
			for (var i:Number = 0; i < Channel.kichnlMax; i++)
				hg._achnl[i] = _achnl[i].Clone();
			return hg;
		}
		
		public function get channels():Array{
			return _achnl;
		}
		
		// fnDone() is called (w/ no args) when the calculation is complete
		public function Calculate(bmd:BitmapData, ichnl:Number, fQuick:Boolean, fnDone:Function):Boolean {
			_ichnl = ichnl;
			_fnDone = fnDone;
			_y = 0;
			if (_iid) {
				clearInterval(_iid);
				_iid = undefined;
			}
			
			_cmsStart = getTimer();
			_achnl = new Array();
		
			for (var i:Number = 0; i < Channel.kichnlMax; i++) {
				var chnl:Channel = new Channel();
				_achnl[i] = chnl
				for (var j:Number = 0; j < 256; j++) {
					chnl[j] = 0;
				}
			}
			
			_cx = bmd.width;
			_cy = bmd.height;
			if (fQuick) {
				// Create a small copy of the image (no larger than 200x200) to create the
				// histogram from. My 2.4 GHz Athlon x2 creates kichnlRGB histograms from
				// ~200x200 images in ~1000 milliseconds.
				if (_cx > kcxyQuick) {
					_cy = kcxyQuick * _cy / _cx;
					_cx = kcxyQuick;
				}
				if (_cy > kcxyQuick) {
					_cx = kcxyQuick * _cx / _cy;
					_cy = kcxyQuick;
				}
			}
			
			_bmd = new VBitmapData(_cx, _cy, false);
			if (!_bmd)
				return false;
				
			if (_cx != bmd.width || _cy != bmd.height) {
				var mat:Matrix = new Matrix();
				mat.scale(_cx / bmd.width, _cx / bmd.width);
				_bmd.draw(bmd, mat);
				_cx = int(_cx);
				_cy = int(_cy);
			} else {
				_bmd.draw(bmd);
			}
			
			/* show the small image on-screen (for debugging)
			var mcApprox:MovieClip = _root.createEmptyMovieClip("approx" + chnl, 999 + chnl);
			mcApprox._x = (chnl * 205) + 60;
			mcApprox._y = 5;
			mcApprox.attachBitmap(bmdNew, 1, "normal", false);
			*/
			
			if (ichnl == Channel.kichnlIntensity) {
				// A nice web page discussing color conversion algorithms:
				// http://www.cs.rit.edu/~ncs/color/t_convert.html
				// NTSC says use the formula I = R*0.299 + G*0.587 + B*0.114 ("YIQ color conversion equation")
				// Paul Haeberli says the YIQ equation is incorrect for linear RGB and the formula
				// I = R*0.3086 + G*0.6095 + B*0.0820 is the one to use. There are algorithms that
				// better take into account human perceptual non-linearities but they don't map well
				// to what Flash can do quickly so we'll use the Haeberli formula.
				var anMatrix:Array = [
						0, 0, 0, 0, 0,
						0, 0, 0, 0, 0,
						
						// NTSC's numbers
						//0.299, 0.587, 0.114, 0, 0,
						
						// Paul Haeberli's numbers
						//0.3086, 0.6095, 0.0820, 0, 0,
						
						// The Colorspace FAQ (http://wwww.faqs.org/faqs/graphics/colorspace-faq/) numbers
						0.212671, 0.715160, 0.072169, 0, 0,
						0, 0, 0, 1, 0 ];
				var flt:ColorMatrixFilter = new ColorMatrixFilter(anMatrix);
				_bmd.applyFilter(_bmd, _bmd.rect, new Point(0, 0), flt);
			}
			
			_iid = setInterval(_OnInterval, 1);
			
			return true;
		}
		
		// Spend approx 50 ms calcing the histogram then return if not finished
		// NOTE: this function is public only so Histogram_test.as can call it
		public function _OnInterval():void {
			var cmsStart:Number = getTimer();
			var anRed:Channel = _achnl[Channel.kichnlRed];
			var anGreen:Channel = _achnl[Channel.kichnlGreen];
			var anBlue:Channel = _achnl[Channel.kichnlBlue];
			var anRGB:Channel = _achnl[Channel.kichnlRGB];
			var anIntensity:Channel = _achnl[Channel.kichnlIntensity];
			
			while (_y < _cy) {
				if (_ichnl == Channel.kichnlIntensity) {
					for (var x1:Number = 0; x1 < _cx; x1++) {
						var co1:Number = _bmd.getPixel(x1, _y);
						anIntensity[co1 & 0xff]++;
					}
				} else {
					for (var x:Number = 0; x < _cx; x++) {
						var co:Number = _bmd.getPixel(x, _y);
						var bR:Number = (co & 0xff0000) >> 16;
						var bG:Number = (co & 0xff00) >> 8;
						var bB:Number = co & 0xff;
						anRed[bR]++;
						anGreen[bG]++;
						anBlue[bB]++;
						anRGB[bR]++;
						anRGB[bG]++;
						anRGB[bB]++;
					}
				}
				_y++;
				if (getTimer() - cmsStart >= 50)
					return;
			}
			
	//		trace("histograms of " + _cx + "x" + _cy + " image calculated in " + (getTimer() - _cmsStart) + " milliseconds");
	//		trace("histogram: " + _achnl[_ichnl].toString());
			clearInterval(_iid);
			
			// clean up
			_bmd.dispose();
			_bmd = null;
			
			_fnDone();
		}
		
		public function Draw(ichnl:Number, cx:Number, cy:Number, co:Number):BitmapData {
			return _achnl[ichnl].Draw(cx, cy, co);
		}
	
		public function GetMinMax(ichnl:Number, nClipMin:Number, nClipMax:Number):Object {
			return _achnl[ichnl].GetMinMax(nClipMin, nClipMax);
		}
	
		// GetMedian returns the median of the combined (added) R, G, and B channels
		public function GetMedian():Number {
			return _achnl[Channel.kichnlRGB].GetMedian();
		}
		
		public function RemapChannel(ichnl:Number, chnlMapper:Channel):void {
			_achnl[ichnl].Remap(chnlMapper);
		}
		
		// Remap the histogram according to the mapped palette
		public function ApplyPalette(pal:Palette):void {
			Debug.Assert(pal.channels.length == 3, "ApplyPalette assumes a 3-channel (R, G, B) palette");
				
			// Map R, G, B channels
			for (var ichnl:Number = 0; ichnl < 3; ichnl++)
				_achnl[ichnl].Remap(pal.channels[ichnl]);
		}
	}
}
