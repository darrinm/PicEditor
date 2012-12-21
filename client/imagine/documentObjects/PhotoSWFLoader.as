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
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.PixelSnapping;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.utils.getQualifiedClassName;
	
	import mx.controls.SWFLoader;
	
	import overlays.helpers.RGBColor;
	
	[RemoteClass]
	public class PhotoSWFLoader extends DocumentObjectBase {
		//
		// IDocumentObject interface
		//
		
		private var _strUrl:String = null;
		private var _fListening:Boolean = false;
		private var _ldr:SWFLoader;
		private var _nRetries:Number = 0;
		private static const knMaxRetries:Number = 2;
		public var toolTip:String;
		
		public var previewUrl:String = null;
		public var previewWidth:Number;
		public var previewHeight:Number;
		
		public var initialWidth:Number = NaN;
		
		public override function get serializableProperties(): Array {
			return super.serializableProperties.concat([ "url" ]);
		}
		
		public override function get typeName(): String {
			return "Picture";
		}
		
		override protected function SizeNewContent(dobContent:DisplayObject): void {
			dobContent.width = unscaledWidth;
			dobContent.height = unscaledHeight;
		}
		
		[Bindable]
		public function set url(strUrl:String): void {
			if (_strUrl != strUrl) {
				_strUrl = strUrl;
				if (strUrl == null || strUrl == "") {
					Unload();
				} else {
					StartLoad(strUrl);
				}
			}
		}
		
		public function get url(): String {
			return _strUrl;
		}
		
		protected function Unload(): void {
			status = DocumentStatus.Loading;
			_ldr.source = null;
			Invalidate();
		}
		
		protected function StartLoad(strUrl:String, nRetries:Number=0): void {
			if (_fListening) throw new Error("already loading...");
			_ldr = new SWFLoader();
			
			if (status != DocumentStatus.Preview)
				status = DocumentStatus.Loading;
			AddLoadEvents();
			if (nRetries > 0) {
				strUrl = PicnikService::AppendUrl(strUrl,
						{ "try": nRetries + 1, nocache: Math.random() });
			}
			_ldr.load(urlBasePath + strUrl);
			Invalidate();
		}
		
		private function AddLoadEvents(): void {
			if (!_fListening) {
				_fListening = true
				_ldr.addEventListener(IOErrorEvent.IO_ERROR, OnLoadError);
				_ldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnLoadError);
				_ldr.addEventListener(Event.COMPLETE, OnLoadComplete);
				_ldr.addEventListener(ProgressEvent.PROGRESS, OnLoadProgress);
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
		
		protected function GetLoaderDims(ldr:SWFLoader): Point {
			if (ldr == null) return new Point(0,0);
			return new Point(ldr.content.loaderInfo.width, ldr.content.loaderInfo.height);
		}
			
		protected function PostLoadSizeUpdate(ldr:SWFLoader): void {
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
		
		protected function CompleteLoad(ldr:SWFLoader): void {
			if (ldr == _ldr) RemoveLoadEvents();
			// Resize to fit within the old dims if they have default values
			if (ldr.contentWidth == 0 || ldr.contentHeight == 0) {
				content = null;
			} else {
				content = ldr.content as DisplayObject;
				PostLoadSizeUpdate(ldr);
				if (content is Bitmap) {
					Bitmap(content).smoothing = true;
					Bitmap(content).pixelSnapping = PixelSnapping.AUTO;
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
			if (_fListening) {
				_ldr.removeEventListener(IOErrorEvent.IO_ERROR, OnLoadError);
				_ldr.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, OnLoadError);
				_ldr.removeEventListener(Event.COMPLETE, OnLoadComplete);
				_ldr.removeEventListener(ProgressEvent.PROGRESS, OnLoadProgress);
				_fListening = false;
			}
		}
		
		//
		//
		//
		
		public function PhotoSWFLoader(strUrl:String=null, clr:uint=0, strToolTip:String=null) {
			super();
			url = strUrl;
			color = clr;
			if (strToolTip) toolTip = strToolTip;
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
