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
	
	
	public class Octree {

		protected var _aKids:Array;
		protected var _cWeight:Number;		
		protected var _nKids:Number;
		protected var _fUseAverage:Boolean;
		protected var _nDepth:Number;
		protected var _nMaxDepth:Number;
		protected var _rgb:Object;

		public function Octree(nMaxDepth:Number=8, nDepth:Number=0) {
			_rgb = {r:0,g:0,b:0};	
			_cWeight = 0;
			_nDepth = nDepth;
			_nMaxDepth = nMaxDepth;
			_aKids = null;
			_nKids = 0;
			_fUseAverage = true;
		}
		
		private function ToRGB( rgb: Number ):Object {
			return { r: (rgb & 0xFF0000) >> 16,
					 g: (rgb & 0x00FF00) >> 8,
					 b: (rgb & 0x0000FF) };
		}
		
		private function FromRGB( rgb: Object ):Number{
			return (rgb.r << 16) + (rgb.g << 8) + (rgb.b);
		}
		
		public function set use_average( b:Boolean ):void {
			_fUseAverage = b;		
		}
		
		// returns true if a new node was created
		public function Insert(rgb:Number):void {		
			_Insert( ToRGB(rgb) );	
		}

		private function _Insert(rgb:Object):void {						
			if (_aKids==null && _nMaxDepth>1 && _cWeight==1) {				
				_aKids = new Array(8);	// instantiate the subnodes array							
				InsertIntoKids( _rgb );
			}
			if (_aKids!=null) {
				// we have an array of subnodes, so insert the new color
				InsertIntoKids( rgb );
			}

			// add this new color to our average			
			_rgb.r += rgb.r;
			_rgb.g += rgb.g;
			_rgb.b += rgb.b;
			_cWeight++;
		}

		private function InsertIntoKids(rgb:Object):void {
			var i:Number = GetChildIndex(rgb,_nDepth);
			if (!_aKids[i]) {
				_aKids[i] = new Octree(_nMaxDepth-1,_nDepth+1);
				_nKids++;
			}
			_aKids[i]._Insert(rgb);
		}		
		
		// reduces the number of colors in our tree to the given number
		public function Reduce( nColors:Number ):void {			
			var i:Number;
			var rgb:Object = { r:0, b:0, g:0 };
			var weight:Number = 0;
			
			if (_aKids == null)
				return;
			
			// if they want us to have one color, then we can
			// just chop off all the kids and be done with it.
			if (nColors==1) {
				_aKids = null;
				_nKids = 0;
				return;		
			}
			
			// add up the kids' weights and store indexes & weights for sorting
			var cKids:Number=0;
			for (i=0; i<8; i++) {
				if (_aKids[i]!=null) {
					cKids += 1;
				}				
			}
			
			// this is an arbitrary ordering for determining how we reduce
			// colors.  Earlier colors are more likey to be eliminated.
			// This ordering is just off the top of my head, and is
			// mostly an attempt to improve contrast.
			var aOrder:Array = [3,1,2,5,4,6,0,7];
			
			// it looks like we'll be having some subnodes, so reset our value
			_rgb.r = 0;
			_rgb.g = 0;
			_rgb.b = 0;
			_cWeight = 0;
			
			for (i=0; i<8; i++) {
				var index:Number = aOrder[i];
				if (_aKids[index]!=null) {
					var nToAssign:Number = Math.floor(nColors / cKids);
					if (nToAssign == 0) {
						// we're pruning this one, so suck its value up into us
						_rgb.r += _aKids[index]._rgb.r;
						_rgb.g += _aKids[index]._rgb.g;
						_rgb.b += _aKids[index]._rgb.b;
						_cWeight += _aKids[index]._cWeight;
						_aKids[index] = null;
						_nKids--;
					} else {				
						_aKids[index].Reduce(nToAssign);
						_rgb.r += _aKids[index]._rgb.r;
						_rgb.g += _aKids[index]._rgb.g;
						_rgb.b += _aKids[index]._rgb.b;
						_cWeight += _aKids[index]._cWeight;
						nColors -= nToAssign;
					}
					cKids--;
				}
			}	
		}
		
		public function Map( rgb:Number ):Number {			
			var obRGB:Object = ToRGB( rgb );	
			obRGB = _Map(obRGB);
			return FromRGB(obRGB);
		}
		
		private function _Map(rgb:Object):Object{
			// walk through our tree until we get to a leaf node
			if (!_aKids) {
				// with no subnodes, we can just return our average
				return { r: Math.floor(_rgb.r/_cWeight), g: Math.floor(_rgb.g/_cWeight), b: Math.floor(_rgb.b/_cWeight) };
			}
			var i:Number = GetChildIndex(rgb,_nDepth);			
			if (_aKids[i]) {
				return _aKids[i]._Map(rgb);
			}			
			else if (!_fUseAverage) {
				// we couldn't find a match, so search for kids near this node
				var aMaps:Array = [				  
					[1,2,4,3,5,6,7],	// 0 black
					[2,3,5,0,7,5,4],	// 1 blue
					[3,1,6,0,7,4,5],	// 2 green
					[2,1,5,0,7,4,6],	// 3 aqua
					[1,5,6,0,7,2,3],	// 4 red
					[4,1,3,0,7,6,2], 	// 5 purple
					[2,4,3,7,0,5,1],	// 6 yellow
					[6,5,3,4,2,1,0] 	// 7 white
					];				
				
				for (var j:Number = 0; j < 7; j++) {
					if (_aKids[aMaps[i][j]]) {
						return _aKids[aMaps[i][j]]._Map(rgb);
					}
				}
			}
			return { r: Math.floor(_rgb.r/_cWeight), g: Math.floor(_rgb.g/_cWeight), b: Math.floor(_rgb.b/_cWeight) };
		}
		
		
		private function GetChildIndex( rgb:Object, bit:Number):Number {
			var r:Number = (rgb.r << 2) >> (7-bit);
			r &= 0x04;
			var g:Number = (rgb.g << 1) >> (7-bit);
			g &= 0x02;
			var b:Number = rgb.b >> (7-bit);
			b &= 0x01;
			return r+g+b;					
		}
		
		public function Dump():String {
			var strOut:String = "";
			var r:Number = _rgb.r/_cWeight;
			var g:Number = _rgb.g/_cWeight;
			var b:Number = _rgb.b/_cWeight;
			strOut += r.toString(16) + "," + g.toString(16) + "," + b.toString(16) + "/" + String(_cWeight) + "\n";
			
			if (_aKids) {
				for ( var i:Number=0; i<_aKids.length; i++) {
					for (var j:Number = 0; j<_nDepth; j++) {
						strOut += "    ";
					}
					strOut += String(i) + " ";
					if (_aKids[i])
						strOut += _aKids[i].Dump();
					else
						strOut += "\n";
				}
			}
			return( strOut );
		}
		
		public function SerializeXML():XML {
			var xml:XML = <Octree weight={_cWeight} r={_rgb.r} g={_rgb.g} b={_rgb.b} />
			if (_aKids) {
				for (var i:Number=0; i<8;i++) {
					if (_aKids[i]) {
						var xmlKid:XML = _aKids[i].SerializeXML();
						xmlKid.@i = i;
						xml.appendChild( xmlKid );
					}
				}
			}
			return xml;			
		}
		
		public function DeserializeXML( xml:XML ):void {
			_rgb.r = Number(xml.@r);
			_rgb.g = Number(xml.@g);
			_rgb.b = Number(xml.@b);
			_cWeight = Number(xml.@weight);
			
			for each (var subtree:XML in xml.Octree) {
				if (!_aKids) _aKids = new Array(8);
				var i:Number = Number(subtree.@i);
				_aKids[i] = new Octree(8, _nDepth+1);
				_aKids[i].DeserializeXML(subtree);								
			}
		}		
	}
}
