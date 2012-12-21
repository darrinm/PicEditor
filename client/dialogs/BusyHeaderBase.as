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
package dialogs
{
	import flash.events.Event;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.Canvas;
	import mx.controls.ProgressBar;
	import mx.core.UIComponent;
	import mx.effects.Effect;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	import util.AdManager;

	public class BusyHeaderBase extends Canvas implements IBusyDialog
	{
		private var _strMessage:String = "";
		private var _strDesiredState:String;
		private var _fFirstProgress:Boolean = true;
		private var _msStart:Number;
		private var _nTimerId:uint = 0;
		private var _fnComplete:Function = null;
		private var _cwParentWidth:ChangeWatcher = null;
		private var _cwParentHeight:ChangeWatcher = null;
		
		[Bindable] protected var progressComplete:Boolean = false;
		
		[Bindable] public var _pb:ProgressBar;
		[Bindable] protected var percentComplete:String = "";
		
		[Bindable] public var _efBefore:Effect;

		public function BusyHeaderBase()
		{
			super();
			PositionOnParent();
			addEventListener(FlexEvent.CREATION_COMPLETE, Init);
		}
		
		public function Constructor(uicParent:UIComponent, strStatus:String, strState:String, msShowDelay:Number, fnComplete:Function):void
		{
			PositionOnParent();
			_fnComplete = fnComplete;
			message = strStatus;
			// currentState = strState;
		}
		
		protected function LoadAd(): void {
			AdManager.GetInstance().LoadFullscreenAd();
		}
		
		protected function Init(evt:Event): void {
			AdManager.GetInstance().PrepareForFullScreenAd();
			_efBefore.play();
		}
		
		protected function ShowAd(): void {
			AdManager.GetInstance().ShowFullscreenAd();
		}
		
		public function Position(): void {
			PositionOnParent();
			if (_cwParentWidth) _cwParentWidth.unwatch();
			_cwParentWidth = ChangeWatcher.watch(PicnikBase.app, "width", PositionOnParent);
			if (_cwParentHeight) _cwParentHeight.unwatch();
			_cwParentHeight = ChangeWatcher.watch(PicnikBase.app, "height", PositionOnParent);
		}
		
		protected function PositionOnParent(evt:Event=null): void {
			width = PicnikBase.app.width;
			height = PicnikBase.app.height;
		}
				
		public function Hide():void
		{
			progressComplete = true;
		}
		
		protected function ReallyHide(): void {
			AdManager.GetInstance().HideFullscreenAd();
			this.visible = false;
			PopUpManager.removePopUp(this);
		}
		
		[Bindable]
		public function set progress(nPercent:Number):void
		{
			_pb.setProgress(nPercent, 100);
			percentComplete = Math.round(nPercent) + "%";
		}
		
		public function get progress():Number
		{
			return _pb.percentComplete;
		}
		
		[Bindable]
		public function set message(strMessage:String):void
		{
			_strMessage = strMessage;
		}
		
		public function get message():String
		{
			return _strMessage;
		}
		
		public function get isDone(): Boolean {
			return progressComplete;
		}
	}
}