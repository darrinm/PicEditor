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
// UNDONE: dropshadow filter fails at size ~2645 for the string 'g'

package documentObjects {
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import mx.events.PropertyChangeEvent;
	
	import util.FontResource;
	import util.PicnikFont;
	import util.VBitmapData;
	
	[Bindable] // App public members and getter/setters are bindable and will fire property changed events
	public class Text extends DocumentObjectBase {
		private var _fnt:PicnikFont = null;
		private var _nFontSize:Number = 100;
		private var _fUnderline:Boolean = false;
		private var _nLeading:Number = 0;
		private var _strText:String = "";
		private var _strAlign:String = TextFormatAlign.LEFT;
		private var _tf:TextField = null;
		private var _tfas:String = TextFieldAutoSize.LEFT;
		
		//
		// IDocumentObject interface
		//

		override public function get typeName(): String {
			return "Type";
		}
		
		override public function get typeSubTab(): String {
			return "_ctType";
		}
		
		override public function get objectPaletteName(): String {
			return "Text";
		}
		
		// Return false to make default drag behavior not lock aspect ratio
		public function get hasFixedAspectRatio(): Boolean {
			return _tfas != TextFieldAutoSize.NONE;
		}
		
		override public function get serializableProperties(): Array {
			return super.serializableProperties.concat([ "text", "font", "fontSize", "textColor", "underline",
					"textAlign", "leading", "autoSize" ]);
		}
		
		protected function get ready(): Boolean {
			return status >= DocumentStatus.Loaded;
		}

		// This is for TextTool.mxml to bind to		
		public function GetParent(): DisplayObjectContainer {
			return parent;	
		}
		
		override public function Validate(): void {
			ValidateChildren();
			
			if (_ffInvalid) {
				_ffInvalid = 0;
				UpdateTextFormat();
			}
		}
		
		override public function set localRect(rc:Rectangle): void {
			if (_tfas == TextFieldAutoSize.NONE)
				super.localRect = rc;
			else if (ready)
				// Setting the fontSize will result in the recomputation of _rcBounds
				fontSize = (rc.height / Math.abs(_nScaleY)) / GetLineCount();
		}
		
		//
		//
		//
		
		public function Text() {
			super();
			status = DocumentStatus.Loading; // Wait for the font to load
			content = _tf = new TextField();
			_tf.autoSize = _tfas;
			_tf.embedFonts = true;
			_tf.selectable = true;
			_tf.alwaysShowSelection = true;
			_tf.multiline = true;
//			_tf.type = TextFieldType.INPUT;
			
			// Handy for debugging:
//			_tf.background = true;
//			_tf.backgroundColor = 0xffff00;

			// We use AntiAliasType.NORMAL because .ADVANCED has all sort of strange behaviors,
			// including but probably not limited to:
			// - color fringing
			// - partial transparancy regardless of alpha value!
			// - reverts to NORMAL for text >= 256 pixels in height
			// - reverts to NORMAL when rotated
			// - reverts to NORMAL when colored, alphaed, filtered, and for certain fonts
			// - reverts to NORMAL when ClearType is disabled at the system level			
			_tf.gridFitType = GridFitType.SUBPIXEL;
			_tf.antiAliasType = AntiAliasType.NORMAL;
			alpha = 1.0;
//			filters = [ new DropShadowFilter(4.0, 45.0, 0.0, 0.5),
//					new BevelFilter() ];
			textColor = 0xffffff; // default to white
			font = PicnikFont.Default();
			_tf.text = " ";
			name = Math.random().toString();
		}
		
		public function get font(): PicnikFont {
			return _fnt;
		}
		
		public function set font(fnt:PicnikFont): void {
			if (PicnikFont.Equals(_fnt, fnt))
				return;
			if (_fnt) {
				_fnt.RemoveReference(this);
			}
			_fnt = fnt;
			if (!_fnt.AddReference(this, OnFontLoaded)) {
				status = DocumentStatus.Loading;
			}
			// OnFontLoaded calls Invalidate
		}
		
		private function OnFontLoaded(fr:FontResource): void {
			if (fr.state == FontResource.knLoaded) {
				status = DocumentStatus.Static;
			} else {
				status = DocumentStatus.Error;
				var strError:String = "Error loading font " + _fnt.familyName + ", " + fr.errorText;
				trace(strError);
			}
			UpdateSuperText();
			Invalidate();
		}
		
		public function get fontSize(): Number {
			return _nFontSize;
		}
		
		public function set fontSize(nSize:Number): void {
			if (_nFontSize == nSize)
				return;
				
			_nFontSize = nSize;
			Invalidate();
		}
		
		public function get bold(): Boolean {
			return _fnt.isBold;
		}
		
		public function get italic(): Boolean {
			return _fnt.isItalic;
		}
		
		public function get underline(): Boolean {
			return _fUnderline;
		}
		
		public function set underline(fUnderline:Boolean): void {
			if (_fUnderline == fUnderline)
				return;
				
			_fUnderline = fUnderline;
			Invalidate();
		}
		
		public function get textAlign(): String {
			return _strAlign;
		}
		
		public function set textAlign(strAlign:String): void {
			if (_strAlign == strAlign)
				return;
				
			_strAlign = strAlign;
			Invalidate();
		}
				
		public function get leading(): Number {
			return _nLeading;
		}
		
		public function set leading(nLeading:Number): void {
			if (_nLeading == nLeading)
				return;
				
			_nLeading = nLeading;
			Invalidate();
		}
		
		public function get textWidth(): Number {
			return _tf.textWidth;
		}

		public function get textHeight(): Number {
			return _tf.textHeight;
		}
				
		// We override these to make them bindable (send PropertyChangeEvents).
		// They must send PropertyChangeEvents so the ImageDocument can monitor them.
		
		public function get textColor(): uint {
			return _tf.textColor;
		}
		
		public function set textColor(co:uint): void {
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "color", _tf.textColor, co));
			_tf.textColor = co;
		}
		
		public function get autoSize(): String {
			return _tfas;
		}
		
		public function set autoSize(tfas:String): void {
			if (_tfas == tfas)
				return;
				
			_tfas = tfas;
			_tf.autoSize = _tfas;
			Invalidate();
		}
		
		override public function get color(): uint {
			return textColor;
		}
		
		override public function set color(co:uint): void {
			textColor = co;
		}
		
		// _strText is the real text of the object. super.text is the displayed text which
		// differs when the text is empty and when characters are being used that the current
		// font can't display (we substitute question marks).
		public function get text(): String {
			return _strText;
		}
		
		public function set text(strText:String): void {
			_strText = strText;
			
			UpdateSuperText();
			Invalidate();
		}
		
		private function UpdateSuperText(): void {
 			// HACK: Always have at least one character so textHeight/Width will be non-zero
 			if (_strText == "") {
				_tf.text = " ";
				return;
			}

			var afnt:Array = Font.enumerateFonts(false);
			var strSuperText:String = "";
			for (var ich:int = 0; ich < _strText.length; ich++) {
				var ch:String = _strText.charAt(ich);
				// BST: Newlines (code 13) fail HasGlyphs() for flash compiled fonts (but they render correctly)
				if (ch.charCodeAt(0) == 13 || _fnt.HasGlyphs(ch))
					strSuperText += ch;
				else if (_fnt.HasGlyphs("?"))
					strSuperText += "?";
				else
					strSuperText += "x";
			}
						
			_tf.text = strSuperText;
		}
		
		// UNDONE: how to reuse this code for all DisplayObjects?
		// This code is copied in DocumentObjectBase
		// Flash TextFields can't do pixel-level hit testing but that's what need so we
		// do it ourselves. NOTE: x, y are in Stage-relative coordinates
		override public function hitTestPoint(x:Number, y:Number, fPixelTest:Boolean=false): Boolean {
			if (!ready) return false;
			Validate();
//			Debug.Assert(_ffInvalid == 0, "must be validated to hitTestPoint");
			
			// Don't use Flash's hitTestPoint to do the bounding box test because it uses
			// the transform.pixelBounds (or something like it) which is a stage axis aligned
			// bounding box (i.e. it screws up on rotated objects).
			//var fHit:Boolean = super.hitTestPoint(x, y, false);
			
			// Transform the stage coord into a local coord. Can't use this.globalToLocal because it
			// will take scaling into account.
			var ptp:Point = parent.globalToLocal(new Point(x, y));
			var mat:Matrix = new Matrix();
			mat.translate(-this.x, -this.y);
			mat.rotate(-rotation * Math.PI/180);
			var ptl:Point = mat.transformPoint(ptp);
			
			// Do a bounding box test
			var fHit:Boolean = _rcBounds.containsPoint(ptl);
			if (!fPixelTest || !fHit)
				return fHit;
			
			// It's up to us to check the pixels. Draw the TextField into a single-pixel BitmapData,
			// offset so the point we want to test ends up being drawn as the single pixel.
			// Hopefully Flash's rendering optimizes clipped drawing well and this is fast.
			var bmd:BitmapData = new VBitmapData(1, 1, true, 0x000000ff);
			
			// Get a translated/scaled/rotated point to match what bmd.draw() will do below
			ptl = _tf.globalToLocal(new Point(x, y));
			mat = new Matrix();
			mat.tx = -ptl.x;
			mat.ty = -ptl.y;
			
			// HACK: the AntiAliasType.NORMAL text rasterizer produces text slightly
			// shifted from where AntiAliasType.ADVANCED puts it. We compensate here.
			// Nevermind, we're going with the NORMAL font rasterizer for now
//			mat.tx += 1;
//			mat.ty -= 1;
			
			// Speed things up and eliminate undesired side effects by turning off filters
			// before drawing the TextField into the BitmapData
			var afltSav:Array = filters;
			filters = null; // clear out filters
			
			// Disregard transparency
			var nAlphaSav:Number = alpha;
			alpha = 1.0;
			
			// HACK: !!! why is this needed to make the text draw into the bitmap but
			// it isn't needed for text being drawn into the ImageDocument.composite?
			// Nevermind, we're going with the NORMAL font rasterizer for now
//			antiAliasType = AntiAliasType.NORMAL;
			
			bmd.draw(this._tf, mat);
			
			// Restore all the stuff we had to tweak to make the hit testing work
//			antiAliasType = AntiAliasType.ADVANCED;
			alpha = nAlphaSav;
			filters = afltSav;

			fHit = (bmd.getPixel32(0, 0) & 0xff000000) != 0; // Not transparent?
			/*			
			trace("getPixel(0, 0): " + bmd.getPixel32(0, 0).toString(16));
			var bm:Bitmap = new Bitmap(bmd.clone());
			Application.application.stage.addChild(bm);
			*/

			bmd.dispose();
			
			// UNDONE: hitArea compatibility (not used now, maybe we don't care)
			return fHit;
		}
		
		private function UpdateTextFormat(): void {
			if (!ready) return;
			Debug.Assert(_ffInvalid == 0, "must be validated to UpdateTextFormat");
			
			var fBold:Boolean = _fnt.isBold;
			var fItalic:Boolean = _fnt.isItalic;
			_tf.thickness = _fnt.thickness;
			var strFont:String = _fnt.familyName;
			
			var tfmt:TextFormat = new TextFormat(strFont, 40, null, fBold, fItalic, _fUnderline,
					null, null, _strAlign, null, null, null, _nLeading); // CONFIG: 40
			tfmt.kerning = true; // BUGBUG: no apparent effect!
			_tf.defaultTextFormat = tfmt;
			_tf.setTextFormat(tfmt);

			var cx:Number, cy:Number;
			if (_tfas == TextFieldAutoSize.NONE) {
				// The TextFieldAutoSize == NONE Text DocumentObject's bounds are defined by its
				// unscaledWidth and Height, centered around its origin
				cx = Math.abs(unscaledWidth * _nScaleX);
				cy = Math.abs(unscaledHeight * _nScaleY);
			} else {
				// The TextFieldAutoSize != NONE Text DocumentObject's bounds are defined by its
				// (text-derived) width and height, centered around its origin.
				var cLines:Number = GetLineCount();
				var nScale:Number = _nFontSize / (textHeight / cLines);
				cx = Math.abs(textWidth * nScale * _nScaleX);
				cy = Math.abs(textHeight * nScale * _nScaleY);
			}
			
			var rcBoundsNew:Rectangle = new Rectangle(-(cx / 2), -(cy / 2), cx, cy);
			if (!rcBoundsNew.equals(_rcBounds)) {
				var rcBoundsOld:Rectangle = _rcBounds.clone();
				_rcBounds = rcBoundsNew;
				dispatchEvent(PropertyChangeEvent.createUpdateEvent(
						this, "localRect", _rcBounds.clone(), rcBoundsNew.clone()));
			}
			// Changes to the text format are likely to change the overall text size
			// so it's time to update the center/scale/rotate transform.
			UpdateTransform();
		}
	
		// A primary task of UpdateTransform is to perform rotations around the center of the
		// object, rather than the top-left which is what TextField objects really want to do.	
		// UpdateTransform also scales the object to fit _rcBounds. We use scaling instead
		// of the TextField fontSize property to get the size we want because fontSizes top
		// out at 127.
		override protected function UpdateTransform(): void {
			if (!ready) return;
			
			var dx:Number, dy:Number, nScale:Number, nContentScaleX:Number, nContentScaleY:Number;
			if (_tfas == TextFieldAutoSize.NONE) {
				var cx:Number = unscaledWidth * _nScaleX;
				var cy:Number = unscaledHeight * _nScaleY;
				var cxText:Number = (textWidth + xOffset * 2);
				var cyText:Number = (textHeight + yOffset * 2);
				var nScaleX:Number = cx / cxText;
				var nScaleY:Number = cy / cyText;
				nScale = Math.min(nScaleX, nScaleY);
				cx = nScaleX > 1 || nScale != nScaleX ? cx / nScale : cxText;
				_tf.width = cx;
				cy = nScaleY > 1 || nScale != nScaleY ? cy / nScale : cyText;
				_tf.height = cy;
				dx = cx / 2;
				dy = cy / 2;
				nContentScaleX = nContentScaleY = nScale;
			} else {
				nScale = (_nFontSize * GetLineCount()) / textHeight;
				nContentScaleX = _nScaleX * nScale;
				nContentScaleY = _nScaleY * nScale;
				dx = (textWidth + xOffset * 2) / 2 + GetAlignPadding();
				dy = (textHeight + yOffset * 2) / 2;
			}
			
			var mat:Matrix = new Matrix();
			mat.translate(-dx, -dy);
			mat.scale(nContentScaleX, nContentScaleY);
			_tf.transform.matrix = mat;
		}
		
		// TextFieldType.INPUT fields have a 2 pixel gutter on all sides plus if
		// TextFieldAutoSize != NONE they have 10 pixels added to the left and/or right
		// distributed according to alignment type. TextFormatAlign.LEFT puts all the
		// extra padding to the right, RIGHT puts it to the left, and CENTER puts half
		// on the left and half on the right.
		// NOTE: TextField.wordWrap == true also eliminates the extra 10 pixels.
		private function GetAlignPadding(): Number {
			if (_tfas == TextFieldAutoSize.NONE)
				return 0;
				
			switch (_strAlign) {
			case TextFormatAlign.LEFT:
			default: // UNDONE: TextFormatAlign.JUSTIFY?
				return 0;
				
			case TextFormatAlign.RIGHT:
				return 10;
			
			case TextFormatAlign.CENTER:
				return 5;
			}
		}
		
		// This was put in when we were using TextFieldType.DYNAMIC which has a bizarre
		// mismatch between textHeight and numLines behavior. textHeight doesn't count
		// empty lines following carriage returns but numLines does. Our workaround
		// was to use _tf.getLineIndexOfChar(_tf.text.length - 1) + 1 to return a line
		// count that matched textHeight. TextFieldType.INPUT doesn't have this problem
		// so we can just return numLines now.
		private function GetLineCount(): Number {
			if (!ready) return 1;
			return _tf.numLines;
		}

		// TextField has a 2 pixel margin on each side
		protected function get xOffset(): Number {
			return 2;
		}

		protected function get yOffset(): Number {
			return 2;
		}
	}
}
