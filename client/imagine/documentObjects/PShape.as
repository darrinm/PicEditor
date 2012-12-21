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
package imagine.documentObjects {
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import mx.events.PropertyChangeEvent;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	
	[Bindable]
	[RemoteClass]
	public class PShape extends DocumentObjectBase {
		// Override this in child classes
		override public function get typeName(): String {
			return "Shape";
		}
		
		public function PShape(): void {
			createShape();
		}
		
		// Override this in subclasses
		protected function drawShape(gr:Graphics, clr:uint): void {
			throw new Error("subclasses of PShape must override drawShape: " + this);
		}

		override protected function Redraw(): void {
			var spr:Sprite = content as Sprite;
			if (spr == null) {
				createShape();
			} else {
				drawShape(spr.graphics, color);
			}
		}
		
		protected function createShape(): void {
			var spr:Sprite;
			if (content == null) spr = new Sprite();
			else spr = (content as Sprite);
			drawShape(spr.graphics, color);
			content = spr;
		}
		
		override public function set color(clr:uint): void {
			super.color = clr;
			createShape();
		}
		
	}
}
