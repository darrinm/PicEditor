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
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	import imagine.imageOperations.bokeh.Bokeh;
	import imagine.imageOperations.bokeh.BokehLensType;
	import imagine.imageOperations.bokeh.BokehStyle;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class BokehImageOperation extends BlendImageOperation {
		private var _nThreshold:Number;
		private var _cxyRadius:Number;
		private var _nIntensity:Number;
		private var _strMode:String = "real";
		private var _uiLens:uint = BokehLensType.CIRCULAR;
		private var _uiStyle:uint = BokehStyle.VIVID;
		private var _degRotation:Number = 0.0;
		private var _bok:Bokeh;
		
		public function set threshold(n:Number): void {
			_nThreshold = n;
		}
		
		public function get threshold(): Number {
			return _nThreshold;
		}
		
		public function set radius(cxy:Number): void {
			_cxyRadius = cxy;
		}
		
		public function get radius(): Number {
			return _cxyRadius;
		}
		
		public function set intensity(n:Number): void {
			_nIntensity = n;
		}
		
		public function get intensity(): Number {
			return _nIntensity;
		}
		
		public function set mode(strMode:String): void {
			_strMode = strMode;
		}
		
		public function get mode(): String {
			return _strMode;
		}
		
		public function set lensType(uiLens:uint): void {
			_uiLens = uiLens;
		}
		
		public function get lensType(): uint {
			return _uiLens;
		}
		
		public function set style(uiStyle:uint): void {
			_uiStyle = uiStyle;
		}
		
		public function get style(): uint {
			return _uiStyle;
		}
		
		public function set lensRotation(deg:Number): void {
			_degRotation = deg;
		}
		
		public function get lensRotation(): Number {
			return _degRotation;
		}
				
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['threshold', 'radius', 'intensity', 'mode', 'lensType', 'style', 'lensRotation']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		public function BokehImageOperation(nThreshold:Number=NaN, cxyRadius:Number=NaN, nIntensity:Number=NaN,
				strMode:String=null, uiLens:uint=BokehLensType.CIRCULAR, uiStyle:uint=BokehStyle.VIVID,
				degRotation:Number=0.0) {
			_nThreshold = nThreshold;
			_cxyRadius = cxyRadius;
			_nIntensity = nIntensity;
			_strMode = strMode;
			_uiLens = uiLens;
			_uiStyle = uiStyle;
			_degRotation = degRotation;
			
			_bok = new Bokeh();
		}
		
		override public function Dispose(): void {
			if (_bok) {
				_bok.Dispose();
				_bok = null;
			}
			super.Dispose();
		}
	
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@threshold, "BokehImageOperation threshold parameter missing");
			_nThreshold = Number(xmlOp.@threshold);
			Debug.Assert(xmlOp.@radius, "BokehImageOperation radius parameter missing");
			_cxyRadius = Number(xmlOp.@radius);
			Debug.Assert(xmlOp.@intensity, "BokehImageOperation intensity parameter missing");
			_nIntensity = Number(xmlOp.@intensity);
			Debug.Assert(xmlOp.@mode, "BokehImageOperation mode parameter missing");
			_strMode = String(xmlOp.@mode);
			Debug.Assert(xmlOp.@lensType, "BokehImageOperation lensType parameter missing");
			_uiLens = uint(xmlOp.@lensType);
			Debug.Assert(xmlOp.@style, "BokehImageOperation style parameter missing");
			_uiStyle = uint(xmlOp.@style);
			Debug.Assert(xmlOp.@lensRotation, "BokehImageOperation lensRotation parameter missing");
			_degRotation = Number(xmlOp.@lensRotation);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Bokeh threshold={_nThreshold} radius={_cxyRadius} intensity={_nIntensity} mode={_strMode}
					lensType={_uiLens} style={_uiStyle} lensRotation={_degRotation}/>
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var bmdTmp:BitmapData = VBitmapData.Construct(bmdSrc.width, bmdSrc.height, true, 0xff0000ff);
			var uiThreshold:uint = int(_nThreshold) << 16 | int(_nThreshold) << 8 | int(_nThreshold);
			_bok.Render(bmdSrc, bmdTmp, uiThreshold, _cxyRadius, _uiLens, _uiStyle, _nIntensity, _degRotation, _strMode);
			return bmdTmp;
		}
	}
}
