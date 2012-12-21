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
	import creativeTools.SpecialEffectsCanvasBase;
	
	import flash.filters.DropShadowFilter;
	
	import imagine.ImageDocument;
	
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;
	import mx.effects.AnimateProperty;
	import mx.effects.Fade;

	public class EffectSetBase extends Canvas
	{
		[Bindable] public var _imgd:ImageDocument;
		[Bindable] public var _imgv:ImageView;
		
		[Bindable] protected var _efFadeFast:Fade = new Fade();
		[Bindable] protected var _efFadeSlow:Fade = new Fade();
		[Bindable] protected var _fiHeadShad:DropShadowFilter;
		[Bindable] protected var _efBGdim:AnimateProperty = new AnimateProperty();
		[Bindable] protected var _efBGbrighten:AnimateProperty = new AnimateProperty();
		
		[Bindable] public var expanded:Boolean = false;

		public function EffectSetBase()
		{
			super();
			_efFadeFast.duration = 150;
			_efFadeSlow.duration = 300;

			//blurX="2" blurY="2" distance="1" color="#000000" alpha=".6" quality="3"
			// angle="90" id="_fiHeadShad"/>
			_fiHeadShad = new DropShadowFilter(1, 90, 0, 0.6, 2, 2, 1, 3);
			
			//fromValue="1" toValue=".7" property="backgroundAlpha" isStyle="true" duration="150"			
			_efBGdim.fromValue = 1;
			_efBGdim.toValue = 0.7;
			_efBGdim.property = "backgroundAlpha";
			_efBGdim.isStyle = true;
			_efBGdim.duration = 150;

			// fromValue=".7" toValue="1" property="backgroundAlpha" isStyle="true" duration="300"/>			
			_efBGbrighten.fromValue = 0.7;
			_efBGbrighten.toValue = 1;
			_efBGbrighten.property = "backgroundAlpha";
			_efBGbrighten.isStyle = true;
			_efBGbrighten.duration = 300;
			
			width = 210;
			verticalLineScrollSize = 38;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
		}
		
		static public function OnAdvancedCollageClick(evt:Event=null, strLogSource:String = ""): void {
			SpecialEffectsCanvasBase.OnAdvancedCollageClick(evt, strLogSource);
		}

		static public function OnShowClick(evt:Event=null, strLogSource:String = ""): void {
			SpecialEffectsCanvasBase.OnShowClick(evt, strLogSource);
		}
	}
}