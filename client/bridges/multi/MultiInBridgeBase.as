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
package bridges.multi {
	import bridges.*;
	import bridges.picnik.*;
	import bridges.storageservice.StorageServiceInBridgeBase;
	
	import flash.events.Event;
	
	import mx.events.FlexEvent;
	import mx.binding.utils.ChangeWatcher;

	public class MultiInBridgeBase extends StorageServiceInBridgeBase {
		
		protected override function OnInitialize(evt:FlexEvent): void {
			var ssMulti:MultiStorageService = new MultiStorageService();
			ssMulti.SetMultiItems( PicnikBase.app.multi.items );
			_ss = ssMulti;
			super.OnInitialize(evt);
			
			// keep track of any changes to multi items
			ChangeWatcher.watch(PicnikBase.app.multi, "items",
				function():void{
					ssMulti.SetMultiItems( PicnikBase.app.multi.items );
					RefreshEverything();
				 });
		}		
	}
}
