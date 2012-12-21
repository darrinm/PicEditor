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
package inspiration
{
	import mx.controls.Image;
	
	public class InspirationRenderer extends Image
	{
		private var _insp:Inspiration = null;
		public var _nSize:Number = 400;
		
		public function InspirationRenderer()
		{
			super();
		}
		
		[Bindable]
		public function set inspiration(insp:Inspiration): void {
			_insp = insp;
			if (_insp == null)
				return;
			var obPhoto:Object = _insp.photos[0];
			source = GetUrl(obPhoto);
			width = GetWidth(obPhoto);
			height = GetHeight(obPhoto);
		}
		
		public function get inspiration(): Inspiration {
			return _insp;
		}
		
		private function GetWidth(obPhoto:Object): Number {
			if (obPhoto.width > obPhoto.height)
				return _nSize;
			
			// Height is limiting factor (larger)
			return Math.round(_nSize * obPhoto.width / obPhoto.height);
		}
		
		private function GetHeight(obPhoto:Object): Number {
			if (obPhoto.height > obPhoto.width)
				return _nSize;
			
			// Width is limiting factor (larger)
			return Math.round(_nSize * obPhoto.height / obPhoto.width);
		}

		private function GetUrl(obPhoto:Object): String {
			if (_insp == null)
				return null;
			
			var strUrl:String = obPhoto.url;
			
			// http://lh5.ggpht.com/_sRmhDJ73ai8/TNrtOOGyACI/AAAAAAAAAC0/mQXBE4ya9sY/JollyRedNose.jpg
			// becomes
			// http://lh5.ggpht.com/_sRmhDJ73ai8/TNrtOOGyACI/AAAAAAAAAC0/mQXBE4ya9sY/s400/JollyRedNose.jpg
			var astrParts:Array = strUrl.split("/");
			var strTail:String = astrParts.pop();
			astrParts.push("s" + _nSize);
			astrParts.push(strTail);
			return astrParts.join("/");
		}
	}
}