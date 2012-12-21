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
	import flash.geom.Matrix;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.serialization.SerializationInfo;
	import imagine.imageOperations.engine.instructions.BlendInstruction;
	import imagine.imageOperations.engine.instructions.GetVarInstruction;
	import imagine.imageOperations.engine.instructions.OpInstruction;
	
	[RemoteClass]
	public class OverlayGetVarImageOperation extends BlendImageOperation {
		private var _strName:String;
		private var _strOverlayBlendMode:String;
		private var _nOverlayAlpha:Number = 1.0;
		private var _xScale:Number;
		private var _yScale:Number;
		private var _xOffset:Number;
		private var _yOffset:Number;
		
		public function set Name(strName:String): void {
			_strName = strName;
		}
		
		public function get Name(): String {
			return _strName;
		}
		
		public function set xOffset(n:Number): void {
			_xOffset = Math.floor(n);
		}		
		
		public function get xOffset(): Number {
			return _xOffset;
		}		
		
		public function set yOffset(n:Number): void {
			_yOffset = Math.floor(n);
		}	
		
		public function get yOffset(): Number {
			return _yOffset;
		}	
		
		public function set xScale(n:Number): void {
			_xScale = Math.floor(n);
		}		
		
		public function get xScale(): Number {
			return _xScale;
		}		
		
		public function set yScale(n:Number): void {
			_yScale = Math.floor(n);
		}		
		
		public function get yScale(): Number {
			return _yScale;
		}		
		
		public function set overlayBlendMode(s:String): void {
			_strOverlayBlendMode = s;
		}	
		
		public function get overlayBlendMode(): String {
			return _strOverlayBlendMode;
		}	
		
		public function set overlayAlpha(n:Number): void {
			_nOverlayAlpha = n;
		}	
		
		public function get overlayAlpha(): Number {
			return _nOverlayAlpha;
		}	
		
		public function OverlayGetVarImageOperation(strName:String=null, strBlendMode:String=null) {
			Name = strName;
			BlendMode = strBlendMode;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['Name', 'xOffset', 'yOffset', 'xScale', 'yScale', 'overlayBlendMode', 'overlayAlpha']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@varName, "OverlayGetVarImageOperation varName argument missing");
			_strName = xmlOp.@varName;
			Debug.Assert(xmlOp.@xOffset, "OverlayGetVarImageOperation xOffset parameter missing");
			_xOffset = Number(xmlOp.@xOffset);
			Debug.Assert(xmlOp.@yOffset, "OverlayGetVarImageOperation yOffset parameter missing");
			_yOffset = Number(xmlOp.@yOffset);
			Debug.Assert(xmlOp.@xScale, "OverlayGetVarImageOperation xScale parameter missing");
			_xScale = Number(xmlOp.@xScale);
			Debug.Assert(xmlOp.@yScale, "OverlayGetVarImageOperation yScale parameter missing");
			_yScale = Number(xmlOp.@yScale);
			Debug.Assert(xmlOp.@overlayBlendMode, "OverlayGetVarImageOperation overlayBlendMode parameter missing");
			_strOverlayBlendMode = String(xmlOp.@overlayBlendMode);
			Debug.Assert(xmlOp.@overlayAlpha, "OverlayGetVarImageOperation overlayBlendMode parameter missing");
			_nOverlayAlpha = Number(xmlOp.@overlayAlpha);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <OverlayGetVar varName={_strName} xOffset={_xOffset} yOffset={_yOffset} xScale={_xScale} yScale={_yScale} overlayBlendMode={_strOverlayBlendMode} overlayAlpha={_nOverlayAlpha}/>
		}

		override protected function HasBlending(nAlpha:Number): Boolean {
			return true;
		}
		
		override protected function GetBlendInstruction(nAlpha:Number): OpInstruction {
			if (isNaN(_xScale)) _xScale = 1.0;
			if (isNaN(_yScale)) _yScale = 1.0;
			if (isNaN(_xOffset)) _xOffset = 0;
			if (isNaN(_yOffset)) _yOffset = 0;

			var matTransform:Matrix = new Matrix;
			matTransform.scale(_xScale, _yScale);
			matTransform.translate(_xOffset, _yOffset);
			
			return new BlendInstruction(_nOverlayAlpha, _strOverlayBlendMode, matTransform);
		}

		override protected function CompileApplyEffect(ainst:Array):void {
			ainst.push(new GetVarInstruction(_strName));
		}

	}
}
