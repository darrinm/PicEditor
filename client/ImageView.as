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
// - local, aka component space, coordinates have no prefix or 'l', e.g. l = v(d)
// - content coordinates are offset from local coordinates and are suffixed with 'c', e.g. xc = xl - xlContentOffset)
// - stage coordinates are suffixed with 's', e.g. xs = this.localToGlobal(ptl).x
// - document coordinates are suffixed with 'd', e.g. xd = xv / nZoom, d = d(v(l))
// - view coordinates are suffixed with 'v', e.g. xv = xd * nZoom

package {
	import controllers.DocoController;
	import controllers.MoveSizeRotate;
	import controllers.StretchAndSqueeze;
	import controllers.TextMSR;
	
	import imagine.documentObjects.IDocumentObject;
	import imagine.documentObjects.Photo;
	import imagine.documentObjects.Text;
	
	import errors.InvalidBitmapError;
	
	import events.GenericDocumentEvent;
	import events.ImageDocumentEvent;
	import events.ImageViewEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.MovieClip;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import imagine.ImageDocument;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.resources.ResourceBundle;
	
	import imagine.objectOperations.*;
	
	import objectPalette.ObjectPalette;
	
	import overlays.helpers.Cursor;
	
	import util.LocUtil;
	import util.VBitmapData;
	
	import viewObjects.ViewObject;
	
	[Style(name="color", type="Number", format="Color", inherit="yes")]
	
	public class ImageView extends UIComponent {
		private var _imgd:ImageDocument;
		private var _xlViewOffset:Number = 0;
		private var _ylViewOffset:Number = 0;
		private var _fMouseDown:Boolean = false;
		private var _xlMouseDown:Number;
		private var _ylMouseDown:Number;

   		[ResourceBundle("ImageView")] private var _rb:ResourceBundle;
		
		private var _csrImgv:Cursor = null; // The cursor specified by the image view
		private var _csrOverlay:Cursor = null; // The cursor requested by the overlay
		private var _nCursorMode:Number = knSystemCursorMode; // Default mode
		
		private const knSystemCursorMode:Number = 0; // Use this to override other cursors
		private const knImageViewCursorMode:Number = 1; // Use this to ignore overlay cursors
		private const knOverlayCursorMode:Number = 2; // This mode looks at first the overlay, then the image view cursor
		
		private var _fMouseOverImageView:Boolean = true;
		private var _fMouseOffStage:Boolean = false;
		private var _fSpacebarDragMode:Boolean = false;
		
		// The position of the view before dragging begins (only updated on mouse down)
		private var _xlViewOffsetDown:Number;
		private var _ylViewOffsetDown:Number;

		// Use this to make sure we don't handle outside moves
		// when we have already captured a move.
		private var _fAlreadyHandledMove:Boolean = false;
		
		// nZoom is a floating point zoom factor. .5 = half size, 1.0 = full size, 2.0 = 2x zoom, etc
		private var _nZoom:Number = NaN; // Initialized to force a first-time zoom recalc
		private var _fZoomedImageFitsInsideView:Boolean = false;
		private var _bm:Bitmap = null;
		private var _bmClipped:Bitmap = null;
		private var _fBitmapAdded:Boolean = false;
		private var _sprViewObjectRoot:Sprite;	// 'view' coordinates are relative to this sprite
		private var _mcOverlay:MovieClip = null;
		private var _ovl:IOverlay = null;
		private var _bmdBackground:BitmapData;
		private var _strAlign:String = "center";
		private var _strHorizontalAlign:String = "center";
		private var _nSelectMode:int = kNoSelection;
		private var _aSelectables:Array = null;
		
		
		private var _cxPaddingLeft:Number = 0;
		private var _cxPaddingRight:Number = 0;
		private var _cyPaddingTop:Number = 0;
		private var _cyPaddingBottom:Number = 0;
		
		private var _cxBitmap:Number = 0;
		private var _cyBitmap:Number = 0;
		
		private var _obp:ObjectPalette = null;
		
		private var _fShowOriginal:Boolean = false;
		
		public function ImageView() {
			super();
			tabChildren = false;
			
			addEventListener(FlexEvent.SHOW, OnShow);
			addEventListener(FlexEvent.HIDE, OnHide);
			addEventListener(ResizeEvent.RESIZE, OnResize);
			addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
			addEventListener(MouseEvent.ROLL_OVER, OnRollOver);
			addEventListener(MouseEvent.MOUSE_WHEEL, OnMouseWheel);
			addEventListener(MouseEvent.DOUBLE_CLICK, OnMouseDoubleClick);
			_sprViewObjectRoot = new Sprite();
			addChild(_sprViewObjectRoot);
		}
		
		public function Constructor(): void {
		}
		
		//
		// Public API
		//
		
		public function CreateOverlay(ovl:IOverlay): MovieClip {
			Debug.Assert(_bm != null, "Can't create an overlay if there's no view Bitmap!");
			Debug.Assert(!_mcOverlay, "Only one overlay allowed at a time");
			_ovl = ovl;
			overlayCursor = null;
			_mcOverlay = new MovieClip();
			_sprViewObjectRoot.addChild(_mcOverlay);
			
			// Keep track of whether the spacebar is down so space+drag can override
			// any overlay's UI.
			stage.addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, OnKeyUp);
			return _mcOverlay;
		}

		public function DestroyOverlay(mc:MovieClip): void {
			Debug.Assert(_mcOverlay != null, "Can't destroy an overlay that doesn't exist!");
			_sprViewObjectRoot.removeChild(_mcOverlay);
			_mcOverlay = null;
			_ovl = null;
			overlayCursor = null;
			
			if (stage) stage.removeEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
			if (stage) stage.removeEventListener(KeyboardEvent.KEY_UP, OnKeyUp);
			_fSpacebarDragMode = false;
		}

		// UNDONE: these two are the same. Ditch RclFromRcd. Its users are really working in View space		
		public function RclFromRcd(rcd:Rectangle): Rectangle {
			var rcl:Rectangle = new Rectangle();
			rcl.left = Math.floor(rcd.left * _nZoom);
			rcl.right = Math.ceil(rcd.right * _nZoom);
			rcl.top = Math.floor(rcd.top * _nZoom);
			rcl.bottom = Math.ceil(rcd.bottom * _nZoom);
			return rcl;
//			return new Rectangle(Math.floor(rcd.left * _nZoom), Math.floor(rcd.top * _nZoom),
//					Math.ceil(rcd.width * _nZoom), Math.ceil(rcd.height * _nZoom));
		}
		
		public function RcvFromRcd(rcd:Rectangle): Rectangle {
			var rcv:Rectangle = new Rectangle();
			rcv.left = Math.floor(rcd.left * _nZoom);
			rcv.right = Math.ceil(rcd.right * _nZoom);
			rcv.top = Math.floor(rcd.top * _nZoom);
			rcv.bottom = Math.ceil(rcd.bottom * _nZoom);
			return rcv;
//			return new Rectangle(Math.floor(rcd.left * _nZoom), Math.floor(rcd.top * _nZoom),
//					Math.ceil(rcd.width * _nZoom), Math.ceil(rcd.height * _nZoom));
		}
		
		public function RcdFromRcl(rcl:Rectangle): Rectangle {
			return new Rectangle(rcl.left / _nZoom, rcl.top / _nZoom, rcl.width / _nZoom, rcl.height / _nZoom);
		}
		
		// UNDONE: this is rediculous to have so many coordinate spaces. Narrow to doc, view, and local/screen
		
		// Convert from local coordinates to document coordinates
		public function PtdFromPtl(ptl:Point): Point {
			return new Point((ptl.x - _xlViewOffset - _cxPaddingLeft) / _nZoom,
					(ptl.y - _ylViewOffset - _cyPaddingTop) / _nZoom);
		}
		
		// Convert from document coordinates to view coordinates		
		public function PtvFromPtd(ptd:Point): Point {
//			return new Point(Math.round(ptd.x * _nZoom), Math.round(ptd.y * _nZoom));
			return new Point(ptd.x * _nZoom, ptd.y * _nZoom);
		}
		
		// Convert from view coordinates to document coordinates
		public function PtdFromPtv(ptv:Point): Point {
			return new Point(ptv.x / _nZoom, ptv.y / _nZoom);
		}
		
		// Convert from stage coordinates to document coordinates
		public function PtdFromPts(pts:Point): Point {
			var ptl:Point = globalToLocal(pts);
			return new Point((ptl.x - _xlViewOffset - _cxPaddingLeft) / _nZoom,
					(ptl.y - _ylViewOffset - _cyPaddingTop) / _nZoom);
		}
		
		public function AptsFromAptd(aptd:Array): Array {
			var apts:Array = new Array(aptd.length);
			for (var ipt:Number = 0; ipt < aptd.length; ipt++)
				apts[ipt] = new Point(Math.round(aptd[ipt].x * _nZoom), Math.round(aptd[ipt].y * _nZoom));
			return apts;
		}
		
		// Return the visible rectangle of the ImageDocument, in document coordinates
		public function GetViewRect(): Rectangle {
			var rcv:Rectangle = new Rectangle(-viewX, -viewY, width, height);
			var rcd:Rectangle = RcdFromRcl(rcv);
			return rcd.intersection(new Rectangle(0, 0, _imgd.width, _imgd.height));
		}
		
		// The Object Palette is reparented to the application when the Edit or Create
		// tabs are active, or to the primary ZoomView when they are inactive. This way
		// it will appear/disappear as appropriate without triggering show/hide effects.
		public function ReparentObjectPalette(dobc:DisplayObjectContainer): void {
			if (_obp) {
				_obp.parent.removeChild(_obp);
				dobc.addChild(_obp);
			}
		}
		
		// Return the top-most ViewObject, if any, that intersects the stage coordinate.
		public function HitTestViewObjects(xs:Number, ys:Number): ViewObject {
			// Go in reverse order so the objects drawn last (on top) are hit first
			for (var i:int = _sprViewObjectRoot.numChildren-1; i >=0 ; i--) {
				var vo:ViewObject = _sprViewObjectRoot.getChildAt(i) as ViewObject;
				if (vo == null)
					continue;
				if (!vo.mouseEnabled)
					continue;
				if (vo.hitTestPoint(xs, ys, true))
					return vo;
			}
			return null;
		}
		
		public function IsEntireImageVisible(): Boolean {
			return _cxBitmap * _nZoom <= width && _cyBitmap * _nZoom <= height;
		}
		
		public static const kFreeSelection:int = 0; 	// no limits on selection
		public static const kNoSelection:int = 1;		// selecting objects is disabled
		public static const kForceSelection:int = 2;	// all items in aSelectables will always be selected
		public static const kFilterSelection:int = 3;   // only items in aSelectables may be selected
		
		public function FilterSelection( nSelectMode:int, aSelectables:Array = null ) : void {
			// aSelectables should be an array of IDocumentObjects		
	
			_nSelectMode = nSelectMode;
			_aSelectables = aSelectables;
		
			if (_imgd) {
				var aDocosFiltered:Array = FilterSelectionArray( _imgd.selectedItems );
				if (_imgd.selectedItems.length != aDocosFiltered.length) {
					_imgd.selectedItems = aDocosFiltered;
				}
			}
			UpdateControllers(null, _imgd ? _imgd.selectedItems : null);
		}
		
		private function FilterSelectionDoco( doco:IDocumentObject ): IDocumentObject {
			if (_nSelectMode == kFreeSelection)
				return doco;
			if (_nSelectMode == kNoSelection)
				return null;
			if (_aSelectables != null && _aSelectables.indexOf(doco) != -1)
				return doco;
			return null;
			
		}
	
		private function FilterSelectionArray( adoco:Array ): Array {
			if (_nSelectMode == kForceSelection) {
				return _aSelectables != null ? _aSelectables : [];
			}
			if (_nSelectMode == kFreeSelection) {
				return adoco;
			}
			if (_nSelectMode == kNoSelection) {
				return [];
			}
			var aDocosFiltered:Array = [];
			for each (var doco:IDocumentObject in adoco) {
				if (_aSelectables && _aSelectables.indexOf(doco) != -1) {
					aDocosFiltered.push(doco);
				}
			}
			return aDocosFiltered;
		}
		
		
		//
		// Public properties
		//
		
		[Inspectable(category="Picnik")]
		public function set paddingLeft(cxPaddingLeft:Number): void {
			_cxPaddingLeft = cxPaddingLeft;
			invalidateDisplayList();
		}
		
		public function get paddingLeft(): Number {
			return _cxPaddingLeft;
		}
		
		[Inspectable(category="Picnik")]
		public function set paddingRight(cxPaddingRight:Number): void {
			_cxPaddingRight = cxPaddingRight;
			invalidateDisplayList();
		}
		
		public function get paddingRight(): Number {
			return _cxPaddingRight;
		}
		
		[Inspectable(category="Picnik")]
		public function set paddingTop(cyPaddingTop:Number): void {
			_cyPaddingTop = cyPaddingTop;
			invalidateDisplayList();
		}
		
		public function get paddingTop(): Number {
			return _cyPaddingTop;
		}
		
		[Inspectable(category="Picnik")]
		public function set paddingBottom(cyPaddingBottom:Number): void {
			_cyPaddingBottom = cyPaddingBottom;
			invalidateDisplayList();
		}
		
		public function get paddingBottom(): Number {
			return _cyPaddingBottom;
		}
		
		[Inspectable(category="Picnik", enumeration="top,center,bottom", defaultValue="center")]
		public function set verticalAlign(strAlign:String): void {
			_strAlign = strAlign;
			invalidateDisplayList();
		}

		public function get verticalAlign(): String {
			return _strAlign;
		}
		
		[Inspectable(category="Picnik", enumeration="left,center,right", defaultValue="center")]
		public function set horizontalAlign(strHorizontalAlign:String): void {
			_strHorizontalAlign = strHorizontalAlign;
			invalidateDisplayList();
		}

		public function get horizontalAlign(): String {
			return _strHorizontalAlign;
		}
		
		[Inspectable(category="Picnik")]
		public function set backgroundImage(ob:Object): void{
			Debug.Assert(ob is Class, "Only embedded images are supported at this time");
			var bm:Bitmap = new ob();
			_bmdBackground = bm.bitmapData;
			invalidateDisplayList();
		}
		
		public function get viewObjects(): DisplayObjectContainer {
			return _sprViewObjectRoot as DisplayObjectContainer;
		}
		
		[Inspectable(category="Picnik")]
		public function set viewX(x:Number): void {
			_xlViewOffset = x;
			invalidateDisplayList();
		}
		
		public function get viewX(): Number {
			return _xlViewOffset;
		}
		
		[Inspectable(category="Picnik")]
		public function set viewY(y:Number): void {
			_ylViewOffset = y;
			invalidateDisplayList();
		}
		
		public function get viewY(): Number {
			return _ylViewOffset;
		}
		
		public function get zoomMin(): Number {
			if (!_imgd)
				return 1.0;
				
			var nZoomMin:Number = CalcFitInsideScaleFactor();

			// Don't zoom smaller than 48 pixels on a side unless the image is smaller than 48 pixels
			var minViewSize:Number = 48;
			var cxyMin:Number = Math.min(_cxBitmap, _cyBitmap);
			return Math.max(nZoomMin, Math.min(cxyMin, minViewSize) / cxyMin);
		}
		
		public function get zoomMax(): Number {
			return 8.0;
		}
		
		[Inspectable(category="Picnik")]
		public function get zoom(): Number {
			return _nZoom;
		}
	
		/**
		 * zoom tries to keep the same pixel of the image centered in the view.
		 * This isn't always possible because other constraints (e.g. fitting to
		 * view) take precedence.
		 */
		public function set zoom(nZoom:Number): void {
			ZoomAroundPoint(nZoom, new Point(width / 2, height / 2));
		}
		
		// Zoom so the specified point (in view space) will stay in place
		private function ZoomAroundPoint(nZoom:Number, ptl:Point): void {
			// Ignore requests to zoom to the current size. This avoids infinite recursion when
			// Relayout() attempts to FitToView
			if (nZoom == _nZoom)
				return;
				
			// _nZoom is initialized to NaN
			var nZoomOld:Number = isNaN(_nZoom) ? 1.0 : _nZoom;
			var xlViewCenter:Number = ptl.x - _cxPaddingLeft;
			var ylViewCenter:Number = ptl.y - _cyPaddingTop;
			var dxlOld:Number = xlViewCenter - _xlViewOffset;
			var dylOld:Number = ylViewCenter - _ylViewOffset;
			_nZoom = nZoom;
			_xlViewOffset = xlViewCenter - (dxlOld / nZoomOld) * _nZoom;
			_ylViewOffset = ylViewCenter - (dylOld / nZoomOld) * _nZoom;

			_fZoomedImageFitsInsideView = _nZoom == zoomMin;
			
			invalidateDisplayList();
			dispatchEvent(new ImageViewEvent(ImageViewEvent.ZOOM_CHANGE, nZoomOld, _nZoom));
		}

		[Inspectable(category="Picnik")]
		[Bindable]
		public function set imageDocument(imgd:ImageDocument): void {
			if (_imgd != null) {
				ClearControllers();
				RemoveObjectPalette();
				RemovePrimaryBitmap();
				_bm = null;
				_imgd.removeEventListener(ImageDocumentEvent.BITMAPDATA_CHANGE, OnDocumentBitmapDataChange);
				_imgd.removeEventListener(ImageDocumentEvent.SELECTED_ITEMS_CHANGE, OnDocumentSelectedItemsChange);
				_imgd = null;
			}
			
			_xlViewOffset = 0;
			_ylViewOffset = 0;
			
			if (imgd != null) {
				_imgd = imgd;
				_imgd.addEventListener(ImageDocumentEvent.BITMAPDATA_CHANGE, OnDocumentBitmapDataChange);
				_imgd.addEventListener(ImageDocumentEvent.SELECTED_ITEMS_CHANGE, OnDocumentSelectedItemsChange);
				CreateDocumentBitmap();
				zoom = zoomMin;
				AddControllers();
			} else {
				zoom = 1.0;
			}
		}
		
		public function get imageDocument(): ImageDocument {
			return _imgd;
		}
		
		public function get objectPalette(): ObjectPalette {
			return _obp;
		}
		
		private function RemoveObjectPalette(): void {
			if (_obp) {
				_obp.Hide();
				_obp = null;
			}
		}
	
		[Bindable]
		public function get showOriginal(): Boolean {
			return _fShowOriginal;
		}
		
		public function set showOriginal(f:Boolean): void {
			_fShowOriginal = f;
			if (_imgd) CreateDocumentBitmap(true,true);
		}
				
		public function get imageViewCursor(): Cursor {
			return _csrImgv;
		}
		
		public function set imageViewCursor(csrImgv:Cursor): void {
			_csrImgv = csrImgv;
			UpdateCursor();
		}
		
		public function get overlayCursor(): Cursor {
			return _csrOverlay;
		}
		
		public function set overlayCursor(csrOverlay:Cursor): void {
			_csrOverlay = csrOverlay;
			UpdateCursor();
		}
		
		private function get cursorMode(): Number {
			return _nCursorMode;
		}
		
		private function set cursorMode(nCursorMode:Number): void {
			_nCursorMode = nCursorMode;
			UpdateCursor();
		}
		
		public function get bitmapX(): Number {
			// _sprViewObjectRoot.x/y are invalid while the ImageDocument's composite is invalid
			// We need them to be valid here so we tap the composite property to force validation
			_imgd.composite;
			return _sprViewObjectRoot.x;
		}

		public function get bitmapY(): Number {
			// _sprViewObjectRoot.x/y are invalid while the ImageDocument's composite is invalid
			// We need them to be valid here so we tap the composite property to force validation
			_imgd.composite;
			return _sprViewObjectRoot.y;
		}

		// The ImageView contains a Bitmap that has the ImageDocument BitmapData attached to it.
		// This way we can easily position and zoom the bitmap.
		private function CreateDocumentBitmap(fResetView:Boolean=false, fNewComposite:Boolean=true): void {
			if (fNewComposite) {
				if (showOriginal) {
					_bm = new Bitmap(_imgd.original, PixelSnapping.ALWAYS, false);
				} else {
					_bm = new Bitmap(_imgd.composite, PixelSnapping.ALWAYS, false);
				}

				_cxBitmap = _bm.width;
				_cyBitmap = _bm.height;

				// Add the bitmap at the bottom to be sure any overlay stays on top of it
				RemoveClippedBitmap(); // Clear out our clipped bitmap (if any)
			}
			
			// We can't just invalidateDisplayList here because the new bitmap
			// will be visible THIS frame
			if (fResetView) {
				SetInitialLayout();
			} else if (fNewComposite) {
				Relayout();
			} else {
				// Even if the composite bitmap didn't change, the DocumentObjects might have so
				// update ViewObjects attached to them.
				UpdateViewObjects();
			}
		}
		
		// 1. If the mouse is out of the view and not down, show the system cursor
		// 2. If we're in spacebar drag mode, show the ImageView cursor
		//	  else the Overlay cursor
		private function UpdateCursorMode(): void {
			if (!_fMouseOverImageView && !_fMouseDown) {
				cursorMode = knSystemCursorMode;
			} else {
				if (_fSpacebarDragMode) {
					cursorMode = knImageViewCursorMode;
				} else {
					cursorMode = knOverlayCursorMode;
				}
			}
		}
		
		private function UpdateCursor(): void {
			// Don't update the cursor if this ImageView isn't visible
			if (!Util.IsVisible(this))
				return;
				
			var csr:Cursor = Cursor.csrSystem; // Default to system cursor

			if (cursorMode == knOverlayCursorMode) {
				if (overlayCursor != null) {
					csr = overlayCursor;
				} else if (imageViewCursor != null) {
					csr = imageViewCursor;
				}
			} else if (cursorMode == knImageViewCursorMode && imageViewCursor != null) {
				csr = imageViewCursor;
			}
			
			if (csr == null) csr = Cursor.csrSystem;
			
			csr.Apply();
		}
		
		// Update the mouse cursor the ImageView wants to display (system, hand, or move).
		// This cursor may be overridden by the active Overlay or a DocoController the
		// mouse is over.
		private function UpdateImageViewCursor(): void {
			// Default to the system cursor
			var csr:Cursor = Cursor.csrSystem;
			if (_imgd) {
				
				// Change to a hand cursor if the zoomed document is larger than the view
				if (!IsEntireImageVisible())
					csr = _fMouseDown ? Cursor.csrHandGrab : Cursor.csrHand;
	
				// If the mouse is over a moveable object show the move cursor			
				// Bounding box test to find all objects under the mouse
				var ptdMouse:Point = PtdFromPtl(new Point(mouseX, mouseY));
				var adoco:Array = _imgd.GetObjectsUnderPoint(ptdMouse, false);
				var fFixed:Boolean = true;
				var cUnfiltered:int = 0;

				for each (var dob:DisplayObject in adoco) {
					var doco:IDocumentObject = dob as IDocumentObject;
					// darrinm: When debugging I sometimes add DisplayObjects (not DocumentObjects) straight
					// to the document. This keeps them from wreaking too much havok.
					if (doco == null)
						continue;
					
					if (FilterSelectionDoco(doco)) {
						cUnfiltered++;
						if (!doco.isFixed) {
							fFixed = false;
							break;
						}
					}
				}
						
				if (cUnfiltered > 0)
					csr = fFixed ? Cursor.csrArrowSelect : Cursor.csrMove;
			}
			
			imageViewCursor = csr;
		}
		
		
		private function Relayout(): void {
			if (!_bm)
				return;
		
			// If the image already completely fits inside the view make sure it
			// still does after relayout (which is often accompanying a resize)
			var nZoomFit:Number = zoomMin;
			if (_fZoomedImageFitsInsideView) {
				if (_nZoom != nZoomFit) {
					zoom = nZoomFit;
				}
			} else {
				_fZoomedImageFitsInsideView = _nZoom == nZoomFit;
			}

			var cxZoomed:Number = _cxBitmap * _nZoom;
			var cyZoomed:Number = _cyBitmap * _nZoom;
			
			// Make sure the view is completely within the bounds (plus padding for border)
			// of the scaled document.
			var rcFrame:Rectangle = GetFrameRect();
			var rcView:Rectangle = new Rectangle(0, 0, width, height);
			rcFrame.offset(_xlViewOffset, _ylViewOffset);
			if (rcView.width >= rcFrame.width)
				switch (horizontalAlign) {
				case "left":
					_xlViewOffset = 0;
					break;
					
				case "right":
					_xlViewOffset = rcFrame.width - rcView.width;
					break;
					
				default:
					_xlViewOffset = (rcView.width - rcFrame.width) / 2;
					break;
				}
			else if (rcFrame.right < rcView.right)
				_xlViewOffset += rcView.right - rcFrame.right;
			else if (rcView.left < rcFrame.left)
				_xlViewOffset -= rcFrame.left - rcView.left;
			if (rcView.height >= rcFrame.height) {
				switch (verticalAlign) {
				case "top":
					_ylViewOffset = 0;
					break;
					
				case "bottom":
					_ylViewOffset = rcFrame.height - rcView.height;
					break;
					
				default:
					_ylViewOffset = (rcView.height - rcFrame.height) / 2;
					break;
				}
			} else if (rcFrame.bottom < rcView.bottom)
				_ylViewOffset += rcView.bottom - rcFrame.bottom;
			else if (rcView.top < rcFrame.top)
				_ylViewOffset -= rcFrame.top - rcView.top;
			
			// Flash's fastest Bitmap drawing routine only kicks in if the bitmap
			// is on a whole pixel boundary (and not scaled, ie 1.0 zoom)
			_sprViewObjectRoot.x = Math.round(_xlViewOffset + _cxPaddingLeft);
			_sprViewObjectRoot.y = Math.round(_ylViewOffset + _cyPaddingTop);
			
			/* UNDONE: 3D objects
			var pproj:PerspectiveProjection = new PerspectiveProjection();
			pproj.projectionCenter = new Point(rcFrame.width / 2, rcFrame.height / 2);
			trace("fov: " + pproj.fieldOfView + ", fl: " + pproj.focalLength);
			//pproj.fieldOfView = 55;
			_sprViewObjectRoot.transform.perspectiveProjection = pproj;
			*/
			
			_bm.scaleX = _nZoom;
			_bm.scaleY = _nZoom;
			_bm.smoothing = _nZoom < 1.0; // Smooth scaled-down images only

			if (_mcOverlay && _mcOverlay.OnResize)
				_mcOverlay.OnResize();

			UpdateClippedBitmap(rcView);
			UpdateViewObjects();
			UpdateImageViewCursor();
			
			dispatchEvent(new Event("layoutChange"));
		}
		
		private function UpdateViewObjects(): void {
			for (var i:Number = 0; i < _sprViewObjectRoot.numChildren; i++) {
				var vo:ViewObject = _sprViewObjectRoot.getChildAt(i) as ViewObject;
				if (vo && vo.visible)
					vo.UpdateDisplayList();
			}
		}

		// Remove the current bitmap from image view
		private function RemovePrimaryBitmap(): void {
			SetPrimaryBitmap(null);
		}
		
		// Add or set the current bitmap (either _bm or _bmClipped)
		private function SetPrimaryBitmap(bm:Bitmap): void {
			if (_sprViewObjectRoot.numChildren > 0 && _sprViewObjectRoot.getChildAt(0) == bm) return; // Don't add over itself
			
			if (_fBitmapAdded) {
				_sprViewObjectRoot.removeChildAt(0); // 0 == bottom-most child
				_fBitmapAdded = false;
			}
			if (bm) {
				_sprViewObjectRoot.addChildAt(bm, 0); // 0 == bottom-most child
				_fBitmapAdded = true;
			}
		}

		// Returns true if we are displaying a part of the image at a zoom level that requires
		// a clipped bitmap to solve the bitmap memory address bug
		private function NeedClippedBitmap(rcView:Rectangle): Boolean {
			const knZoomFactor:Number = 525; // Increase this to increase clip coverage
			const knOffset:Number = 4050; // Decrease this to increase clip coverage

			// NOTE: don't raise this to GetMaxImageWidth or we'll hit the problem again.
			if ((_nZoom * Math.max(_cxBitmap, _cyBitmap) / 2800) < 2.5)
				return false;
			var rcl:Rectangle = new Rectangle(0, 0, rcView.width/2, rcView.height/2);
			var rcd:Rectangle = RcdFromRcl(rcl);
			
			var cxFromCenter:Number = Math.abs((_cxBitmap / 2) - rcd.left);
			var cyFromCenter:Number = Math.abs((_cyBitmap / 2) - rcd.top);
			
			
			var cxMaxOffset:Number = knOffset - knZoomFactor * _nZoom - _cxBitmap / 2;
			var cyMaxOffset:Number = knOffset - knZoomFactor * _nZoom - _cyBitmap / 2;

			return (cxFromCenter > cxMaxOffset ) || (cyFromCenter > cyMaxOffset);
		}
		
		private function RemoveClippedBitmap(): void {
			SetPrimaryBitmap(_bm);
			if (_bmClipped != null) {
				if  (_bmClipped.bitmapData) _bmClipped.bitmapData.dispose();
				_bmClipped = null;
			}
		}

		private function AddClippedBitmap(bm:Bitmap): void {
			_bmClipped = bm;
			SetPrimaryBitmap(bm);
		}

		private function UpdateClippedBitmap(rcView:Rectangle): void {
			if (NeedClippedBitmap(rcView)) {
				var rcl:Rectangle = new Rectangle(-_sprViewObjectRoot.x, -_sprViewObjectRoot.y, rcView.width, rcView.height);
				var rcd:Rectangle = RcdFromRcl(rcl);
				rcd.x = Math.round(rcd.x);
				rcd.y = Math.round(rcd.y);				
				rcd.x = Math.max(0, rcd.x);
				rcd.y = Math.max(0, rcd.y);
				rcd.inflate(1,1);
				rcd = rcd.intersection(new Rectangle(0, 0, _cxBitmap, _cyBitmap));
				var rclActual:Rectangle = RclFromRcd(rcd);
				var cxlOffset:Number = rclActual.x - rcl.x;
				var cylOffset:Number = rclActual.y - rcl.y;
				
				var bmd:BitmapData = VBitmapData.Construct(rcd.width, rcd.height, true);
				bmd.copyPixels(_bm.bitmapData, rcd, new Point(0,0));
				if (_bmClipped == null) {
					AddClippedBitmap(new Bitmap(bmd, PixelSnapping.ALWAYS, false));
				} else {
					if (_bmClipped.bitmapData) _bmClipped.bitmapData.dispose();
					_bmClipped.bitmapData = bmd;
				}
				_bmClipped.scaleX = _nZoom;
				_bmClipped.scaleY = _nZoom;
				_bmClipped.smoothing = false;

				_bmClipped.x = cxlOffset - _sprViewObjectRoot.x;
				_bmClipped.y = cylOffset - _sprViewObjectRoot.y;
			} else {
				RemoveClippedBitmap();
			}
		}
		
		private function OnResize(evt:ResizeEvent=null): void {
			// Clip children (e.g. _bm) to the ImageView bounds
			scrollRect = new Rectangle(0, 0, width, height);
			var rcBounds:Rectangle = new Rectangle(0, 0, width, height);

			with (graphics) {
				clear();
				if (_bmdBackground)
					beginBitmapFill(_bmdBackground);
				else if (getStyle("color"))
					beginFill(getStyle("color"));
				else {
					// Without a background, we lose background mouse events
					// HACK: In this case (Picnik lite) treat the padding area as off-canvas
					// (unless the bitmap is zoomed to cover that area). This way the rasnfrasn
					// Picnik lite footer can still be clicked.
					beginFill(0, 0); // alpha 0, completely transparent
					rcBounds.left += paddingLeft;
					rcBounds.right -= paddingRight;
					rcBounds.top += paddingTop;
					rcBounds.bottom -= paddingBottom;
				}
				moveTo(rcBounds.left, rcBounds.top);
				lineTo(rcBounds.right, rcBounds.top);
				lineTo(rcBounds.right, rcBounds.bottom);
				lineTo(rcBounds.left, rcBounds.bottom);
				lineTo(rcBounds.left, rcBounds.top);
				endFill();
			}
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(cxUnscaled:Number, cyUnscaled:Number): void {
			Relayout();
		}
	
		private function SetInitialLayout(): void {
			var rcFrame:Rectangle = GetFrameRect();
			_xlViewOffset = (width - rcFrame.width) / 2;
			_ylViewOffset = (height - rcFrame.height) / 2;
			Relayout();
		}

		// Calculate a scale factor that will fit the image plus padding completely
		// within the view. If the image fits without scaling, return a 1.0 scaling
		// factor.
		private function CalcFitInsideScaleFactor(): Number {
			var cxPadding:Number = _cxPaddingLeft + _cxPaddingRight;
			var cyPadding:Number = _cyPaddingTop + _cyPaddingBottom;
			// if image wholly fits within view
			if (_cxBitmap + cxPadding <= width && _cyBitmap + cyPadding <= height)
				return 1.0;
			else
				return Math.min((width - cxPadding) / _cxBitmap, (height - cyPadding) / _cyBitmap);
		}
		
		// The frame rect is the dimensions of the zoomed image plus the padding
		private function GetFrameRect(): Rectangle {
			var cxPadding:Number = _cxPaddingLeft + _cxPaddingRight;
			var cyPadding:Number = _cyPaddingTop + _cyPaddingBottom;
			return new Rectangle(0, 0, (_cxBitmap * _nZoom) + cxPadding, (_cyBitmap* _nZoom) + cyPadding);
		}
	
		// If the document's BitmapData has changed we need to recreate _bm
		// and attach the new BitmapData to it. We also need to re-layout the
		// view if the BitmapData's dimensions have changed.
		private function OnDocumentBitmapDataChange(evt:GenericDocumentEvent): void {
//			trace("bmdOld: " + evt.obOld.toString() + ", bmdNew: " + evt.obNew.toString() + ", change: " + (_bm.bitmapData != evt.obNew));
			var bmdOld:BitmapData = evt.obOld as BitmapData;
			var bmdNew:BitmapData = evt.obNew as BitmapData;
			var fResetView:Boolean;
			try {
				fResetView = bmdOld.width != bmdNew.width || bmdOld.height != bmdNew.height;
			} catch (e:Error) {
				fResetView = false;
			}
			
			if (bmdNew as VBitmapData) {
				(bmdNew as VBitmapData).PrepareToDisplay();
			}
			
			// Can't rely on direct BitmapData updating if a 'clipped bitmap' is being used.
			CreateDocumentBitmap(fResetView, bmdOld != bmdNew ||
					NeedClippedBitmap(new Rectangle(0, 0, width, height)));
		}
	
		// If the document's selected items list has changed we need to update the controller
		// list to match.
		private function OnDocumentSelectedItemsChange(evt:GenericDocumentEvent): void {
			UpdateControllers(evt.obOld as Array, evt.obNew as Array);
		}
		
		// Remove any existing view-based controllers and create new ones to correspond
		// to each selected DocumentObject
		private function UpdateControllers(adobOld:Array, adobNew:Array): void {
			ClearControllers();
			AddControllers();
			
			// Show the ObjectPalette if item selection is enabled and there is a selection.
			if (_nSelectMode != kNoSelection && adobNew != null && adobNew.length != 0) {
				
				// Don't show the object palette if nobody wants it.
				var fShow:Boolean = false;
				for each (var doco:IDocumentObject in adobNew) {
					if (doco.showObjectPalette) {
						fShow = true;
						break;
					}
				}
				
				if (fShow) {
					if (_obp == null) {
						_obp = new ObjectPalette();
						Application.application.addChild(_obp);
						// UNDONE: initial positioning
						_obp.x = Application.application.width - 225;
						_obp.y = 102;
					}
					_obp.Show();
				}
			}
			if (_nSelectMode == kNoSelection && _obp != null && _obp.visible)
				_obp.Hide();
		}
		
		// Remove all view-based controllers
		private function ClearControllers(): void {
			// End to front so we can remove as we go
			for (var i:Number = _sprViewObjectRoot.numChildren - 1; i >= 0; i--) {
				var dococ:DocoController = _sprViewObjectRoot.getChildAt(i) as DocoController;
				if (dococ)
					// This seemingly unnecessary cast is required to differentiate the viewObjects
					// property from the viewObjects package
					DisplayObjectContainer(viewObjects).removeChildAt(i);
			}
		}
		
		// Add view-based controllers corresponding to each selected DocumentObject
		private function AddControllers(): void {
			if (_nSelectMode == kNoSelection || _imgd == null)
				return;
				
			var adoco:Array = _imgd.selectedItems;
			for each (var doco:IDocumentObject in adoco) {
				var dob:DisplayObject = doco as DisplayObject;
				
				// It's possible this object has already been removed from the document (e.g. via
				// Undo).
				if (dob.parent == null)
					continue;
				
				// Put the MoveSizeRotate controller in crop mode if the selected item is a mask
				// UNDONE: ask the IDocumentObject for its controller's name
				var clsDococ:Class = doco.controller;
				var dococ:DocoController;
				if (clsDococ) {
					dococ = new clsDococ(this, dob, dob.parent.mask == dob);
				} else {
					dococ = new MoveSizeRotate(this, dob, dob.parent.mask == dob);
				}
					
				// This seemingly unnecessary cast is required to differentiate the viewObjects
				// property from the viewObjects package
				DisplayObjectContainer(viewObjects).addChild(dococ);
			}
		}
		
		// If this document object has a view-based controller, return it
		private function FindController(doco:IDocumentObject): DocoController {
			for (var i:Number = 0; i < _sprViewObjectRoot.numChildren; i++) {
				var dococ:DocoController = _sprViewObjectRoot.getChildAt(i) as DocoController;
				if (dococ && dococ.target == doco)
					return dococ;
			}
			return null;
		}
	
		//
		// UI
		// - allow the user to drag the view around when it is larger than the view area
		// - show the hand cursor when the view is draggable
		// - if itemSelectionEnabled, hit test DocumentObjects on mousedown and select them if hit
		//
		
		private function OnShow(evt:FlexEvent): void {
			cursorMode = knOverlayCursorMode;
		}
		
		private function OnHide(evt:FlexEvent): void {
			cursorMode = knSystemCursorMode;
			UpdateCursorMode();
		}
		
		// Return true if at least one element appears in both arrays
		private function arraysOverlap(aob1:Array, aob2:Array): Boolean {
			if (aob1 == null || aob2 == null) return false;
			for each (var ob:Object in aob1) {
				if (aob2.indexOf(ob) != -1) return true; // Found an element in both
			}
			return false;
		}

		// Select any object you click on and return a list of right click
		// menu items appropriate for that item
		public function get rightClickMenuItems(): Array {
			if (_nSelectMode == kNoSelection)
				return null;
				
			UpdateSelectionForClick();

			if (_imgd.selectedItems.length == 0)
				return null; // Nothing selected
			
			// Now return a menu for the selected document objects.
			
			// For now, assume that the all respond to right click events/
			// We may eventually want to customize this menu for the selected items
			// Selected type is used for the title of the delete option, e.g. "Delete Objects" or "Delete Type"
			var strSelectedType:String;
			if (_imgd.selectedItems.length > 1) {
				strSelectedType = Resource.getString('ImageView', 'Objects'); // UNDONE: For multi-select, we might want this to say "Type Objects" etc.
			} else {
				strSelectedType = (_imgd.selectedItems[0] as IDocumentObject).typeName;
			}
			
			var fUnzoomable:Boolean = true;
			var fFixed:Boolean = false;
			var doco:IDocumentObject;
			for each (doco in _imgd.selectedItems) {
				if (!(doco is Photo)) {
					fUnzoomable = false;
				}
				if (doco.isFixed)
					fFixed = true;
			}
			
			var aobItems:Array = [
			/*
				{label:LocUtil.rbSubst('ImageView', 'Cut', strSelectedType),
					click:function(): void {CutSelectedObjects()}},
				{label:LocUtil.rbSubst('ImageView', 'Copy', strSelectedType),
					click:function(): void {CopySelectedObjects()}},
				{label:Resource.getString('ImageView', 'Paste'),
					click:function(): void {PasteClipboardContents()}},
			*/
				{id:'Delete', label:LocUtil.rbSubst('ImageView', 'Delete', strSelectedType), separatorBefore: false,
					click:function(): void {ApplyOpToSelected(DestroyObjectOperation, "Destroy " + strSelectedType, ["{id}"]);}},
				{id:'SendToBack', label:Resource.getString('ImageView', 'SendToBack'), separatorBefore: true,
					click:function(): void {ApplyOpToSelected(SetDepthObjectOperation, "Set " + strSelectedType + " Depth", ["{id}", Number.NEGATIVE_INFINITY], true);}},
				{id:'SendBackward', label:Resource.getString('ImageView', 'SendBackward'),
					click:function(): void {ApplyOpToSelected(SetDepthObjectOperation, "Set " + strSelectedType + " Depth", ["{id}", -_imgd.selectedItems.length], true);}},
				{id:'BringForward', label:Resource.getString('ImageView', 'BringForward'),
					click:function(): void {ApplyOpToSelected(SetDepthObjectOperation, "Set " + strSelectedType + " Depth", ["{id}", _imgd.selectedItems.length]);}},
				{id:'BringToFront', label:Resource.getString('ImageView', 'BringToFront'),
					click:function(): void {ApplyOpToSelected(SetDepthObjectOperation, "Set " + strSelectedType + " Depth", ["{id}", Number.POSITIVE_INFINITY]);}},
				{id:'FlipVertically', label:Resource.getString('ImageView', 'FlipVertically'), separatorBefore: true,
					click:function(): void {ApplyOpToSelected(FlipObjectOperation, "Flip " + strSelectedType, ["{dob}", false]);}},
				{id:'FlipHorizontally', label:Resource.getString('ImageView', 'FlipHorizontally'),
					click:function(): void {ApplyOpToSelected(FlipObjectOperation, "Flip " + strSelectedType, ["{dob}", true]);}},
			/*
				{label:Resource.getString('ImageView', 'Crop'),
					click:function(): void {CropSelectedObject()}},
			*/
				];

			if (!fFixed)
				aobItems.push(
				{id:'Straighten', label:Resource.getString('ImageView', 'Straighten'),
					click:function(): void {ApplyOpToSelected(StraightenObjectOperation, "Straighten " + strSelectedType, ["{dob}"]);}});
			if (!fFixed)
				aobItems.push(
				{id:'RemoveDistortion', label:Resource.getString('ImageView', 'RemoveDistortion'),
					click:function(): void {ApplyOpToSelected(RemoveDistortionObjectOperation, "Destroy " + strSelectedType, ["{dob}"]);}});
				
			if (fUnzoomable)
				aobItems.push(
					{id:'Unzoom', label:Resource.getString('ImageView', 'Unzoom'),
						click:function(): void {ApplyOpToSelected(NormalScaleObjectOperation, "Normal Scale " + strSelectedType, ["{dob}"]);}});

			if (fUnzoomable && AccountMgr.GetInstance().isCollageAuthor)
				aobItems.push(
					{id:'Center', label:Resource.getString('ImageView', 'Center'),
						click:function(): void {ApplyOpToSelected(CenterObjectOperation, "Center " + strSelectedType, ["{dob}"]);}});

			if (!fFixed)
				aobItems.push(
				{id:'Duplicate', label:LocUtil.rbSubst('ImageView', 'Duplicate', strSelectedType), click:DuplicateSelected});
			
			// give each item a chance to modify the menu items
			for each (doco in _imgd.selectedItems)
				aobItems = doco.FilterMenuItems(aobItems);

			return aobItems;
		}
		
		//
		// Right click menu functions
		//
		
		private function DuplicateSelected(): void {
			var adoco:Array = _imgd.selectedItems.slice();
			var astrNames:Array = [];
			if (adoco && adoco.length > 0) {
				adoco.sort(sortOnZOrderAscending);
					
				_imgd.BeginUndoTransaction("Duplicate", true, false);
				for each (var doco:IDocumentObject in adoco) {
					var xmlProperties:XML = ImageDocument.DocumentObjectToXML(doco);
					// Convert it into the form CreateObjectOperation likes
					var dctProperties:Object = Util.ObFromXmlProperties(xmlProperties);

					// Tweak some of the properties
					if ("x" in dctProperties) dctProperties.x += 30;
					if ("y" in dctProperties) dctProperties.y += 30;
					dctProperties.name = Util.GetUniqueId();
					
					// Create a new DocumentObject
					var strType:String = ImageDocument.GetDocumentObjectType(doco);
					var coop:imagine.objectOperations.CreateObjectOperation =
							new imagine.objectOperations.CreateObjectOperation(strType, dctProperties);
					coop.Do(_imgd);
					
					astrNames.push(dctProperties.name);
				}
				_imgd.EndUndoTransaction();
				
				var adocoSelect:Array = [];
				
				for each (var strName:String in astrNames) {
					var docoSelect:Object = _imgd.getChildByName(strName);
					if (docoSelect) {
						adocoSelect.push(docoSelect);
					}
				}
				_imgd.selectedItems = adocoSelect;					
			}
		}

		// Params to each object may need to be specific for that object.
		// Do some magic here to parse out a few {} style params
		// Supported {} params:
		//   {dob}: the selected display object
		//   {doco}: the selected document object (is also a display object)
		//   {id}: the id of the selected object, same is dob.name
		//   {dob.name}: the name of the selected object, same as id
		private function PreProcessParams(aobParams:Array, doco:IDocumentObject): Array {
			var aobOut:Array = aobParams.slice();
			for (var i:Number = 0; i < aobOut.length; i++) {
				if (aobOut[i] == "{dob}")
					aobOut[i] = DisplayObject(doco);
				else if (aobOut[i] == "{doco}")
					aobOut[i] = doco;
				else if (aobOut[i] == "{dob.name}" || aobOut[i] == "{id}")
					aobOut[i] = DisplayObject(doco).name;
			}
			return aobOut;
		}
		
		// Call a constructor with optional parameters.
		// Preprocess the parameters, specific to the target object
		private function CreateObjectOperation(clOp:Class, aobParams:Array, doco:IDocumentObject):ObjectOperation {
			aobParams = PreProcessParams(aobParams, doco);
			var doop:ObjectOperation;
			// Note: It would be nice if we could write this code for reuse.
			// However, the classes referenced must be included by this file which limits the benefit of sharing the code.
			if (!aobParams || aobParams.length == 0) doop = new clOp();
			else if (aobParams.length == 1) doop = new clOp(aobParams[0]);
			else if (aobParams.length == 2) doop = new clOp(aobParams[0], aobParams[1]);
			else if (aobParams.length == 3) doop = new clOp(aobParams[0], aobParams[1], aobParams[2]);
			else throw new Error("Too many parameters to object operation constructor");
			return doop;
		}

		// Compare two display objects by z-order, descending		
		private function sortOnZOrderDescending(dob1:DisplayObject, dob2:DisplayObject): Number {
			return sortOnZOrder(dob1, dob2, false);
		}
		
		// Compare two display objects by z-order, ascending
		private function sortOnZOrderAscending(dob1:DisplayObject, dob2:DisplayObject): Number {
			return sortOnZOrder(dob1, dob2, true);
		}
		
		// Compare two display objects by z-order
		private function sortOnZOrder(dob1:DisplayObject, dob2:DisplayObject, fAscending:Boolean=true): Number {
			var nCmp:Number = 0;
			var nZ1:Number = _imgd.getChildIndex(dob1);
			var nZ2:Number = _imgd.getChildIndex(dob1);
			if (nZ1 > nZ2) nCmp = 1;
			else if (nZ1 < nZ2) nCmp = -1;
			if (!fAscending) nCmp = -nCmp;
			return nCmp;
		}

		// Apply an operation to one or more selected objects
		// clOpp: the class of the operation to apply
		// strOpName: the name of the operation, mostly for logging
		// aobParams: The parameters to use when construction the class (some may be dynamic, see PreProcessParams())
		// fIterateFromFrontToBack: Selected items are itereated in z-order, default is back to front. This is useful for SetDepthImageOperations
		private function ApplyOpToSelected(clOp:Class, strOpName:String, aobParams:Array, fIterateFromFrontToBack:Boolean=false): void {
			var adoco:Array = _imgd.selectedItems.slice();
			if (adoco && adoco.length > 0) {
				if (fIterateFromFrontToBack)
					adoco.sort(sortOnZOrderDescending);
				else
					adoco.sort(sortOnZOrderAscending);
					
				_imgd.BeginUndoTransaction(strOpName, true, false);
				for each (var doco:IDocumentObject in adoco) {
					var doop:ObjectOperation = CreateObjectOperation(clOp, aobParams, doco);
					doop.Do(_imgd);
				}
				_imgd.EndUndoTransaction();
			}
		}
		
		private function CopySelectedObjects(): void {
			
		}
		
		private function CutSelectedObjects(): void {
			
		}
		
		private function PasteClipboardContents(): void {
			
		}

		private function CropSelectedObject(): void {
			var dob:DisplayObject = _imgd.selectedItems[0];
			
			// If the selected object doesn't already have a mask DisplayObject, create one for it.
			if (dob.mask == null) {
				// Create the mask DocumentObject as a child of the DocumentObject to be masked
				var doco:IDocumentObject = dob as IDocumentObject;
				var dctProperties:Object = {
					name: Util.GetUniqueId(), parent: dob.name,
					unscaledWidth: doco.unscaledWidth, unscaledHeight: doco.unscaledHeight
				}
				
				_imgd.BeginUndoTransaction("Crop Object", false, false);
				var coop:imagine.objectOperations.CreateObjectOperation =
						new imagine.objectOperations.CreateObjectOperation("PRectangle", dctProperties);
				coop.Do(_imgd);
				
				// Set the mask DocumentObject as its parent's mask
				var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(dob.name, { maskId: dctProperties.name });
				spop.Do(_imgd);
				_imgd.EndUndoTransaction();
			}
			_imgd.selectedItems = [ dob.mask ];
		}
		
		// The user clicked the mouse. Update the selection.
		// Returns true if the selection was changed.
		// UNDONE: Add multi-select support
		private function UpdateSelectionForClick(): Boolean {
			if (_imgd == null)
				return false;
				
			var doco:IDocumentObject = null;
			var fSelectionChanged:Boolean = false;
			
			// handle failure case
			if (!_imgd) return false;
			
			// Bounding box test to find all objects under the mouse
			var ptdMouse:Point = PtdFromPtl(new Point(mouseX, mouseY));
			var adoco:Array = FilterSelectionArray(_imgd.GetObjectsUnderPoint(ptdMouse, false));
			if (adoco.length > 0) {
				doco = adoco[0] as IDocumentObject;
				
				// If more than one object's bounding box intersects the mouse point
				// do a pixel level hit test to pick the one the user is hopefully
				// targeting. The pixel level test may return nothing, since all objects
				// may be transparent at that point. If so, fall back to the top most
				// object the bounding box test found.
				if (adoco.length > 1) {
					adoco = _imgd.GetObjectsUnderPoint(ptdMouse, true);
					if (adoco.length > 0)
						doco = adoco[0] as IDocumentObject;
				}
			}
			
			if (!doco) {
				fSelectionChanged = _imgd.selectedItems.length != 0;
				_imgd.selectedItems = null;
			} else {
				if (!_imgd.selectedItems || _imgd.selectedItems.indexOf(doco) == -1) {
					// ImageDocumentEvent.SELECTED_ITEMS_CHANGE event handling will cause
					// a corresponding controller to be created synchronously
					_imgd.selectedItems = [ doco ];
					fSelectionChanged = true;
				}
			}
			return fSelectionChanged;
		}

		// We have a variety of responses to mouse down events, in this priority order:
		// 1. If an object is clicked on, select it, forward the mouse down event to it,
		//    and disregard further mouse events.
		// 2. If an overlay exists let it handle the event
		// 3. Begin dragging (panning) the view
		private function OnMouseDown(evt:MouseEvent): void {
			setFocus();
			
			if (_nSelectMode != kNoSelection && _imgd) {
				// Perform a bounding box test to see if an object is under the mouse.
				// If there is more than one, disambiguate with a pixel-level hit test.
				// If there is none, clear the selection and fall into the overlay/view dragging tests
				
				UpdateSelectionForClick();
				if (_imgd.selectedItems.length > 0) {
					// UNDONE: Add multiple select support
					var doco:IDocumentObject = _imgd.selectedItems[0] as IDocumentObject;
					// Pass the mousedown event on to the newly selected object's controller
					// so it can begin dragging.
					var dococ:DocoController = FindController(doco);
					Debug.Assert(dococ != null, "DocumentObject should have a corresponding controller");
					var ptT:Point = dococ.globalToLocal(new Point(evt.stageX, evt.stageY));
					var evtT:MouseEvent = new MouseEvent(evt.type, false, false, ptT.x, ptT.y,
							doco as InteractiveObject, evt.ctrlKey, evt.altKey, evt.shiftKey,
							evt.buttonDown, evt.delta);
					dococ.dispatchEvent(evtT);
					
					evt.stopPropagation(); // NOTE: keeps focus from being set to the ImageView
					UpdateCursor();
					evt.updateAfterEvent();
					return;
				}
			}
			
			stage.addEventListener(MouseEvent.MOUSE_UP, OnCaptureMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, OnCaptureMouseMove);
			_fMouseDown = true;
			_xlMouseDown = mouseX;
			_ylMouseDown = mouseY;
			_xlViewOffsetDown = _xlViewOffset;
			_ylViewOffsetDown = _ylViewOffset;
			UpdateImageViewCursor();
			Cursor.Capture();

			if (!_fSpacebarDragMode && _ovl) {
				_ovl.OnOverlayPress(evt);
				evt.updateAfterEvent();
			}
		}

		private function OnCaptureMouseUp(evt:MouseEvent): void {
			if (_fMouseDown) {
				stage.removeEventListener(MouseEvent.MOUSE_UP, OnCaptureMouseUp);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnCaptureMouseMove);
				_fMouseDown = false;
				Cursor.Release();
				UpdateCursorMode();
				UpdateImageViewCursor();
				
				if (!_fSpacebarDragMode && _ovl) {
					_ovl.OnOverlayReleaseOutside();
					evt.updateAfterEvent();
				}
			}
		}
		
		private function OnMouseUp(evt:MouseEvent): void {
			stage.removeEventListener(MouseEvent.MOUSE_UP, OnCaptureMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnCaptureMouseMove);
			_fMouseDown = false;
			Cursor.Release();
			UpdateCursorMode();
			UpdateImageViewCursor();
			
			if (!_fSpacebarDragMode && _ovl) {
				_ovl.OnOverlayRelease();
				evt.updateAfterEvent();
			}
		}
		
		private function OnRollOver(evt:MouseEvent): void {
			_fMouseOverImageView = true;
			UpdateCursorMode();
		}
		
		private function OnRollOut(evt:MouseEvent): void {
			_fMouseOverImageView = false;
			UpdateCursorMode();
		}
		
		private function OnCaptureMouseMove(evt:MouseEvent): void {
			evt.updateAfterEvent();
			
			// Turn the cursor on/off when we enter/exit the stage
			if (evt.target == stage && !_fMouseOffStage) {
				_fMouseOffStage = true;
				cursorMode = knSystemCursorMode;
			} else if (evt.target != stage && _fMouseOffStage) {
				_fMouseOffStage = false;
				UpdateCursorMode();
			}
			
			if (!_fAlreadyHandledMove) {
				if (!_fSpacebarDragMode && _ovl && _ovl.OnOverlayMouseMoveOutside())
					return;
				DragView(evt);
			} else {
				_fAlreadyHandledMove = false; // Get ready for the next move
			}
		}
		
		private function OnMouseMove(evt:MouseEvent): void {			
			// Make sure we don't handle this move twice
			_fAlreadyHandledMove = true;
			evt.updateAfterEvent();

			if (!_fSpacebarDragMode && _ovl && _ovl.OnOverlayMouseMove())
				return;

			// Mouse may be over a moveable object
			UpdateImageViewCursor();
			
			if (!_fMouseDown)
				return;
				
			DragView(evt);
		}

		// Zoom so the point the mouse cursor is at will stay in place (subject
		// to the usual constraints)
		private function OnMouseWheel(evt:MouseEvent): void {
			var nZoomFactor:Number = (evt.delta > 0 ? 1.2 : 1 / 1.2);
			if (evt.delta == 0) nZoomFactor = 1; // Don't zoom.
			var nZoom:Number = zoom * nZoomFactor;
			if (nZoom < zoomMin)
				nZoom = zoomMin;
			else if (nZoom > zoomMax)
				nZoom = zoomMax;
			var ptLocal:Point = globalToLocal(new Point(evt.stageX, evt.stageY));
			ZoomAroundPoint(nZoom, ptLocal);
		}
		
		private function OnMouseDoubleClick(evt:MouseEvent): void {
			if (_ovl)
				_ovl.OnOverlayDoubleClick();
		}
		
		private function DragView(evt:MouseEvent): void {
			if (!_imgd)
				return;
				
			var xlViewOffsetCur:Number = _xlViewOffset;
			var ylViewOffsetCur:Number = _ylViewOffset;
				
			var cxvZoomed:Number = _cxBitmap * _nZoom;
			var cyvZoomed:Number = _cyBitmap * _nZoom;

			var dxl:Number = _xlMouseDown - mouseX;
			var dyl:Number = _ylMouseDown - mouseY;
			if (cxvZoomed > width)
				_xlViewOffset = _xlViewOffsetDown - dxl;
			if (cyvZoomed > height)
				_ylViewOffset = _ylViewOffsetDown - dyl;
				
			if (_xlViewOffset != xlViewOffsetCur || _ylViewOffset != ylViewOffsetCur)
				invalidateDisplayList();
		}

		private function OnKeyDown(evt:KeyboardEvent): void {
			// Keep track of the spacebar's state to support overlay-overriding view dragging
			if (evt.keyCode == Keyboard.SPACE && !_fMouseDown) {
				_fSpacebarDragMode = true;
				UpdateCursorMode();
			}
		}
		
		private function OnKeyUp(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.SPACE) {
				_fSpacebarDragMode = false;
				UpdateCursorMode();
			}
		}
		
		// Returns a view rect which represents the on screen portion of the document
		public function get onScreenDocumentViewRect(): Rectangle {
			if (!_imgd)
				return new Rectangle();

			var rcView:Rectangle = new Rectangle();
			rcView.left = Math.max(0, bitmapX);
			rcView.top = Math.max(0, bitmapY);
			if (_imgd.background) {
				try {
					rcView.bottom = Math.min(height, bitmapY + _imgd.background.height * zoom);
					rcView.right = Math.min(width, bitmapX + _imgd.background.width * zoom);
				} catch (e:InvalidBitmapError) {
					rcView.bottom = height;
					rcView.width = width;
				}
			} else {
				rcView.bottom = height;
				rcView.width = width;
			}
			return rcView;
		}
		
		// aspect ratio is width/height
		// scale factor is a target area modifier.
		//   > 1 means target area is larger, < 1 means target area is smaller
		public function GetDropSize(nAspectRatio:Number, nScaleFactor:Number=1, fStupid:Boolean=false): Point {
			var rcView:Rectangle = onScreenDocumentViewRect;
			var rcd:Rectangle = RcdFromRcl(rcView);
			
			// Sometimes objects should be sized relative to each other, not a calculated area of
			// the view. In that case, give them a height equal to 1/2 the width of the view.
			// Give them a width to match their height and the specified aspect ratio.
			// The caller will scale them down further based to size them relatively.
			if (fStupid) {
				var cy:Number = rcd.width / 2;
				var cx:Number = cy * nAspectRatio;
				return new Point(cx * nScaleFactor, cy * nScaleFactor); 
			}
			
			// Now we have the width and height. This is our special logic
			
			const knPreferredDropSizeAreaPct:Number = 1/9; // Drop size is 1/9 of what you can see
			const knMinBorderPct:Number = 0.1; // Never drop so large that you have less than this much border top or bottom
			const knMaxDropSizeAreaPct:Number = 1/5;
			
			const knMinWidthHeight:Number = 10; // Don't use area resizing if we get smaller than this
			const knAbsoluteMinWidthHeight:Number = 1; // Never resize smaller than this
			
			var nPreferredDropSizeAreaPct:Number = knPreferredDropSizeAreaPct * nScaleFactor;

	    	var nViewArea:Number = rcd.width * rcd.height;
			
	    	// First, choose a size that fits within our border limits
		    	
	    	// Now scale down to occupy 1/9 of the image area
	    	// Image area = xSize * ySize * nAreaScale * nAreaScale
	    	
	    	// If this is 1/9 of nViewArea, we have:
	    	// nAreaScale ^ 2 * ( xSize * y) = knPreferredAreaPct * nViewArea
	    	// or nAreaScale = sqrt( knPreferredAreaPct * nViewArea / ( xSize * y)
	    	
	    	var nAreaScale:Number = Math.sqrt(nPreferredDropSizeAreaPct * nViewArea / nAspectRatio);
		    	
	    	// Start with the area size
	    	var xSize:Number = nAreaScale * nAspectRatio;
	    	var ySize:Number = nAreaScale;
	    	
	    	// Next, scale down to fit with a bit of border around the sides
	    	var xMax:Number = rcd.width * (1-knMinBorderPct);
	    	if (xSize > xMax) {
	    		ySize *= xMax / xSize;
	    		xSize = xMax;
	    	}
		    	
	    	var yMax:Number = rcd.height * (1-knMinBorderPct);
	    	if (ySize > yMax) {
	    		xSize *= yMax / ySize;
	    		ySize = yMax;
		    }
		    	
	    	// Finally, resize back up so that we are tall/wide enough that we are selectable.
	    	if (xSize < knMinWidthHeight) {
	    		ySize *= knMinWidthHeight / xSize;
	    		xSize = knMinWidthHeight;
		    }
	    	if (xSize < knMinWidthHeight) {
	    		ySize *= knMinWidthHeight / xSize;
	    		xSize = knMinWidthHeight;
	    	}

		    return new Point(xSize, ySize);
		}
	}
}
