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
package imagine.objectOperations
{
	import flash.display.BitmapData;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	import imagine.imageOperations.ImageOperation;
	
	[RemoteClass]
	public class NestedObjectOperation extends ObjectOperation
	{
		public function NestedObjectOperation()
		{
			super();
		}

		protected var _aopChildren:Array = new Array();
		
		public function set children(aopChildren:Array): void {
			for each (var op:ImageOperation in _aopChildren) {
				op.Dispose();
			}
			_aopChildren = aopChildren;
		}
		
		public function get children():Array {
			return _aopChildren;
		}
		
		public override function Dispose(): void {
			for each (var op:ImageOperation in _aopChildren) {
				op.Dispose();
			}
			super.Dispose();
		}
				
		// Undo child operations in the reverse order from how they were Do'ed.
		// This is for the benefit of ObjectOperations and nested NestedObjectOperations.
		override public function Undo(imgd:ImageDocument): Boolean {
			for (var iop:Number = _aopChildren.length - 1; iop >= 0; iop--) {
				var op:ImageOperation = _aopChildren[iop];
				op.Undo(imgd);
			}
			return true;
		}
		
		override public function Do(imgd:ImageDocument, fDoObjects:Boolean=true, fUseCache:Boolean=false):Boolean {
			for (var iop:Number = 0; iop < _aopChildren.length; iop++) {
				var op:ImageOperation = _aopChildren[iop];
				op.Do(imgd, fDoObjects, fUseCache);
			}
			return true;
		}
		
		override public function Compile(ainst:Array):void {
			for (var iop:Number = 0; iop < _aopChildren.length; iop++) {
				var op:ImageOperation = _aopChildren[iop];
				op.Compile(ainst);
			}
		}
		
		override public function Apply(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean=false):BitmapData {
			throw new Error("Don't call this directly");
			return null;
		}
		
		public function push(op:ImageOperation): void {
			_aopChildren.push(op);
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['children']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override public function Deserialize(xnodOp:XML): Boolean {
			for each (var xmlChildOp:XML in xnodOp.children()) {
				var op:ImageOperation = XMLToImageOperation(xmlChildOp);
				if (op) push(op);
			}
			return true;
		}

		override public function Serialize(): XML {
			var xml:XML = <Nested />
			for each (var op:ImageOperation in _aopChildren) {
				xml.appendChild(op.Serialize());
			}
			return xml;
		}
		
	}
}