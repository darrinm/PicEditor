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
package dialogs.Upsell
{
	import com.adobe.utils.StringUtil;
	
	import containers.ResizingDialog;
	
	import dialogs.CloudyResizingDialog;
	import dialogs.DialogManager;
	import dialogs.RegisterHelper.UpgradePathTracker;
	
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	
	import mx.containers.ViewStack;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	import util.AdManager;
	
	public class TargetedUpsellDialogBase extends CloudyResizingDialog
	{
		// Params to carry forward to old upsell path
		private var _strSourceEvent:String;
		private var _obDefaults:Object;
		
		[Bindable] public var defaultTabName:String = "";
		[Bindable] public var firstRunMode:Boolean = false;

		public override function setVisible(value:Boolean, noEvent:Boolean=false):void {
			super.setVisible(value, noEvent);
			if (noEvent) dispatchEvent(new Event("silentVisibleChange")); // Used by FloatingImage
		}
		
		override public function Hide():void {
			AdManager.GetInstance().OnUpgradeWindowHide();
			super.Hide();
			if (null != _fnComplete) _fnComplete();
		}
		
		protected function ShowPaymentSelector(): void {
			super.Hide();
			DialogManager.ShowPurchase(_strSourceEvent, _uicParent, _fnComplete, _obDefaults);
		}
		
		protected function ShowLogIn(): void {
			super.Hide();
			DialogManager.ShowLogin(_uicParent, _fnComplete);
		}
		
		protected function ShowRegister(): void {
			super.Hide();
			DialogManager.ShowRegister(_uicParent, _fnComplete);
		}
		
		override protected function OnShow(): void {
			UpgradePathTracker.LogPageView('Upsell');
			super.OnShow();
		}
		
		
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			super.Constructor(fnComplete, uicParent, obParams);
			if ('strSourceEvent' in obParams) _strSourceEvent = obParams['strSourceEvent'];
			if ('fFirstRun' in obParams) firstRunMode = obParams['fFirstRun'];
			UpdateDefaultTabName(_strSourceEvent);			
		}
		
		protected function TabNameToIndex(vstk:ViewStack, strTabName:String): Number {
			if (vstk == null) return 0;
			for (var i:Number = 0; i < vstk.numChildren; i++) {
				var obChild:Object = vstk.getChildAt(i);
				if ('area' in obChild && obChild.area == strTabName) return i;
			}
			return 0;
		}
		
		// Will be sorted by length
		private static var kobPrefixMap:Object = {
			fontShop: ['/font', '/create_text'],
			unlimitedHistory: ['/in_history', '/history'],
			multiFile: ['/in_upload', '/home_welcome/upsell100'],
			premEffects: ['/create_effects', '/effect_', 
					'/home_welcome/featured/panography', '/home_welcome/featured/mirroredFrame',
					'/create_'
					],
			// advTools: ['/create_advanced', '/effect_CloneEffect', '/effect_LevelsEffect'],
			curvesEffect: ['/effect_Curves'],
			fullscreen: ['/fullscreen'],
			touchup: ['/create_touchup',
					'/home_welcome/featured/eyecolor',
					'/home_welcome/featured/touchup',
					'/effect_EyeColorEffect',
					'/effect_InstantThinEffect',
					'/effect_HairColorEffect',
					'/effect_BlemishEffect',
					'/effect_ShineEffect',
					'/effect_SkinSmoothing',
					'/effect_WrinkleRemoverEffect',
					'/effect_SprayTanEffect',
					'/effect_BlushEffect',
					'/effect_EyeColorEffect',
					'/effect_EyeWhitenEffect',
					'/effect_MascaraEffect',
					'/effect_TeethWhitenEffect',
					'/effect_LipstickEffect',
					'/effect_GlitterEffect',
					'/effect_Touchup'
			],
			shapes: ['/create_shapes'],
			create: ['/create_frames']
		};
		// shapes: ['/create_shapes'], // Once we add an image and text for premium shapes...
		
		private static var _astrSortedPrefixMaps:Array = null;
		
		private static function ComparePrefixMaps(a:Array, b:Array): Number {
			var nDiff:Number = a[0].length - b[0].length;
			if (nDiff > 0) return -1; // A is larger, should come first
			if (nDiff < 0) return 1; // A is smaller, should come after
			return 0;
		}
		
		private static function get prefixMaps(): Array {
			if (_astrSortedPrefixMaps == null) {
				_astrSortedPrefixMaps = [];
				for (var strKey:String in kobPrefixMap) {
					for each (var strVal:String in kobPrefixMap[strKey]) {
						_astrSortedPrefixMaps.push([strVal, strKey])
					}
				}
				_astrSortedPrefixMaps.sort(ComparePrefixMaps);
			}
			return _astrSortedPrefixMaps;
		}
		
		private function GetDefaultTabName(strSourceEvent:String): String {
			for each (var astrMap:Array in prefixMaps) {
				if (StringUtil.beginsWith(strSourceEvent, astrMap[0])) {
					return astrMap[1];
				}
			}
			return "";
		}
		
		private function UpdateDefaultTabName(strSourceEvent:String): void {
			 defaultTabName = GetDefaultTabName(strSourceEvent);
		}
	}
}
