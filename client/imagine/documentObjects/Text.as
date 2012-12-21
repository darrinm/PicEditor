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

package imagine.documentObjects {
	import com.adobe.serialization.json.JSON;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.PixelSnapping;
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
	import flash.utils.ByteArray;
	
	import mx.core.Application;
	import mx.events.PropertyChangeEvent;
	import mx.utils.ArrayUtil;
	import mx.utils.ObjectUtil;
	
	import util.FontResource;
	import util.PicnikFont;
	import util.RectUtil;
	import util.VBitmapData;
	
	[Bindable] // App public members and getter/setters are bindable and will fire property changed events
	[RemoteClass]
	public class Text extends DocumentObjectBase {
		private var _fnt:PicnikFont = null;
		private var _nFontSize:Number = 100;
		private var _fUnderline:Boolean = false;
		private var _nLeading:Number = 0;
		private var _strText:String = "";
		private var _strAlign:String = TextFormatAlign.LEFT;
		private var _tf:TextField = null;
		private var _fWordWrap:Boolean = false;
		private var _strSizingLogic:String = TextSizingLogic.DYNAMIC_BOX;
		
		// DWM: Adobe's documentation says is "in pixels" but what would that mean really? I think it is points.
		private const knStandardFontSize:Number = 40;
		
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
			return _strSizingLogic == TextSizingLogic.DYNAMIC_BOX;
		}
		
		// NOTE: autoSize is deprecated and effectively ignored.
		override public function get serializableProperties(): Array {
			return super.serializableProperties.concat([ "text", "font", "fontSize", "textColor", "underline",
					"textAlign", "leading", "autoSize", "wordWrap", "sizingLogic", "unscaledWidth", "unscaledHeight" ]);
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
			switch (_strSizingLogic) {
			// Setting the fontSize will result in the recomputation of _rcBounds
			case TextSizingLogic.DYNAMIC_BOX:
				fontSize = (rc.height / Math.abs(_nScaleY)) / GetLineCount();
				break;
			
			case TextSizingLogic.FIXED_BOX_DYNAMIC_FONT:
				super.localRect = rc;
				break;
			
			// Change unscaled* instead of scale*. This is how we treat manual resizing
			// of the Text differently from the automatic resizing which alters scale*.
			// See the word-wrapp comment in UpdateTransform for details.
			case TextSizingLogic.FIXED_BOX_FIXED_FONT:
				unscaledWidth = rc.width / scaleX;
				unscaledHeight = rc.height / scaleY;
				break;
			}
		}
		
		//
		//
		//
		
		public function Text() {
			super();
			status = DocumentStatus.Loading; // Wait for the font to load
			content = _tf = new TextField();
			_tf.autoSize = TextFieldAutoSize.LEFT;
			_tf.embedFonts = true;
			_tf.selectable = true;
			_tf.alwaysShowSelection = true;
			_tf.multiline = true;
			_tf.wordWrap = _fWordWrap;
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
			// - OS-specific behaviors
			_tf.antiAliasType = AntiAliasType.NORMAL;
//			_tf.gridFitType = GridFitType.SUBPIXEL; // Only applies when antiAliasType is ADVANCED
			alpha = 1.0;
//			filters = [ new DropShadowFilter(4.0, 45.0, 0.0, 0.5),
//					new BevelFilter() ];
			textColor = 0xffffff; // default to white
			font = PicnikFont.Default();
			_tf.text = " ";
			name = Util.GetUniqueId();
		}
		
		// Deserialize is called after all child objects have been deserialized and must
		// initialize this instance's properties.
		public function Deserialize(xml:XML): void {
			// Implement the standard deserialization behavior.
			var ob:Object = Util.ObFromXmlProperties(xml);
			for (var strProp:String in ob)
				this[strProp] = ob[strProp];
			
			// Handle device fonts specially.
			if (!font.isDevice)
				return;
			
			// If this code is executing as part of the FlashRenderer it should substitute device text
			// snapshot bitmaps for the usual TextField content.
			if (Application.application.name == "FlashRenderer") {
				var obAsset:Object = document.GetEmbeddedAsset(name);
				if (obAsset) {
					UseContentSnapshot({ data: obAsset.data, metadata: obAsset.metadata });
					return;
				}
			}
			
			// Substitute the Universal font if the desired font isn't available.
			if (font.familyName != "_sans") {
				if (s_afnt == null)
					s_afnt = Font.enumerateFonts(true);
				for each (var fnt:Font in s_afnt) {
					if (fnt.fontName == font.familyName)
						return;
				}
				
				// This is expected to be a very rare case. Log it and see.
				Util.UrchinLogReport("/missingfont/" + font.familyName);
				font = PicnikFont.Universal();
			}
		}
		
		private static var s_afnt:Array;
		
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
			
			// This is a bit confusing but we flag device fonts with isEmbeded=true to
			// differentiate them from loaded fonts. But they AREN'T actually embedded
			// in the SWF, as Trebuchet is, so we handle that here.
			// _tf.embedFonts needs to be true for the embedded Trebuchet and all served fonts
			// (each is a standalone SWF containing an embedded font) but false for local
			// device fonts.
			_tf.embedFonts = !_fnt.isDevice;
			
			if (!_fnt.AddReference(this, OnFontLoaded)) {
				status = DocumentStatus.Loading;
			}
			// OnFontLoaded calls Invalidate
		}
		
		private var s_fFontLoadFailureReported:Boolean = false;
		
		private function OnFontLoaded(fr:FontResource): void {
			if (fr.state == FontResource.knLoaded) {
				status = DocumentStatus.Static;
			} else {
				status = DocumentStatus.Error;
				
				// Only report one font load failure per Picnik instance
				if (!s_fFontLoadFailureReported) {
					s_fFontLoadFailureReported = true;
					var strError:String = "Error loading font " + _fnt.familyName + ", " + fr.errorText;
					PicnikService.Log(strError, PicnikService.knLogSeverityWarning);
				}
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
			if (_tf.parent == null)
				return _tf.textWidth;
			
			// HACK: this is crazy but the TextField's textWidth varies depending on its parent's
			// transform.matrix (scale & rotation). [DWM: I think this is only the case when a
			// device font is being used]. So we remove the TextField from the display list
			// before using its textWidth and put it back afterwards.
			var dobOldContent:DisplayObject = content;
			SetContent(null, false);
			var cx:Number = _tf.textWidth;
			SetContent(dobOldContent, false);
			return cx;
		}
		
		public function get textHeight(): Number {
			if (_tf.parent == null)
				return _tf.textHeight;
			
			// HACK: this is crazy but the TextField's textHeight varies depending on its parent's
			// transform.matrix (scale & rotation). [DWM: I think this is only the case when a
			// device font is being used]. So we remove the TextField from the display list
			// before using its textHeight and put it back afterwards.
			var dobOldContent:DisplayObject = content;
			SetContent(null, false);
			var cy:Number = _tf.textHeight;
			SetContent(dobOldContent, false);
			return cy;
		}
		
		// We override these to make them bindable (send PropertyChangeEvents).
		// They must send PropertyChangeEvents so the ImageDocument can monitor them.
		
		public function get textColor(): uint {
			return _tf.textColor;
		}
		
		public function set textColor(co:uint): void {
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "color", _tf.textColor, co));
			_tf.textColor = co;
			Invalidate();
		}
		
		// DEPRECATED: As of 11/23/2010 the new sizingLogic property now determines the
		// value of autoSize. Nobody should be setting autoSize directly except possibly
		// some old admin-created documents.
		public function get autoSize(): String {
			return TextFieldAutoSize.LEFT;
		}
		
		public function set autoSize(tfas:String): void {
			if (tfas == TextFieldAutoSize.NONE)
				sizingLogic = TextSizingLogic.FIXED_BOX_DYNAMIC_FONT;
		}
		
		public function get wordWrap(): Boolean {
			return _fWordWrap;
		}
		
		public function set wordWrap(f:Boolean): void {
			_fWordWrap = f;
			_tf.wordWrap = f;
			Invalidate();
		}
		
		public function get sizingLogic(): String {
			return _strSizingLogic;
		}
		
		public function set sizingLogic(strSizingLogic:String): void {
			_strSizingLogic = strSizingLogic;
			_tf.autoSize = _strSizingLogic == TextSizingLogic.DYNAMIC_BOX ? TextFieldAutoSize.LEFT : TextFieldAutoSize.NONE;
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
			mat.rotate(Util.RadFromDeg(-rotation));
			var ptl:Point = mat.transformPoint(ptp);
			
			// Do a bounding box test
			var fHit:Boolean = _rcBounds.containsPoint(ptl);
			if (!fPixelTest || !fHit)
				return fHit;
			
			// It's up to us to check the pixels. Draw the TextField into a single-pixel BitmapData,
			// offset so the point we want to test ends up being drawn as the single pixel.
			// Hopefully Flash's rendering optimizes clipped drawing well and this is fast.
			var bmd:BitmapData = new VBitmapData(1, 1, true, 0x000000ff, "text field hit test temp");
			
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
			
			bmd.draw(_tf, mat);
			
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
			
			var tfmt:TextFormat = new TextFormat(strFont, knStandardFontSize, null, fBold, fItalic, _fUnderline,
					null, null, _strAlign, null, null, null, _nLeading);
			tfmt.kerning = true; // BUGBUG: no apparent effect!
			_tf.defaultTextFormat = tfmt;
			_tf.setTextFormat(tfmt);
			
			// Clear out any previous scaling (which can influence device font textHeight!)
			_tf.transform.matrix = new Matrix();
			_tf.autoSize = autoSize;
			
			var cx:Number, cy:Number;
			if (_strSizingLogic == TextSizingLogic.DYNAMIC_BOX) {
				// If the TextSizingLogic is DYNAMIC_BOX the Text DocumentObject's bounds are
				// defined by its (text-derived) width and height, centered around its origin.
				var cLines:Number = GetLineCount();
				var nScale:Number = _nFontSize / (textHeight / cLines);
				cx = Math.abs(textWidth * nScale * _nScaleX);
				cy = Math.abs(textHeight * nScale * _nScaleY);
			} else {
				// If the TextSizingLogic != DYNAMIC_BOX the Text DocumentObject's bounds are
				// defined by its unscaledWidth and Height, centered around its origin
				cx = Math.abs(unscaledWidth * _nScaleX);
				cy = Math.abs(unscaledHeight * _nScaleY);
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
			var cx:Number = unscaledWidth * _nScaleX;
			var cy:Number = unscaledHeight * _nScaleY;
			
			// HACK: this is crazy but the TextField's textHeight varies depending on its parent's
			// transform.matrix (scale & rotation). [DWM: I think this is only the case when a
			// device font is being used]. So we remove the TextField from the display list
			// before using its textHeight and put it back afterwards.
			var dobOldContent:DisplayObject = content;
//			trace("textHeight before removal: " + _tf.textHeight + ", height: " + _tf.height);
			SetContent(null, false);
//			trace("textHeight after removal: " + _tf.textHeight + ", height: " + _tf.height);
			
			switch (_strSizingLogic) {
			case TextSizingLogic.FIXED_BOX_DYNAMIC_FONT:
				var cxText:Number = (textWidth + xOffset * 2);
				var cyText:Number = (textHeight + yOffset * 2);
				var nScaleX:Number = cx / cxText;
				var nScaleY:Number = cy / cyText;
				nScale = Math.min(nScaleX, nScaleY);
				cx = nScaleX > 1 || nScale != nScaleX ? cx / nScale : cxText;
				_tf.width = cx;
				cy = nScaleY > 1 || nScale != nScaleY ? cy / nScale : cyText;
				_tf.height = cy;
				nContentScaleX = nContentScaleY = nScale;
				dx = cx / 2;
				dy = cy / 2;
				break;
			
			// The desired behavior of FIXED_BOX_FIXED_FONT Text objects is to not
			// scale the font as the Text object's dimensions change. Its scaleX/Y
			// factors do still apply to the font, however, to support global resizes, etc.
			//
			// Controlled resizing of FIXED_BOX_FIXED_FONT text boxes is done by changing
			// unscaledWidth/Height. Note that unscaledWidth/Height aren't the actual
			// dimensions of anything. They're initialized to 100x100 and localRect changes
			// scale them to match the desired size/proportions.
			// TODO(darrinm): Text Properties font Size doesn't account for scaling [getting greedy?]
			case TextSizingLogic.FIXED_BOX_FIXED_FONT:
				nContentScaleX = _nFontSize / knStandardFontSize * _nScaleX;
				nContentScaleY = _nFontSize / knStandardFontSize * _nScaleY;
				cx = _tf.width = cx / nContentScaleX;
				cy = _tf.height = cy / nContentScaleY;
				dx = cx / 2;
				dy = cy / 2;
				break;
			
			case TextSizingLogic.DYNAMIC_BOX:
				nScale = (_nFontSize * GetLineCount()) / Math.round(textHeight);
				nContentScaleX = _nScaleX * nScale;
				nContentScaleY = _nScaleY * nScale;
				dx = (textWidth + xOffset * 2) / 2 + GetAlignPadding();
				dy = (textHeight + yOffset * 2) / 2;
				cx = _tf.width * nContentScaleX;
				cy = _tf.height * nContentScaleY;
				break;
			}

			UpdateTextFieldTransform(nContentScaleX, nContentScaleY, dx, dy);
			
			// Restore the content to the display list (see HACK above).
			SetContent(dobOldContent, false);
			
			// Device fonts can't be rotated, distorted, or flipped so when asked to do so
			// we draw the text into a bitmap and rotate/distort/flip that.
			// TODO(darrinm): Flash 10 has a new text engine that supposedly can rotate, etc.
			// Consider switching to it when we drop FP9 support (maintaining both text solutions
			// would be a pain).
			UpdateCachedBitmap(nContentScaleX, nContentScaleY, Math.abs(cx), Math.abs(cy));
		}

		// TODO(darrinm): but this is still screwed up. Device text is bigger than the box calced for it
		// and it overflows or is clipped.
		private function UpdateTextFieldTransform(nContentScaleX:Number, nContentScaleY:Number, dx:Number, dy:Number): void {
			// Flash screws up the textHeight calculation for vertically flipped (negative scaleY) TextFields.
			// Get the textHeight THEN flip it.
			var mat:Matrix = new Matrix();
			mat.translate(-dx, -dy);
			mat.scale(nContentScaleX, Math.abs(nContentScaleY));
			_tf.transform.matrix = mat;
			var cyText:Number = _tf.textHeight;
			var cxText:Number = _tf.textWidth;
			
			// OK, apply the flip (if any).
			mat = new Matrix();
			mat.translate(-dx, -dy);
			mat.scale(nContentScaleX, nContentScaleY);
			_tf.transform.matrix = mat;
			
			// Flash has issues autoSizing device fonts. It can calculate a height too small for
			// the size of the font! Here we take control and add an empirically determined
			// amount to height. Note that we must leave autoSize off until drawing happens
			// but re-enable it before doing further text formatting and transforming (see
			// UpdateTextFormat).
			_tf.autoSize = TextFieldAutoSize.NONE;
			_tf.height = cyText + 5; // +4 for border +1 for precision-randomness? Just a guess.
			_tf.width = cxText + 5;
		}
		
		// Remember the parameters that produced the cached bitmap.
		private var _obCachedParams:Object = null;
		
		// Flash won't draw device fonts rotated. Create a bitmap snapshot of the text,
		// cropped to be no bigger than necessary (i.e. on-screen), and display that
		// instead of the TextField.
		private function UpdateCachedBitmap(nContentScaleX:Number, nContentScaleY:Number, cx:Number, cy:Number): void {
			var dobOld:DisplayObject = content;

			if (_bmSnapshot) {
				if (content != _bmSnapshot)
					SetContent(_bmSnapshot, false);
				return;
			}
			
			// Display the TextField when possible.
			if (!font.isDevice || (rotation == 0 && nContentScaleX == nContentScaleY && nContentScaleX >= 0 && nContentScaleY >= 0)) {
				if (dobOld != _tf) {
					SetContent(_tf, false);
					(dobOld as Bitmap).bitmapData.dispose();
				}
				_obCachedParams = null;
				return;
			}
			
			// Have any of the properties the cache depends on changed?
			// TODO(darrinm): Too fragile. People will add new properties and not think to add
			// them to this list.
			// Could add a second list of non-invaliding properties then assert that all
			// serializeableproperties are on one list or the other.
			// NOTE: A few properties do not invalidate the cached bitmap: x, y, alpha, rotation, name, blendmode
			var obParams:Array = [ nContentScaleX, nContentScaleY, color, text, font, fontSize, textColor,
					underline, textAlign, leading, autoSize, wordWrap, sizingLogic, unscaledWidth, unscaledHeight,
					scaleX, scaleY, color, maskId, visible ];
			
			if (_obCachedParams) {
				var fCacheInvalid:Boolean = false;
				for (var i:int = 0; i < obParams.length; i++) {
					if (obParams[i] != _obCachedParams[i]) {
						fCacheInvalid = true;
						break;
					}
				}
				if (!fCacheInvalid)
					return;
			}
//			if (_obCachedParams)
//				trace("cache invalidated by param " + i + ": " + obParams[i] + " != " + _obCachedParams[i]);
			_obCachedParams = obParams;

			// Remove the TextField (or Bitmap) from the DisplayList so its parent's transform doesn't
			// influence drawing below.
			SetContent(null, false);
			if (dobOld is Bitmap)
				(dobOld as Bitmap).bitmapData.dispose();

			var mat:Matrix = new Matrix();
			mat.scale(Math.abs(nContentScaleX), Math.abs(nContentScaleY));
			
			// Make sure we don't ask for a bitmap larger than Flash can deal with.
			var nScale:Number = 1;
			if (cx > 2800 || cy > 2800) {
				nScale = Math.min(2800 / cx, 2800 / cy);
				mat.scale(nScale, nScale);
				cx = Math.ceil(cx * nScale);
				cy = Math.ceil(cy * nScale);
			}
			
			var bmd:BitmapData = new VBitmapData(cx, cy, true, 0);
			bmd.draw(_tf, mat);
			
			// Use PixelSnapping.ALWAYS so flipped text stays nice and crisp.
			var bm:Bitmap = new Bitmap(bmd, PixelSnapping.ALWAYS, true);
			
			bm.scaleX /= nScale;
			bm.scaleY /= nScale;
			
			if (nContentScaleX < 0) {
				bm.scaleX *= -1;
				bm.x = Math.round(bm.width / 2);
			} else {
				bm.x = -Math.round(bm.width / 2);
			}
			if (nContentScaleY < 0) {
				bm.scaleY *= -1;
				bm.y = Math.round(bm.height / 2);
			} else {
				bm.y = -Math.round(bm.height / 2);
			}
			
			SetContent(bm, false);
		}
		
		// TextFieldType.INPUT fields have a 2 pixel gutter on all sides plus if
		// TextFieldAutoSize != NONE they have 10 pixels added to the left and/or right
		// distributed according to alignment type. TextFormatAlign.LEFT puts all the
		// extra padding to the right, RIGHT puts it to the left, and CENTER puts half
		// on the left and half on the right.
		// NOTE: TextField.wordWrap == true also eliminates the extra 10 pixels.
		private function GetAlignPadding(): Number {
			if (_tf.autoSize == TextFieldAutoSize.NONE || _tf.type == TextFieldType.DYNAMIC)
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
		
		// Take a document-space bitmap snapshot of the text to be embedded in the document
		// and used by the server for rendering. This is how we capture device font text.
		// Returns: { id:String, data:ByteArray, metadata:String }
		public function GetContentSnapshot(): Object {
			// Get the bounding rect of the object in document coords. The bounding rect
			// fully encloses scaled/rotated objects.
			var rcBounds:Rectangle = getBounds(document.documentObjects);
			rcBounds = RectUtil.Integerize(rcBounds);

			// The snapshot's origin, in document coords.
			var ptG:Point = localToGlobal(new Point(0, 0));

			// Clip to the document's bounds.
			// NOTE: Use background instead of composite to avoid throwing a ValidateComposite into the mix.
			rcBounds = rcBounds.intersection(new Rectangle(0, 0, document.background.width, document.background.height));
			if (rcBounds.isEmpty())
				return null;
			
			var bmdSnapshot:BitmapData = new VBitmapData(rcBounds.width, rcBounds.height, true, 0x00000000);
			
			// Derive a transform that will have the text drawn in document space, within the
			// document-clipped bounds.
			var mat:Matrix = GetConcatenatedMatrix(this);
			mat.tx = ptG.x - rcBounds.x;
			mat.ty = ptG.y - rcBounds.y;
			
			bmdSnapshot.draw(this, mat);

			// The snapshot will be drawn as a child of this DocumentObject but we want it to
			// be drawn at a specific document coord and orientation. Calc the inverse transform
			// that will make this happen.
			var matInverse:Matrix = transform.matrix.clone();
			matInverse.invert();
			var matRotate:Matrix = new Matrix();
			matRotate.rotate(Util.RadFromDeg(-rotation));
			
			/*
			// darrinm: this seems to be hitting a numerical precision limit that causes
			// increasing drift from the correct coordinates for rotated objects as they are
			// placed toward the bottom right of the document.
			// (Text object is transformed, its content counter-transformed)
			// Because of this we adjust the position of the DocumentObject instead of its content.
			var ptRotated:Point = matRotate.transformPoint(new Point(rcBounds.x, rcBounds.y));
			matInverse.translate(ptRotated.x, ptRotated.y);
			
			var ptT:Point = matInverse.transformPoint(new Point(0, 0));
			ptT = localToGlobal(ptT);
			trace("n top-left: " + ptT.x + ", " + ptT.y + ", diff: " + (rcBounds.x - ptT.x) + ", " + (rcBounds.y - ptT.y));
			*/

			// Package up the data and metadata.
			var baData:ByteArray = bmdSnapshot.getPixels(bmdSnapshot.rect);
			baData.compress();
			
			var obMetadata:Object = {
				width: bmdSnapshot.width, height: bmdSnapshot.height,
				a: matInverse.a, b: matInverse.b, c: matInverse.c, d: matInverse.d, tx: matInverse.tx, ty: matInverse.ty,
				x: rcBounds.x, y: rcBounds.y
			};
			bmdSnapshot.dispose();
			
			return { id: name, data: baData, metadata: JSON.encode(obMetadata) };
		}
		
		// DisplayObject.transform.concatenatedMatrix (and pixelBounds) doesn't work reliably
		// for objects that are not on the Stage's display list. So we concatenate ourselves.
		private function GetConcatenatedMatrix(dob:DisplayObject): Matrix {
			// Concatenate from top down because e.g. rotate + translate is not the same as translate + rotate.
			var amat:Array = [];
			while (dob) {
				amat.push(dob.transform.matrix);
				dob = dob.parent;
			}
			
			var mat:Matrix = new Matrix();
			for (var i:int = amat.length - 1; i >= 0; i--)
				mat.concat(amat[i]);
			return mat;
		}
		
		private var _bmSnapshot:Bitmap;
		private var _dxSnapshot:Number;
		private var _dySnapshot:Number;
		
		// The FlashRenderer will ask Text objects for which image data has been embedded
		// (e.g. Text objects using device fonts) to use the embedded image as their
		// rendered content. The FlashRenderer is the only use case for embedded text
		// images; clients disregard it and substitute the Universal font if they don't
		// have the desired font.
		//
		// The passed-in object's members are { data:ByteArray, metadata:String }.
		// metadata is a JSON encoded object containing the embedded image's dimensions
		// and an inverse transform to put it in document coords.
		// { width:Number, height:Number, a:Number, b:Number, c:Number, d:Number, tx:Number, ty:Number, x:Number, y:Number }
		public function UseContentSnapshot(ob:Object): void {
			var baData:ByteArray = ob.data;
			baData.uncompress();
			var obMetadata:Object = JSON.decode(ob.metadata);
			
			// Offset the Text object to so the snapshot will be drawn in the right place.
			// Ideally this would simply be incorporated into the content's transform but
			// doing so introduces enough of an error in precision that the snapshot can
			// be positioned off +/- 10 or more pixels when it is positioned in the lower-
			// right corner of a large image.
			x += obMetadata.x;
			y += obMetadata.y;
			_dxSnapshot = obMetadata.x;
			_dySnapshot = obMetadata.y;
			
			var rc:Rectangle = new Rectangle(0, 0, obMetadata.width, obMetadata.height);
			
			// Don't use VBitmapData because any testing of this will indicate a leak while in fact
			// our use case for content snapshots (rendering) is one-time.
			var bmd:BitmapData = new BitmapData(rc.width, rc.height, true);
			bmd.setPixels(rc, baData);
			var bm:Bitmap = new Bitmap(bmd);
			
			// Apply an inverse transform to the snapshot so even though it is nested
			// (for correct depth sorting) it will be drawn untransformed.
			bm.transform.matrix = new Matrix(obMetadata.a, obMetadata.b, obMetadata.c, obMetadata.d, obMetadata.tx, obMetadata.ty);
			
			_bmSnapshot = bm;
			SetContent(_bmSnapshot);
		}
		
		public function ClearContentSnapshot(): void {
			x -= _dxSnapshot;
			y -= _dySnapshot;
			_bmSnapshot = null;
			SetContent(_tf);
			_obCachedParams = null;
		}
	}
}
