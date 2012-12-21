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
	import flash.events.Event;
	
	import mx.containers.VBox;
	import mx.utils.StringUtil;
	
	import util.QuestionManager;

	public class QuestionBase extends VBox
	{
		public function QuestionBase()
		{
			super();
		}
		
		protected function Prompt(obData:Object): String {
			return obData.prompt.toString();
		}
		
		protected function OptionList(obData:Object): XMLList {
			return obData.options.option;
		}
		
		protected function Answer(str:String, fValidate:Boolean=true): void {
			if (fValidate) {
				if (str == null) return;
				str = StringUtil.trim(str);
				if (str.length == 0) return;
			}
			QuestionManager.Answer(data.@id, str);
			dispatchEvent(new Event("close", true));
		}
		protected function AnswerOption(xml:XML): void {
			if (xml.hasOwnProperty('@value'))
				Answer(xml.@value, false);
			else
				Answer(xml.toString(), false);
		}
	}
}