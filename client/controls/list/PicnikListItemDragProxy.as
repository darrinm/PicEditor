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
package controls.list
{

import flash.display.DisplayObject;
import flash.events.Event;
import flash.geom.Point;

import mx.core.UIComponent;

/**
 *  The default drag proxy used when dragging from a PicnikTileList
 *  A drag proxy is a component that parents the objects
 *  or copies of the objects being dragged
 */
public class PicnikListItemDragProxy extends UIComponent
{
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

	/**
	 *  Constructor.
	 */
	public function PicnikListItemDragProxy()
	{
		super();
	}

	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------

	private var _aobData:Array = [];
	
	public function get dataArray(): Array {
		return _aobData;
	}
	
	//--------------------------------------------------------------------------
	//
	//  Overridden methods: UIComponent
	//
	//--------------------------------------------------------------------------
	
	
	/**
	 *  @private
	 */
	override protected function createChildren():void
	{
        super.createChildren();
        this.addEventListener(Event.REMOVED_FROM_STAGE, OnRemoved);
        var ptlOwner:PicnikTileList = PicnikTileList(owner);
       
		var anSelectedItemIds:Array = ptlOwner.copySelectedItems(false);

		for each (var nItemId:Number in anSelectedItemIds)
		{
			var tli:ITileListItem = ptlOwner.itemRenderer.newInstance();

			var obData:Object = ptlOwner.indexToData(nItemId);
			_aobData.push(obData);
			tli['data'] = obData;
			
			var dob:DisplayObject = DisplayObject(tli);
			
			var ptOffset:Point = ptlOwner.dragImageOffset(nItemId);
			
			addChild(dob);
			
			dob.width = ptlOwner.columnWidth;
			dob.height = ptlOwner.rowHeight;
			dob.x = ptOffset.x;
			dob.y = ptOffset.y;

			measuredHeight = Math.max(measuredHeight, tli.y + tli.height);
			measuredWidth = Math.max(measuredWidth, tli.x + tli.width);
		}

		invalidateDisplayList();
	}

	// When an item is removed, make sure we free up (null out) any item data
	// If we need to retrieve hte data held by the item, we can use the dataArray getter
	private function OnRemoved(evt:Event): void {
		while (numChildren) {
			var dobChild:DisplayObject = removeChildAt(0);
			var tli:ITileListItem = dobChild as ITileListItem;
			if (tli) {
				tli['data'] = null; // Make sure we free any resources held by the child
			}
		}
	}
	
}

}
