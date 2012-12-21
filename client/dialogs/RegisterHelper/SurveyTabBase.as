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
package dialogs.RegisterHelper
{
	import api.PicnikRpc;
	
	import com.adobe.utils.StringUtil;
	
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.ui.Keyboard;
	
	import mx.controls.ComboBox;
	import mx.controls.RadioButtonGroup;
	import mx.controls.TextInput;
	import mx.effects.Sequence;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	
	import util.LocUtil;
	import util.UserBucketManager;
	
	public class SurveyTabBase extends RegisterBoxBase
	{
		[Bindable] public var _effError:Sequence;
		[Bindable] public var _cboxAge:ComboBox;
		[Bindable] public var _rbgGender:RadioButtonGroup;
		[Bindable] public var _tiZip:TextInput;
		[Bindable] public var _strSuccessFeedbackMessage:String;

   		[Bindable] [ResourceBundle("SurveyTab")] protected var _rb:ResourceBundle;

		public function SurveyTabBase():void {
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			
		}
		
		private function OnInitialize(evt:Event): void {
			// populate the "age" dropdown
			var astrAges:Array = new Array();
			astrAges.push( { data: 0, label: Resource.getString("SurveyTab", "pick_year") } );

			for( var i:Number = min_year; i > min_year - 90; i-- ) {
				astrAges.push( { data: i, label: i.toString() } );				
			}
			astrAges.push( { data: i, label: LocUtil.rbSubst('SurveyTab', "earlier_than", i ) } );
			_cboxAge.dataProvider = astrAges;			
		}

		protected function OnSurveyTabLink(evt:TextEvent): void {
			if (StringUtil.beginsWith(evt.text.toLowerCase(), "showdialog=")) {
				var strDialog:String = evt.text.substr("showdialog=".length);
				if (strDialog == "Privacy") {
					PicnikBase.app.ShowDialog("privacy");
				}
			}
		}		

		public function SurveyCompleteKeyEvent(event:KeyboardEvent):void
		{
			// BST: buttons treat space as a click, let the button handle those.
			if (event.keyCode == Keyboard.ESCAPE || event.keyCode == Keyboard.TAB || event.keyCode == Keyboard.SPACE)
				return;
			SurveyComplete();
		}
		
		protected function SurveyClose(): void {
			// clear out the fields so that everything stays private
			dataModel.resetAll();
			SaveSurvey();
			
			// Hide this dialog and show the "Account Created" message
			working = false;
			Hide();
			PicnikBase.app.Notify(_strSuccessFeedbackMessage);
		}
				
		public override function OnEscape(evt:KeyboardEvent): void {
			SurveyClose();
		}
						
		// User clicked a button (etc) to submit the form
		public function SurveyComplete(): void {
			// First, make sure everything is valid
			if (dataModel.validateAll()) {
				SaveSurvey();
				
				// Hide this dialog and show the "Account Created" message
				working = false;
				Hide();
				PicnikBase.app.Notify(_strSuccessFeedbackMessage);
			} else {
				_effError.end();
				_effError.play();
			}
		}
		
		// User clicked a button (etc) to submit the form
		public function SaveSurvey(): void {
			var obAnswers:Object = {};
			
			obAnswers['yearborn'] = birthyear.length ? birthyear : "-";
			obAnswers['gender'] = gender.length ? gender : "-";
			obAnswers['postalcode'] = zipcode.length ? zipcode : "-";

			PicnikRpc.SetUserProperties(obAnswers, 'survey');
			
			var obShortAnswers:Object = {
				yb:obAnswers['yearborn'],
				gd:String(obAnswers['gender']).substr(0,1),
				pc:obAnswers['postalcode']
			}
			UserBucketManager.GetInst().OnQuestionsAnswered("Reg", obShortAnswers);

			// clear out the fields so that everything stays private
			dataModel.resetAll();			
		}

		[Bindable] protected function get min_year(): Number {
			return new Date().getFullYear() - 13;
		}
		
		protected function set min_year( n:Number ): void {
			// unsettable
		}
		
		public function get birthyear(): String {
			var nSelected:Number = _cboxAge.selectedIndex;
			if (0 == _cboxAge.selectedIndex) {
				return "";
			} else if (_cboxAge.selectedLabel.length > 4) {
				// "Earlier than 1905"
				return "1900";
			}
			return _cboxAge.selectedLabel;
		}
		
		private function get gender(): String {
			if (null == _rbgGender.selectedValue)
				return "";
			return _rbgGender.selectedValue as String;
		}
		
		public function get zipcode(): String {
			return _tiZip.text;
		}
	}
}
