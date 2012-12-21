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
// SpecialEffects take too long to initialize so this modified VBox is used
// to load one effect at a time with a callLater in between. The end result
// looks and feels more like a web page load.

package containers {
	import flash.events.Event;
	
	import mx.containers.VBox;
	import mx.core.IFlexDisplayObject;
	import mx.events.FlexEvent;

	public class IncrementalInitVBox extends VBox {
		private var _iuicd:Number = 0;
		
		override public function createComponentsFromDescriptors(fRecurse:Boolean=true): void {
			if (childDescriptors.length <= 0)
				return;
			callLater(OnLater);
			processedDescriptors = true;
		}
		
		private function OnLater(): void {
			if (_iuicd < childDescriptors.length) {
	            var fdo:IFlexDisplayObject = createComponentFromDescriptor(childDescriptors[_iuicd++], true);
	            fdo.addEventListener(FlexEvent.CREATION_COMPLETE, OnChildCreationComplete);
			} else {
				dispatchEvent(new Event("allChildrenCreated"));
			}
		}
		
		private function OnChildCreationComplete(evt:FlexEvent): void {
			evt.target.removeEventListener(FlexEvent.CREATION_COMPLETE, OnChildCreationComplete);
			callLater(OnLater);
		}
	}
}
