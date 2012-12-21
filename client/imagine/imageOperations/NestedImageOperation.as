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
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.getQualifiedClassName;
	
	import imagine.ImageDocument;
	import imagine.imageOperations.engine.instructions.DupeInstruction;
	import imagine.objectOperations.ObjectOperation;
	import imagine.serialization.SerializationInfo;
	
	import util.BitmapCache;
	
	[RemoteClass]
	public class NestedImageOperation extends BlendImageOperation implements ISimpleOperation
	{
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
		// This is for the benefit of ObjectOperations and nested NestedImageOperations.
		// Currently only the RasterizeImageOperation takes advantage of having its Undo
		// method called.
		override public function Undo(imgd:ImageDocument): Boolean {
			for (var iop:Number = _aopChildren.length - 1; iop >= 0; iop--) {
				var op:ImageOperation = _aopChildren[iop];
				op.Undo(imgd);
			}
			return true;
		}

		override protected function CompileApplyEffect(ainst:Array): void {
			// Duplicate the base bitmap on the stack - we'll need this for blending the final result
			ainst.push(new DupeInstruction());
			
			// Apply the operations.
			// Each operation should replace the head of the stack with a new result
			for each (var op:ImageOperation in _aopChildren)
				op.Compile(ainst);
			
			// Done applying our ops. Our stack now contains the base bitmap and our result.
			// Let the super class Compile() do the blending
		}
		
		public function ApplySimple(bmdSrc:BitmapData, bmdDst:BitmapData, rcSource:Rectangle, ptDest:Point): void {
			for each (var op:ImageOperation in _aopChildren) {
				var sop:ISimpleOperation = op as ISimpleOperation;
				if (sop != null) {
					sop.ApplySimple(bmdSrc, bmdDst, rcSource, ptDest);
					if (rcSource.x != ptDest.x || rcSource.y != ptDest.y) {
						rcSource = rcSource.clone();
						rcSource.x = ptDest.x;
						rcSource.y = ptDest.y;
					}
					bmdSrc = bmdDst;
				} else {
					throw new Error("Simple nesting requires simple ops");
				}
			}
		}

		public function push(op:ImageOperation): void {
			_aopChildren.push(op);
		}
		
		protected override function DeserializeSelf(xnodOp:XML): Boolean {
			for each (var xmlChildOp:XML in xnodOp.children()) {
				if (!IsBlendChild(xmlChildOp)) {
					var op:ImageOperation = XMLToImageOperation(xmlChildOp);
					if (op) push(op);
					else return false;
				}
			}
			return true;
		}

		protected override function SerializeSelf(): XML {
			var xml:XML = <Nested/>
			for each (var op:ImageOperation in _aopChildren) {
				xml.appendChild(op.Serialize());
			}
			return xml;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['children']);

		// DEBUG: Uncomment this and call it from writeExternal to see which class is broken		
		/*
		private function DebugWriteOperation(op:ImageOperation, strPrefix:String=""): void {
			var strName:String = strPrefix + "/" + getQualifiedClassName(op);
			trace(strName + ": TEST");
			var strError:String = "";
			var ba:ByteArray = new ByteArray();
			if (op is BlendImageOperation) {
				var msk:ImageMask = (op as BlendImageOperation).Mask;
				if (msk != null) {
					var strMaskName:String = strName + "/MASK:" + getQualifiedClassName(msk);
					trace(strMaskName + ": TEST");
					try {
						ba.writeObject(msk);
						trace(strMaskName + ": PASSED");
					} catch (e:Error) {
						trace(strMaskName + ": ERROR");
						trace(e + ", " + e.getStackTrace());
						strError = "Mask failed";
					}
				}
			}
			if (strError == "") {
				try {
					ba.writeObject(op);
				} catch (e:Error) {
					trace(strName + ": ERROR");
					trace(e + ", " + e.getStackTrace());
					strError = "op failed";
				}
			}
			if (op is NestedImageOperation) {
				for each (var opChild:ImageOperation in (op as NestedImageOperation).children) {
					DebugWriteOperation(opChild, strName);
				}
			}
			
			if (strError == "") {
				trace(strName + ": PASSED");
			} else {
				trace(strName + ": FAILED: " + strError);
			}
		}
		*/
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this)); // Non-debug version
			
			// debug version: use this to see child class is breaking serialization.
			/*
			try {
				output.writeObject(_srzinfo.GetSerializationValues(this));
			} catch (e:Error) {
				// If there was a problem, figure out which child it was. Also, try child masks.
				DebugWriteOperation(this);
			}
			*/
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
	}
}
