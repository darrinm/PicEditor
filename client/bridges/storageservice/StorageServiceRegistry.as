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
package bridges.storageservice {
	
	// The StorageServiceRegistry's job is to keep a list of StorageServices that utilize
	// the "ss:" protocol for their resources and to help consumers of such resources
	// resolve them to final URLs that can be used to request the resource.
	
	public class StorageServiceRegistry {
		private static var s_ass:Array = [];
		
		private static var s_dctSS:Object = {
			facebook: {
				id: "Facebook",
				module: "ModBridges",
				visible: true,
				name: "Facebook",
				create_sets: true,
				set_descriptions: true },
			
			picasaweb: {
				id: "PicasaWeb",
				module: "ModBridges",
				visible: true,
				name: "Picasa Web Albums",
				create_sets: true,
				max_items_per_set: 500,
				set_descriptions: true },
			
			flickr: {
				id: "flickr",
				module: "ModBridges",
				name: "Flickr",
				visible: true,
				create_sets: true,
				set_descriptions: true,
				has_rotated_originals:true },
			
			show: {
				id: "Show",
				module: "ModBridges",
				name: "Show",
				visible: true,
				create_sets: true,
				set_descriptions: false },
			
			yahoomail: {
				id: "yahoomail",
				module: "ModBridges",
				name: "Yahoo! Mail",
				visible: true,
				create_sets: false,
				set_descriptions: false,
				
				// Yahoo docs say it lasts for 1 hour but Ali says it feels more like 1/2 hour.
				// Better to make it too short than too long so let's use 1/4 hour.
				login_lifetime: 3600 / 4 },
			
			multi: {
				id: "Multi",
				name: "Multi",
				create_sets: false,
				set_descriptions: false },
			
			photobucket: {
				id: "Photobucket",
				module: "ModBridges",
				name: "Photobucket",
				visible: true,
				create_sets: true,
				set_descriptions: false },
			
			picnik: {
				id: "Picnik",
				name: "Picnik",
				visible: true,
				create_sets: true,
				set_descriptions: true },
			
			history: {
				id: "Picnik",
				module: "ModBridges",
				name: "Picnik",
				visible: true,
				create_sets: true,
				set_descriptions: true },

			twitter: {
				id: "Twitter",
				module: "ModBridges",
				name: "Twitter",
				create_sets: false,
				visible: PicnikBase.app.canNavParentFrame,
				set_descriptions: false,
				maxwidth:600}
			
			};
		
		public static function Register(ss:IStorageService): String {
			return String(s_ass.push(ss) - 1);
		}
		
		public static function GetResourceURL(strUrl:String): String {
			// Parse the URL into its components (service index, service-specific resource id)
			var astrMatch:Array = strUrl.match(/^ss:\/\/(?P<ssid>[^\?]+)\?(?P<resid>.*)/);
			
			// If the URL doesn't match the "ss" storage service protocol just return it
			if (astrMatch == null || astrMatch.length == 0)
				return strUrl;
			
			var iss:int = int(astrMatch.ssid);
			var strResourceId:String = astrMatch.resid;
			var ss:IStorageService = s_ass[iss];

			return ss.GetResourceURL(strResourceId);
		}
		
		public static function GetStorageServiceURL(ss:IStorageService, strResourceId:String): String {
			for (var i:int = 0; i < s_ass.length; i++) {
				if (s_ass[i] == ss)
					return "ss://" + i + "?" + strResourceId;
			}
			return null;
		}
		
		public static function GetStorageServiceInfo(strId:String): Object {
			if (strId in s_dctSS) {
				return s_dctSS[strId];
			}
			return null;
		}
		
		public static function CreateStorageService( strId:String ): IStorageService {
			var obInfo:Object = GetStorageServiceInfo(strId);
			if (!obInfo) return null;
			
			if ('module' in obInfo && obInfo['module'] != null) {
				return new StorageServiceProxy( obInfo );
			} else if ('ssClass' in obInfo && obInfo['ssClass'] != null) {
				return new obInfo.ssClass();
			}
			return null;
		}
	}
}
