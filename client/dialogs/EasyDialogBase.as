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
package dialogs {
	import containers.ResizingDialog;
	
	import flash.display.GradientType;
	import flash.events.TextEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	import mx.managers.PopUpManager;
	
	
	/**
 	 * This is a generic dialog which presents a piece of text and two buttons.
 	 * If you don't specify a label for the "OK" button, then it won't be shown,
 	 * making this a one-button dialog! Convenient!
   	 */
	public class EasyDialogBase extends ResizingDialog {		
		[Bindable] public var hasLinks:Boolean = false;
		
		private var _acstrLabels:ArrayCollection = null;
		
		private var _strLinkTarget:String = "_self";
		private var _strText:String;
		private var _strHeadline:String;
		private var _fAllowDefaultButton:Boolean;
		private var _nFooterHeight:Number = 46;		

		public static function Show(uicParent:UIComponent,
				aLabels:Array,
				strHeadline:String, strText:String,
				fnComplete:Function=null,
				fAllowDefaultButton:Boolean = false): EasyDialog {
			var dlg:EasyDialog = new EasyDialog();
			// PORT: use the cool varargs way to relay these params
			if (null == uicParent) {
				uicParent = PicnikBase.app;
			}
			
			dlg.Constructor(fnComplete, uicParent, {headline:strHeadline, text:strText, labels:new ArrayCollection(aLabels)});
			PopUpManager.addPopUp(dlg, uicParent, true);
			mx.managers.PopUpManager.centerPopUp(dlg);
			return dlg;
		}
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			super.Constructor(fnComplete, uicParent, obParams);
			headline = obParams['headline'];
			text = obParams['text'];
			buttonLabels = obParams['labels'];
			
			addEventListener(ResizeEvent.RESIZE, OnResize);
			InitFilters();
			Redraw();
			clipContent = true;
		}

		[Bindable]
		public function set footerHeight(n:Number): void {
			_nFooterHeight = n;
			Redraw();
		}
		
		public function get footerHeight(): Number {
			return _nFooterHeight;
		}
		
		
		[Bindable]
		public function get linkTarget():String {
			return _strLinkTarget;
		}
		
		public function set linkTarget( str:String ):void {
			_strLinkTarget = str;
		}
			
		[Bindable]
		public function get buttonLabels():ArrayCollection {
			return _acstrLabels;
		}
		
		public function set buttonLabels( acstrLabels:ArrayCollection ):void {
			_acstrLabels = acstrLabels;
		}

		[Bindable]
		public function get allowDefaultButton():Boolean {
			return _fAllowDefaultButton;
		}
		
		public function set allowDefaultButton( f:Boolean ):void {
			_fAllowDefaultButton = f;
		}
		
		[Bindable]
		public function get text():String {
			return _strText;
		}
		
		public function set text( strText:String ):void {
			_strText = strText;

			// Switch http links with event: links
			var pat:RegExp = /href=[\"\']([^\"]*)[\'\"]/gi;
			if (_strText.search(pat) >= 0) {
				_strText = _strText.replace(/href=[\'\"]([^\"]*)[\'\"]/gi, 'href="event:$1"');
				hasLinks = true;
			}
		}
		
		[Bindable]
		public function get headline():String {
			return _strHeadline;
		}
		
		public function set headline( strHeadline:String ):void {
			_strHeadline = strHeadline;
		}
		
		protected function OnLink(evt:TextEvent): void {
			PicnikBase.app.NavigateToURL(new URLRequest(evt.text), _strLinkTarget);
		}
		
		protected function buttonClick(id:int): void {
			Hide();
			if (_fnComplete != null)
				_fnComplete({ success: (id==0), button: id });
		}

		private static const knCornerRadius:Number = 8;
		private static const kaclrTopGradient:Array = [0xeeeeee, 0xffffff];
		private static const kaclrFooterGradient:Array = [0xdddddd, 0xeeeeee];
		private static const kanFooterGradientRatios:Array = [0,255];
		
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
			var fltShadow:DropShadowFilter = new DropShadowFilter(9, 90, 0, 0.6, 20, 20, 1, 3);
			var fltGlow:GlowFilter = new GlowFilter(0, 0.15, 8, 8, 1, 3);
			
			filters = [fltInnerGlow, fltShadow, fltGlow];
		}
		
		private function OnResize(evt:ResizeEvent): void {
			Redraw();
		}
		
		private function Redraw(): void {
			if (width == 0 || height == 0) return;
			graphics.clear();
			
			var mat:Matrix;

			// Draw the top half
			mat = new Matrix();
			mat.createGradientBox(width, height, Math.PI/2);
			graphics.beginGradientFill(GradientType.LINEAR, kaclrTopGradient, DefaultAlphas(kaclrTopGradient), DefaultRatios(kaclrTopGradient), mat);
			graphics.drawRoundRect(0, 0, width, height, 2* knCornerRadius, 2* knCornerRadius);
			graphics.endFill();
			
			// Draw the footer
			mat = new Matrix();
			mat.createGradientBox(width, footerHeight, Math.PI/2, 0, height-footerHeight);
			graphics.beginGradientFill(GradientType.LINEAR, kaclrFooterGradient, DefaultAlphas(kaclrFooterGradient), kanFooterGradientRatios, mat);
			graphics.drawRoundRectComplex(0, height - footerHeight, width, footerHeight, 0, 0, knCornerRadius, knCornerRadius);
			graphics.endFill();
		}

	}
}
