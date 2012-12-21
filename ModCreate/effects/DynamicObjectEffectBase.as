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
package effects {
	import containers.EffectCanvas;
	import containers.NestedControlCanvasBase;
	import containers.NestedControlEvent;

	import imagine.imageOperations.ImageOperation;
	
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	public class DynamicObjectEffectBase extends EffectCanvas {
		[Bindable] public var _strObjectNameRoot:String = null;
				
		private var _strObjectNameRootCreated:String = null;
		private var _obObjectProperties:Object = {};
		
		public function DynamicObjectEffectBase() {
			super();
			_strObjectNameRoot = Util.GetUniqueId();
			_strObjectNameRootCreated = null;
			
			this.addEventListener(NestedControlEvent.SELECTED_EFFECT_UPDATED_BITMAPDATA, OnEffectUpdated);
		}
		
		override public function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null):void {
			super.Deselect(fForceRollOutEffect, efcvsNew);
			_strObjectNameRoot = Util.GetUniqueId(); // Create a new unique ID for next time.
			_strObjectNameRootCreated = null;
			_obObjectProperties = {};
		}

		protected function UpdateObjectProperties(nWidth:Number, nHeight:Number, nRandSeed:Number=1): void {
			// overridden in baseclasses
		}
		
		protected function SetDynamicObjectProperties( strObjName:String, obProps:Object ): void {
			_obObjectProperties[strObjName] = MergeObjects( (strObjName in _obObjectProperties) ? _obObjectProperties[strObjName] : {}, obProps );
		}
		
		override protected function UpdateBitmapData():void {
			UpdateObjectProperties(imagewidth, imageheight);
			super.UpdateBitmapData();
		}
		
		protected function OnDynamicObjectParamChange(): void {
			UpdateObjectProperties(imagewidth, imageheight);
			OnDynamicObjectPropsChanged();
		}
		
		private function OnEffectUpdated(evt:Event):void {
			_strObjectNameRootCreated = _strObjectNameRoot;
		}
		
		protected function GetExtraParams(): Object {
			return {};
		}
		
		protected function GetObjectName(strObj:String):String {
			return _strObjectNameRoot+strObj;
		}	
			
		private function MergeObjects(ob1:Object, ob2:Object): Object {
			var obOut:Object = {};
			var strKey:String;
			for (strKey in ob1)
				obOut[strKey] = ob1[strKey];
			for (strKey in ob2)
				obOut[strKey] = ob2[strKey];
			return obOut;
		}
		
		private var _fObjectPropertiesSet:Boolean = false;
		
		protected function OnDynamicObjectPropsChanged(): void {
			if (_imgd != null && _strObjectNameRoot == _strObjectNameRootCreated && _strObjectNameRootCreated != null) {
				// If the CreateObjectOperation hasn't been committed, do so. Otherwise,
				// rollback the previous SetPropertiesObjectOperation.
				_imgd.EndUndoTransaction(!_fObjectPropertiesSet); // rollback, don't clear cache
				
				_imgd.BeginUndoTransaction(name, true, false); // fCacheInUse = true
				
				for (var strObjName:String in _obObjectProperties) {
					var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(GetObjectName(strObjName),
							MergeObjects(_obObjectProperties[strObjName], GetExtraParams()));
					spop.Do(_imgd);
				}
				_fObjectPropertiesSet = true;
			}
		}
		
		public override function Revert(): void {
			if (_fObjectPropertiesSet) {
				_fObjectPropertiesSet = false;
				
				// _imgd may be cleared by the time Revert is called. Use _imgdCleanup.
				if (_imgdCleanup) {
					// Undo the SetPropertiesObjectOperation
					_imgdCleanup.EndUndoTransaction(false, false);
					
					// Undo the CreateObjectOperation
					_imgdCleanup.Undo();
					
					// Don't leave an unexpected operation on the redo stack
					_imgdCleanup.ClearRedo();
				}
			}
			super.Revert();
		}

		public override function Apply(): void {
			if (_fObjectPropertiesSet) {
				_fObjectPropertiesSet = false;
				_imgd.EndUndoTransaction(false, false);
				_imgd.Undo();
				_imgd.BeginUndoTransaction(name, true, false);
				if (!(operation as ImageOperation).Do(_imgd, true, true)) // fUseCache == true
					_imgd.AbortUndoTransaction();
			}

			// Force double composite validation
			// Frames invalide the composite during validation - which can result in an
			// invalid composite.
			// UNDONE: Fix this properly in ImageDocument.ValidateComposite()
			_imgd.composite; // Force composite validation.
			_imgd.InvalidateComposite();
			_imgd.composite; // Force composite validation.
			
			super.Apply();
		}
	}
}