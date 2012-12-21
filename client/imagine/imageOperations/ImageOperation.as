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
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import imagine.ImageDocument;
	import imagine.imageOperations.NestedImageOperation;
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.engine.OpEngine;
	import imagine.imageOperations.engine.instructions.ApplyInstruction;
	import imagine.imageOperations.engine.instructions.PopInstruction;
	import imagine.serialization.SerializationUtil;
	
	import util.BitmapCache;
	import util.ISerializable;
	import util.PerformanceManager;
	import util.VBitmapData;
	
	// Do is called when
	// - the user invokes a command through the UI
	// - a .pik file is loaded and its operations are played back
	// - a document is recovered from a SharedObject and its operations are played back
	
	[RemoteClass]
	public class ImageOperation implements ISerializable, IExternalizable {
		private var _openg:OpEngine = null;

		// Public for debugging only
		[Bindable]
		public function get opEngine(): OpEngine {
			return _openg;
		}
		public function set opEngine(openg:OpEngine): void {
			_openg = openg;
		}
		
		public function get assetRefs(): Array {
			return null;
		}
		
		public function Deserialize(xmlOp:XML): Boolean {
			Debug.Assert(false, "ImageOperation.Deserialize must be overridden!");
			return false;
		}
		
		public function Serialize(): XML {
			Debug.Assert(false, "ImageOperation.Serialize must be overridden!");
			return null;
		}
		
		/*
		public function SerializeTest(): XML {
			var xml1:XML = Serialize();
			var ba:ByteArray = new ByteArray();
			ba.writeObject(this);
			ba.position = 0;
			var opCopy:ImageOperation = ba.readObject();
			var xml2:XML = opCopy.Serialize();
			
			try {
				SerializationUtil.ValidateStringMatch(xml1.toXMLString(), xml2.toXMLString());
			} catch (e:Error) {
				xml1 = Serialize();
				ba.position = 0;
				ba.writeObject(this);
				opCopy = ba.readObject();
				xml2 = opCopy.Serialize();
				
				throw e;
			}
			return xml1;
		}
		*/
		
		public function writeExternal(output:IDataOutput):void {
			// Override in sub-classes
		}
		
		public function readExternal(input:IDataInput):void {
			// Override in sub-classes
		}
				
		public function Dispose(): void{
		}

		// Operations that fail must leave the document in an unchanged state
		public function Do(imgd:ImageDocument, fDoObjects:Boolean=true, fUseCache:Boolean=false): Boolean {
			var nStart:Number = new Date().time;
			try {
				var vbmdBG:VBitmapData = imgd.background as VBitmapData;
				if (!imgd.background || (vbmdBG && !vbmdBG.valid)) {
					imgd.OnMemoryError(new Error());
					return false;
				}

				if (_openg == null)
					_openg = new OpEngine(this);
					
				var bmdr:BitmapReference = _openg.Do(imgd, fDoObjects, fUseCache);
				BitmapCache.AddDisposable(_openg);
				
				if (fUseCache) {
					imgd.interactiveBackground = bmdr;
				} else {
					var bmdResult:BitmapData;
					if (imgd.background == bmdr._bmd) {
						// UNDONE: Use reference counting so we don't need to always
						// return a new bitmap.
						// Once we do that, we won't need to make this clone.
						bmdResult = imgd.background.clone();
					} else {
						bmdr.MakeExternal();
						bmdResult = bmdr._bmd;
					}
					imgd.background = bmdResult;
				}
				bmdr.dispose();
				// imgd.background = bmdResult;

				// If fUseCache is true, our op engine might be hanging on to cached objects
				// if fUseCache is false, our op engine is no longer hanging on to any objects

				// It's up to the caller to dispose the old background. Normally this is handled by
				// ImageDocument.EndUndoTransaction()
				imgd.RecordImageOperation(this);
			} catch (errInvalidBitmap:InvalidBitmapError) {
				// NOTE: OnMemoryError is smart enough to report on all InvalidBitmapErrors, not just memory	
				imgd.OnMemoryError(errInvalidBitmap);	
				return false;
				
			// Known ImageOperation exceptions:
			// - FP9 tries to execute an FP10-specific operation (e.g. ShaderImageOperation)
			} catch (err:Error) {
				var strClassName:String = getQualifiedClassName(this);
				PicnikService.Log("Exception: " + strClassName + ".Do " + err + ", " + err.getStackTrace(), PicnikService.knLogSeverityInfo);
				return false;
			}
			PerformanceManager.OnImageOperationDo(new Date().time - nStart);
			return true;
		}

		// Return a new BitmapData with the operation applied to the data in bmdSrc		
		public function Apply(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean=false): BitmapData {
			Debug.Assert(false, "ImageOperation.Apply must be overridden!");
			return null;
		}
		
		// All ImageOperations are given a chance to Undo themselves but most non-ObjectOperations
		// leave the job to the ImageDocument which will restore the entire image. An exception
		// is the NestedImageOperation which asks its children to Undo themselves.
		public function Undo(imgd:ImageDocument): Boolean {
			return true;
		}

		// Override in sub-classes
		public function Compile(ainst:Array): void {
			ainst.push(new ApplyInstruction(this, Serialize()));
			ainst.push(new PopInstruction(1));
		}

		// Apply the effect to a bitmap and return a new bitmap.
		// Does not dispose of the old bitmap.
		public function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			// Apply all of the children
			return bmdSrc.clone();
		}

		public static function XMLToImageOperation(xmlOp:XML): ImageOperation {
			// Create ImageOperation instances by looking up their class
			// ("imagine.imageOperations." + op name + "ImageOperation") dynamically
			var strClassName:String = "imagine.imageOperations." + xmlOp.localName();
			// Special case for "SetVar" since we don't want this to look like an image operation.
			if (xmlOp.localName() != "SetVar") strClassName += "ImageOperation";
			
			var clsImageOperation:Class;
			try {
				clsImageOperation = getDefinitionByName(strClassName) as Class;
			} catch (err:ReferenceError) {
				// Maybe it is an ObjectOperation
				strClassName = "imagine.objectOperations." + xmlOp.localName() + "ObjectOperation";
				try {
					clsImageOperation = getDefinitionByName(strClassName) as Class;
				} catch (err:ReferenceError) {
					Debug.Assert(false, "Unknown ImageOperation " + xmlOp.localName());
					return null;
				}
			}
			var op:ImageOperation = new clsImageOperation();
			if (!op.Deserialize(xmlOp)) {
				return null;
			}
			return op;
		}
	}
}
