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
package dialogs {
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceError;
	import bridges.storageservice.StorageServiceSetComboItem;
	
	import containers.CoreDialog;
	
	import controls.TextAreaPlus;
	import controls.TextInputPlus;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.controls.Text;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import mx.resources.ResourceBundle;
		
	public class CreateAlbumDialogBase extends CoreDialog {
		// MXML-specified variables
		[Bindable] public var _tiTitle:TextInputPlus;
		[Bindable] public var _taDescription:TextAreaPlus;
		[Bindable] public var _cboxSets:ComboBox;
		[Bindable] public var _btnCreate:Button;
		[Bindable] public var _lblSetName:Label;		
		[Bindable] public var _txtTitle:Text;		
		
		[Bindable] public var _fShowDescription:Boolean;
		
		private var _ss:IStorageService;
		private var _bsy:IBusyDialog;
		private var _adctSetInfos:Array;
		private var _strSelectedSetID:String = null;
		private var _obPhrases:Object = null;
		
  		[ResourceBundle("CreateAlbumDialog")] static protected var _rb:ResourceBundle;
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			super.Constructor(fnComplete, uicParent, obParams);
			_ss = obParams['storageservice'];
			_adctSetInfos = obParams['sets'];
			_obPhrases = 'phrases' in obParams ? obParams['phrases'] : {};
			_fShowDescription = _ss.GetServiceInfo().set_descriptions;
		}
		
		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			_btnCreate.addEventListener(MouseEvent.CLICK, OnCreateClick);			
			_cboxSets.addEventListener(Event.CHANGE, OnSetsComboChange);
			
			// modify some of our text to handle localized phrases
			var strSet:String = _obPhrases['set'] ? _obPhrases['set'] : "set";
			if (strSet == "set") {
				_lblSetName.text = Resource.getString("CreateAlbumDialog", "set_name");
				_txtTitle.htmlText = '<font size="21" color="#618430"><b>' + Resource.getString("CreateAlbumDialog", "create_a_new_set") + '</b></font>';
			} else if (strSet == "album") {
				_lblSetName.text = Resource.getString("CreateAlbumDialog", "album_name");
				_txtTitle.htmlText = '<font size="21" color="#618430"><b>' + Resource.getString("CreateAlbumDialog", "create_a_new_album") + '</b></font>';
			}
		}
				

		override protected function OnCreationComplete(evt:FlexEvent): void {
			super.OnCreationComplete(evt);
			// OnInitialize is too early for this
			_tiTitle.setFocus();
			if (!_adctSetInfos || _adctSetInfos.length == 0) {
				currentState = "NoParentAlbums";	
			} else {
				var aitmSets:Array = [];
				for each (var dctSetInfo:Object in _adctSetInfos) {
					if (null != dctSetInfo && dctSetInfo.child_sets) {
						aitmSets.push(new StorageServiceSetComboItem(dctSetInfo.title, dctSetInfo.thumbnailurl, dctSetInfo));
					}
				}
				StorageServiceSetComboItem.UpdateHasIcons(aitmSets);
				
				if (0 == aitmSets.length) {
					currentState = "NoParentAlbums";	
				} else {
					_cboxSets.dataProvider = aitmSets;
					var iSelected:Number = FindItemIndex(_strSelectedSetID);
					_cboxSets.selectedIndex = iSelected >= 0 ? iSelected : 0;
				}
			}			
		}
		
		private function FindItemIndex(strLabel:String): Number {
			var aitm:Array = _cboxSets.dataProvider.source;
			for (var i:Number = 0; i < aitm.length; i++)
				if (aitm[i].label == strLabel)
					return i;
			return -1;
		}
		
		protected function OnSetsComboChange(evt:Event): void {
			_strSelectedSetID = (_cboxSets.selectedItem as StorageServiceSetComboItem).setinfo.id;
		}		
		
		private function OnCreateClick(evt:Event): void {
			var strSet:String = _obPhrases['set'] ? _obPhrases['set'] : "set";
			var strBusy:String = "";
			if (strSet == "set") {
				strBusy = Resource.getString("CreateAlbumDialog", "creating_set");				
			} else {
				strBusy = Resource.getString("CreateAlbumDialog", "creating_album");
			}				
			
			_bsy = BusyDialogBase.Show(this, strBusy, BusyDialogBase.OTHER, "IndeterminateNoCancel", 0);
			_ss.CreateSet( { title: _tiTitle.text, description: _taDescription.text, parent_id: _strSelectedSetID },
				function(err:Number, strError:String, dctSetInfo:Object=null):void {
					_bsy.Hide();
					_bsy = null;
					if (err != StorageServiceError.None) {
						var strT:String = "";
						if (strSet == "set") {
							strT = Resource.getString("CreateAlbumDialog", "create_album_error");				
						} else {
							strT = Resource.getString("CreateAlbumDialog", "create_set_error");
						}				
						
						Util.ShowAlertWithoutLogging(strT, Resource.getString("CreateAlbumDialog", "Error"), Alert.OK);
					} else {
						Hide();
						if (_fnComplete != null) {
							_fnComplete({ success: true, dctSetInfo:dctSetInfo });
						}
					}
				},
				null );						
		}
		
		private function CapitalizeFirst( str:String ):String {
			if (!str || !str.length) return str;
			return str.charAt(0).toUpperCase() + str.substr(1);
		}
	}
}
