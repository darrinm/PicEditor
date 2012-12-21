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
package events {
	import flash.events.Event;
	
	public class HelpEvent extends Event {
		public static const SHOW_HELP:String = "showHelp";
		public static const HIDE_HELP:String = "hideHelp";
		public static const SET_HELP_TEXT:String = "setHelpText";
		
		private var _strHelpText:String;
		private var _strHelpTitle:String;
		private var _obExtraData:Object;
		
		public function HelpEvent(type:String, strHelpText:String=null, strHelpTitle:String=null, obExtraData:Object=null) {
			super(type, true, true);
			_strHelpText = strHelpText;
			_strHelpTitle = strHelpTitle;
			_obExtraData = obExtraData;
		}
		
		public function get extraData(): Object {
			return _obExtraData;
		}
		
		public function get helpText(): String {
			return _strHelpText;
		}
		
		public function get helpTitle(): String {
			return _strHelpTitle;
		}
		
		// Override the inherited clone() method
		override public function clone(): Event {
			return new HelpEvent(type, _strHelpText, _strHelpTitle, _obExtraData);
		}
	}
}
