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

	/*** FloatingImage
	 * Use this when you have an animating image that is slowing things down.
	 * This object is the placeholder. The animation will float above it.
	 * Note that this needs an explicit size.
	 */
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.core.Application;
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	import mx.events.MoveEvent;
	import mx.events.ResizeEvent;
	import mx.managers.PopUpManager;

	//--------------------------------------
	//  Events copied from SWFLoader
	//--------------------------------------
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="httpStatus", type="flash.events.HTTPStatusEvent")]
	[Event(name="init", type="flash.events.Event")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	[Event(name="open", type="flash.events.Event")]
	[Event(name="progress", type="flash.events.ProgressEvent")]
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]
	[Event(name="unload", type="flash.events.Event")]
	
	//--------------------------------------
	//  Styles copied from SWFLoader
	//--------------------------------------
	[Style(name="brokenImageBorderSkin", type="Class", inherit="no")]
	[Style(name="brokenImageSkin", type="Class", inherit="no")]
	[Style(name="horizontalAlign", type="String", enumeration="left,center,right", inherit="no")]
	[Style(name="verticalAlign", type="String", enumeration="bottom,middle,top", inherit="no")]
	
	public class FloatingImage extends UIComponent
	{
		private var _aedAncestors:Array = [];
		private var _img:ImagePlus = new ImagePlus();
		private var _fOnStage:Boolean = false;
 		private var _acw:Array = [];

		private static const kastrImageEvents:Array = ["complete", "httpStatus", "init", "ioError", "open", "progress", "securityError", "unload"]
 		
		public function FloatingImage()
		{
			super();
			_img.autoStartStopSwf = true;
			_img.addEventListener(Event.COMPLETE, OnResize);
			
			addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
			
			for each (var strEvent:String in kastrImageEvents)
				_img.addEventListener(strEvent, ForwardEvent, false, 0, true);
		}
		
		private function ForwardEvent(evt:Event): void {
			dispatchEvent(evt);
		}
		
		public override function setStyle(styleProp:String, newValue:*):void {
			super.setStyle(styleProp, newValue);
			_img.setStyle(styleProp, newValue);
		}
		
		private function OnResize(evt:Event=null): void {
			// Position the image
			if (_img.parent != null && this.parent != null) {
				var ptLoc:Point = this.localToGlobal(new Point(0,0));
				ptLoc = _img.parent.globalToLocal(ptLoc);
				_img.x = ptLoc.x;
				_img.y = ptLoc.y;
			}
			_img.width = this.width;
			_img.height = this.height;
		}
		
		private function ListenForPosChange(aedContainers:Array): void {
			for each (var ed:IEventDispatcher in aedContainers) {
				if (ed) {
					ed.addEventListener(ResizeEvent.RESIZE, OnResize);
					ed.addEventListener(MoveEvent.MOVE, OnResize);
					ed.addEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);
					ed.addEventListener("alphaChanged", UpdateAlpha);
					ed.addEventListener("silentVisibleChange", UpdateVisible);
					if (!(ed is Stage))_acw.push(ChangeWatcher.watch(ed, "visible", UpdateVisible));
				}
			}
 		}
 		
 		private function OnRemovedFromStage(evt:Event): void {
 			onStage = false;
 		}
 		
		private function UnListenForPosChange(aedContainers:Array): void {
			for each (var ed:IEventDispatcher in aedContainers) {
				if (ed) {
					ed.removeEventListener(ResizeEvent.RESIZE, OnResize);
					ed.removeEventListener(MoveEvent.MOVE, OnResize);
					ed.removeEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);
					ed.removeEventListener("alphaChanged", UpdateAlpha);
					ed.removeEventListener("silentVisibleChange", UpdateVisible);
				}
			}
			
			while (_acw.length > 0) {
				var cw:ChangeWatcher = _acw.pop();
				cw.unwatch();
			}
 		}
		
 		private function UpdateAlpha(evt:Event=null): void {
 			var dob:DisplayObject = this;
 			var nAlpha:Number = 1;
 			while (dob != null) {
 				nAlpha *= dob.alpha;
 				dob = dob.parent;
 			}
 			_img.alpha = nAlpha;
 		}
 		
 		public function set onStage(f:Boolean): void {
 			if (_fOnStage == f) return;
 			_fOnStage = f;
 			if (_fOnStage) {
 				PopUpManager.addPopUp(_img, Application.application as Container);
 			} else {
 				PopUpManager.removePopUp(_img);
 			}
 			UpdateVisible();
 		}
 		
 		private function UpdateVisible(evt:Event=null): void {
 			var fVisible:Boolean = _fOnStage;
 			var dob:DisplayObject = this;
 			while (dob != null) {
 				if (!dob.visible) {
 					fVisible = false;
 					break;
 				}
 				dob = dob.parent;
	 		}
 			_img.visible = fVisible;
 		}
 		
 		public function set source(ob:Object): void {
 			_img.source = ob;
 			OnResize();
			UpdateVisible();
			UpdateAlpha();
 		}
 		
 		private function set ancestors(aed:Array): void {
			UnListenForPosChange(_aedAncestors);
			_aedAncestors = aed;
			ListenForPosChange(_aedAncestors);
			OnResize();
			UpdateVisible();
			UpdateAlpha();
 		}
 		
		private function OnAddedToStage(evt:Event): void {
			onStage = true;
			var aedAncestors:Array = [];
 			var dob:DisplayObject = this;
 			while (dob != null) {
 				if (dob is IEventDispatcher) {
 					aedAncestors.push(dob);
 				}
 				dob = dob.parent;
 			}
 			ancestors = aedAncestors;
		}
	}
}