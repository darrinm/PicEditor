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
package imagine.imageOperations
{
	import com.gskinner.geom.ColorMatrix;
	
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imageUtils.Octree;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	import imagine.imageOperations.ColorMatrixImageOperation;
	import imagine.imageOperations.NestedImageOperation;
	import imagine.imageOperations.PaletteMapImageOperation;
	
	import overlays.helpers.RGBColor;
	
	import util.SplineInterpolator;
	import util.VBitmapData;

	// This is a palette image operation to adjust curves
	[RemoteClass]
	public class QuantizePaletteImageOperation extends BlendImageOperation {
		private var _nSteps:Number = 255;		
		private var _nDepth:Number = 2;
		private var _aColors:Array = null;

		public function QuantizePaletteImageOperation( nSteps:Number=5, nDepth:Number=2, aColors:Array=null ) {
			Steps = nSteps;
			Depth = nDepth;
			_aColors = aColors;
		}

		public function set Steps(nSteps:Number): void {
			_nSteps = nSteps;
		}
		
		public function get Steps(): Number {
			return _nSteps;
		}
		
		public function set Depth(nDepth:Number): void {
			_nDepth = nDepth;
		}
		
		public function get Depth(): Number {
			return _nDepth;
		}
		
		public function set ColorsArray(aColors:Array): void {
			_aColors = aColors;
		}
		
		public function get ColorsArray(): Array {
			return _aColors;
		}
		
		public function set Colors(strColors:String): void {
			_aColors = strColors.split(",");
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['ColorsArray', 'Steps', 'Depth']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			_nSteps = int(xmlOp.@Steps);
			_nDepth = int(xmlOp.@Depth);
			_aColors = String(xmlOp.@Colors).split(",");
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			var strColors:String = _aColors ? _aColors.join(",") : null;
			return <QuantizePalette Steps={_nSteps} Depth={_nDepth} Colors={strColors}/>
		}
						
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var bmdNew:BitmapData = VBitmapData.Construct(bmdSrc.width, bmdSrc.height, true, 0xffffff);
			if (!bmdNew)
				return null;
			
			var oTree:Octree = new Octree(_nDepth);
			
			if (!_aColors || _aColors.length == 0 || !_aColors[0] || _aColors[0] == null || _aColors[0] == "null") {
				// take the src bitmap and reduce it to a reasonable size
				const kSmall:Number = 50;
				var bmdSmall:BitmapData = VBitmapData.Construct(kSmall, kSmall, true, 0xffffff);
				if ( kSmall != bmdSrc.width || kSmall != bmdSrc.height) {
					var mat:Matrix = new Matrix();
					mat.scale(kSmall/bmdSrc.width, kSmall/bmdSrc.width);
					bmdSmall.draw(bmdSrc, mat);
				} else {
					bmdSmall.draw(bmdSrc);
				}
				
				for ( var x:Number=0; x<kSmall; x++) {
					for (var y:Number=0; y<kSmall;y++) {
						oTree.Insert( bmdSmall.getPixel(x,y) );
					}
				}		
				
				bmdSmall.dispose();
				
				if (_nSteps == 2 ) {
					oTree.Reduce( 2 );
					oTree.use_average = false;
				} else {
					oTree.Reduce(_nSteps-1);
				}
					
			} else {
				for (var index:int = 0; index < _aColors.length; index++) {
					oTree.Insert( _aColors[index] );
				}
				oTree.Reduce( 255 );
			}
			
			var r:Number;
			var g:Number;
			var b:Number;
			var acoRed:Array = new Array(256);
			var acoGreen:Array = new Array(256);
			var acoBlue:Array = new Array(256);
			var i:Number;
			
			// map the original image from 24-bit to 8-bit color
			for (i = 0; i < 256; i++) {
				r = (i & 0xE0);
				r = r << 16;
				g = ((i>>3) & 0x1C);
				g = g << 16;
				b = ((i>>6) & 0x03);
				b = b << 16;
				acoRed[i] = r;
				acoGreen[i] = g;
				acoBlue[i] = b;
			}			
			bmdNew.paletteMap(bmdSrc, bmdSrc.rect, new Point(0, 0), acoRed, acoGreen, acoBlue, null);	
			
			// map the 8-bit color back to 24-bit using our Octree
			for (i = 0; i < 256; i++) {
				r = (i & 0xE0) << 16;
				g = (i & 0x1C) << 11;
				b = (i & 0x03) << 6;
				var co:Number = r + g + b;		
				var map:Number = oTree.Map(co);	
				acoRed[i] = map;
				acoGreen[i] = 0;
				acoBlue[i] = 0;
			}			
			
			bmdNew.paletteMap(bmdNew, bmdNew.rect, new Point(0, 0), acoRed, acoGreen, acoBlue, null);	
			return bmdNew;
		}
		
	}
}