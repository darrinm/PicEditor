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
package objectPalette {
	import controls.ComboBoxPlus;
	import controls.EyeDropperButton;
	import controls.HSBColorSwatch;
	import controls.HSliderPlus;
	import controls.TextInputPlusBase;
	
	import imagine.documentObjects.DocumentObjectBase;
	import imagine.documentObjects.DocumentObjectUtil;
	import imagine.documentObjects.IDocumentObject;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import imagine.ImageDocument;
	
	import mx.collections.ArrayCollection;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.events.DropdownEvent;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.events.SliderEvent;
	import mx.resources.ResourceBundle;
	
	public class CommonPaletteBase extends VBox {
		[Bindable] public var _btnDelete:Button;
		[Bindable] public var _sldrAlpha:HSliderPlus;
		[Bindable] public var _clrsw:HSBColorSwatch;
		[Bindable] public var _eyeb:EyeDropperButton;
		[Bindable] public var _cbBlendMode:ComboBoxPlus;
		[Bindable] public var _tiColorValue:TextInputPlusBase;
		
		[Bindable] public var _doco:IDocumentObject;
		[Bindable] public var title:String;
		
		public var _imgd:ImageDocument;
		
  		[Bindable] [ResourceBundle("CommonPaletteBase")] protected var _rb:ResourceBundle;
		
		public function CommonPaletteBase() {
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
		}
		
		protected function OnInitialize(evt:Event): void {
			if (_btnDelete)
				_btnDelete.addEventListener(MouseEvent.CLICK, DeleteSelected);
			
			// When these controls change we want to add UndoTransactions
			if (_sldrAlpha) {
				_sldrAlpha.addEventListener(SliderEvent.THUMB_RELEASE, OnAlphaSliderThumbRelease);
				_sldrAlpha.addEventListener(SliderEvent.CHANGE, OnAlphaSliderChange);
			}
			
			// When these controls change we want to add UndoTransactions
			if (_clrsw) {
				_clrsw.addEventListener(Event.CHANGE, OnColorChange);
				_clrsw.addEventListener(MouseEvent.MOUSE_UP, OnColorMouseUp);
			}
			
			// When these controls change we want to add UndoTransactions
			if (_eyeb)
				_eyeb.addEventListener(Event.CHANGE, OnColorChange);
			
			if (_cbBlendMode) {
				_cbBlendMode.addEventListener(DropdownEvent.OPEN, OnBlendModeOpen);
				_cbBlendMode.addEventListener(ListEvent.CHANGE, OnBlendModeChange);
			}
			
			if (_tiColorValue) {
				// listen for escape (cancel), enter (apply), focus out (cancel), focus in (select all)
				_tiColorValue.addEventListener(FlexEvent.ENTER, OnColorValueEnter);
				_tiColorValue.addEventListener(KeyboardEvent.KEY_DOWN, OnColorValueKeyDown);
				_tiColorValue.addEventListener(FocusEvent.FOCUS_OUT, OnColorValueFocusOut);
				_tiColorValue.addEventListener(FocusEvent.FOCUS_IN, OnColorValueFocusIn);
			}
		}
		
		private var _strOpenBlendMode:String;

		// Remember the blendMode state before the interactive updates to it begin		
		private function OnBlendModeOpen(evt:DropdownEvent): void {
			if (!_doco)
				return;
				
			_strOpenBlendMode = _doco.blendMode;
		}
		
		private function OnBlendModeChange(evt:ListEvent): void {
			if (!_doco)
				return;
				
			// Restore the blendMode to its initial state so AddPropertyChangeToUndo will know what to undo to
			var strNewVal:String = _doco.blendMode;
			_doco.blendMode = _strOpenBlendMode;
			
			DocumentObjectUtil.AddPropertyChangeToUndo("Change " + DocumentObjectUtil.objectTypeName(_doco) + " BlendMode",
					_imgd, _doco as DisplayObject, { blendMode: strNewVal }, false);
		}
		
		private function OnAlphaSliderChange(evt:SliderEvent): void {
			// Don't do anything if the alpha isn't really changing
			if (!_doco || evt.target.value == _doco.alpha)
				return;
				
			DocumentObjectUtil.AddPropertyChangeToUndo("Change " + DocumentObjectUtil.objectTypeName(_doco) + " Alpha",
					_imgd, _doco as DisplayObject, { alpha: 1 - evt.target.value }, true);
		}
		
		protected function OnAlphaSliderThumbRelease(evt:SliderEvent): void {
			DocumentObjectUtil.SealUndo(_imgd);
		}
		
		protected function OnColorChange(evt:Event): void {
			// Don't do anything if the color isn't really changing
			if (!_doco || evt.target.color == _doco.color)
				return;
			
			DocumentObjectUtil.AddPropertyChangeToUndo("Change " + DocumentObjectUtil.objectTypeName(_doco) + " Color",
					_imgd, _doco as DisplayObject, { color: evt.target.color }, true);
		}

		// Swiped from Flex's color picker		
		protected function HexFromRGB(color:uint): String {
			// Find hex number in the RGB offset
			var colorInHex:String = color.toString(16);
			var c:String = "00000" + colorInHex;
			var e:int = c.length;
			c = c.substring(e - 6, e);
			return c.toUpperCase();
		}
   
		protected function OnColorMouseUp(evt:MouseEvent): void {
			DocumentObjectUtil.SealUndo(_imgd);
		}
		
		protected function DeleteSelected(evt:MouseEvent=null): void {
			DocumentObjectUtil.Delete(_doco, _imgd);
		}
		
		protected function FlipSelected(fHorizontal:Boolean=true): void {
			DocumentObjectUtil.Flip(_doco, _imgd, fHorizontal);
		}
		
		private var _aBlendModes:ArrayCollection = null;
		
		private static const _aobBlendModeKeys:Array = [
		    {key:"Normal", data:"normal"},
		    {key:"Add", data:"add"},
		    {key:"Darken", data:"darken"},
		    {key:"Difference", data:"difference"},
		    {key:"Hardlight", data:"hardlight"},
		    {key:"Lighten", data:"lighten"},
		    {key:"Multiply", data:"multiply"},
		    {key:"Overlay", data:"overlay"},
		    {key:"Screen", data:"screen"},
		    {key:"Subtract", data:"subtract"}
		];
		
		[Bindable]
		public function set aBlendModes(ac:ArrayCollection): void {
			_aBlendModes = ac;
		}
		
		public function get aBlendModes(): ArrayCollection {
			if (_aBlendModes == null) {
				// Initialize
				var aBlendModes:Array = [];
				for each (var ob:Object in _aobBlendModeKeys) {
					aBlendModes.push({label:Resource.getString("CommonPaletteBase", ob.key), data:ob.data});
				}
				_aBlendModes = new ArrayCollection(aBlendModes);
			}
			return _aBlendModes;
		}
		
		public function GetBlendModeIndex(strVal:String): Number {
			var i:Number = 0;
			for (i = 0; i < aBlendModes.length; i++) {
				if (aBlendModes[i].data == strVal) return i;
			}
			
			return 0; // Not found. Default to normal
		}
		
		//
		// Support for entering color hex values by hand
		//
		
		private function OnColorValueEnter(evt:FlexEvent): void {
			_clrsw.color = parseInt(_tiColorValue.text, 16);
			setFocus(); // Take the focus away from the TextInput
		}
		
		private function OnColorValueKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode != Keyboard.ESCAPE)
				return;
			setFocus(); // Take the focus away from the TextInput
		}
		
		private function OnColorValueFocusOut(evt:FocusEvent): void {
			// Restore the TextInput's value to the current color
			_tiColorValue.text = HexFromRGB(DocumentObjectBase(_doco).color);
		}
		
		private function OnColorValueFocusIn(evt:FocusEvent): void {
			// Select the whole string for easy type over
			_tiColorValue.setSelection(0, _tiColorValue.text.length);
		}
	}
}
