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
	import util.smartresize.ISmartResizeComponent;

	[Style(name="offsetDown", type="Number", format="Length", inherit="no")]
	[Style(name="offsetRight", type="Number", format="Length", inherit="no")]

	public class ResizingButton extends ButtonPlus implements ISmartResizeComponent
	{
		public function ResizingButton(): void {
			_srh = new SmartResizeHelper(this) // smart resize code
			_srh.ignoreHeight = true; // Default to ignore height
			super();
		    // extraSpacing = 1;
	}
		
	    include "../util/smartresize/ResizeHelperInc.as";
	    include "../util/smartresize/ResizeHelperLabelsInc.as";
	    include "../util/smartresize/ResizeHelperWidthInc.as";
	    include "../util/smartresize/ResizeHelperFontSizeInc.as";
	    include "../util/smartresize/ResizeHelperPaddingLRInc.as";
	}
}