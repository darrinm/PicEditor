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
	import containers.NestedControlCanvasBase;
	
	import controllers.SpiderWebMSR;
	
	import controls.HSBColorPicker;
	import controls.HSliderFastDrag;
	
	import de.polygonal.math.PM_PRNG;
	
	import imagine.documentObjects.DocumentObjectBase;
	import imagine.documentObjects.IDocumentObject;
	
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.utils.ObjectUtil;
	
	import imagine.objectOperations.CreateObjectOperation;
	
	import util.LocUtil;
	
	public class SpiderWebEffectBase extends DynamicObjectEffectBase {
		[Bindable] public var _op:CreateObjectOperation;
		[Bindable] public var _cpkr:HSBColorPicker;
		[Bindable] public var _cpkrGlow:HSBColorPicker;
		[Bindable] public var _hbxButtons:HBox;
		[Bindable] public var _sldrKookiness:HSliderFastDrag;
		[Bindable] public var _sldrThickness:HSliderFastDrag;
		[Bindable] public var _sldrVariation:HSliderFastDrag;
		[Bindable] public var decay:Number;
		[Bindable] public var drawFrame:Boolean;
		[Bindable] public var hflip:Boolean;
		[Bindable] public var glowBlur:Number;
		[Bindable] public var glowStrength:Number;
		[Bindable] public var radials:Number;
		[Bindable] public var spacing:Number;
		[Bindable] public var style:String;
		
		// The user may have manually moved, sized, or rotated the web. Pull this
		// state directly from the web and permanently add it to the undo history.
		override public function Apply(): void {
			var doco:DocumentObjectBase = GetCreatedObject() as DocumentObjectBase;
			_op["props"].x = doco.x;
			_op["props"].y = doco.y;
			_op["props"].scaleX = doco.scaleX;
			_op["props"].scaleY = doco.scaleY;
			_op["props"].rotation = doco.rotation;
			
			// Force the CreateObjectOperation to be undone and replaced with one that
			// has the above parameters in it.
			OnDynamicObjectPropsChanged();
			super.Apply();
		}
		
		// A random variation is chosen when the effect is opened. Update all the
		// variation-derived parameters as well.
		override public function Select(efcnvCleanup:NestedControlCanvasBase): Boolean {
			var f:Boolean = super.Select(efcnvCleanup);
			OnVariationChange();
			return f;
		}

		// Restore the selection mode to the default
		override public function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null): void {
			_imgv.FilterSelection(ImageView.kFreeSelection);
			super.Deselect(fForceRollOutEffect, efcvsNew);
		}
		
		// After the spider web object has been created, use the special spider web
		// controller that knows to ignore the delete key.
		override protected function UpdateBitmapData(): void {
			super.UpdateBitmapData();
			
			var doco:IDocumentObject = GetCreatedObject();
			if (doco) {
				doco.controller = SpiderWebMSR;
				doco.showObjectPalette = false;
				
				// Limit selection to this one object
				_imgv.FilterSelection(ImageView.kFilterSelection, [ doco ]);
			}
		}
		
		// This override enables selection/manipulation of the SpiderWeb while the Effect is selected.
		override protected function UpdateZoomviewForSelected(fSelected:Boolean): void {
		}
		
		// This override allows us to use OnBufferedOpChange w/o unintended side-effects.
		override public function OnOpChange(): void {
			OnDynamicObjectParamChange();
		}
		
		override protected function UpdateObjectProperties(nWidth:Number, nHeight:Number, nRandSeed:Number=1): void {
			SetDynamicObjectProperties("SpiderWeb", _op["props"]);
		}
		
		// Apply a style (preset properties)				
		public function ApplyStyle(obStyle:Object): void {
			if ("position" in obStyle) {
				if (_imgd.selectedItems.length == 0) {
					var doco:DocumentObjectBase = GetCreatedObject() as DocumentObjectBase;
					if (doco) {
						switch (obStyle.position) {
						case "topleft":
							doco.x = doco.width / 2;
							doco.y = doco.height / 2;
							break;
						
						case "topright":
							doco.x = imagewidth - doco.width / 2;
							doco.y = doco.height / 2;
							break;
						
						default:
							doco.x = imagewidth / 2;
							doco.y = imageheight / 2;
						}
					}
				}
				obStyle = ObjectUtil.copy(obStyle);
				delete obStyle.position;
			}
			
			for (var strProp:String in obStyle) {
				var obValue:* = obStyle[strProp];
				
				switch (strProp) {
				case "style":
					style = obValue;
					break;
				
				case "hflip":
					hflip = obValue;
					break;
				
				case "drawFrame":
					drawFrame = obValue;
					break;
				
				case "decay":
					decay = obValue;
					break;
				
				case "spacing":
					spacing = obValue;
					break;
				
				case "radials":
					radials = obValue;
					break;
				
				case "thickness":
					_sldrThickness.value = obValue;
					break;
				
				case "kookiness":
					_sldrKookiness.value = obValue;
					break;
				
				case "glowBlur":
					glowBlur = obValue;
					break;
				
				case "glowStrength":
					glowStrength = obValue;
					break;
				
				case "glowColor":
					_cpkrGlow.selectedColor = _op["props"][strProp] = obValue;
					break;
				
				case "color":
					_cpkr.selectedColor = _op["props"][strProp] = obValue;
					break;
				
				default:
					_op["props"][strProp] = obValue;
					break;
				}
			}
			
			OnOpChange();
		}
		
		// The Variation slider controls the seed passed to the SpiderWeb DocumentObject
		// plus the thickness, radials, spacing, decay, and kookiness properties.
		// NOTE: image resolution is taken into account when calculating spiral spacing
		// and line thickness.
		protected function OnVariationChange(): void {
			// Improve randomness by spreading seeds apart
			var rnd:PM_PRNG = new PM_PRNG();
			rnd.seed = _sldrVariation.value * 16705;
			
			var degArc:Number;
			if (style == "corner") {
				radials = rnd.nextIntRange(5, 12);
				degArc = 90 / radials;
				spacing = rnd.nextIntRange(degArc * 3, degArc * 8) * Math.min(imagewidth, imageheight) / 2000;
				_sldrThickness.value = rnd.nextIntRange(1, Math.ceil(spacing / 5));
			} else {
				radials = rnd.nextIntRange(6, 40);
				degArc = 360 / radials;
				spacing = rnd.nextIntRange(degArc * 3, degArc * 4) * Math.min(imagewidth, imageheight) / 2000;
				_sldrThickness.value = rnd.nextIntRange(1, Math.ceil(spacing / 3));
			}
			_sldrKookiness.value = rnd.nextIntRange(40, 60);
			decay = rnd.nextIntRange(0, 20);
			
			OnOpChange();
		}
		
		// Make the web type buttons act like radio buttons
		protected function SelectButton(btnToSelect:Button): void {
			if (_hbxButtons == null) return;
			for (var i:Number = 0; i < _hbxButtons.numChildren; i++) {
				var btnChild:Button = _hbxButtons.getChildAt(i) as Button;
				if (btnChild) {
					btnChild.selected = btnToSelect == btnChild;
					if (btnChild.selected)
						ApplyStyle(btnChild.data);
				}
			}
			OnVariationChange();
		}
		
		private function GetCreatedObject(): IDocumentObject {
			if (_imgd == null)
				return null;
			return _imgd.getChildByName(GetObjectName("SpiderWeb")) as IDocumentObject;
		}
		
		protected function GetX(): Number {
			var doco:DocumentObjectBase = GetCreatedObject() as DocumentObjectBase;
			return doco ? doco.x : imagewidth / 2;
		}
		
		protected function GetY(): Number {
			var doco:DocumentObjectBase = GetCreatedObject() as DocumentObjectBase;
			return doco ? doco.y : imageheight / 2;
		}
	}
}
