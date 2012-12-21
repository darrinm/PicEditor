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
	import containers.ResizingDialog;
	
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	
	import mx.events.ResizeEvent;
	import mx.events.FlexEvent;
	import mx.controls.RadioButton;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	import mx.controls.Button;
	import flash.events.MouseEvent;
	
	public class GalleryPrivacyBase extends CloudyResizingDialog
	{
		[Bindable] public var _gald:GalleryDocument = null;
		[Bindable] public var _rbtnPublic:RadioButton;
		[Bindable] public var _btnDone:Button;
		
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			super.Constructor(fnComplete, uicParent, obParams);
			_gald = obParams['gald'];
		}
		
		public function GalleryPrivacyBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		private function OnCreationComplete( evt:FlexEvent ): void {
			_btnDone.addEventListener(MouseEvent.CLICK, OnDoneClick);
		}
		
		private function OnDoneClick(evt:MouseEvent):void {
			// note that the implementation of isPublic suppresses undo transactions
			_gald.isPublic = _rbtnPublic.selected;
			Hide();			
		}
	}
}
