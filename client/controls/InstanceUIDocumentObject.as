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
package controls
{
	import imagine.documentObjects.DocumentObjectBase;
	import imagine.documentObjects.IDocumentObject;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import mx.binding.utils.ChangeWatcher;
	
	public class InstanceUIDocumentObject extends UIDocumentObject
	{
		private var _nPrevWidth:Number = 0;
		private var _nPrevHeight:Number = 0;

		public function InstanceUIDocumentObject(xml:XML=null): void {
			addEventListener(Event.RESIZE, OnResize);
			init(xml);
		}
	
		override protected function init(xml:XML): void {
			super.init(xml);
			// Convert the XML into a child object.
			child = ChildFromXML(xml);
		}

		override public function set child(doco:IDocumentObject): void {
			if (child) removeChild(child as DisplayObject);
			super.child = doco;
			addChild(doco as DisplayObject);
			if ("color" in doco) {
				doco["color"] = childColor;
			}
			measure();
			SizeChild();
			ChangeWatcher.watch(doco, "unscaledWidth", OnSizeChange);
			ChangeWatcher.watch(doco, "unscaledHeight", OnSizeChange);
			ChangeWatcher.watch(doco, "content", OnSizeChange);
		}
		
		// Override in children to react accordingly
		override public function set childColor(clr:uint): void {
			super.childColor = clr;
			var doco:IDocumentObject = child;
			if (doco == null || !("color" in doco)) return;
			doco["color"] = clr;
			doco.Validate();
		}
		
		private function SizeChild(): void {
			Redraw();
			var doco:IDocumentObject = child;
			if (doco == null) return; // No child
			
			if ("x" in doco) doco["x"] = Math.round(width/2);
			if ("y" in doco) doco["y"] = Math.round(height/2);
			
			var rc:Rectangle = new Rectangle(0,0,measuredWidth * childSizeFactor, measuredHeight * childSizeFactor);
			if (doco is DocumentObjectBase) {
				var cx:Number = (doco as DocumentObjectBase).unscaledWidth;
				var cy:Number = (doco as DocumentObjectBase).unscaledHeight;
				if ("defaultScaleY" in doco) {
					cy *= doco["defaultScaleY"];
				}
				rc.width = rc.width * cx / Math.max(cx,cy);
				rc.height = rc.height * cy / Math.max(cx,cy);
			}
			doco.localRect = rc;
			doco.Validate();
		}
		
		
		private function OnResize(evt:Event): void {
			if (_nPrevWidth == width && _nPrevHeight == height) return; // No updates
			_nPrevHeight = height;
			_nPrevWidth = width;
			SizeChild();
		}
		
		private function OnSizeChange(evt:Event): void {
			SizeChild();
		}

	}
}