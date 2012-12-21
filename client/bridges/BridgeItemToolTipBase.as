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
// UNDONE: recursive GetPhotoInfo calls
// UNDONE: styling, presentation of title, description, tags, owner, other attribution
// UNDONE: apply to easter egg
// UNDONE: apply to other InBridges
// UNDONE: selecting a BridgeItem keeps its tooltip from coming up
// UNDONE: derive max size from stage size (for Facebook, etc)
// UNDONE: prioritized image loading
// UNDONE: second-invocation behavior
// UNDONE: cancel in-progress loads when tooltip closes

package bridges {
	import flash.display.Loader;
	import flash.events.Event;
	
	import mx.containers.Canvas;
	import mx.controls.Image;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	
	public class BridgeItemToolTipBase extends Canvas {
        [Bindable] public var mouseOffsetX:Number = 10;
        [Bindable] public var mouseOffsetY:Number = 0;
        [Bindable] public var _imgThumbnail:Image;
       
        private var _imgp:ImageProperties;
        private var _cxStart:Number, _cyStart:Number;

		public function BridgeItemToolTipBase() {
			super();
			
			// Have the tooltip follow the mouse
			addEventListener(Event.ENTER_FRAME, OnEnterFrame);
			addEventListener(ResizeEvent.RESIZE, OnResize);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
			
			// The tip doesn't need mouse events and we don't want
			// entering inside of it to make it go away.
			mouseEnabled = false;
			mouseChildren = false;
		}
		
		public function SetStartSize(cx:Number, cy:Number): void {
			_cxStart = cx;
			_cyStart = cy;
		}
		
		private function OnCreationComplete(evt:FlexEvent): void {
			_imgThumbnail.minWidth = _cxStart;
			_imgThumbnail.minHeight = _cyStart;
			Reposition();
		}
					
		private function OnResize(evt:ResizeEvent): void {
			Reposition();
		}
		
		private function OnEnterFrame(evt:Event): void {
			if (parent != null)
				Reposition();
		}
		
		private function Reposition(): void {
			if (stage == null)
				return;
				
			var x:Number = stage.mouseX - (width / 2);
			var y:Number = stage.mouseY + mouseOffsetY;
			
			// If the tip doesn't fit completely on the stage, flip it so it does.
			// This approach means the mouse pointer will never end up over the tip.
			if (x + width > stage.stageWidth)
				x = stage.stageWidth - width;
			if (x < 0)
				x = 0;
			if (y + height > stage.stageHeight)
				y = stage.stageHeight - height;
			if (y < 0)
				y = 0;
			move(x, y);
		}

        [Bindable]
        public function get imageProperties(): ImageProperties {
        	return _imgp;
        }
       
        public function set imageProperties(imgp:ImageProperties): void {
        	_imgp = imgp;
        	invalidateProperties();
        }
       
        override public function validateProperties(): void {
        	super.validateProperties();
        	
        	var ldr:Loader = _imgp.GetMediumThumbnail();
        	try {
        		if (ldr.content) {
	       			currentState = "Medium";
        		}
        	} catch (err:Error) {
       			currentState = "Medium";
        	}

        	var fnSetStateMedium:Function = function (evt:Event): void {
					ldr.contentLoaderInfo.removeEventListener(Event.COMPLETE, fnSetStateMedium);
		        	currentState = "Medium";
		        }
        	
        	if (currentState == "Medium") {
        		Reposition();
        	} else {
	       		ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, fnSetStateMedium);
	       	}
        }
       
        //  Implement required methods of the IToolTip interface; these
        //  methods are not used in this example, though.
        public function get text():String {
            return "bogus";
        }
       
        public function set text(value:String): void {
        }
	}
}
