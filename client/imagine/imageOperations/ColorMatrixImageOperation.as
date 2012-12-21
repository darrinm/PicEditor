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
	import com.gskinner.geom.ColorMatrix;
	
	import flash.display.BitmapData;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class ColorMatrixImageOperation extends BlendImageOperation implements ISimpleOperation {
		protected var _anMatrix:Array;
		protected var _fUseAlpha:Boolean = true; // Means use an alpha channel when creating bitmap
		
		private static const kanIdentity:Array = [
				1, 0, 0, 0, 0,
				0, 1, 0, 0, 0,
				0, 0, 1, 0, 0,
				0, 0, 0, 1, 0];
		
		public function ColorMatrixImageOperation(anMatrix:Array=null) {
			// ImageOperation constructors are called with no arguments during Deserialization
			if (!anMatrix)
				return;
			
			_anMatrix = anMatrix.slice();
		}
		
		public function set Matrix(anMatrix:Array): void {
			_anMatrix = anMatrix.slice();
		}
		
		public function get Matrix(): Array {
			return _anMatrix;
		}
		
		override protected function get applyHasNoEffect(): Boolean {
			for (var i:Number = 0; i < _anMatrix.length; i++)
				if (_anMatrix[i] != kanIdentity[i])
					return false;

			return true;
		}
		
		public function set UseAlpha(fUseAlpha:Boolean): void {
			_fUseAlpha = fUseAlpha;
		}
		
		public function get UseAlpha(): Boolean {
			return _fUseAlpha;
		}		
	
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@matrix, "ColorMatrixImageOperation matrix argument missing");
			_fUseAlpha = xmlOp.@UseAlpha;
			var strT:String = xmlOp.@matrix;
				
			_anMatrix = new Array();
			var astrT:Array = strT.split(',');
			for (var i:Number = 0; i < astrT.length; i++)
				_anMatrix[i] = Number(astrT[i]);
				
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <ColorMatrix UseAlpha={_fUseAlpha} matrix={_anMatrix.join(",")}/>
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['Matrix', 'UseAlpha']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return ApplyColorMatrix(bmdSrc, _anMatrix, _fUseAlpha);
		}
		
		private static function ApplyColorMatrix(bmdOrig:BitmapData, anMatrix:Array, fUseAlpha:Boolean): BitmapData {
			var bmdNew:BitmapData = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, fUseAlpha, NaN);
			if (!bmdNew)
				return null;
	
			var flt:ColorMatrixFilter = new ColorMatrixFilter(anMatrix);
			bmdNew.applyFilter(bmdOrig, bmdOrig.rect, new Point(0, 0), flt);
			return bmdNew;
		}
		
		public static function CalcLevelsMatrix(anMin:Array, anMax:Array): Array {
			// stretch each channel over the whole range
			var cmat:ColorMatrix = new ColorMatrix([
					255 / (anMax[0] - anMin[0]), 0, 0, 0, 0,
					0, 255 / (anMax[1] - anMin[1]), 0, 0, 0,
					0, 0, 255 / (anMax[2] - anMin[2]), 0, 0,
					0, 0, 0, 1, 0 ]);
					
			// shift each channel darker by the amount of unused low levels
			// NOTE: because of the behavior of concatenated matrices this shift
			// happens BEFORE the above stretch (very important that it happens
			// in this order!)
			cmat.concat([
					1, 0, 0, 0, -anMin[0],
					0, 1, 0, 0, -anMin[1],
					0, 0, 1, 0, -anMin[2],
					0, 0, 0, 1, 0 ]);
			return cmat;
		}

		public function ApplySimple(bmdSrc:BitmapData, bmdDst:BitmapData, rcSource:Rectangle, ptDest:Point): void {
			var flt:ColorMatrixFilter = new ColorMatrixFilter(_anMatrix);
			bmdDst.applyFilter(bmdSrc, rcSource, ptDest, flt);
		}
	}
}
