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
package imagine.imageOperations {
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	
	import overlays.helpers.RGBColor;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class PaletteMapImageOperation extends BlendImageOperation implements ISimpleOperation {
		protected var _acoRed:Array;
		protected var _acoGreen:Array;
		protected var _acoBlue:Array;
		
		public function set Reds(acoRed:Array): void {
			_acoRed = acoRed.slice();
		}
		
		public function set Greens(acoGreen:Array): void {
			_acoGreen = acoGreen.slice();
		}
		
		public function set Blues(acoBlue:Array): void {
			_acoBlue = acoBlue.slice();
		}
		
		// Sets R, G, B maps to luminosity map
		public function set Luminosities(acoLum:Array): void {
			_acoRed = [];
			_acoGreen = [];
			_acoBlue = [];
			for each (var nLum:Number in acoLum) {
				_acoRed.push(RGBColor.RGBtoUint(nLum, 0, 0));
				_acoGreen.push(RGBColor.RGBtoUint(0, nLum, 0));
				_acoBlue.push(RGBColor.RGBtoUint(0, 0, nLum));
			}
		}
		
		public function get Reds(): Array {
			return _acoRed;
		}
		
		public function get Greens(): Array {
			return _acoGreen;
		}
		
		public function get Blues(): Array {
			return _acoBlue;
		}
		
		public function set ColorMaps(aan:Array): void {
			if (aan == null) aan = [null, null, null];
			Reds = aan[0];
			Greens = aan[1];
			Blues = aan[2];
		}
		
		public function PaletteMapImageOperation(acoRed:Array=null, acoGreen:Array=null, acoBlue:Array=null) {
			// ImageOperation constructors are called with no arguments during Deserialization
			if (acoRed == null)
				return;
	
			if (acoRed)
				_acoRed = acoRed.slice();
			if (acoGreen)
				_acoGreen = acoGreen.slice();
			if (acoBlue)
				_acoBlue = acoBlue.slice();
		}
		
		private function NOPArray(an:Array, nBitPos:Number): Boolean {
			if (an == null || an.length == 0)
				return true;
			for (var i:Number = 0; i < an.length; i++) {
				if (an[i] != undefined)
					return false;
			}
			return true;
		}
		
		override protected function get applyHasNoEffect(): Boolean {
			return NOPArray(_acoRed, 16) && NOPArray(_acoGreen, 8) && NOPArray(_acoBlue, 0);
		}
	
		// CONSIDER: makes more sense to store as elements?
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			var astrT:Array;
			var i:Number;

			var strT:String;			
			if (xmlOp.@redMap.toString().length > 0) {
				strT = xmlOp.@redMap;
				_acoRed = new Array();
				astrT = strT.split(',');
				for (i = 0; i < astrT.length; i++)
					_acoRed[i] = Number(astrT[i]);
			}
			
			if (xmlOp.@greenMap.toString().length > 0) {
				strT = xmlOp.@greenMap;
				_acoGreen = new Array();
				astrT = strT.split(',');
				for (i = 0; i < astrT.length; i++)
					_acoGreen[i] = Number(astrT[i]);
			}
			
			if (xmlOp.@blueMap.toString().length > 0) {
				strT = xmlOp.@blueMap;
				_acoBlue = new Array();
				astrT = strT.split(',');
				for (i = 0; i < astrT.length; i++)
					_acoBlue[i] = Number(astrT[i]);
			}
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			var xml:XML = <PaletteMap/>
			if (_acoRed)
				xml.@redMap = _acoRed.join(",");
			if (_acoGreen)
				xml.@greenMap = _acoGreen.join(",");
			if (_acoBlue)
				xml.@blueMap = _acoBlue.join(",");
			return xml;
		}

		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			var obVals:Object = {reds:_acoRed, greens:_acoGreen, blues:_acoBlue};
			output.writeObject(obVals);
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			var obVals:Object = input.readObject();
			_acoRed = obVals.reds;
			_acoGreen = obVals.greens;
			_acoBlue = obVals.blues;
		}
		
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return ApplyPaletteMap(bmdSrc, _acoRed, _acoGreen, _acoBlue);
		}

		public static function ApplyPaletteMap(bmdOrig:BitmapData, acoRed:Array, acoGreen:Array, acoBlue:Array):BitmapData {
			var bmdNew:BitmapData = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true, NaN);
			if (!bmdNew)
				return null;
	
			bmdNew.paletteMap(bmdOrig, bmdOrig.rect, new Point(0, 0), acoRed, acoGreen, acoBlue, null);
			return bmdNew;
		}
		
		public function ApplySimple(bmdSrc:BitmapData, bmdDst:BitmapData, rcSource:Rectangle, ptDest:Point): void {
			bmdDst.paletteMap(bmdSrc, rcSource, ptDest, _acoRed, _acoGreen, _acoBlue);
		}
	}
}
