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
package util {
	public dynamic class PicnikFile {		
		public static function GetThumbUrls( strBaseUrl:String, obPutThemHere:Object = null ): Object {
			// returns URLs to access thumbnail images. 
			//strBaseUrl describes the original rendered image.
			
			// remove any file extensions on the base URL (".jpg" or ".png")
			var nDot:Number = strBaseUrl.lastIndexOf( "." ); 
			if (nDot != -1) {
				strBaseUrl = strBaseUrl.substr(0, nDot);
			}
			
			var oThumbs:Object = {
				thumb320url: strBaseUrl + "/thumb320.jpg",
				thumb100url: strBaseUrl + "/thumb100.jpg",
				thumb75url: strBaseUrl + "/thumb75.jpg"			
			}
			
			if (obPutThemHere) {
				for(var strKey:String in oThumbs) {
					obPutThemHere[strKey] = oThumbs[strKey];
				}
			}

			return oThumbs;
		}				
	}
}
