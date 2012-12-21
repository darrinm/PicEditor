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
// The ShaderImageOperation encapsulates a Pixel Bender shader and a set of parameters for it

package imagine.imageOperations {
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.filters.ShaderFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class ShaderImageOperation extends BlendImageOperation implements ISimpleOperation {
		private var _baByteCode:ByteArray;
		private var _obParams:Object;
				
		public function ShaderImageOperation(baByteCode:ByteArray=null, obParams:Object=null) {
			_baByteCode = baByteCode;
			_obParams = obParams;
		}
		
		public function set bytecode(baByteCode:ByteArray): void {
			_baByteCode = baByteCode;
		}
		
		public function get bytecode(): ByteArray {
			return _baByteCode;
		}
		
		public function set params(obParams:Object): void {
			_obParams = obParams;
		}
		
		public function get params(): Object {
			return _obParams;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['params', 'bytecode']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			var strT:String = xmlOp.child("ByteCode").toString();
			Debug.Assert(strT != "", "ByteCode child text missing");
			var dec:Base64Decoder = new Base64Decoder();
			dec.decode(strT);
			_baByteCode = dec.drain();
			_baByteCode.uncompress();
			
			_obParams = Util.ObFromXmlProperties(xmlOp.child("Params")[0]);
			return true;
		}
		
		// <Shader>
		//     <Params>
		//         <Property name="name" type="type" value="value"/>
		//         ...
		//     </Params>
		//     <ByteCode>
		//         -- base64 encoded compressed Pixel Bender bytecode --
		//     </ByteCode>
		// </Shader>
		override protected function SerializeSelf(): XML {
			var xml:XML = <Shader/>;
			xml.appendChild(Util.XmlPropertiesFromOb(_obParams, "Params"));
			
			var baT:ByteArray = new ByteArray();
			_baByteCode.position = 0;
			_baByteCode.readBytes(baT);
			baT.compress(); // CONSIDER: would deflate() be better?
			var enc:Base64Encoder = new Base64Encoder();
			enc.encodeBytes(baT);
			var xmlByteCode:XML = new XML(enc.drain());
			var xmlT:XML = <ByteCode/>;
			xmlT.appendChild(xmlByteCode);
			xml.appendChild(xmlT);
			return xml;
		}
		
		public function ApplySimple(bmdSrc:BitmapData, bmdDst:BitmapData, rcSource:Rectangle, ptDest:Point): void {
			var bmdTemp:BitmapData = VBitmapData.Construct(rcSource.width, rcSource.height, true, 0);
			bmdTemp.copyPixels(bmdSrc, rcSource, new Point(0,0));
			
			var shdr:Shader = new Shader(_baByteCode);
			if (_obParams) {
				for (var strParam:String in _obParams)
					shdr.data[strParam].value = _obParams[strParam];
			}

			var fltr:ShaderFilter = new ShaderFilter(shdr);
			// bmdDst.applyFilter(bmdSrc, rcSource, ptDest, fltr);
			bmdDst.applyFilter(bmdTemp, bmdTemp.rect, ptDest, fltr);
			bmdTemp.dispose();
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var bmdNew:BitmapData = VBitmapData.Construct(bmdSrc.width, bmdSrc.height, true, 0xff000000);
			var shdr:Shader = new Shader(_baByteCode);
			if (_obParams) {
				for (var strParam:String in _obParams)
					shdr.data[strParam].value = _obParams[strParam];
			}

			var fltr:ShaderFilter = new ShaderFilter(shdr);
			bmdNew.applyFilter(bmdSrc, bmdSrc.rect, new Point(0, 0), fltr);
			return bmdNew;
		}
	}
}
