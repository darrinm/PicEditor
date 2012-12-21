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
	
	import mx.core.IFactory;

	// Group shapes into hboxes
	public class ShapeSection extends BoxSection
	{
		// Shape sections group a few items into a container
		
		// This is the container to use
		static public const kclShapeContainer:Class = ShapeHBox;
		
		// The divider to place between shapes
		static public const kclShapeContainerDivider:Class = ShapeVRule;
		
		// This is the max number of items per container
		static public const knShapesPerBox:Number = 4;
		
		// The above constants could be extracted into a sub-class if we need to use this elsewhere
		override protected function CreateChildren(): void {
			var dobc:DisplayObjectContainer;
			
			for (var i:int = 0; i < _dataProvider.length; i++)
			{
				if (i % knShapesPerBox == 0)
					dobc = null;
				
				if (dobc == null) {
					dobc = new kclShapeContainer();
					_bxChildItems.addChild(dobc);
				}
			
				var obItem:Object = new _clItemRenderer();
				var xmlData:XML = _dataProvider.getItemAt(i) as XML;

				// localize the tooltip				
				if (xmlData.hasOwnProperty("@toolTipText")) {
					xmlData.@toolTip = xmlData.@toolTipText;
				}

				if (data.hasOwnProperty('sectionId')) {
					xmlData.@sectionId = data.sectionId;
				}
				
				obItem["data"] = xmlData;
				var dobItem:DisplayObject = null;
				if (obItem is IFactory)
					dobItem = (obItem as IFactory).newInstance() as DisplayObject;
				else
					dobItem = obItem as DisplayObject;
				dobc.addChild(dobItem);
				if ((i % knShapesPerBox != (knShapesPerBox-1)) && kclShapeContainerDivider) {
					dobc.addChild(new kclShapeContainerDivider() as DisplayObject);
				}
			}
		}
	}
}