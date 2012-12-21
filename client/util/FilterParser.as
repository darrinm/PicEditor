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
	import flash.filters.BitmapFilter;
	import flash.utils.getDefinitionByName;
	
	public class FilterParser
	{
		public function FilterParser()
		{
		}

		public static function Parse(aobFilters:Array, nScaleFactor:Number): Array {
			// Convert an array of filter params into an array of filters
			var aflt:Array = [];
			for each (var obFilter:Object in aobFilters) {
				var flt:BitmapFilter;
				var cl:Class = getDefinitionByName("flash.filters." + obFilter.xmlName) as Class;
				flt = new cl();
				aflt.push(flt);
				for (var strKey:String in obFilter) {
					if (strKey in flt) {
						if (flt[strKey] is Boolean) {
							flt[strKey] = obFilter[strKey] == "true";
						} else if (flt[strKey] is Number) {
							var strVal:String = obFilter[strKey].toString();
							var nVal:Number = Number(obFilter[strKey]);
							
							if (strKey == 'blurX' || strKey == 'blurY')
								nVal *= nScaleFactor;
							
							flt[strKey] = nVal;
						} else {
							flt[strKey] = obFilter[strKey];
						}
					}
				}
			}
			
			return aflt;
		}
	}
}