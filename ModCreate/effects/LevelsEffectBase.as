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
	
	import controls.SingleLevel;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import imagine.imageOperations.PaletteMapImageOperation;
	
	import imagine.ImageDocument;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.controls.ComboBox;
	import mx.controls.List;
	import mx.controls.PopUpButton;
	import mx.events.ListEvent;
	
	public class LevelsEffectBase extends EffectCanvas
	{
		import imageUtils.ChannelMap;
		import imageUtils.SimpleHistogram;
		import mx.resources.ResourceBundle;

		[Bindable] public var _cboxChannel:ComboBox;
		[Bindable] public var _cboxAutoLevels:ComboBox;
		[Bindable] public var _cnv:Canvas;
		[Bindable] public var _lvlR:SingleLevel;
		[Bindable] public var _lvlG:SingleLevel;
		[Bindable] public var _lvlB:SingleLevel;
		[Bindable] public var _lvlRGB:SingleLevel;
		[Bindable] public var _pop:PopUpButton;
		[Bindable] public var _acPresets:ArrayCollection;
		
   		private var reds:Array = [];
   		private var greens:Array = [];
   		private var blues:Array = [];
   		
   		private var _fDirty:Boolean = false;

   		private var _alvls:Array = null;
   		
   		private var _ahist:Array = null;
   		
   		private var _fInitialized:Boolean = false;
   		
   		private var _fAllStagesCreated:Boolean = false;
   		
		override protected function OnAllStagesCreated(): void {
			super.OnAllStagesCreated();
			_fAllStagesCreated = true;
   			if (_imgd && _imgd.background)
   				SetBitmap(_imgd.background);
		}
		
		protected override function set imageDocument(imgd:ImageDocument): void {
			super.imageDocument = imgd;
   			if (_imgd && _imgd.background && _fAllStagesCreated)
   				SetBitmap(_imgd.background);
   		}

		protected function SetupMenu(): void {
              var lst:List = new List();
              // Set the data provider
              lst.dataProvider = _acPresets;
              // Style the list
              lst.setStyle("dropShadowEnabled", true);
              lst.setStyle("dropShadowDirection", 90);
              lst.setStyle("borderThickness", 0);
              // Show all elements (up to 10)
              lst.rowCount = Math.min(10, lst.dataProvider.length);
             
              // Glue
              lst.addEventListener(ListEvent.ITEM_CLICK, OnPopupItemSelect);
              lst.addEventListener(Event.RESIZE, OnPopupListResize);
              var cnv:Canvas = new Canvas();
              cnv.addChild(lst);
              _pop.popUp = cnv;
              _pop.data = lst.dataProvider[0];
              _pop.label = _pop.data.label;
          }
         
		// List glue
        public function OnPopupListResize(evt:Event): void {
              // Add space for the drop shadow
              var lst:List = evt.target as List;
              var cnv:Canvas = lst.parent as Canvas;
              cnv.width = lst.width + 5;
              cnv.height = lst.height + 5;
        }
       
        // List item selected
        public function OnPopupItemSelect(evt:ListEvent): void {
              var lst:List = evt.target as List;
              _pop.data = lst.selectedItem;
              _pop.label = _pop.data.label;
              _pop.close();
              AutoLevel(lst.selectedItem);
        }

		public function SetBitmap(bmd:BitmapData): void {
			if (!_fInitialized) init();
			var ob:Object = SimpleHistogram.HistogramsFromBitmap(bmd);
			_ahist = ob.ahist;
			var nClipMax:Number = ob.clipMax;
			var ahistRGB:Array = [];
			for (var i:Number = 0; i < _alvls.length; i++) {
				var lvl:SingleLevel = _alvls[i];
				lvl._histView.clipMax = nClipMax;
				lvl._histView.histogram = _ahist[i];
				lvl.histogramOut.setArray((_ahist[i] as SimpleHistogram).array);
				ahistRGB.push(lvl.histogramOut);
			}
			_lvlRGB._histView.clipMax = nClipMax;
			_lvlRGB._histView.histograms = ahistRGB;
		}
   		
   		public function Reset(): void {
   			// Reset the levels
   			_fDirty = false;
   			_lvlR.Reset();
   			_lvlG.Reset();
   			_lvlB.Reset();
   			_lvlRGB.Reset();
   			_cboxChannel.selectedIndex = 0;
   			ShowSelectedChannel();
			_cboxAutoLevels.selectedIndex = 0; // Default
			invalidateArrays();
   		}
   		
   		private var _aobSavedLevels:Array = null;
   		
   		private function SaveLevels(): void {
   			_aobSavedLevels = [];
   			for (var i:Number = 0; i < _alvls.length; i++) {
   				_aobSavedLevels.push(_alvls[i].GetLevels());
   			}
   			_aobSavedLevels.push(_lvlRGB.GetLevels());
   		}
   		
   		private function LoadLevels(): void {
   			if (_aobSavedLevels == null) return;
   			for (var i:Number = 0; i < _alvls.length; i++) {
   				_alvls[i].SetLevels(_aobSavedLevels[i]);
   			}
   			_lvlRGB.SetLevels(_aobSavedLevels[_alvls.length]);
   		}
   		
   		public function OnEdit(): void {
			_cboxAutoLevels.selectedIndex = 1;
			_fDirty = true;   			
   		}
   		
   		private function GetVal(ob:Object, strKey:String, obDefault:*): * {
   			if (strKey in ob) return ob[strKey];
   			else return obDefault;
   		}
   		
   		private function SetLevels(lvl:SingleLevel, obSettings:Object): void {
   			lvl._sldrIn.leftVal = obSettings.minIn;
   			lvl._sldrIn.rightVal = obSettings.maxIn;
   			lvl._sldrIn.midVal = obSettings.mid;
   		}
   		
   		public function AutoLevel(obSettings:Object): void {
   			if (!_ahist) return;
   			
   			if (_fDirty) {
   				// Save the current state
   				SaveLevels();
	   			_fDirty = false;
   			}
   			
   			if (obSettings == null || 'fIgnore' in obSettings) return;
   			
   			if ('fCustom' in obSettings) {
   				LoadLevels();
   				return;
   			}
   			
   			if ('fReset' in obSettings) {
   				Reset();
   				return;
   			}
   			var fPerChannel:Boolean = GetVal(obSettings, 'fPerChannel', true); 
   			var nClipPct:Number = GetVal(obSettings, 'nClipPct', 0.1);
   			var fNeutralMidtones:Boolean = GetVal(obSettings, 'fNeutralMidtones', false);
   			// UNDONE: Support Find Dar & Find Light colors (what does this do?)
   			// UNDONE: Support choosing target colors (what does this do?)
   			
   			// Analyze the histograms in _ahist to find settings
   			var i:Number;
   			if (fPerChannel) {
   				for (i = 0; i < _alvls.length; i++) {
   					_alvls[i].SetLevels(_ahist[i].GetAutoLevels(nClipPct, fNeutralMidtones));
   				}
   				_lvlRGB.Reset();
   			} else {
   				_lvlRGB.SetLevels(_ahist[3].GetAutoLevels(nClipPct, fNeutralMidtones));
   				for (i = 0; i < _alvls.length; i++) {
   					_alvls[i].Reset();
   				}
   				
   			}
   			_lvlRGB._histView.invalidateHist();
   			_cboxChannel.selectedIndex = 0;
   			ShowSelectedChannel();
   			invalidateArrays();
   		}
   		
		protected function ShowSelectedChannel(): void {
			var lvlSelected:SingleLevel = _cboxChannel.selectedItem.data as SingleLevel;
			_cnv.setChildIndex(lvlSelected, _cnv.numChildren-1);
			for each (var doChild:DisplayObject in _cnv.getChildren()) {
				doChild.visible = (doChild == lvlSelected);
			}
		}

   		protected function init(): void {
   			calcArrays();
   			_alvls = [_lvlR, _lvlG, _lvlB];
   			_fInitialized = true;
   			//SetupMenu();
   		}
   		
   		protected function calcArray(an:Array, cm1:ChannelMap, cm2:ChannelMap, nShift:Number): void {
   			for (var i:Number = 0; i < 256; i++) {
   				an[i] = cm2.map(cm1.map(i, false)) << nShift;
   			}
   		}
   		
   		protected function calcArrays(): Boolean {
   			var op:PaletteMapImageOperation = operation as PaletteMapImageOperation;
   			if (op && _lvlR && _lvlRGB && _lvlG && _lvlB) {
	   			calcArray(reds, _lvlR.channelMap, _lvlRGB.channelMap, 16);
	   			calcArray(greens, _lvlG.channelMap, _lvlRGB.channelMap, 8);
	   			calcArray(blues, _lvlB.channelMap, _lvlRGB.channelMap, 0);
   				op.Reds = reds;
   				op.Blues = blues;
   				op.Greens = greens;
   				return true;
   			}
   			return false;
   		}
   		
   		private var _fArraysInvalid:Boolean = true;
   		
   		protected override function commitProperties():void {
   			super.commitProperties();
   			validateArrays();
   		}

   		protected function invalidateArrays(): void {
   			_fArraysInvalid = true;
   			invalidateProperties();
   		}
   		
   		protected function validateArrays(): void {
   			if (_fArraysInvalid) {
	   			if (calcArrays()) {
		   			_fArraysInvalid = false;
		   			OnOpChange();
		   		}
	   		}
   		}
   		
   		protected function OnLevelChange(): void {
   			invalidateArrays();
   		}
	}
}