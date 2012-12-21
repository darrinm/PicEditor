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
	import bridges.picnik.PicnikStorageService;
	
	import containers.PaletteWindow;
	
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.CheckBox;
	import mx.controls.ComboBox;
	import mx.controls.TextInput;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import mx.utils.ObjectProxy;
	
	import util.TemplateGroup;
	import util.TemplateManager;

	public class TemplatePropertiesDialogBase extends PaletteWindow
	{
		private static var s_dctTemplateToPanel:Dictionary = new Dictionary();
		private static var s_tpa:ThirdPartyAccount = null;
		
		private static var s_acb:AdvancedCollageBase;
		
		[Bindable] protected var _obTemplate:Object;
		[Bindable] protected var _acPreviewInfo:ArrayCollection = null;
		
		[Bindable] public var _tiTitle:TextInput;
		[Bindable] public var _tiAuthor:TextInput;
		[Bindable] public var _tiAuthorUrl:TextInput;
		[Bindable] public var _cbGroup:ComboBox;
		[Bindable] public var _cbxPremium:CheckBox;
		
		[Bindable] protected var _fid:String = "";
		[Bindable] protected var _strOwnerId:String = "";

		public static function ShowPanel(acb:AdvancedCollageBase, obTemplate:Object): void {
			if (s_tpa == null)
				s_tpa = new ThirdPartyAccount("RecentImports", new PicnikStorageService("i_mycomput", "recentuploads", "Recent Uploads"));

			s_acb = acb;
			
			if (obTemplate in s_dctTemplateToPanel) TemplatePropertiesDialogBase(s_dctTemplateToPanel[obTemplate]).Hide();
			var dlg:TemplatePropertiesDialogBase = new TemplatePropertiesDialog();
			dlg.Constructor(obTemplate);
			PopUpManager.addPopUp(dlg, acb);
			PopUpManager.centerPopUp(dlg);
		}
		
		public static function HideAll(): void {
			for each (var dlg:TemplatePropertiesDialogBase in s_dctTemplateToPanel)
				dlg.Hide();
		}
		
		private static function get picnikStorageService():PicnikStorageService {
			return s_tpa.storageService as PicnikStorageService;
		}
		
		public function TemplatePropertiesDialogBase()
		{
			super();
			showCloseButton = true;
			title = "Edit Template";
			addEventListener(CloseEvent.CLOSE, Hide);
			
			LoadPreviewInfo();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		protected static function FriendlyCMSStageName(strCMSStage:String):String {
			return s_acb.FriendlyCMSStageName(strCMSStage);
		}
		
		private function OnCreationComplete(evt:Event): void {
			var iSelected:Number = 0;
			
			var atgrps:Array = TemplateManager.templateStructure.groups;
			var acGroups:ArrayCollection = new ArrayCollection(atgrps);
			
			for (var i:Number = 0; i < atgrps.length; i++) {
				var tgrp:TemplateGroup = atgrps[i];
				if (tgrp.id == _obTemplate.groupid) {
					iSelected = i;
					break;
				}
			}
			
			_cbGroup.dataProvider = acGroups;
			_cbGroup.selectedIndex = iSelected;
		}
		
		private function LoadPreviewInfo(): void {
			// Set up _acPreviewInfo
			// Load recent uploads
			var fnComplete:Function = function(err:Number, strError:String, aitemInfo:Array=null): void {
				if (err != PicnikService.errNone) {
					trace("error: " + err + ", " + strError);
				} else {
					// Got results
					_acPreviewInfo = new ArrayCollection();
					
					var obItem:ObjectProxy = new ObjectProxy();
					obItem.fid = _obTemplate['ref:preview'];
					obItem.url = PicnikService.GetFileURL(obItem.fid);
					obItem.label = "Current";
					_acPreviewInfo.addItem(obItem);
					
					for each (var itemInfo:ItemInfo in aitemInfo) {
						obItem = new ObjectProxy();
						obItem.fid = itemInfo.id;
						obItem.url = itemInfo.thumbnailurl;
						obItem.label = itemInfo.filename;
						_acPreviewInfo.addItem(obItem);
					}
				}
			}
			
			picnikStorageService.GetItems("recentuploads", null, null, 0, 100, fnComplete);
		}
		
		protected function SavePreview(fid:String): void {
			var fnDone:Function = function(err:Number, strError:String): void {
				if (err != PicnikService.errNone) {
					trace("error saving: " + err + ", " + strError);
					Alert.show("Error saving properties: " + err + ", " + strError);
				} else {
					s_acb.RefreshTemplateList();
				}
			}
			
			PicnikService.SetTemplatePreview(_obTemplate.fid, fid, fnDone);
		}

		protected function SaveProperties(): void {
			var obProps:Object = {};
			obProps['title'] = _tiTitle.text;
			obProps['author'] = _tiAuthor.text;
			obProps['authorurl'] = _tiAuthorUrl.text;
			obProps['groupid'] = _cbGroup.selectedItem.id;
			obProps['fPremium'] = _cbxPremium.selected;
			
			var fnDone:Function = function(err:Number, strError:String): void {
				if (err != PicnikService.errNone) {
					Alert.show("Error saving properties: " + err + ", " + strError);
				} else {
					s_acb.RefreshTemplateList();
				}
			}
			
			PicnikService.SetTemplateProperties(obProps, _obTemplate.fid, fnDone);
		}
		
		private function Constructor(obTemplate:Object): void {
			_obTemplate = obTemplate;
			_fid = _obTemplate.fid;
			_strOwnerId = _obTemplate.strOwnerId;
			s_dctTemplateToPanel[_obTemplate] = this;
		}
		
		public function Hide(evt:Event=null): void {
			PopUpManager.removePopUp(this);
			delete s_dctTemplateToPanel[_obTemplate];
		}
		
		protected function Delete(): void {
			var fnDone:Function = function(err:Number, strError:String): void {
				if (err != PicnikService.errNone) {
					trace("error deleteing: " + err + ", " + strError);
					Alert.show("Error deleteing template: " + err + ", " + strError);
				} else {
					s_acb.RefreshTemplateList();
				}
			}
			
			PicnikService.DeleteTemplate(_obTemplate.fid, fnDone);
			Hide();
		}
		
		// Retuns -1 if not found
		private function StageToIndex(strStage:String): Number {
			var astrCMSStages:Array = AdvancedCollageBase.GetTemplateStages();
			for (var i:Number = 0; i < astrCMSStages.length; i++) {
				if (astrCMSStages[i] == strStage) return i;
			}
			return -1;
		}
		
		// Returns null if none found
		protected function GetPrevStage(strStage:String): String {
			var astrCMSStages:Array = AdvancedCollageBase.GetTemplateStages();
			var nIndex:Number = StageToIndex(strStage);
			if (nIndex < 1) return null;
			return astrCMSStages[nIndex-1];
		}

		protected function GetNextStage(strStage:String): String {
			var astrCMSStages:Array = AdvancedCollageBase.GetTemplateStages();
			var nTargetIndex:Number = StageToIndex(strStage) + 1;
			if (nTargetIndex <= 0 || nTargetIndex >= astrCMSStages.length) return null;
			return astrCMSStages[nTargetIndex];
		}
		
		protected function GoToStage(strStage:String): void {
			var fnDone:Function = function(err:Number, strError:String): void {
				if (err != PicnikService.errNone) {
					Alert.show("Error setting stage to " + strStage + ": " + err + ", " + strError);
				} else {
					s_acb.RefreshTemplateList();
				}
			}
			PicnikService.SetTemplateStage(_obTemplate.fid, strStage, fnDone);
			Hide();
		}
	}
}