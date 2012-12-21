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
package imagine.documentObjects {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.PixelSnapping;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.getQualifiedClassName;
	
	import imageDocument.DisplayObjectPool;
	
	import overlays.helpers.RGBColor;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class PSWFLoader extends DocumentObjectBase {
		private var _strUrl:String = null;
		private var _fListening:Boolean = false;
		private var _ldr:Loader;
		private var _nRetries:Number = 0;
		private static const knMaxRetries:Number = 2;
		public var toolTip:String;
		
		public var previewUrl:String = null;
		public var previewWidth:Number;
		public var previewHeight:Number;
		
		public var initialWidth:Number = NaN;
		
		// Assume SWFs are vector by default
		private var _fVector:Boolean = true;
		
		private var _bmdLoaded:BitmapData = null;
		
		public override function get serializableProperties(): Array {
			return super.serializableProperties.concat([ "url", "isVector" ]);
		}
		
		public override function get typeName(): String {
			return "Picture";
		}
		
		override protected function SizeNewContent(dobContent:DisplayObject): void {
			dobContent.width = unscaledWidth;
			dobContent.height = unscaledHeight;
		}

		private function ClearOldContent(): void {
			if (_bmdLoaded != null) {
				content = null;
				_bmdLoaded.dispose();
				_bmdLoaded = null;
			}
		}

		[Bindable]
		public function set url(strUrl:String): void {
			if (_strUrl != strUrl) {
				ClearOldContent();
				_strUrl = strUrl;
				if (strUrl == null || strUrl == "") {
					Unload();
				} else {
					StartLoad(strUrl);
				}
			}
		}
		
		public override function Dispose():void {
			super.Dispose();
			ClearOldContent();
			url = null;
		}
		
		public function get url(): String {
			return _strUrl;
		}
		
		protected function Unload(): void {
			status = DocumentStatus.Loading;
			if (_ldr) {
				try {
					RemoveLoadEvents();
					_ldr.close();
				} catch (e:Error) {
					// Ignore close errors. Might already be closed/unloaded
				}
				_ldr = null;
			}
			Invalidate();
		}

		protected function StartLoad(strUrl:String, nRetries:Number=0): void {
			if (_fListening) {
				RemoveLoadEvents();
			}
			
			var ldr:Loader = DisplayObjectPool.Get(strUrl) as Loader;
			if (ldr) {
				CompleteLoad(ldr);
			} else {
				_ldr = new Loader();
				var lc:LoaderContext = new LoaderContext();
				lc.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
	
				if (status != DocumentStatus.Preview)
					status = DocumentStatus.Loading;
				AddLoadEvents();
				if (nRetries > 0) {
					strUrl = PicnikService::AppendUrl(strUrl,
							{ "try": nRetries + 1, nocache: Math.random() });
				}
				_ldr.load(new URLRequest(PicnikBase.StaticUrl(urlBasePath + strUrl)), lc);
			}
			Invalidate();
		}
		
		private function AddLoadEvents(): void {
			if (!_fListening) {
				_fListening = true
				_ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, OnLoadError);
				_ldr.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnLoadError);
				_ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, OnLoadComplete);
				_ldr.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, OnLoadProgress);
			}
		}
		
		protected function OnLoadProgress(evt:ProgressEvent): void {
			if (status == DocumentStatus.Loading)
				fractionLoaded = evt.bytesLoaded / evt.bytesTotal;
		}
		
		// Called with IOErrorEvents and SecurityErrorEvents
		private function OnLoadError(evt:Event): void {
			RemoveLoadEvents();
			var strError:String = "";
			if (evt is IOErrorEvent) {
				strError = "IO Error: " + (evt as IOErrorEvent).text;
			} else if (evt is SecurityErrorEvent) {
				strError = "Security Error: " + (evt as SecurityErrorEvent).text;
			}
			if (_nRetries < knMaxRetries) {
				// Retry
				_nRetries++;
				StartLoad(_strUrl, _nRetries);
				PicnikService.Log("Retry loading " + typeName + " after load error: " + strError, PicnikService.knLogSeverityDebug);
			} else {
				HandleLoadFailure();
				PicnikService.Log("Failed to load " + typeName + " with error: " + strError + ", url = " + _strUrl, PicnikService.knLogSeverityWarning);
			}
		}
		
		protected function HandleLoadFailure(): void {
			document.LogLoadFailure(getQualifiedClassName(this) + ": " + _strUrl);
			status = DocumentStatus.Error;
		}
		
		protected function GetLoaderDims(ldr:Loader): Point {
			if (ldr == null) return new Point(0,0);
			return new Point(ldr.content.loaderInfo.width, ldr.content.loaderInfo.height);
		}
			
		protected function PostLoadSizeUpdate(ldr:Loader): void {
			var ptLoadedDims:Point = GetLoaderDims(ldr);
			SetUnscaledSize(ptLoadedDims.x, ptLoadedDims.y);
			if (!isNaN(initialWidth)) {
				// Use the preview width to adjust our scale
				scaleX = scaleY = initialWidth / ptLoadedDims.x;
				initialWidth = NaN;
			}
			if (content) SizeNewContent(content);
		}
		
		protected function OnLoadComplete(evt:Event): void {
			CompleteLoad(_ldr);
		}
		
		private function CompleteLoad(ldr:Loader): void {
			if (ldr == _ldr)
				RemoveLoadEvents();
			ClearOldContent();
				
			// Resize to fit within the old dims if they have default values
			if (ldr == null || ldr.content == null || ldr.content.height == 0 || ldr.content.width == 0) {
				content = null;
			} else {
				var fBitmapized:Boolean = false;
				if (isVector) {
					content = ldr as DisplayObject;
				} else {
					// Bitmap SWFs need to be a multiple of 4 pixels wide and high to be filtered nicely
					// by the Flash Player. Instead of leaving it to chance we draw bitmap SWFs into a
					// multiple-of-4 padded bitmap and keep that around instead of the original SWF.
					var ptLoadedDims:Point = GetLoaderDims(ldr);
					var cx:int = Math.ceil(ptLoadedDims.x);
					var cy:int = Math.ceil(ptLoadedDims.y);
					if (cx & 3 != 0 || cy & 3 != 0) {
						var cxPadded:int = (cx + 3) & ~3;
						var cyPadded:int = (cy + 3) & ~3;
						// UNDONE: When is this disposed? Only when the shape happens to be gc'ed
						_bmdLoaded = new VBitmapData(cxPadded, cyPadded, true, 0x00000000, "PSwf 4 pix aligned bitmap copy: " + _strUrl);
						var mat:Matrix = new Matrix();
						mat.translate(int((cxPadded - cx) / 2), int((cyPadded - cy) / 2));
						_bmdLoaded.draw(ldr, mat);
						var bmT:Bitmap = new Bitmap(_bmdLoaded, PixelSnapping.AUTO, true);
						content = bmT;
						fBitmapized = true;
					} else {
						content = ldr as DisplayObject;
					}
				}
				PostLoadSizeUpdate(ldr);
				
				// If this DocumentObject is responsible for the Loader (i.e. not pulled from the
				// DisplayObjectPool) and has bitmap-ized it then we can discard the Loader to
				// save memory.
				if (ldr == _ldr && fBitmapized) {
					ldr.unload();
					_ldr = null;
				}
					
				var bm:Bitmap = (content is Loader) ? Loader(content).content as Bitmap : content as Bitmap;
				if (bm != null) {
					bm.smoothing = true;
					bm.pixelSnapping = PixelSnapping.AUTO;
				} else {
					UpdateBlendMode();
				}
				SetContentColor(color);
				PostLoadStatusUpdate();
			}
		}
		
		protected function PostLoadStatusUpdate(): void {
			status = DocumentStatus.Static;
		}
		
		private function RemoveLoadEvents(): void {
			if (_ldr) {
				_ldr.removeEventListener(IOErrorEvent.IO_ERROR, OnLoadError);
				_ldr.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, OnLoadError);
				_ldr.removeEventListener(Event.COMPLETE, OnLoadComplete);
				_ldr.removeEventListener(ProgressEvent.PROGRESS, OnLoadProgress);
			}
			_fListening = false;
		}
		
		//
		//
		//
		
		public function PSWFLoader(strUrl:String=null, clr:uint=0, strToolTip:String=null) {
			super();
			url = strUrl;
			color = clr;
			if (strToolTip) toolTip = strToolTip;
		}
		
		public function set isVector(fVector:Boolean): void {
			_fVector = fVector;
		}
		
		public function get isVector(): Boolean {
			return _fVector;
		}
		
		protected function get urlBasePath(): String {
			return "";
		}
		
		// We want SWFs to be completely drawn before they are composited. This way their
		// internal construction (overlapping polygons) won't be unpleasantly revealed.
		// BlendMode.LAYER is the key.
		private function UpdateBlendMode(): void {
			if (content == null)
				return;
				
			// BlendMode.LAYER is slower because it buffers to a bitmap prior to compositing.
			// Only use it for SWFs with less than full alpha.
			if (!(content is Bitmap) && (/*blendMode != BlendMode.NORMAL ||*/ alpha != 1.0))
				content.blendMode = BlendMode.LAYER;
			else
				content.blendMode = BlendMode.NORMAL;
		}
		
		protected function get isLoading(): Boolean {
			return _fListening;
		}
					
		[Bindable]
		override public function set color(clr:uint): void {
			super.color = clr;
			SetContentColor(clr);
		}
		
		override public function set alpha(alpha:Number): void {
			super.alpha = alpha;
			UpdateBlendMode();
		}
		
		private function SetContentColor(clr:uint): void {
			if (content) {
				content.transform.colorTransform = GetColorTransform(clr);
			}
		}
		
		private function GetColorTransform(clr:Number): ColorTransform {
			var mat:Array = new Array();
			var nR:Number = RGBColor.RedFromUint(clr);
			var nG:Number = RGBColor.GreenFromUint(clr);
			var nB:Number = RGBColor.BlueFromUint(clr);
			var nRM:Number = (255-nR)/255;
			var nGM:Number = (255-nG)/255;
			var nBM:Number = (255-nB)/255;
			
			return new ColorTransform(nRM, nGM, nBM, 1, nR, nG, nB);
		}
	}
}
