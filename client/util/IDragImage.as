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
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import imagine.ImageDocument;
	
	public interface IDragImage
	{
		function get aspectRatio(): Number; // Returns 1 if unknown, otherwise returns width/height
		function get scaleWeight(): Number; // Returns 1 for full size, smaller number for things that want to be smaller
		function get groupScale(): Number; // Returns 0 if not part of a group, otherwise a scaling factor to normalize group elements to each other
		
		function DoAdd(imgd:ImageDocument, ptTargetSize:Point, imgvTarget:ImageView, nSnapLogic:Number, nViewZoom:Number, strParentId:String=null): DisplayObject;

		function get createType(): String; // The type of object this will create, e.g. Photo or Shape. Used for transaction names, e.g. "Create " + createType

		function localToGlobal(pt:Point): Point;
		function set getDropScaleFunction(fnGetDropScale:Function): void;
	}
}