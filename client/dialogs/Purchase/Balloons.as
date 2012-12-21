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
package dialogs.Purchase {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	
	import mx.controls.SWFLoader;
	import mx.core.UIComponent;
	import mx.effects.Move;
	import mx.effects.easing.Linear;
	import mx.effects.easing.Quadratic;
	import mx.events.EffectEvent;
	
	public class Balloons extends UIComponent {
		private const kcBalloonTypes:int = 6; // Balloon naming convention: balloonN.swf
		
		public function Float(cBalloons:int=20): void {
			// Create a bunch of balloon SWFLoaders
			for (var i:int = 0; i < cBalloons; i++) {
				var ldr:SWFLoader = new SWFLoader();
		        ldr.addEventListener(Event.COMPLETE, OnBalloonLoaded);
		        ldr.addEventListener(IOErrorEvent.IO_ERROR, OnBalloonError);
		        ldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnBalloonError);
				ldr.load(PicnikBase.StaticUrl("../graphics/balloon" + int(Math.random() * kcBalloonTypes) + ".swf"));
			}

/* DWM: Not adding much, we'll see			
			var ntf:Notifier = new Notifier();
			ntf.addEventListener(FlexEvent.CREATION_COMPLETE, OnNotifierCreationComplete);
			FloatComponent(ntf, (systemManager.screen.width - 250) / 2, systemManager.screen.height);
*/
		}

/*		
		private function OnNotifierCreationComplete(evt:FlexEvent): void {
			var ntf:Notifier = evt.target as Notifier;
			ntf._lblNotification.text = "Thank you!";
		}
*/		
		private function OnBalloonLoaded(evt:Event): void {
			// Add the balloon as an immediate child of the stage
			var ldr:SWFLoader = evt.target as SWFLoader;
			ldr.maintainAspectRatio = false;
			ldr.width = ldr.contentWidth;
			ldr.height = ldr.contentHeight;
			FloatComponent(ldr);
		}
		
		private function FloatComponent(uic:UIComponent, xFrom:int=-1, yFrom:int=-1): void {
			// SystemManager.rawChildren are all the topmost DisplayObjects. Add to the end of this list
			// to put something on top of everything.
			systemManager.rawChildren.addChild(uic);
			uic.visible = true;
			
			// Stage-proportional scale factor
			uic.scaleX = uic.scaleY = systemManager.screen.width / 1024;
			var cxBalloon:Number = uic.width * uic.scaleX;
			var cyBalloon:Number = uic.height * uic.scaleY;
			
			// Attach an effect that animates them off the top
			var eff:Move = new Move();
			eff.target = uic;
			eff.easingFunction = Quadratic.easeIn;
			if (xFrom == -1) {
				eff.xFrom = int(Math.random() * (systemManager.screen.width - cxBalloon));
			} else {
				eff.xFrom = xFrom;
				eff.easingFunction = Linear.easeIn;
			}
			eff.xTo = eff.xFrom + (Math.random() * cxBalloon * 2) - (cxBalloon);
			
			// Give them random start points off the bottom of the stage
			if (yFrom == -1)
				eff.yFrom = int(Math.random() * (systemManager.screen.height / 4)) + systemManager.screen.height;
			else
				eff.yFrom = yFrom;
			eff.yTo = -cyBalloon;
			eff.addEventListener(EffectEvent.EFFECT_END, OnBalloonMoveEnd);
			
			// Let them fly! (for 5 secs + random(0-5) secs)
			eff.duration = int(Math.random() * 5000) + 5000;
			eff.play();
		}
		
		private function OnBalloonMoveEnd(evt:EffectEvent): void {
			// Get rid of them as they go off the top
			systemManager.rawChildren.removeChild(evt.target.target);
//		evt.target.target.unload();
		}
		
		private function OnBalloonError(evt:Event): void {
			// Oh well, forget it
		}
	}
}
