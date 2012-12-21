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
package imagine.documentObjects {
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import imagine.ImageDocument;
	import imagine.ImageUndoTransaction;
	
	import imagine.objectOperations.DestroyObjectOperation;
	import imagine.objectOperations.FlipObjectOperation;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	public class DocumentObjectUtil	{
		public static function AddPropertyChangeToUndo(strTransactionName:String, imgd:ImageDocument,
				dob:DisplayObject, dctProperties:Object, fCoalesce:Boolean=false): void {
			// If the object hasn't been added to the document yet, just set its properties
			// directly, no need for undo.
			if (dob.parent == null) {
				for (var strProp:String in dctProperties)
					dob[strProp] = dctProperties[strProp];
				return;
			}
			
			var spop:SetPropertiesObjectOperation;
			
			// If fCoalesce == true check to see if the UndoTransaction at the top
			// of the stack targets the same object and property(s). If so, Undo it
			// to restore the original values before adding the new transaction.
			if (fCoalesce) {
				var imgut:ImageUndoTransaction = imgd.topUndoTransaction;
				if (imgut != null && imgut.objectOperationsOnly && imgut.coalescable && imgut.aop.length == 1) {
					if (imgut.aop[0] is SetPropertiesObjectOperation) {
						spop = SetPropertiesObjectOperation(imgut.aop[0]);
						if (spop.IsCoalesceMatch(dob.name, dctProperties)) {
							imgd.Undo();
							IDocumentObject(dob).Validate();
						}
					}
				}
			}

			imgd.BeginUndoTransaction(strTransactionName, false, false, false);
			spop = new SetPropertiesObjectOperation(dob.name, dctProperties);
			spop.Do(imgd);
			imgd.EndUndoTransaction();
			IDocumentObject(dob).Validate();
		}
		
		public static function GetDocumentScale(doco:IDocumentObject, dobStop:DisplayObject=null): Point {
			// Walk the tree, trace something out.
			
			var xScale:Number = 1;
			var yScale:Number = 1;
			
			for (var dob:DisplayObject = doco as DisplayObject; dob != null && dob != dobStop; dob = dob.parent) {
				xScale *= dob.scaleX;
				yScale *= dob.scaleY;
			}
			return new Point(xScale, yScale);
		}
		
		public static function GetDocumentRotation(doco:IDocumentObject, dobStop:DisplayObject=null): Number {
			var nRotation:Number = 0.0;
			for (var dob:DisplayObject = doco as DisplayObject; dob != null && dob != dobStop; dob = dob.parent)
				nRotation += dob.rotation;
			return nRotation;
		}
		
		public static function SealUndo(imgd:ImageDocument): void {
			var imgut:ImageUndoTransaction = imgd.topUndoTransaction;
			if (imgut != null && imgut.objectOperationsOnly)
				imgut.coalescable = false;
		}
		
		public static function Delete(doco:IDocumentObject, imgd:ImageDocument): void {
			if (doco && imgd.contains(DisplayObject(doco))) {
				var doop:DestroyObjectOperation = new DestroyObjectOperation(DisplayObject(doco).name);
				imgd.BeginUndoTransaction("Destroy " + objectTypeName(doco), false, false);
				doop.Do(imgd);
				imgd.EndUndoTransaction();
			}
		}
		
		public static function Flip(doco:IDocumentObject, imgd:ImageDocument, fHorizontal:Boolean): void {
			if (doco && imgd.contains(DisplayObject(doco))) {
				var foop:FlipObjectOperation = new FlipObjectOperation(DisplayObject(doco), fHorizontal);
				imgd.BeginUndoTransaction("Flip " + objectTypeName(doco), false, false);
				foop.Do(imgd);
				imgd.EndUndoTransaction();
			}
		}
		
		public static function objectTypeName(doco:IDocumentObject): String {
			// UNDONE: Add support for multi-select.
			if (doco == null)
				return "None";
			else
				return doco.typeName;
		}
	}
}
