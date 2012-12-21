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
package bridges {
	import events.*;
	
	public class OutBridge extends Bridge {
		[Bindable] public var _imgvPreview:ImageView;

		public static const POSTSAVE_SUB_TAB:String = "_brgPostSave";
		public static const PICNIK_SUB_TAB:String = "_brgPicnikOut";
		public static const PHOTOBUCKET_SUB_TAB:String = "_brgPhotobucketOut";
		public static const FLICKR_SUB_TAB:String = "_brgFlickrOut";
		public static const PICASA_SUB_TAB:String = "_brgPicasaWebOut";
		public static const FACEBOOK_SUB_TAB:String = "_brgFacebookOut";
		public static const SHARE_SUB_TAB:String = "_brgShareOut";
		public static const EMAIL_SUB_TAB:String = "_brgEmailOut";
		public static const DOWNLOAD_SUB_TAB:String = "_brgMyComputerOut";
		public static const PRINT_SUB_TAB:String = "_brgPrinterOut";
		public static const GALLERY_SUB_TAB:String = "_brgGalleryOut";
		public static const TWITTER_SUB_TAB:String = "_brgTwitterOut";

		public static const PUBLISH_ACTION:String = "Publish";
		
		override protected function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			super.OnActiveDocumentChange(evt);
			if (_imgvPreview != null)
				_imgvPreview.imageDocument = _imgd;
		}
	}
}
