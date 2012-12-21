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
package containers.sectionList
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	// Group shapes into hboxes
	public class CollageSection extends BoxSection {
		// Collage sections group a few items into a container
		
		// This is the container to use
		static public const kclItemContainer:Class = ShapeHBox;
		
		// The divider to place between items
		static public const kclItemContainerDivider:Class = ShapeVRule;
		
		// This is the max number of items per container
		protected var _nItemsPerBox:Number = 4;
		
		// The above constants could be extracted into a sub-class if we need to use this elsewhere
		override protected function CreateChildren(): void {
			var dobc:DisplayObjectContainer;
			
			for (var i:int = 0; i < _dataProvider.length; i++) {
				if (i % _nItemsPerBox == 0)
					dobc = null;
				
				if (dobc == null) {
					dobc = new kclItemContainer();
					_bxChildItems.addChild(dobc);
				}
			
				var obItem:Object = new _clItemRenderer();
				var obData:Object = _dataProvider.getItemAt(i);
				if (data.premium) {
					// Pass premium flag down to the item so it knows what to do when clicked
					obData.premium = data.premium;
//					obItem.selectedColor = 0xb2d6ef;
//					obItem.deselectedColor = 0xb2d6ef;
				}
				obItem["data"] = obData;
				dobc.addChild(obItem as DisplayObject);
				if ((i % _nItemsPerBox != (_nItemsPerBox-1)) && kclItemContainerDivider) {
					if ("rightDivider" in obItem)
						obItem['rightDivider'] = true;
					else
						dobc.addChild(new kclItemContainerDivider() as DisplayObject);
				}
			}
		}
	}
}
