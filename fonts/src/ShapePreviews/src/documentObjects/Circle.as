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
package documentObjects
{
	import flash.display.Graphics;
	
	public class Circle extends PShape
	{
		public override function get typeName(): String {
			return "Circle";
		}
		
		public function Circle() {
		}

		protected override function drawShape(gr:Graphics, clr:uint): void {
			gr.clear();
			gr.beginFill(clr);
			gr.drawCircle(unscaledWidth / 2, unscaledHeight / 2, (unscaledWidth + unscaledHeight) / 4);
			gr.endFill();
		}
	}
}