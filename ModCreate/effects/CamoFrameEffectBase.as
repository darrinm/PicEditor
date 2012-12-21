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
package effects
{
	import containers.EffectCanvas;
	import containers.NestedControlEvent;
	
	import controls.ComboBoxPlus;
	import controls.ResizingComboBox;
	
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.utils.ObjectProxy;

	public class CamoFrameEffectBase extends EffectCanvas
	{
   		[Bindable] protected var selectedStyleIconUrl:String = null;
   		[Bindable] protected var frameSize:Number = 15;
   		[Bindable] protected var seed:Number = 1;
   		[Bindable] public var _cbStyles:ResizingComboBox;

   		private static const kobDefaults:Object = {
   			colors:[0x485b41, 0xd9d187, 0x8c9557, 0x1e2e22],
			bottomThreshold:136,
			topThreshold:150,
			frameBleed:100,
			isFrame:true,
			xFrequency:0.13,
			yFrequency:0.06,
			fractal:true,
			octaves:2,
			topScale:0.9,
			pixelation:0.5
   		};

		public function CamoFrameEffectBase()
		{
			super();
		}

   		protected function IconNameToUrl(strName:String): String {
   			return "../graphics/effects/MemorialDay/styleIcons/" + strName;
   		}

		protected function GetStylesArray(): Array {
			throw new Error("Override in sub-classes");
			return null;
		}
   		
   		protected function GetStyles(): ArrayCollection {
   			var ac:ArrayCollection = new ArrayCollection();
   			var aobStyles:Array = GetStylesArray();

   			for each (var ob:Object in aobStyles)
   				ac.addItem(new ObjectProxy({label:Resource.getString('CamoFrameEffect', ob.label), url:IconNameToUrl(ob.icon)}));

   			return ac;
   		}
   		
   		// User changed a value. Update.
   		protected function OnParamChange(): void {
   			UpdateOpParams();
   			OnOpChange();
   		}
   		
   		public override function OnSelectedEffectBegin(evt:Event):void {
   			super.OnSelectedEffectBegin(evt);
   			UpdateOpParams();
   		}
   		
   		private function UpdateOpParams(): void {
   			if (operation == null)
   				return;

   			var aobStyles:Array = GetStylesArray();
   			
   			var i:Number = 0;
   			if (_cbStyles && _cbStyles.selectedIndex >= 0)
   				i = _cbStyles.selectedIndex;
   			
   			var strKey:String;

   			// First, apply defaults
   			for (strKey in kobDefaults)
   				operation[strKey] = kobDefaults[strKey];
   			
   			// Then, look up our values and apply those
   			var obData:Object = aobStyles[i].data;
   			for (strKey in obData) {
   				if (strKey == 'pixelationCubes') {
   					var nPixelation:Number;
   					var nMinDim:Number = Math.min(origImageHeight, origImageWidth);
   					nPixelation = Math.max(1,Math.round(nMinDim / obData['pixelationCubes']));
   					operation['pixelation'] = nPixelation;
   				} else {
	   				operation[strKey] = obData[strKey];
	   			}
   			}

			// Apply our frame size and seed
			operation['frameSize'] = frameSize;
			operation['seed'] = seed;
			
			selectedStyleIconUrl = aobStyles[i].icon;
   		}

		override protected function OnInitialize(evt:Event): void {
			UpdateOpParams();
			super.OnInitialize( evt );
		}
	}
}