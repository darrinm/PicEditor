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
package imagine.imageOperations.bokeh.customShapes {
	import flash.display.Graphics;
	import flash.display.Shape;

	public class Star {
		public static function draw(target:Shape, radius:Number):void {
			var t:Graphics=target.graphics;
			var r:Number=radius;

			var steps:uint=5;
			var aspan:Number=360/steps;
			var a:Number=-90;
			var arad:Number;
			var tx:Number;
			var ty:Number;
			
			var r2:Number;
			
			for(var i:uint=0; i<steps*2; i++) {
				i%2==0 ? r2=r : r2=r*.5;
				arad=a/180*Math.PI;
				tx=Math.cos(arad)*r2;
				ty=Math.sin(arad)*r2;
				i==0 ? t.moveTo(tx, ty) : t.lineTo(tx, ty);
				
				a+=aspan/2;
			}
		}
	}
}