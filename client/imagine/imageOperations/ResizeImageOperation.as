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
	import flash.display.StageQuality;
	import flash.geom.Matrix;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import mx.core.Application;
	
	import util.DrawUtil;
	import util.VBitmapData;
	
	[RemoteClass]
	public class ResizeImageOperation extends BlendImageOperation {
		private var _cx:Number = 0;
		private var _cy:Number = 0;
		private var _fSmoothing:Boolean = true;
		private var _fScaleObjects:Boolean = true;
		private var _fScaleBitmap:Boolean = true;
		private var _fHiQuality:Boolean = true;
		
		public function ResizeImageOperation(cx:Number=NaN, cy:Number=NaN, fSmoothing:Boolean=true, fScaleObjects:Boolean=true, fScaleBitmap:Boolean=true,fHiQuality:Boolean=true) {
			// ImageOperation constructors are called with no arguments during Deserialization
			if (isNaN(cx))
				return;
				
			_cx = Math.max(1, Math.round(cx));
			_cy = Math.max(1, Math.round(cy));
			_fSmoothing = fSmoothing;
			_fScaleObjects = fScaleObjects;
			_fScaleBitmap = fScaleBitmap;
			_fHiQuality = fHiQuality;
		}
		
		public function set width(val:Number): void {
			_cx = Math.max(1, Math.round(val));
		}
		
		public function get width(): Number {
			return _cx;
		}
		
		public function set height(val:Number): void {
			_cy = Math.max(1, Math.round(val));
		}
		
		public function get height(): Number {
			return _cy;
		}
		
		public function set smoothing(val:Boolean): void {
			_fSmoothing = val;
		}
		
		public function get smoothing(): Boolean {
			return _fSmoothing;
		}
		
		public function set scaleObjects(val:Boolean): void {
			_fScaleObjects = val;
		}
		
		public function get scaleObjects(): Boolean {
			return _fScaleObjects;
		}
		
		public function set hiQuality(f:Boolean): void {
			_fHiQuality = f;
		}		
		
		public function get hiQuality(): Boolean {
			return _fHiQuality;
		}		
		
		public function set scaleBitmap(f:Boolean): void {
			_fScaleBitmap = f;
		}		
		
		public function get scaleBitmap(): Boolean {
			return _fScaleBitmap;
		}		
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'width', 'height', 'smoothing', 'scaleObjects', 'hiQuality', 'scaleBitmap']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@width, "ResizeImageOperation width argument missing");
			_cx = Number(xmlOp.@width);
			Debug.Assert(xmlOp.@height, "ResizeImageOperation height argument missing");
			_cy = Number(xmlOp.@height);
			if (xmlOp.hasOwnProperty("@smoothing"))
				_fSmoothing = xmlOp.@smoothing == "true";
			else
				_fSmoothing = true;
			if (xmlOp.hasOwnProperty("@scaleObjects"))
				_fScaleObjects = xmlOp.@scaleObjects == "true";
			else
				_fScaleObjects = true;
			if (xmlOp.hasOwnProperty("@scaleBitmap"))
				_fScaleBitmap = xmlOp.@scaleBitmap == "true";
			else
				_fScaleBitmap = true;
			if (xmlOp.hasOwnProperty("@hiQuality"))
				_fHiQuality = Boolean(xmlOp.@hiQuality == "true");
			else
				_fHiQuality = true;
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Resize width={_cx} height={_cy} smoothing={_fSmoothing} scaleObjects={_fScaleObjects} scaleBitmap={_fScaleBitmap} hiQuality={_fHiQuality}/>
		}
		
		override public function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean,
				fUseCache:Boolean): BitmapData {
			return Resize(imgd, bmdSrc, fDoObjects, _cx, _cy, _fSmoothing, _fScaleObjects, true, _fHiQuality);
		}
		
		private static function Resize(imgd:ImageDocument, bmdOrig:BitmapData, fDoObjects:Boolean,
				cx:Number, cy:Number, fSmooth:Boolean=true, fScaleObjects:Boolean=true, fScaleBitmap:Boolean=true, fHiQuality:Boolean=true): BitmapData {
			var bmdNew:BitmapData;
			
			// Create a new VBitmapData w/ the resized dimensions
			if (fScaleBitmap)
				bmdNew = DrawUtil.GetResizedBitmapData(bmdOrig, cx, cy, true, imgd.backgroundColor, false, fHiQuality && fSmooth);
			else
				bmdNew = VBitmapData.Construct(cx, cy, true, imgd.backgroundColor);
			
			// Resize all the DocumentObjects too
			if (fScaleObjects && fDoObjects) {
				var nScaleX:Number = cx / bmdOrig.width;
				var nScaleY:Number = cy / bmdOrig.height;
				
				var dctPropertySets:Object = {};
				SetPropertiesObjectOperation.ScaleDocumentObjects(dctPropertySets, imgd, nScaleX, nScaleY);
				SetPropertiesObjectOperation.SetProperties(dctPropertySets, imgd);
			}
		
			return bmdNew;
		}
	}
}
