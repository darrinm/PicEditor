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
package util
{
	import api.PicnikRpc;
	
	import controls.QuestionButton;
	import controls.QuestionComboBox;
	import controls.QuestionText;
	import controls.QuestionTextArea;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.core.UIComponent;
	
	public class QuestionManager
	{
		private static var _qm:QuestionManager = null;
 		private var _ldr:URLLoader = null;
 		private var _axmlQuestions:Array = []; // Remaining questions
 		private var _axmlAllQuestions:Array = [];
 		private var _strPrevQuestionID:String = null;
 		private var _obResponses:Object = null;
 		
 		// Returns true if we have any questions to ask
 		// Will return false until we have loaded the question list and the questions answered list
 		public static function HasQuestions():Boolean {
 			return GetInstance()._HasQuestions();
 		}
 		
 		// Call this early so that we have questions to ask when we need them
 		public static function Init():void {
 			// STL: turning off QuestionManager code until we need it
 			//GetInstance();
 		}

 		public static function Answer(strId:String, strVal:String): void {
 			// STL: turning off QuestionManager code until we need it
 			//GetInstance()._Answer(strId, strVal);
 		}
 		
 		public static function GetQuestionXML(): XML {
 			return GetInstance()._GetQuestionXML();
 		}
 		
 		public static function GetQuestionControl():UIComponent {
 			return CreateQuestionControl(GetQuestionXML());
 		}
 		
 		public static function UserChanged(): void {
 			// STL: turning off QuestionManager code until we need it
 			//GetInstance().LoadResponses();
 		}

		private static function GetInstance(): QuestionManager {
			if (_qm == null) _qm = new QuestionManager();
			return _qm;
		}
		
		public function QuestionManager()
		{
			LoadQuestions();
		}
		
		private function LoadQuestions(): void {
			_ldr = new URLLoader();
			_ldr.load(new URLRequest(GetQuestionPath()));
			
 			_ldr.addEventListener(Event.COMPLETE, OnLoadComplete);
 			_ldr.addEventListener(IOErrorEvent.IO_ERROR, OnLoadError);
 			_ldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnLoadError);
		}
		
		private function GetQuestionPath(): String {
			return PicnikBase.StaticUrl("../app/" + PicnikBase.Locale() + "/questions.xml");
		}
		
 		protected function OnLoadError(evt:Event): void {
 			trace("Failed to load question file, " + evt);
 		}
 		
 		protected function LoadResponses(): void {
 			_obResponses = null;
 			UpdateQuestionsRemaining();
			PicnikService.GetUserProperties("questions", OnGetUserProperties);
 		}
 		
 		private function OnGetUserProperties(err:Number, obResults:Object=null): void {
 			if (obResults) {
 				if ('questions' in obResults) {
	 				_obResponses = obResults.questions;
	 			} else {
	 				_obResponses = {}; // No questions answered.
	 			}
	 		}
 			UpdateQuestionsRemaining();
 		}
 		
 		protected function UpdateQuestionsRemaining(): void {
 			_axmlQuestions.length = 0;
 			if (_obResponses != null) {
 				for each (var xmlQuestion:XML in _axmlAllQuestions) {
 					if (!(xmlQuestion.@id in _obResponses)) {
 						_axmlQuestions.push(xmlQuestion);
 					}
 				}
 			}
 		}
 		
 		protected function OnLoadComplete(evt:Event): void {
 			var xmlQuestions:XML = XML(_ldr.data);

 			for each (var xml:XML in xmlQuestions.question) {
 				xml.@id = String(xml.@id).toLowerCase();
 				_axmlAllQuestions.push(xml);
 			}
 			
 			_axmlAllQuestions.sortOn('@priority', Array.NUMERIC);
 			
			UpdateQuestionsRemaining();
 		}
 		
 		protected function _HasQuestions(): Boolean {
 			return _axmlQuestions.length > 0;
 		}

		protected function _GetQuestionXML(): XML {
			if (_axmlQuestions.length < 1) return null;
			
			var i:Number = 0;
			
			if (_axmlQuestions.length > 1 && _axmlQuestions[0].@id == _strPrevQuestionID) {
				i = 1;
			}
			_strPrevQuestionID = _axmlQuestions[i].@id;
			return _axmlQuestions[i];
		}
		
		// Given question XML, create an appropriate wrapper container
		protected static function CreateQuestionControl(xml:XML): UIComponent {
			if (xml == null) return null;
			var uic:UIComponent;
			if (xml.@type == 'text')
				uic = new QuestionText();
			else if (xml.@type == 'button')
				uic = new QuestionButton();
			else if (xml.@type == 'combobox')
				uic = new QuestionComboBox();
			else if (xml.@type == 'textarea')
				uic = new QuestionTextArea();
			else
				throw new Error("Unknown question type: " + xml.@type);

			uic["data"] = xml;
			return uic;
		}
		
		protected function GetAnswerIndexById(strId:String): Number {
			var i:Number;
			for (i = 0; i < _axmlQuestions.length; i++) {
				if (_axmlQuestions[i].@id == strId) return i;
			}
			return -1;
		}
		
		protected function RemoveAnswerByIndex(i:Number): void {
			if (i < 0 || i >= _axmlQuestions.length) return;
			for (var j:Number = i+1; j < _axmlQuestions.length; j++) {
				_axmlQuestions[j-1] = _axmlQuestions[j];
			}
			_axmlQuestions.length -= 1;
		}
		
		protected function RemoveAnswerById(strId:String): void {
			var i:Number = GetAnswerIndexById(strId);
			if (i >= 0) {
				RemoveAnswerByIndex(i);
			}
		}
		
		protected function _Answer(strId:String, strVal:String): void {
			// Remove the question from the list and record the answer
			RemoveAnswerById(strId);
			
			var obAnswer:Object = {};
			obAnswer[strId] = strVal;
			PicnikRpc.SetUserProperties(obAnswer, 'questions');
		}
	}
}