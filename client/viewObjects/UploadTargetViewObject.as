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
package viewObjects {
	import bridges.mycomputer.UploadInterface;
	
	import imagine.documentObjects.DocumentStatus;
	import imagine.documentObjects.IDocumentObject;
	import imagine.documentObjects.Target;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.setTimeout;
	
	import mx.core.Application;
	import mx.core.IFlexDisplayObject;
	import mx.resources.ResourceBundle;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;

	public class UploadTargetViewObject extends TargetViewObject {
		[ResourceBundle("UploadTargetViewObject")] private var _rb:ResourceBundle;
		[Embed(source="/assets/bitmaps/icon_uploadArrow_sml.png")]
		public static var s_clsUploadArrow:Class;

		private static const knNormalArrowAlpha:Number = 0.2;

		private static var s_bmdNormalArrow:BitmapData;
		
		private var _tf:TextField;
		private var _spr:Sprite;
		private var _bm:Bitmap;
		private var _fShowUploadButton:Boolean = false;
		
		public function UploadTargetViewObject(imgv:ImageView, dob:DisplayObject) {
			super(imgv, dob);
			dragDropEnabled = false;
		}
		
		// Default style setter sets blendmode, line thickness, dash spacing
		override protected function set style(strStyle:String): void {
			_strStyle = strStyle;
		}
		
		private function get showUploadButton(): Boolean {
			return _fShowUploadButton;
		}
		
		private function set showUploadButton(f:Boolean): void {
			if (_fShowUploadButton == f)
				return;
			
			_fShowUploadButton = f;
			InvalidateDisplayList();
			UpdateDisplayList();
		}
		
		private function get normalArrowBitmapData(): BitmapData {
			if (s_bmdNormalArrow == null) {
				var bm:Bitmap = new s_clsUploadArrow();
				var bmdSource:BitmapData = bm.bitmapData;
				s_bmdNormalArrow = bmdSource.clone();
			}
			return s_bmdNormalArrow;
		}
		
		override protected function DrawController(gr:Graphics, rcl:Rectangle, co:Number, nThickness:Number, nAlpha:Number): void {
			const kcxGap:int = 3;
			const kcxMargin:int = 2;
			const kcxButton:int = 80;
			const kcyButton:int = 26;
			
			if (IDocumentObject(target).status == DocumentStatus.Error) {
				super.DrawController(gr, rcl, co, nThickness, nAlpha);
				return;
			}

			if (_spr == null) {
				_spr = new Sprite();
				addChild(_spr);

				// Hey, it's easy to reuse, e.g. button, styles for non-UIComponent purposes.
				var cssd:CSSStyleDeclaration = StyleManager.getStyleDeclaration(".BigButton");
				var cls:Class = cssd.getStyle("upSkin");
				var fdob:IFlexDisplayObject = new cls() as IFlexDisplayObject;
				fdob.setActualSize(kcxButton, kcyButton);
				// Skin's origin is at its upper-left.
				fdob.move(-kcxButton / 2, -kcyButton / 2);
				_spr.addChild(fdob as DisplayObject);
				/* TODO(darrinm): need this?
				// If the skin is programmatic, and we've already been
				// initialized, update it now to avoid flicker.
				if (newSkin is IInvalidating && initialized) {
					IInvalidating(newSkin).validateNow();
				}
				else if (newSkin is IProgrammaticSkin && initialized) {
					IProgrammaticSkin(newSkin).validateDisplayList()
				}
				*/
				_spr.addEventListener(MouseEvent.CLICK, OnMouseClick);

				_tf = new TextField();
				_tf.text = Resource.getString("UploadTargetViewObject", "upload");
				_tf.autoSize = TextFieldAutoSize.LEFT;
				_tf.selectable = false;
				_tf.antiAliasType = AntiAliasType.ADVANCED;
				_tf.embedFonts = true;
				_tf.setTextFormat(new TextFormat("trebuchetMS", 12, cssd.getStyle("color"), true, null, null, null, null, TextFormatAlign.CENTER));
				_spr.addChild(_tf);
				
				_bm = new Bitmap(normalArrowBitmapData);
				_spr.addChild(_bm);
				
				var rcTextBounds:Rectangle = _tf.getBounds(_tf);
				
				// Scale the text to fit the available space, if necessary.
				var cxAvailable:int = fdob.width - kcxGap - _bm.width - kcxMargin * 2;
				if (rcTextBounds.width > cxAvailable) {
					_tf.scaleX = _tf.scaleY = cxAvailable / rcTextBounds.width;
					rcTextBounds.width *= _tf.scaleX;
					rcTextBounds.height *= _tf.scaleY;
				}
				var cxArrowGapText:int = _bm.width + kcxGap + rcTextBounds.width;
				// Bitmap's origin is at its upper-left.
				_bm.x = -cxArrowGapText / 2;
				_bm.y = -_bm.height / 2;
				// Text's origin is at its upper-left.
				_tf.x = _bm.x + _bm.width + kcxGap;
				_tf.y = -rcTextBounds.height / 2;
			}
			
			if (targetPopulated && !showUploadButton) {
				_spr.visible = false;
			} else {
				// Shrink the upload image+text if needed to fit the target.
				_spr.scaleX = 1;
				_spr.scaleY = 1;
				var nScale:Number = Math.min(rcl.width * .80 / _spr.width, rcl.height * .80 / _spr.height);
				if (nScale < 1.0) {
					_spr.scaleX = nScale;
					_spr.scaleY = nScale;
				}
				_spr.visible = true;
				_spr.y = rcl.bottom - _spr.height;
			}
		}
		
		private function OnMouseClick(evt:MouseEvent): void {
			var upi:UploadInterface = new UploadTargetViewObjectUploadInterface(PicnikBase.app, target as Target, _imgv);
			upi.SingleFileUpload(null);
			
			// HACK: Delay hiding the upload button to prevent ugly visual where move cursor
			// and the upload button are shown at the same time.
			setTimeout(function (): void { showUploadButton = false }, 50);
		}

		// NOTE: Keep in mind that MOUSE_OVER/OUT events are sent when transitioning over
		// child DisplayObjects as well as parent/siblings. These can be disambiguated by
		// examining the Event's target property.
		override protected function OnMouseOver(evt:MouseEvent): void {
			super.OnMouseOver(evt);
			if (!evt.buttonDown && (target as Target).status != DocumentStatus.Loading)
				showUploadButton = true;
		}
		
		override protected function OnMouseOut(evt:MouseEvent): void {
			super.OnMouseOut(evt);
			showUploadButton = false;
		}
		
		// This is only called when the target is populated.
		override protected function OnMouseDown(evt:MouseEvent): void {
			super.OnMouseDown(evt);
			showUploadButton = false;
		}
		
		// This is only called when the target is populated AND the mouse went down on it.
		override protected function OnMouseUp(evt:MouseEvent): void {
			super.OnMouseUp(evt);
			
			// Restore the upload button if the mouse is still over the target.
			if (hitTestPoint(evt.localX, evt.localX, true))
				showUploadButton = true;
		}
	}
}
