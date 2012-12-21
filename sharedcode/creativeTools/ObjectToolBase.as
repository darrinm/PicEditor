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
package creativeTools {
	import controls.HSBColorSwatch;
	import controls.HSliderPlus;
	
	import imagine.documentObjects.DocumentObjectUtil;
	import imagine.documentObjects.IDocumentObject;
	
	import events.ActiveDocumentEvent;
	import events.ImageDocumentEvent;
	import events.GenericDocumentEvent;
	
	import flash.events.MouseEvent;
	
	public class ObjectToolBase extends CreativeToolCanvas {
		[Bindable] public var _idoco:IDocumentObject;
		[Bindable] public var _clrsw:HSBColorSwatch; // Optional - test for null
		[Bindable] public var _sldrAlpha:HSliderPlus; // Optional - test for null
		
		public static const knNone:Number = 0;
		public static const knSame:Number = 1;
		public static const knOther:Number = 2;
		public static const knVaried:Number = 3;

		private var _nSelectionType:Number = knNone;

		protected var _fMouseDown:Boolean = false;
		protected var _fListeningForMouse:Boolean = false;
		
		// override these in sub classes
		protected function toolName(): String {
			throw new Error("Subclasses of ObjectToolBase must override toolName: " + this);
			return "object tool";
		}

		protected function DeleteSelected(evt:MouseEvent=null): void {
			DocumentObjectUtil.Delete(_idoco, imgd);
		}
		
		override public function OnActivate(ctrlPrev:ICreativeTool): void {
			super.OnActivate(ctrlPrev);
			if (stage) {
				if (!_fListeningForMouse) {
					stage.addEventListener(MouseEvent.MOUSE_DOWN, OnStageMouseDown, true, 100);
					stage.addEventListener(MouseEvent.MOUSE_UP, OnStageMouseUp, true, 100);
					_fListeningForMouse = true;
				}
			}
		}
		
		override public function OnDeactivate(ctrlNext:ICreativeTool): void {
			_fMouseDown = false;
			super.OnDeactivate(ctrlNext);
		}
		
		protected function OnStageMouseDown(evt:MouseEvent): void {
			_fMouseDown = true;
		}
		
		protected function OnStageMouseUp(evt:MouseEvent): void {
			_fMouseDown = false;
		}
		
		override protected function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			if (_imgd != null) {
				_imgd.removeEventListener(ImageDocumentEvent.SELECTED_ITEMS_CHANGE, OnSelectedItemsChange);
			}
			super.OnActiveDocumentChange(evt);

			if (_imgd != null) {
				_imgd.addEventListener(ImageDocumentEvent.SELECTED_ITEMS_CHANGE, OnSelectedItemsChange);
				
				// Initialize from the currently selected DocumentObject (if any)
				if (_imgd.selectedItems.length != 0) {
					// Defer this assignment so it will happen after the possibly newly created
					// properties panel has completed its initialization
					callLater(function (): void {
						var doco:IDocumentObject = _imgd.selectedItems[0] as IDocumentObject;
						SetDocumentObject(doco.typeSubTab == name ? doco : null);
					});
				} else {
					// Defer this assignment so it will happen after the possibly newly created
					// properties panel has completed its initialization
					callLater(function (): void {
						SetDocumentObject(null);
					});
				}
			}
		}
		
		private function OnSelectedItemsChange(evt:GenericDocumentEvent): void {
			var adoco:Array = evt.obNew;
			
			// If this tool panel is meant to manage this type of object, set it as the
			// current document object.
			if (adoco != null && adoco.length > 0 && adoco[0].typeSubTab == name)
				SetDocumentObject(adoco[0]);
			else
				SetDocumentObject(null);
		}
		
		// Override this as necessary
		protected function SetDocumentObject(doco:IDocumentObject): void {
			_idoco = doco;
		}
	}
}
