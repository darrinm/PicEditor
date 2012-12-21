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
package dialogs.RegisterHelper{

	// IFormContainer is the interface that a parent control needs to implement
	// in order to happily contain on the the RegisterHelper dialogs
	public interface IFormContainer {

		// selects a form for display, optionally providing path/event details for Urchin 		
		function SelectForm( strName:String, obDefaults:Object = null ): void;
		function PushForm( strName:String, obDefaults:Object = null ): void;
		function GetActiveForm(): RegisterBoxBase;

		// we're all done -- tell the container to hide itself		
		function Hide(): void;

		// display a modal set of gears if you've got one
		function set working( fWorking:Boolean ): void;
		function get working(): Boolean;		
	}
}
