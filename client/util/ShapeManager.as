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
package util
{
	import mx.core.Application;
	
	public class ShapeManager
	{
		private static function IsStandaloneFlashPlayer(): Boolean {
			return ("http" != Application.application.url.substr(0,4).toLowerCase());
		}
		
		public static function ShapesBasePath(): String {
			var strBase:String;
			if (ShapeManager.IsStandaloneFlashPlayer()) {
				strBase = "website/app/";
			} else {
				strBase = "../app/";
			}
			return strBase + CONFIG::locale + "/";
		}
	}
}
