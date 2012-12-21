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
package dialogs.DialogContent {
	import mx.containers.Canvas;
	
	public class DialogContentBase extends Canvas implements IDialogContent {
		private var m_dcc:IDialogContentContainer;
		[Bindable]
		public function get container(): IDialogContentContainer {
			return m_dcc;
		}
		
		public function set container(dcc:IDialogContentContainer): void {
			m_dcc = dcc;			
		}
	}	
}
