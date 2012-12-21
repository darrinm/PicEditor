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
package imagine.imageOperations.paintMask
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	
	[RemoteClass]
	public class Brush {
		{ // static block
			// This alias is for backward compatibility with the pre-Imagine class packaging.
			// Yes, that '>' is unexpected but that's what RemoteClass prefixes them all with
			// so that's what we need to be backward-compatible with.
			// The [RemoteClass] above also registers ">imagine.imageOperations.paintMask.Brush"
			registerClassAlias(">imageOperations.paintMask.Brush", Brush);
		}
		
		public var inverted:Boolean = false;

		public var diameter:Number = 100;
		public var hardness:Number = 0.5;
		
		public function Brush() {
		}

		// Override in sub-classes
		public function get width(): Number {
			return 1;
		}

		// Override in sub-classes
		public function get height(): Number {
			return 1;
		}
		
		public function clone(): Brush {
			return brushFromByteArray(toByteArray());
		}
		
		public function toByteArray(): ByteArray {
			var ba:ByteArray = new ByteArray();
			ba.writeObject(this);
			return ba;
		}
		
		public function dispose(): void {
			// Do nothing. Override in sub-classes
		}
		
		public function GetDrawRect(ptCenter:Point, nColor:Number=NaN, nRot:Number=NaN): Rectangle {
			return new Rectangle(); // Override in sub-classes
		}

		
		// Draw the brush
		// Returns a dirty rectangle
		public function DrawInto(bmdTarget:BitmapData, bmdOrig:BitmapData, ptCenter:Point, nAlpha:Number, nColor:Number=NaN, nScaleX:Number=NaN, nScaleY:Number=NaN, nRot:Number=NaN): Rectangle {
			throw new Error("Override in sub-classes");
			return null;
		}
		
		public static function brushFromByteArray(ba:ByteArray): Brush {
			ba.position = 0;
			return Brush(ba.readObject());
		}
	}
}