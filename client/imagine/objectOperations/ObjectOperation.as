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
package imagine.objectOperations {
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	
	import imagine.ImageDocument;
	import imagine.imageOperations.ImageOperation;
	import imagine.imageOperations.engine.instructions.ApplyObjectInstruction;
	
	[RemoteClass]
	public class ObjectOperation extends ImageOperation {
		// Operations that fail must leave the document in an unchanged state
		override public function Do(imgd:ImageDocument, fDoObjects:Boolean=true, fUseCache:Boolean=false): Boolean {
			imgd.RecordImageOperation(this);
			return true;
		}

		public override function Compile(ainst:Array):void {
			ainst.push(new ApplyObjectInstruction(this, GetApplyKey()));
		}
		
		protected function GetApplyKey(): String {
			var ba:ByteArray = new ByteArray();
			ba.writeObject(this);
			return ba.toString();
		}
		
		public override function Dispose():void {
			// Do nothing
		}		
	}
}
