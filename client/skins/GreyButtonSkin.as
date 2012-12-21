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
// skins/GreyButtonSkin.as
package skins {

	// Import necessary classes here.
	import flash.display.Graphics;
	import mx.skins.Border;
	import mx.skins.ProgrammaticSkin;
	import mx.styles.StyleManager;

	public class GreyButtonSkin extends ProgrammaticSkin {
		public var backgroundFillColor:Number;

		override protected function updateDisplayList(w:Number, h:Number):void {
        // Depending on the skin's current name, set values for this skin.
        switch (name) {
           case "upSkin":
            backgroundFillColor = 0xCCCCCC;
            break;
           case "overSkin":
            backgroundFillColor = 0xb3b3b3;
            break;
           case "downSkin":
            backgroundFillColor = 0xCCCCCC;
            break;
           case "disabledSkin":
            backgroundFillColor = 0xe5e5e5;
            break;
        }

        // Draw the box using the new values.
        var g:Graphics = graphics;
        g.clear();
        g.beginFill(backgroundFillColor,1.0);
//        g.lineStyle(lineThickness, 0xFF0000);
        g.drawRoundRect(0, 0, w, h, 7);
        g.endFill();
        g.moveTo(0, 0);
        g.lineTo(w, h);
        g.moveTo(0, h);
        g.lineTo(w, 0);
     }

	}
}