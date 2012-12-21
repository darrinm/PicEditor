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
	import containers.NestedControlCanvasBase;
	
	import errors.InvalidBitmapError;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	import mx.events.PropertyChangeEvent;
	
	import util.VBitmapData;
	
	[Bindable]
	[RemoteClass]
	public class StretchAndSqueezeDocumentObject extends PRectangle {
		
		public var xStretch:Number = 1;
		public var yStretch:Number = 1;
		
		override public function get typeName(): String {
			return "StretchAndSqueeze";
		}
		
		public function StretchAndSqueezeDocumentObject() {
			super();
			alpha = 0;
		}
		
		override public function FilterMenuItems(aobItems:Array):Array {
			return [];
		}
	}
}
