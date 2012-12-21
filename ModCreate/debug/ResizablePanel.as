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
package debug
{
    import flash.events.MouseEvent;

    import mx.containers.Panel;
    import mx.controls.Button;

    public class ResizablePanel extends Panel
    {
        private var resizer:Button = new Button();

        public function ResizablePanel()
        {
            super();
            resizer.addEventListener(MouseEvent.MOUSE_DOWN, resizeDown);
        }
        override protected function createChildren():void{
            resizer.height=10;
            resizer.width = 10;
            super.createChildren();
            rawChildren.addChild(resizer);
        }
        override protected function updateDisplayList(w:Number, h:Number):void{
            super.updateDisplayList(w,h);
            resizer.y = h - resizer.height;
            resizer.x = w - resizer.width;
        }
        private function resizeDown(e:MouseEvent):void{
            stage.addEventListener(MouseEvent.MOUSE_MOVE, scalePanel);
            stage.addEventListener(MouseEvent.MOUSE_UP, stopScale);
        }
        private function scalePanel(e:MouseEvent):void{
            if((stage.mouseX - x)>50)
                width = (stage.mouseX-x);
            if((stage.mouseY-y)>50)
                height = (stage.mouseY-y);  
        }
        private function stopScale(e:MouseEvent):void{
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, scalePanel);
            stage.removeEventListener(MouseEvent.MOUSE_UP, stopScale);
        }
    }
}