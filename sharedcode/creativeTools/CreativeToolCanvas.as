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
package creativeTools {
	import controls.InspirationTipBase;
	
	import events.ActiveDocumentEvent;
	
	import flash.events.Event;
	
	import imagine.ImageDocument;
	
	import mx.containers.Canvas;
	import mx.events.FlexEvent;

	public class CreativeToolCanvas extends Canvas implements ICreativeTool, IActionListener {
		private var _fActive:Boolean = false;
		[Bindable] protected var _imgv:ImageView = null;
		[Bindable] protected var _imgd:ImageDocument;
		public var urlkit:String; // Used by urlkit
		
		public function CreativeToolCanvas() {
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
		}
		
		protected function OnInitialize(evt:Event): void {
		}
		
		//
		// ICreativeTool implementation
		//
		
		public function HelpStateChange(fVisible:Boolean): void {
		}
		
		public function get active(): Boolean {
			return _fActive;
		}
		
		public function OnActivate(ctrlPrev:ICreativeTool): void {
			InspirationTipBase.OnSubTabActivate();
			Debug.Assert(active == false);
			_imgv = PicnikBase.app.zoomView._imgv;
			_fActive = true;
			PicnikBase.app.addEventListener(ActiveDocumentEvent.CHANGE, OnActiveDocumentChange);
			OnActiveDocumentChange(new ActiveDocumentEvent(ActiveDocumentEvent.CHANGE, null, _imgv.imageDocument))
		}

		protected function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			_imgd = evt.docNew as ImageDocument;
		}
		
		public function OnDeactivate(ctrlNext:ICreativeTool): void {
			PicnikBase.app.removeEventListener(ActiveDocumentEvent.CHANGE, OnActiveDocumentChange);
			OnActiveDocumentChange(new ActiveDocumentEvent(ActiveDocumentEvent.CHANGE, _imgd, null))
			Debug.Assert(active == true);
			_fActive = false;
			_imgv = null;
		}
		
		public function Deselect(): Boolean {
			return false; // Nothing to deselect
		}
		
		public function PerformActionIfSafe(act:IAction): void {
			act.Do();
		}
		
		public function PerformAction(act:IAction): void {
			act.Do();
		}
		
		protected function get imgd(): ImageDocument {
			return _imgd;
		}
	}
}
