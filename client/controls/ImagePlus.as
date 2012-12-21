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
package controls
{
	import flash.display.Bitmap;
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.events.Event;
	import flash.system.LoaderContext;
	
	import mx.core.FlexLoader;

	[Event(name="slowLoadComplete", type="flash.events.Event")]
	[Effect(name="slowLoadCompleteEffect", event="slowLoadComplete")]

	public class ImagePlus extends ImageEx {
		public function ImagePlus() {
			super();
			addEventListener("sourceChanged", OnSourceChanged);
			addEventListener(Event.COMPLETE, OnComplete);
			
			// We really like it when 3rd-party sites have a crossdomain.xml
			// <allow-access-from domain="*"> file. Then we can access the image bits,
			// e.g. for smoothing.
			loaderContext = new LoaderContext(true); // checkPolicyFile = true
		}
		
		[Bindable] public var slowLoadTime:Number = 300;
		[Bindable] public var borderColor:uint = 0x000000;
		[Bindable] public var borderThickness:Number = 0;
		[Bindable] public var borderCornerRadius:Number = 0;
		[Bindable] public var borderAlpha:Number = 1;
		
		public var autoStartStopSwf:Boolean = false;
		
		private var _dtStartLoad:Date = null;
		private var _fNeverScaleUp:Boolean = false;
		
		public override function set visible(value:Boolean):void {
			if (autoStartStopSwf && content) {
				var strFunction:String = value ? "play" : "stop";
				try {
					content[strFunction]();
				} catch (e:Error) {
					trace("Ignoring error calling " + strFunction + " on ImagePlus content: " + e + ", " + e.getStackTrace());
				}
			}
			super.visible = value;
		}
		
		private function OnSourceChanged(evt:Event): void {
			if (source == null)
				_dtStartLoad = null;
			else
				_dtStartLoad = new Date();
		}
		
		[Bindable] public function set neverScaleUp(f:Boolean): void {
			if (_fNeverScaleUp == f) return;
			_fNeverScaleUp = f;
			UpdateMaxSize();
		}
		public function get neverScaleUp(): Boolean {
			return _fNeverScaleUp;
		}
		
		private function OnComplete(evt:Event): void {
			if (_dtStartLoad) {
				var nLoadTime:Number = new Date().time - _dtStartLoad.time;
				if (nLoadTime >= slowLoadTime) {
					dispatchEvent(new Event("slowLoadComplete"));
				}
			}
			if (_fNeverScaleUp) {
				UpdateMaxSize();
			}
		}
		
		private function UpdateMaxSize(): void {
			if (!content || !content.loaderInfo) return;
			if (_fNeverScaleUp) {
				super.maxWidth = content.width;
				super.maxHeight = content.height;
			} else {
				super.maxWidth = NaN;
				super.maxHeight = NaN;
			}
		}

        override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number): void {
            super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			try {
				if (borderThickness && content && content.loaderInfo) {
		            // clear graphics
		            graphics.clear();
		           
		            var nSourceAspect:Number = content.loaderInfo.height ? content.loaderInfo.width / content.loaderInfo.height : 0;
		            var nWorkingAspect:Number = unscaledHeight ? unscaledWidth / unscaledHeight : 0;
		            var nWorkingWidth:Number = unscaledWidth;
		            var nWorkingHeight:Number = unscaledHeight;
		            if (nSourceAspect > 0) {
			            if (nWorkingAspect > nSourceAspect )
			            	nWorkingWidth = nWorkingHeight * nSourceAspect;
			            else if (nWorkingAspect < nSourceAspect)
			            	nWorkingHeight = nWorkingWidth / nSourceAspect;
			      	}
		
		            if (content) {
		                content.scaleX = (nWorkingWidth - borderThickness * 2)/nWorkingWidth;
		                content.scaleY = (nWorkingHeight - borderThickness * 2)/nWorkingHeight;
		                content.x = borderThickness / content.parent.scaleX;
		                content.y = borderThickness / content.parent.scaleY;
		         	}
	
					// objects which have some extra centering info might be offset a little. 
					// Dig around in the object to find the contentHolder
		            var contentHolder:FlexLoader = this.getChildAt(0) as FlexLoader;
		            var xOff:Number = 0;
		            var yOff:Number = 0;
		            if (contentHolder) {
		            	xOff = contentHolder.x;
		            	yOff = contentHolder.y;
		            }
		           
		            // draw a rectangle using the given border info
		            graphics.lineStyle(borderThickness+1,borderColor,borderAlpha,false,LineScaleMode.NORMAL,CapsStyle.NONE,JointStyle.MITER);
		            if (borderCornerRadius)
		            	graphics.drawRoundRect(xOff+borderThickness/2,yOff+borderThickness/2,nWorkingWidth-borderThickness,nWorkingHeight-borderThickness,borderCornerRadius,borderCornerRadius);
		            else
		            	graphics.drawRect(xOff+borderThickness/2,yOff+borderThickness/2,nWorkingWidth-borderThickness,nWorkingHeight-borderThickness);
		
				}
				// We like all our Images to be silky-smooth
	            if (content is Bitmap) {
	                var bm:Bitmap = Bitmap(content);
	                if (bm != null && !bm.smoothing)
	                    bm.smoothing = true;
	            }
			} catch (err:Error) {
				// Probably not accessable due to lack of crossdomain permissions.
			}
        }
	}
}
