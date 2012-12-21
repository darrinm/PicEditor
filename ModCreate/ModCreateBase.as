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
package {
	import creativeTools.*;
	
	import module.PicnikModule;
	
	public class ModCreateBase extends PicnikModule {
		[Bindable] public var _creativeTools:CreativeTools = null;
		[Bindable] public var collage:Collage = null;
		[Bindable] public var advancedCollage:AdvancedCollage = null;

		private function CreateToolCanvasByName(name:String) : CreativeToolCanvas {
			var tab:CreativeToolCanvas = null;
			switch (name) {
				case "featured":
					tab = new Featured();
					break;
				case "effects":
					tab = new SpecialEffectsCanvas();
					break;
				case "type":
					tab = new TextTool();
					break;
				case "shape":
					tab = new ShapeTool();
					break;
				case "beauty":
					tab = new Beauty();
					break;
				case "frames":
					tab = new Frames();
					break;
				case "advanced":
					tab = new Advanced();
					break;
				case "seasonal":
					tab = new Seasonal();
					break;
				case "admin":
					tab = new Admin();
					break;
				default:
					throw new ArgumentError("Unknown tool canvas name: " + name);
			}
			return tab;
		}
		
		public function GetCreativeTool( id:String ):ICreativeTool {
			if (id.match(/creativeTools:[a-zA-Z]*/)) {
				var tabName:String = id.split(":")[1];
				var tab:CreativeToolCanvas = CreateToolCanvasByName(tabName);
				tab.id = tabName;
				tab.includeInLayout = true;
				tab.visible = true;
				tab.percentHeight = 100;
				this.addChild(tab);
				return tab;
			}
			return null;
		}
		
		public function GetActivatableChild( id:String ):IActivatable {
			if ("creativeTools" == id) {
				if (!_creativeTools) {
					_creativeTools = new CreativeTools();
					_creativeTools.id = "creativeTools";
					_creativeTools.includeInLayout = false;
					_creativeTools.visible = false;
					this.addChild(_creativeTools);
				}
				return _creativeTools;
			}
			else if ("collage" == id) {
				if (!collage) {
					collage = new Collage();
					collage.id = "creativeTools";
					collage.includeInLayout = false;
					collage.visible = false;
					this.addChild(collage);
				}
				return collage;
			}
			else if ("advancedcollage" == id) {
				if (!advancedCollage) {
					advancedCollage = new AdvancedCollage();
					advancedCollage.id = "creativeTools";
					advancedCollage.includeInLayout = false;
					advancedCollage.visible = false;
					this.addChild(advancedCollage);
				}
				return advancedCollage;
			}
			return null;	
		}
	}
}
