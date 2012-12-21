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
package containers
{
	import controls.InspirationTipBase;
	
	import flash.events.MouseEvent;
	
	import mx.containers.Box;

	public class BoxPlus extends Box
	{
		public var urlType:String = null;
		public var urlid:String = null;
		[Bindable] public var rolledOver:Boolean = false;
		
		public function BoxPlus()
		{
			addEventListener(MouseEvent.ROLL_OVER, OnRollOver);	
			addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
		}
		
		private function hasUrlId(): Boolean {
			return urlType != null && urlType.length > 0 && urlid != null && urlid.length > 0;
		}
		
		private function get fullurl(): String {
			if (urlType != null && urlType.length > 0 && urlid != null && urlid.length > 0)
				return urlType + ":" + urlid;
			else
				return null;
		}
		
		private function OnRollOver(evt:MouseEvent): void {
			rolledOver = true;
			if (fullurl != null)
				InspirationTipBase.ShowInspirationByTag(fullurl, this);
		}
		
		private function OnRollOut(evt:MouseEvent): void {
			rolledOver = false;
			if (fullurl != null)
				InspirationTipBase.HideTip();
		}
	}
}