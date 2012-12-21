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
	import mx.controls.ToolTip;
	import mx.managers.ToolTipManager;
	import mx.events.PropertyChangeEvent;
	import util.UnicodeHelper;
	
	public class ToolTipPlus extends ToolTip
	{
		private var _unh:UnicodeHelper = null;
		
		public static function InstallToolTipPlus(): void {
			ToolTipManager.toolTipClass = ToolTipPlus;
		}
		
		protected override function commitProperties():void {
			// Make sure we update the
			_unh.Update();
			super.commitProperties();
		}

		public function ToolTipPlus() {
			super();
			_unh = new UnicodeHelper(this);
		}
	}
}