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
/**
 * Sometimes (e.g. Send a Greeting) we want to add a dynamically produced bitmap, i.e. not
 * uploaded or pulled from a server, to an ImageDocument. EmbeddedBitmap provides the means
 * to do this. Just remember: documents with EmbeddedBitmaps can't be serialized.
 **/

package imagine.documentObjects {
	import flash.display.DisplayObject;
	import flash.geom.Point;

	[RemoteClass]
	public class EmbeddedBitmap extends DocumentObjectBase {
		public override function get typeName(): String {
			return "EmbeddedBitmap";
		}
		
		override public function set content(dobContent:DisplayObject): void {
			super.content = dobContent;
			unscaledWidth = content.width;
			unscaledHeight = content.height;
		}
	}
}
