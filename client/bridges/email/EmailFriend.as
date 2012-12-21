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
package bridges.email
{
	import mx.validators.Validator;
	
	import util.UserEmailDictionary;
	
	import validators.PicnikEmailValidator;
	
	public class EmailFriend
	{
		[Bindable] public var name:String = "";
		[Bindable] public var email:String = "";
		
		public function EmailFriend(strEmail:String = "", strName:String = "" )
		{
			email = strEmail;
			name = strName;
		}
		
		public function Persist():String {
			var xml:XML = <EmailFriend email={email} name={name}/>;
			return xml.toXMLString();
		}

		public function Restore( data:String ):void {
			var xml:XML = new XML(data);
			if (xml) {
				name = xml.@name;
				email = xml.@email;
			}
		}

	}
}