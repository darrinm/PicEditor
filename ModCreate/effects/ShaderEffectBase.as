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
// Our Pixel Bender metadata extensions:
// Shader
// - title (takes precedence over "name")
// - author (takes precedence over "vendor")
// - iconURL (string)
// - websiteURL (string)
// - defaultBlendMode (string)
// - canvasTip (string)
//
// Parameter
// - title (takes precedence over "name")
// - snapInterval (int/float)
// - visible (string boolean)
// - controller
// 		mouseXY (float2)
//		imageWidthHeight (float2)
//		mouseX (float) [use mouseX,mouseY instead of mouseXY]
//		mouseY (float)
//		imageWidth (float) -- makes sense to auto-center? deformer just wants the height value
//		imageHeight (float)
//		color (float3)
//		colorSampler (float3)
//		TBD: checkbox

package effects {
	import com.adobe.crypto.MD5;
	
	import containers.NestedControlCanvasBase;
	import containers.PaintEffectCanvas;
	
	import controls.ComboBoxPlus;
	import controls.HSliderPlus;
	
	import effects.components.Color;
	import effects.components.Range;
	import effects.components.Range2;
	import effects.components.Range3;
	import effects.components.Range4;
	
	import flash.display.BlendMode;
	import flash.display.Shader;
	import flash.display.ShaderInput;
	import flash.display.ShaderParameter;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.VBox;
	import mx.events.PropertyChangeEvent;
	import mx.utils.Base64Encoder;
	import mx.utils.ObjectUtil;
	
	public class ShaderEffectBase extends PaintEffectCanvas {
		[Bindable] public var _vbxParameters:VBox;
		[Bindable] public var _sldrFade:HSliderPlus;
		[Bindable] public var _cbBlendMode:ComboBoxPlus;
		[Bindable] public var _strHelpText:String;

		[Bindable] public var title:String;
		[Bindable] public var author:String;
		[Bindable] public var description:String;
		[Bindable] public var iconURL:String = PicnikBase.StaticUrl("../graphics/effects/shader_default.png");
		[Bindable] public var liveBlendMode:String = BlendMode.NORMAL;
		
		private var _baByteCode:ByteArray;
		private var _shdr:Shader;
		private var _obParams:Object = {};
		
		private var _ashdp:Array;
		private var _ashdi:Array;
		private var _strCanvasTip:String;
		private var _fReady:Boolean = false;
		private var _fPaintOnByDefault:Boolean = true;	// painting on by default
		
		// Used by EffectCanvasBase to produce the effect_applied string logged to GA
		override public function get className(): String {
			return super.className + (title ? "/" + title : "");
		}
		
		[Bindable]
		public function set bytecode(ba:ByteArray): void {
			// Create a unique ID for this shader that can be used to remember whether
			// its tip has been closed.
			var b64e:Base64Encoder = new Base64Encoder();
			b64e.encodeBytes(ba);
			id = "shader_" + MD5.hash(b64e.drain());
			
			_baByteCode = ba;
			_shdr = new Shader(_baByteCode);
			
			// "title" is a non-standard Shader metadata extension of our invention.
			// Its purpose is to allow richer names than the identifier-syntax
			// limited "name" metadata field, e.g. "Hex Cells" vs. "HexCells"
			// UNDONE: {locale}_title, description, parameter titles
			if ("title" in _shdr.data && _shdr.data.title != "")
				title = _shdr.data.title;
			else if ("name" in _shdr.data && _shdr.data.name != "")
				title = _shdr.data.name;
			if ("author" in _shdr.data && _shdr.data.author != "")
				author = Resource.getString("ShaderEffect", "shader_author_prefix") + " " + _shdr.data.author;
			else if ("vendor" in _shdr.data && _shdr.data.vendor != "")
				author = Resource.getString("ShaderEffect", "shader_author_prefix") + " " + _shdr.data.vendor;
			if ("description" in _shdr.data && _shdr.data.description != "")
				description = _shdr.data.description;
			else
				description = Resource.getString("ShaderEffect", "_strHelpText");
			if ("websiteURL" in _shdr.data && _shdr.data.websiteURL != "")
				description += "<br><br>" + _shdr.data.websiteURL;
			
			// "iconURL" is a non-standard Shader metadata extension of our invention.
			// We support relative references to images on our own servers, e.g. "../graphics/effects/holga.png"
			// and fully qualified URLs to external servers. The loaded image will be resized to fit the 66x54
			// space provided in the Effect UI.
			if ("iconURL" in _shdr.data)
				iconURL = _shdr.data.iconURL;
		}
		
		public function get bytecode(): ByteArray {
			return _baByteCode;
		}
		
		[Bindable]
		public function set params(obParams:Object): void {
			_obParams = obParams;
		}
		
		public function get params(): Object {
			return _obParams;
		}
		
		private var _xdMouse:int, _ydMouse:int;
		
		[Bindable]
		public function set documentMouseX(xd:int): void {
			_xdMouse = xd;
		}
		
		public function get documentMouseX(): int {
			return _xdMouse;
		}
		
		[Bindable]
		public function set documentMouseY(yd:int): void {
			_ydMouse = yd;
		}
		
		public function get documentMouseY(): int {
			return _ydMouse;
		}
		
		override protected function get canvasTipId(): String {
			return id;
		}
		
		override protected function get canvasTip(): String {
			return _strCanvasTip;
		}
		
		override protected function OnAllStagesCreated(): void {
			if (bytecode)
				UpdateUI();
				
			// super's OnAllStagesCreated sets the effect button's height and starts animating it open
			super.OnAllStagesCreated();
		}
		
		private var _fBrushPaletteOriginallyActive:Boolean;
		
		override public function Select(efcnvCleanup:NestedControlCanvasBase): Boolean {
			showBrushPalette = false;
			
			// super.Select must be done before UpdateUI because it initializes things that UpdateUI
			// needs. BUT it will also attempt to show the brush palette. That is bad because UpdateUI
			// determines whether painting should be enabled by default. SO here we make sure it won't
			// be displayed unintentially. Then we'll decide whether to show it after UpdateUI.
			_fBrushPaletteOriginallyActive = isBrushPalettePersistentlyActive;
			
			var fSelected:Boolean = super.Select(efcnvCleanup);
			if (fSelected) {
				UpdateUI();
				brushPalette.validateNow();
				
				if (_fBrushPaletteOriginallyActive) {
					if (_fPaintOnByDefault) {
						showBrushPalette = true;
						TakeBrushPaletteState();
					} else {
						CloseBrushPalette();
					}
				}
			}
			return fSelected;
		}
		
		override public function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null): void {
			var fRestore:Boolean = IsSelected() && !_fPaintOnByDefault;
			super.Deselect(fForceRollOutEffect, efcvsNew);
			
			// We override the brush palette's initial state if _fPaintOnByDefault is false.
			// Restore it as we leave.
			if (fRestore) {
				brushPalette.active = _fBrushPaletteOriginallyActive;
				isBrushPalettePersistentlyActive = _fBrushPaletteOriginallyActive;
			}
		}
		
		override public function OnOverlayPress(evt:MouseEvent): Boolean {
			super.OnOverlayPress(evt);
			if (!brushActive)
				UpdateDocumentMouseXY();
			return true;
		}
		
		// Override this because DrawOverlayEffectCanvaseBase will avoid calling OnOverlayMouseDrag
		// if !brushActive.
		override public function OnOverlayMouseMove(): Boolean {
			super.OnOverlayMouseMove();
			
			if (!brushActive) {
				if (_fOverlayMouseDown) return OnOverlayMouseDrag();
				else return false;
			} else {
				return true;
			}
		}
		
		override public function OnOverlayMouseDrag(): Boolean {
			super.OnOverlayMouseDrag();
			if (!brushActive)
				UpdateDocumentMouseXY();
			return true;
		}
		
		private function UpdateDocumentMouseXY(): void {
			var ptd:Point = overlayMouseAsPtd;
			documentMouseX = ptd.x;
			documentMouseY = ptd.y;
		}
		
		// UNDONE: clean this sorry code up. Way too much duplication.		
		private function UpdateUI(): void {
			params = {};
			_sldrFade.value = 0;
			_cbBlendMode.selectedIndex = 0;
			liveBlendMode = "defaultBlendMode" in _shdr.data ? _shdr.data.defaultBlendMode : BlendMode.NORMAL;
			var aobBlendModes:Array = _cbBlendMode.dataProvider.source;
			for (var i:int = 0; i < aobBlendModes.length; i++) {
				if (aobBlendModes[i].data == liveBlendMode) {
					_cbBlendMode.selectedIndex = i;
					break;
				}
			}
			
			if ("canvasTip" in _shdr.data)
				_strCanvasTip = _shdr.data.canvasTip;
			
			// Update the Effect UI to reflect the Shader's parameters
			_ashdp = [];
			_ashdi = [];
			for (var strProp:String in _shdr.data) {
				var obT:Object = _shdr.data[strProp];
				if (obT is ShaderParameter)
					_ashdp[ShaderParameter(obT).index] = obT;
				else if (obT is ShaderInput)
					_ashdi[ShaderInput(obT).index] = obT;
//				else
//					trace(strProp + ": " + obT);
			}
				
			// Parameters
			// UNDONE: clean up event listeners
			_vbxParameters.removeAllChildren();
			
			for (i = 0; i < _ashdp.length; i++) {
				var shdp:ShaderParameter = ShaderParameter(_ashdp[i]);
				switch (shdp.type) {
				case "float":
				case "int":
					var rng:Range = new Range();
					ApplyCommonMetadata(rng, shdp);
					if ("controller" in shdp) {
						switch (shdp.controller) {
						case "mouseX":
						case "imageWidth":
							rng.minimum = 0;
							rng.maximum = _imgd.width - 1;
							rng.defaultValue = _imgd.width / 2;
							rng.snapInterval = 1;
							break;
							
						case "mouseY":
						case "imageHeight":
							rng.minimum = 0;
							rng.maximum = _imgd.height - 1;
							rng.defaultValue = _imgd.height / 2;
							rng.snapInterval = 1;
							break;
						}
						
						if (shdp.controller == "mouseX") {
							_fPaintOnByDefault = false;
							documentMouseX = rng.defaultValue;
							BindingUtils.bindProperty(rng, "defaultValue", this, "documentMouseX");
							ChangeWatcher.watch(this, "documentMouseX", GetOnRangeChangeWrapper(rng));
						}
							
						if (shdp.controller == "mouseY") {
							_fPaintOnByDefault = false;
							documentMouseY = rng.defaultValue;
							BindingUtils.bindProperty(rng, "defaultValue", this, "documentMouseY");
							ChangeWatcher.watch(this, "documentMouseY", GetOnRangeChangeWrapper(rng));
						}
					} else {
						rng.minimum = ("minValue" in shdp) ? shdp.minValue[0] : 0.0;
						rng.maximum = ("maxValue" in shdp) ? shdp.maxValue[0] : 1.0;
						rng.defaultValue = ("defaultValue" in shdp) ? shdp.defaultValue[0] : 0.0;
					}
					if ("snapInterval" in shdp)
						rng.snapInterval = shdp.snapInterval;
					rng.addEventListener(Event.CHANGE, OnRangeChange);
					_vbxParameters.addChild(rng);
					_OnRangeChange(rng);
					break;
					
				case "float2":
				case "int2":
					var rng2:Range2 = new Range2();
					ApplyCommonMetadata(rng2, shdp);
					if ("controller" in shdp && (shdp.controller == "mouseXY" || shdp.controller == "imageWidthHeight")) {
						rng2.minimum1 = 0;
						rng2.maximum1 = _imgd.width - 1;
						rng2.defaultValue1 = _imgd.width / 2;
						rng2.snapInterval1 = 1;
						
						rng2.minimum2 = 0;
						rng2.maximum2 = _imgd.height - 1;
						rng2.defaultValue2 = _imgd.height / 2;
						rng2.snapInterval2 = 1;

						if (shdp.controller == "mouseXY") {
							_fPaintOnByDefault = false;
							documentMouseX = rng2.defaultValue1;
							BindingUtils.bindProperty(rng2, "defaultValue1", this, "documentMouseX");
							ChangeWatcher.watch(this, "documentMouseX", GetOnRangeChangeWrapper(rng2));
							
							documentMouseY = rng2.defaultValue2;
							BindingUtils.bindProperty(rng2, "defaultValue2", this, "documentMouseY");
							ChangeWatcher.watch(this, "documentMouseY", GetOnRangeChangeWrapper(rng2));
						}
					} else {
						rng2.minimum1 = ("minValue" in shdp) ? shdp.minValue[0] : 0.0;
						rng2.maximum1 = ("maxValue" in shdp) ? shdp.maxValue[0] : 1.0;
						rng2.defaultValue1 = ("defaultValue" in shdp) ? shdp.defaultValue[0] : 0.0;
						rng2.minimum2 = ("minValue" in shdp) ? shdp.minValue[1] : 0.0;
						rng2.maximum2 = ("maxValue" in shdp) ? shdp.maxValue[1] : 1.0;
						rng2.defaultValue2 = ("defaultValue" in shdp) ? shdp.defaultValue[1] : 0.0;
					}
					if ("snapInterval" in shdp) {
						rng2.snapInterval1 = shdp.snapInterval[0];
						rng2.snapInterval2 = shdp.snapInterval[1];
					}
					rng2.addEventListener(Event.CHANGE, OnRangeChange);
					_vbxParameters.addChild(rng2);
					_OnRangeChange(rng2);
					break;
					
				case "float3":
				case "int3":
					if ("controller" in shdp) {
						switch (shdp.controller) {
						case "colorSampler":
						case "color":
							var clrsw:Color = new Color();
							ApplyCommonMetadata(clrsw, shdp);
							if ("defaultValue" in shdp) {
								clrsw.defaultValue = (Math.round(shdp.defaultValue[0] * 255) << 16) +
										(Math.round(shdp.defaultValue[1] * 255) << 8) + Math.round(shdp.defaultValue[2] * 255); 								
							}
							if (shdp.controller == "colorSampler") {
								_fPaintOnByDefault = false;
								BindingUtils.bindProperty(clrsw, "documentMouseX", this, "documentMouseX");
								BindingUtils.bindProperty(clrsw, "documentMouseY", this, "documentMouseY");
							}
							clrsw.addEventListener(Event.CHANGE, OnColorChange);
							_vbxParameters.addChild(clrsw);
							break;							
						}
					} else {
						var rng3:Range3 = new Range3();
						ApplyCommonMetadata(rng3, shdp);
						rng3.minimum1 = ("minValue" in shdp) ? shdp.minValue[0] : 0.0;
						rng3.maximum1 = ("maxValue" in shdp) ? shdp.maxValue[0] : 1.0;
						rng3.defaultValue1 = ("defaultValue" in shdp) ? shdp.defaultValue[0] : 0.0;
						rng3.minimum2 = ("minValue" in shdp) ? shdp.minValue[1] : 0.0;
						rng3.maximum2 = ("maxValue" in shdp) ? shdp.maxValue[1] : 1.0;
						rng3.defaultValue2 = ("defaultValue" in shdp) ? shdp.defaultValue[1] : 0.0;
						rng3.minimum3 = ("minValue" in shdp) ? shdp.minValue[2] : 0.0;
						rng3.maximum3 = ("maxValue" in shdp) ? shdp.maxValue[2] : 1.0;
						rng3.defaultValue3 = ("defaultValue" in shdp) ? shdp.defaultValue[2] : 0.0;
						if ("snapInterval" in shdp) {
							rng3.snapInterval1 = shdp.snapInterval[0];
							rng3.snapInterval2 = shdp.snapInterval[1];
							rng3.snapInterval3 = shdp.snapInterval[2];
						}
						rng3.addEventListener(Event.CHANGE, OnRangeChange);
						_vbxParameters.addChild(rng3);
						_OnRangeChange(rng3);
					}
					break;
					
				case "float4":
				case "int4":
					var rng4:Range4 = new Range4();
					ApplyCommonMetadata(rng4, shdp);
					rng4.minimum1 = ("minValue" in shdp) ? shdp.minValue[0] : 0.0;
					rng4.maximum1 = ("maxValue" in shdp) ? shdp.maxValue[0] : 1.0;
					rng4.defaultValue1 = ("defaultValue" in shdp) ? shdp.defaultValue[0] : 0.0;
					rng4.minimum2 = ("minValue" in shdp) ? shdp.minValue[1] : 0.0;
					rng4.maximum2 = ("maxValue" in shdp) ? shdp.maxValue[1] : 1.0;
					rng4.defaultValue2 = ("defaultValue" in shdp) ? shdp.defaultValue[1] : 0.0;
					rng4.minimum3 = ("minValue" in shdp) ? shdp.minValue[2] : 0.0;
					rng4.maximum3 = ("maxValue" in shdp) ? shdp.maxValue[2] : 1.0;
					rng4.defaultValue3 = ("defaultValue" in shdp) ? shdp.defaultValue[2] : 0.0;
					rng4.minimum4 = ("minValue" in shdp) ? shdp.minValue[3] : 0.0;
					rng4.maximum4 = ("maxValue" in shdp) ? shdp.maxValue[3] : 1.0;
					rng4.defaultValue4 = ("defaultValue" in shdp) ? shdp.defaultValue[3] : 0.0;
					if ("snapInterval" in shdp) {
						rng4.snapInterval1 = shdp.snapInterval[0];
						rng4.snapInterval2 = shdp.snapInterval[1];
						rng4.snapInterval3 = shdp.snapInterval[2];
						rng4.snapInterval4 = shdp.snapInterval[3];
					}
					rng4.addEventListener(Event.CHANGE, OnRangeChange);
					_vbxParameters.addChild(rng4);
					_OnRangeChange(rng4);
					break;
				}
			}
			
			OnOpChange();
		}
		
		// We can't produce the wrapper in-line because it will end up referencing a variable in its
		// containing scope that will change as UpdateUI iterates. By calling this function a new
		// reference is created.
		private function GetOnRangeChangeWrapper(rng:Object): Function {
			return function (evt:PropertyChangeEvent): void { _OnRangeChange(rng) };
		}
		
		static private function ApplyCommonMetadata(rng:Object, shdp:ShaderParameter): void {
			rng.data = shdp;
			rng.type = shdp.type;
			if ("description" in shdp)
				rng.toolTip = shdp.description;
			// Use the parameter title if there is one, otherwise Up-case the first character of the parameter name
			if ("title" in shdp)
				rng.label = shdp.title;
			else
				rng.label = String(shdp.name).charAt(0).toLocaleUpperCase() + String(shdp.name).slice(1);
			if ("visible" in shdp && shdp.visible == "false") {
				rng.visible = false;
				rng.includeInLayout = false;
			}
		}
		
		private function OnRangeChange(evt:Event): void {
			_OnRangeChange(evt.target);
		}
		
		private function _OnRangeChange(rng:Object): void {
			var obNewParams:Object = ObjectUtil.copy(params);
			
			var shdp:ShaderParameter = rng.data;
			switch (shdp.type) {
			case "float":
			case "int":
				obNewParams[shdp.name] = [ rng.value ];
				break;
				
			case "float2":
			case "int2":
				obNewParams[shdp.name] = [ rng.value1, rng.value2 ];
				break;
				
			case "float3":
			case "int3":
				obNewParams[shdp.name] = [ rng.value1, rng.value2, rng.value3 ];
				break;
				
			case "float4":
			case "int4":
				obNewParams[shdp.name] = [ rng.value1, rng.value2, rng.value3, rng.value4 ];
				break;
			}
			params = obNewParams;
			
			OnOpChange();
		}
		
		private function OnColorChange(evt:Event): void {
			var obNewParams:Object = ObjectUtil.copy(params);
			
			var clrsw:Color = evt.target as Color;
			var shdp:ShaderParameter = clrsw.data as ShaderParameter;
			switch (shdp.type) {
			case "float3":
			case "int3":
				obNewParams[shdp.name] = [ ((clrsw.value & 0xff0000) >> 16) / 255.0,
						((clrsw.value & 0x00ff00) >> 8) / 255.0, (clrsw.value & 0x0000ff) / 255.0 ];
				break;
			}
			params = obNewParams;
			
			OnOpChange();
		}
	}
}
