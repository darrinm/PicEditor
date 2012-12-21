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
// DocumentObjects must implement this interface AND inherit from a DisplayObject

package documentObjects {
	import flash.geom.Rectangle;
	
	public interface IDocumentObject extends IDocumentSerializable, IDocumentStatus { // doco
		
		// Apply any pending property changes
		function Validate(): void;
		function Invalidate(ff:uint=0xffffffff): void;
		
		function GetProperty(strProp:String): *;
		
		// Get/Set the untransformed bounds of the DocumentObject, in origin-relative coordinates
		function get localRect(): Rectangle;
		function set localRect(rc:Rectangle): void;
		
		function get unscaledWidth(): Number;
		function set unscaledWidth(cx:Number): void;
		
		function get unscaledHeight(): Number;
		function set unscaledHeight(cy:Number): void;
		
		function set color(co:uint): void;
		function get color(): uint;

		function set alpha(nAlpha:Number): void;
		function get alpha(): Number;
		
		function set blendMode(strBlendMode:String): void;
		function get blendMode(): String;

		// The name of this type, e.g. text, heart, clipart, shape, etc.
		function get typeName(): String;
		
		// The sub tab for this type, e.g. "_ctType" or "_ctShape"
		function get typeSubTab(): String;
		
		// The object palette to be used for this type, e.g. "Text", "Shape"
		function get objectPaletteName(): String;
		
		// The ImageDocument containing this DocumentObject
		function get document(): ImageDocument;
		function set document(imgd:ImageDocument): void;
	}
}
