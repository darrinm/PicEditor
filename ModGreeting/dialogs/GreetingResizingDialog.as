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
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.core.UIComponent;
	import mx.events.MoveEvent;
	import mx.events.ResizeEvent;

	public class GreetingResizingDialog extends ResizingDialog
	{
		private var _ldrClouds:Loader = null;
		private var _nFooterHeight:Number = 50;		
		
		public function GreetingResizingDialog()
		{
			super();
			addEventListener(ResizeEvent.RESIZE, OnResize);
			addEventListener(MoveEvent.MOVE, OnResize);
			ChangeWatcher.watch(this, "parentHeight", OnResize);			
			InitFilters();
			Redraw();
			clipContent = true;
		}

		override protected function OnHide(): void {
			PicnikBase.app.modalPopup = false;
			super.OnHide();
		}
		
		override protected function OnShow(): void {
			PicnikBase.app.modalPopup = true;
			super.OnShow();
		}	
		
		protected function OnResize(evt:Event): void {
			Redraw();
		}
		
		[Bindable] public function set footerHeight(n:Number): void {
			_nFooterHeight = n;
			Redraw();
		}
		
		public function get footerHeight(): Number {
			return _nFooterHeight;
		}
		
		protected override function createChildren():void {
			super.createChildren();
			
			var ldr:Loader = new Loader();
			ldr.load(new URLRequest(PicnikBase.StaticUrl("../graphics/clouds.jpg")));
			
			var fnError:Function = function(evt:Event): void {
				trace("cloud load error: " + evt);
			}
			
			var fnComplete:Function = function(evt:Event): void {
				ldr.width = 983;
				ldr.height = Math.min(177, height-footerHeight );
				ldr.blendMode = BlendMode.LIGHTEN;
				rawChildren.addChildAt(ldr, 0);
				_ldrClouds = ldr;
				ResetCloudMask();
			}
			
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, fnComplete);
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, fnError);
			ldr.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnError);
		}
		
		private function ResetCloudMask(): void {
			if (width == 0 || height == 0) return;
			if (!_ldrClouds) return;
			var sprMask:Sprite = _ldrClouds.mask as Sprite;
			if (sprMask == null) {
				sprMask = new Sprite();
				_ldrClouds.mask = sprMask;
				rawChildren.addChildAt(sprMask, 0);
			}
			sprMask.graphics.clear();
			sprMask.graphics.beginFill(0,1);
			sprMask.graphics.drawRoundRect(0, 0, width, height, 16, 16);
			sprMask.graphics.endFill();
		}
		
		private static const knCornerRadious:Number = 8;
		
		private static const kaclrTopGradient:Array = [0xd0e9fc, 0xffffff];
		private static const kaclrFooterGradient:Array = [0x256f94, 0x267399, 0x1a4d67];
		//private static const kaclrFooterGradient:Array = [0xff0000, 0x00ff00, 0x0000ff];
		private static const kanFooterGradientRatios:Array = [0,64,255];
		
		private function DefaultAlphas(kaclr:Array): Array {
			var an:Array = [];
			for (var i:Number = 0; i < kaclr.length; i++)
				an.push(1);
			return an;
		}
		
		private function DefaultRatios(kaclr:Array): Array {
			var an:Array = [];
			// First is 0, last is 255, spread evenly between the rest
			for (var i:Number = 0; i < kaclr.length; i++)
				an.push(255 * i/(kaclr.length-1));
			return an;
		}
		
		private function InitFilters(): void {
			var fltInnerGlow:DropShadowFilter = new DropShadowFilter(1, 90, 0xffffff, 1, 1, 1, 1, 3, true);
			var fltShadow:DropShadowFilter = new DropShadowFilter(9, 90, 0, 1, 65, 65, 1, 3);
			var fltGlow:GlowFilter = new GlowFilter(0, 0.15, 8, 8, 1, 3);
			
			filters = [fltInnerGlow, fltShadow, fltGlow];
		}
		
		private function Redraw(): void {
			if (width == 0 || height == 0) return;
			graphics.clear();
			
			var mat:Matrix;

			// Draw the top half
			mat = new Matrix();
			mat.createGradientBox(width, height-footerHeight, Math.PI/2);
			graphics.beginGradientFill(GradientType.LINEAR, kaclrTopGradient, DefaultAlphas(kaclrTopGradient), DefaultRatios(kaclrTopGradient), mat);
			graphics.drawRoundRectComplex(0, 0, width, height - footerHeight, knCornerRadious, knCornerRadious, 0, 0);
			graphics.endFill();
			
			// Draw the footer
			mat = new Matrix();
			mat.createGradientBox(width, footerHeight, Math.PI/2, 0, height-footerHeight);
			graphics.beginGradientFill(GradientType.LINEAR, kaclrFooterGradient, DefaultAlphas(kaclrFooterGradient), kanFooterGradientRatios, mat);
			graphics.drawRoundRectComplex(0, height - footerHeight, width, footerHeight, 0, 0, knCornerRadious, knCornerRadious);
			graphics.endFill();
		}
	}
}
