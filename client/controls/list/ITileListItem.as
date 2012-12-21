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
	import mx.controls.listClasses.IListItemRenderer;
	
	/**
	 * An item in a PicnikTileList must implement this interface
	 * This gives the tile list an easy way to get information about the item
	 */
	public interface ITileListItem extends IListItemRenderer
	{
	    function get highlighted(): Boolean;
	    function get selected(): Boolean;
	    function set highlighted(f:Boolean): void;
	    function set selected(f:Boolean): void;

	    function setState(fHighlighted:Boolean, fSelected:Boolean, fEnabled:Boolean): void;
	   
	    function isLoaded(): Boolean;
	}
}