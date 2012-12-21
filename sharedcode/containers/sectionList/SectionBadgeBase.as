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
package containers.sectionList {
	import mx.containers.VBox;
	import util.SectionBadgeInfo;
	import flash.net.URLRequest;

	// A section renderer renders a header and a list of child items
	public class SectionBadgeBase extends VBox {
		[Bindable] public var moreInfoUrl:String = null;
		
		public function OnBadgeClick():void {
			if (moreInfoUrl)
				PicnikBase.app.NavigateToURL( new URLRequest(moreInfoUrl), "_blank" );
		}
	}	
}
	