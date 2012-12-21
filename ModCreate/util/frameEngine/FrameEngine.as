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
package util.frameEngine
{
	import de.polygonal.math.PM_PRNG;
	
	import flash.filters.BitmapFilter;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	
	public class FrameEngine
	{
		public var _rnd:PM_PRNG;
		public var _aobShapes:Array = [];
		public var _rcArea:Rectangle;
		public var _afltGroupFilters:Array = [];
		public var _afltBackgroundFilters:Array = [];
		
		public function FrameEngine(rcArea:Rectangle, obFrames:Object, nRandomSeed:Number=1)
		{
			_rnd = new PM_PRNG();
			_rnd.seed = nRandomSeed;

			var aobFrameParams:Array;
			if (obFrames is XML)
				aobFrameParams = ParseXML(obFrames as XML);
			else
				aobFrameParams = obFrames as Array;
				
			var aobFrames:Array = [];
			var aobBackgroundFilters:Array = [];
			var aobGroupFilters:Array = [];
			for each (var obFrameParams:Object in aobFrameParams) {
				if (obFrameParams.xmlName == "backgroundFilters")
					aobBackgroundFilters = obFrameParams.aobChildren;
				else if (obFrameParams.xmlName == "groupFilters")
					aobGroupFilters = obFrameParams.aobChildren;
				else if (obFrameParams.xmlName == "frame")
					aobFrames.push(new Frame(this, obFrameParams, aobFrames.length));
			}
			_rcArea = rcArea;
			
			_afltGroupFilters = aobGroupFilters.slice();
			_afltBackgroundFilters = aobBackgroundFilters.slice();
			
			LayoutShapes(aobFrames);
		}
		
		public function get layout(): Object {
			return {shapes:shapes,
				groupFilters:_afltGroupFilters,
				backgroundFilters:_afltBackgroundFilters,
				fMask:true,
				obArea:{x:_rcArea.x, y:_rcArea.y, width:_rcArea.width, height:_rcArea.height}
				};
		}

		private function XmlToOb(xml:XML): Object {
			var obResult:Object = {};
			
			var strKey:String;
			for each (var xmlAttr:XML in xml.attributes()) {
				strKey = xmlAttr.name();
				obResult[strKey] = xmlAttr.toString();
			}
			
			var aobChildren:Array = null;
			for each (var xmlChild:XML in xml.*) {
				if (aobChildren == null) {
					aobChildren = [];
					obResult.aobChildren = aobChildren;
				}
				strKey = xmlChild.name();
				var obChild:Object = XmlToOb(xmlChild);
				obChild.xmlName = strKey;
				aobChildren.push(obChild);
			}
			return obResult;
		}
		
		private function ParseXML(xmlFrames:XML): Array {
			return XmlToOb(xmlFrames).aobChildren as Array;
		}
		
		private function LayoutShapes(aobFrames:Array): void {
			for each (var frm:Frame in aobFrames)
				frm.Layout();
			
			_aobShapes.sortOn('zOrder', Array.NUMERIC);
			for each (var obShape:Object in _aobShapes)
				delete obShape['zOrder'];
		}
		
		public function get shapes(): Array {
			return _aobShapes;
		}
	}
}