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
	import imagine.imageOperations.engine.instructions.FramedBlendInstruction;
	import imagine.imageOperations.engine.instructions.GetVarInstruction;
	import imagine.imageOperations.engine.instructions.OpInstruction;
	
	[RemoteClass]
	public class FramedGetVarImageOperation extends BlendImageOperation {
		private var _strName:String;
		private var _thickness:Number;
		private var _cxMax:int;
		private var _cyMax:int;
		private var _cPixelsMax:int;
		
		public function set Name(strName:String): void {
			_strName = strName;
		}
		
		public function get Name(): String {
			return _strName;
		}
		
		public function set thickness(t:Number): void {
			_thickness = t;
		}
		
		public function get thickness(): Number {
			return _thickness;
		}
		
		public function set maxImageWidth(n:Number): void {
			_cxMax = n;
		}
		
		public function get maxImageWidth(): Number {
			return _cxMax;
		}
		
		public function set maxImageHeight(n:Number): void {
			_cyMax = n;
		}
		
		public function get maxImageHeight(): Number {
			return _cyMax;
		}
		
		public function set maxPixels(n:Number): void {
			_cPixelsMax = n;
		}
		
		public function get maxPixels(): Number {
			return _cPixelsMax;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['Name', 'thickness', 'maxImageWidth', 'maxImageHeight', 'maxPixels']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		public function FramedGetVarImageOperation(strName:String=null, thickness:Number=NaN, strBlendMode:String=null) {
			Name = strName;
			_thickness = thickness;
			BlendMode = strBlendMode;
			_cxMax = Util.GetMaxImageWidth(1);
			_cyMax = Util.GetMaxImageHeight(1);
			_cPixelsMax = Util.GetMaxImagePixels();
		}
	
		// CONSIDER: makes more sense to store as elements?
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@varName, "FramedGetVarImageOperation width argument missing");
			_strName = xmlOp.@varName;
			Debug.Assert(xmlOp.@thickness, "FramedGetVarImageOperation thickness argument missing");
			_thickness = Number(xmlOp.@thickness);
			
			Debug.Assert(xmlOp.hasOwnProperty("@maxWidth"), "FramedGetVarImageOperation maxWidth argument missing");
			_cxMax = Number(xmlOp.@maxWidth);
			_cyMax = Number(xmlOp.@maxHeight);
			_cPixelsMax = Number(xmlOp.@maxPixels);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <FramedGetVar varName={_strName} thickness={_thickness}
					maxWidth={_cxMax} maxHeight={_cyMax} maxPixels={_cPixelsMax}/>
		}
		
		override protected function HasBlending(nAlpha:Number): Boolean {
			return true;
		}
		
		override protected function CompileApplyEffect(ainst:Array):void {
			ainst.push(new GetVarInstruction(_strName));
		}

		override protected function GetBlendInstruction(nAlpha:Number): OpInstruction {
			return new FramedBlendInstruction(_cxMax, _cyMax, _thickness, _cPixelsMax);
		}
		
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			throw new Error("Shouldn't be here");
			return null;
		}
	}
}
