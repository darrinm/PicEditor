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
	import mx.utils.ObjectProxy;
	
	public class StorageServiceSetComboItem {
		[Bindable] public var label:String = null;
		[Bindable] public var icon:String = null;
		[Bindable] public var cmd:String = null;
		[Bindable] public var setinfo:Object = null;
		[Bindable] public var iteminfo:Object = null;
		[Bindable] public var hasIcons:Boolean = false;
		
		public function StorageServiceSetComboItem(strLabel:String, strIcon:String, dctSetInfo:Object, strCmd:String=null): void {
			label = strLabel;
			icon = strIcon;
			cmd = strCmd;
			hasIcons = strIcon != null;
			
			// Do this so setinfo's properties can be bound to
			setinfo = new ObjectProxy(dctSetInfo);
			iteminfo = dctSetInfo is ItemInfo ? dctSetInfo : null;
		}
		
		private static function AnyHaveIcons(aitmSets:Array): Boolean {
			if (aitmSets != null)
				for each (var itmSet:StorageServiceSetComboItem in aitmSets)
					if (itmSet.hasIcons)
						return true;

			return false;
		}
		
		public static function UpdateHasIcons(aitmSets:Array): void {
			var fHasIcons:Boolean = AnyHaveIcons(aitmSets);
			if (aitmSets != null)
				for each (var itmSet:StorageServiceSetComboItem in aitmSets)
					itmSet.hasIcons = fHasIcons;
		}
	}
}
