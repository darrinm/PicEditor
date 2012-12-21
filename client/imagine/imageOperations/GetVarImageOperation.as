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
	import errors.InvalidBitmapError;
	
	import flash.display.BitmapData;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.serialization.SerializationInfo;
	import imagine.imageOperations.engine.instructions.GetVarInstruction;
	
	[RemoteClass]
	public class GetVarImageOperation extends BlendImageOperation {
		private var _strName:String;
		
		public function set Name(strName:String): void {
			_strName = strName;
		}
		
		public function get Name(): String {
			return _strName;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['Name']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		public function GetVarImageOperation(strName:String=null, strBlendMode:String=null) {
			Name = strName;
			BlendMode = strBlendMode;
		}
		
		override protected function CompileApplyEffect(ainst:Array):void {
			ainst.push(new GetVarInstruction(_strName));
		}
	
		// CONSIDER: makes more sense to store as elements?
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@varName, "GetVarImageOperation width argument missing");
			_strName = xmlOp.@varName;
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <GetVar varName={_strName}/>
		}
	}
}
