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
	import containers.PaletteWindow;
	import mx.collections.ArrayCollection;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;

	public class TemplateFilterPanelBase extends PaletteWindow
	{
		[Bindable] protected var _acobExtraCMSStages:ArrayCollection;
		
		private var _acb:AdvancedCollageBase;
		
		[Bindable] protected var _fLive:Boolean = true;
		[Bindable] protected var _fShowHidden:Boolean = false;
		[Bindable] protected var _strExtraStage:String = "_none";
		
		[Bindable] public var _cbExtra:ComboBox;
		[Bindable] public var _cbxLive:CheckBox;
		[Bindable] public var _cbxHidden:CheckBox;
		
		public function TemplateFilterPanelBase()
		{
			super();
		}
		
		protected function Hide(): void {
			_acb.ToggleStageVisibilityPanel();
		}
		
		// Returns -1 if not found
		protected function IndexOfValue(ac:ArrayCollection, str:String): Number {
			if (ac) {
				for (var i:Number = 0; i < ac.length; i++) {
					if (ac.getItemAt(i).data == str) return i;
				}
			}
			return -1;
		}
		
		public function Constructor(acb:AdvancedCollageBase, obFilter:Object): void {
			_acb = acb;
			_fShowHidden = obFilter.fShowHidden;
			_fLive = false;
			_strExtraStage = "_none";
			var strStage:String;
			for each (strStage in obFilter.astrCMSStages) {
				if (strStage == 'live') _fLive = true;
				else _strExtraStage = strStage;
			}
			_acobExtraCMSStages = new ArrayCollection();
			_acobExtraCMSStages.addItem({label:"None", data:"_none"});
			var astrAllCMSStages:Array = AdvancedCollageBase.GetTemplateStages();
			for each (strStage in astrAllCMSStages) {
				if (strStage != "live") {
					_acobExtraCMSStages.addItem({label:FriendlyCMSStageName(strStage), data:strStage});
				}
			}
		}
		
		private function FriendlyCMSStageName(strCMSStage:String):String {
			return _acb.FriendlyCMSStageName(strCMSStage);
		}
		
		public function ApplyFilter(): void {
			var astrCMSStages:Array = [];
			if (_fLive) astrCMSStages.push('live');
			if (_strExtraStage != "_none") astrCMSStages.push(_strExtraStage);
			_acb.UpdateFilter(astrCMSStages, _fShowHidden);
		}
	}
}