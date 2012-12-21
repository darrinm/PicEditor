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
package controls
{
	import mx.core.UIComponent;

	public class BackgroundGradientModes
	{
		private var _uicParent:UIComponent;
		private var _astrModes:Array;
		private var _strMode:String = null;
		private var _obBackgroundModeStyles:Object = {};
		
		public function BackgroundGradientModes(uicParent:UIComponent=null, astrModes:Array=null)
		{
			_uicParent = uicParent;
			_astrModes = astrModes;
			Init();
		}
		
		public function set modes(astrModes:Array): void {
			_astrModes = astrModes;
			Init();
		}
		
		public function set parent(uicParent:UIComponent): void {
			_uicParent = uicParent;
			Init();
		}
		
		private function Init(): void {
			if (_uicParent == null || _astrModes == null)
				return;
			_obBackgroundModeStyles = {};
			for each (var strMode:String in _astrModes) {
				var obModeStyles:Object = {};
				_obBackgroundModeStyles[strMode] = obModeStyles;
				for each (var strSuffix:String in ['Colors', 'Alphas', 'Ratios']) {
					var strSourceKey:String = strMode + "GradientFill" + strSuffix;
					var strDestKey:String = "gradientFill" + strSuffix;
					var obVal:* = _uicParent.getStyle(strSourceKey);
					if (obVal != undefined) {
						obModeStyles[strDestKey] = obVal;
					}
					strSourceKey = strMode + "-gradient-fill-" + strSuffix.toLowerCase();
					strDestKey = "gradient-fill-" + strSuffix.toLowerCase();
					obVal = _uicParent.getStyle(strSourceKey);
					if (obVal != undefined) {
						obModeStyles[strDestKey] = obVal;
					}
				}
			}
			if (_strMode == null)
				mode = _astrModes[0];
			UpdateStyleForMode();
		}
		
		public function set mode(strMode:String): void {
			if (_strMode == strMode)
				return;
			_strMode = strMode;
			if (_uicParent == null)
				return;
			UpdateStyleForMode();
		}
		
		private function UpdateStyleForMode(): void {
			var obStateStyles:Object = _obBackgroundModeStyles[_strMode];
			var obDefaultStyles:Object = _obBackgroundModeStyles[_astrModes[0]];
			for (var strKey:String in obDefaultStyles) {
				_uicParent.setStyle(strKey, (strKey in obStateStyles) ? obStateStyles[strKey] : obDefaultStyles[strKey]);
			}
		}
	}
}