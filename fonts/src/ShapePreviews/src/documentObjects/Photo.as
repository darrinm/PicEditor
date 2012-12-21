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
package documentObjects {
	import controls.ProxyImage;
	
	import events.DocumentObjectEvent;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	
	import mx.controls.SWFLoader;
	
	import objectOperations.CreateObjectOperation;
	
	import util.IAssetSource;

	[Bindable]
	public class Photo extends PhotoSWFLoader {
		[Embed(source="/assets/bitmaps/loadErrorFill.gif")]
		public static var s_clsErrorFill:Class;
		
		private var _dai:int = -1; // -1 == no asset
		private var _aobSizes:Array = null;

		private static const kanSizes:Array = [160,320,640,1280,2800];
		private static const knFullSize:Number = 100000;

		private var _pimgThumb:ProxyImage = null;
		private var _nFitMethod:Number = FitMethod.SNAP_TO_EXACT_SIZE;
		
		private var _nFitWidth:Number;
		private var _nFitHeight:Number;
		
		private var _nBaseWidth:Number = 0;
		private var _nBaseHeight:Number = 0;

		private var _fSizesValid:Boolean = true;
		
		private var _nSourceRotation:Number = 0;

		private var _fLoadingSizes:Boolean = false;
		
		public var isSwf:Boolean = false;
		
		/** Photo
		 * A photo is tied to an asset id
		 * In addition, photos know how to load different URLs for displaying content
		 *
		 * On initial load, a photo might load a temporary thumbnail to display
		 * while loading the asset
		 *
		 * Once the asset loads, the photo calculates its absolute document dimension and then
		 * loads the next larger size photo
		 *
		 * Photos have a fit size and a fit method. At a scale of 1x1, a photo tries to
		 * be the fit sized (based on the fit method).
		 *
		 * Before the asset has been loaded, we use the thumbnail and size accordingy to the
		 * thumbnail aspect ratio.
		 *
		 * Once the asset has been loaded, we get the dimensions of the asset and use these
		 * to calculate our unscaled size.
		 *
		 * Thereafter, the unscaled width and height should not change (unless we change our fit method
		 * or fit size).
		 *
		 * When different resolutions of the asset are loaded, they are scaled down in the content
		 * object to meet our fit unscaled width and height.
		 */
		
		public function Photo(): void {
			addEventListener(DocumentObjectEvent.ABSOLUTE_SCALE_CHANGE, OnAbsoluteScaleChange);
		}
		
		/*
		private static var _snNextId:Number = 0;
		private var _nId:Number = -1;
		override public function toString():String {
			if (_nId == -1) _nId = _snNextId++;
			var strAssetRef:String = String(_dai);
			if (_dai > -1 && document) {
				if (_dai in document.assets) {
					strAssetRef += "->" + document.assets[_dai];
				} else {
					strAssetRef += "->???";
				}
			}
			return "[Photo:" + _nId + ", dai=" + _dai + ", url=" + (url?(url.substr(0,10)+"..."):url) + "]";
		}
		*/
		
		override public function set unscaledHeight(cy:Number): void {
			if (unscaledHeight == cy) return;
			super.unscaledHeight = cy;
			OnAbsoluteScaleChange();
		}
		
		override public function set unscaledWidth(cx:Number):void {
			if (unscaledWidth == cx) return;
			super.unscaledWidth = cx;
			OnAbsoluteScaleChange();
		}
		
		//
		// IDocumentObject interface
		//
		
		public override function get serializableProperties(): Array {
			var astrProps:Array = super.serializableProperties;
			
			// Remove the url property - we use the asset ref only
			astrProps.splice(astrProps.indexOf("url"), 1);
			
			astrProps = astrProps.concat(["assetRef", "fitWidth", "fitHeight", "fitMethod", "baseWidth", "baseHeight", "sourceRotation", "isSwf"]);
			
			return astrProps;
		}

		public function set sourceRotation(n:Number): void {
			n = Math.round(n / 90) * 90;
			while (n > 270) n -= 360;
			while (n < 0) n += 360;
			if (n == _nSourceRotation) return;
			var nDeltaRotation:Number = n - _nSourceRotation;
			_nSourceRotation = n;
			while (nDeltaRotation < 0) nDeltaRotation += 360;
			if ((Math.round(nDeltaRotation / 90)) % 2) {
				// switched orientation
				InvalidateSizes();
			}
			UpdateTransform();
			SizeNewContent(content); // Make sure our content is sized correctly
		}
		
		protected function get contentWidth(): Number {
			return contentSize.x;
		}
		
		protected function get contentHeight(): Number {
			return contentSize.y;
		}

		// ROTMATH: Rotate loaded dimensions
		override protected function GetLoaderDims(ldr:SWFLoader): Point {
			var ptDims:Point = super.GetLoaderDims(ldr);
			if ((ldr != _pimgThumb) && (sourceRotation == 90 || sourceRotation == 270))
				ptDims = new Point(ptDims.y, ptDims.x); // Rotate
			
			return ptDims;
		}

		// ROTMATH: Adjust base content with rotated size in mind
		// Could use "unrotated" unscaled dims to set content
		override protected function SizeNewContent(dobContent:DisplayObject): void {
			// Setting width & height really sets the scaleX/Y, which in turn causes
			// width/height to change. Ends up like this: scaleX = new width / old width
			if (!dobContent) return;
			if (!contentIsThumb && (sourceRotation == 90 || sourceRotation == 270)) {
				dobContent.width = unscaledHeight;
				dobContent.height = unscaledWidth;
			} else {
				dobContent.width = unscaledWidth;
				dobContent.height = unscaledHeight;
			}
		}

		// ROTMATH: Rotated base content size
		protected function get contentSize(): Point {
			var ptSize:Point = null;
			if (content != null) {
				try {
					if (content.loaderInfo != null) {
						ptSize = new Point(content.loaderInfo.width, content.loaderInfo.height);
						if (!contentIsThumb && (sourceRotation == 90 || sourceRotation == 270))
							ptSize = new Point(ptSize.y, ptSize.x);
					}
				} catch (e:Error) {
					trace("Error getting content loaderinfo size: " + e);
					ptSize = null;
				}
				if (ptSize == null)
					ptSize = new Point(content.width, content.height);
			}
			Debug.Assert(ptSize.x > 0 && ptSize.y > 0);
			return ptSize;
		}
		
		public function get sourceRotation(): Number {
			return _nSourceRotation;
		}
		
		override protected function UpdateTransform():void {
			super.UpdateTransform();
			if (content == null || sourceRotation == 0 || baseHeight < 1 || baseWidth < 1 || contentIsThumb) return;
			if (!contentIsThumb) {
				content.rotation = sourceRotation;
				if (sourceRotation == 90 || sourceRotation == 180)
					content.x += unscaledWidth;
					
				if (sourceRotation == 180 || sourceRotation == 270)
					content.y += unscaledHeight;
			}
		}
		
		public function set baseWidth(n:Number): void {
			if (_nBaseWidth != n) {
				_nBaseWidth = n;
				InvalidateSizes();
			}
		}
		
		public function get baseWidth(): Number {
			return _nBaseWidth;
		}
		
		public function set baseHeight(n:Number): void {
			if (_nBaseHeight != n) {
				_nBaseHeight = n;
				InvalidateSizes();
			}
		}
		
		public function get baseHeight(): Number {
			return _nBaseHeight;
		}
		
		public override function get typeName(): String {
			return "Photo";
		}

		public override function get objectPaletteName(): String {
			return "Photo";
		}

		// Deserialize is called after all child objects have been deserialized and must
		// initialize this instance's properties.
		public function Deserialize(xml:XML): void {
			// HACK: for backwards compatiblity with the few files that have been saved with
			// Photo objects having 'url' properties.
			var ob:Object = Util.ObFromXmlProperties(xml);
			delete ob.url;
			for (var strProp:String in ob)
				this[strProp] = ob[strProp];
		}
		
		private function get contentIsThumb(): Boolean {
			return (_pimgThumb && content && content == _pimgThumb.content);
		}
		
		private function CancelThumbLoad(): void {
			if (!_pimgThumb) return;
			if (contentIsThumb) {
				content = null; // Remove the thumbnail if we are displaying it
			}
			RemoveThumbLoadEvents();
			_pimgThumb.source = "";
			_pimgThumb = null;
		}
		
		override protected function HandleLoadFailure(): void {
			super.HandleLoadFailure();
			CancelThumbLoad();
			SetContentPlaceholder();
		}
		
		private function SetContentPlaceholder(): void {
			var shp:flash.display.Shape = new flash.display.Shape();
			var bm:Bitmap = new s_clsErrorFill();
			shp.graphics.beginBitmapFill(bm.bitmapData);
			shp.graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			shp.graphics.endFill();
			content = shp;
			shp.alpha = 0.5;
		}
		
		protected override function SetUnscaledSize(cx:Number, cy:Number):void {
			unscaledWidth = cx;
			unscaledHeight = cy;
			if (content) SizeNewContent(content);
		}

		private function OnGetFileProperties(err:Number, strError:String, dctProps:Object=null): void {
			_fLoadingSizes = false;
			if (err != PicnikService.errNone) {
				// Huh? Something is broken. Give up.
				HandleLoadFailure();
				trace("Photo.OnGetFileProperties error: " + err + ", " + strError);
				return;
			}
			if (dctProps.nWidth == undefined || dctProps.nHeight == undefined) {
				// Huh? Something is broken. Give up.
				HandleLoadFailure();
				trace("Photo.OnGetFileProperties error: properties undefined");
				return;
			}
			if (dctProps.nRotation != undefined)
				sourceRotation = dctProps.nRotation;

			if ('strMimeType' in dctProps && dctProps['strMimeType'] == 'application/x-shockwave-flash')
				isSwf = true;
			baseWidth = dctProps.nWidth;
			baseHeight = dctProps.nHeight;
			
			// Force the next stage of loading to happen right now. Helps deserialization of
			// rasterizedObjects to complete.
			Validate();
		}

		private function get rotatedBaseWidth(): Number {
			return (sourceRotation == 90 || sourceRotation == 270) ? baseHeight : baseWidth;
		}		
		
		private function get rotatedBaseHeight(): Number {
			return (sourceRotation == 90 || sourceRotation == 270) ? baseWidth : baseHeight;
		}		
		
		private function InvalidateSizes(): void {
			_fSizesValid = false;
			Invalidate();
		}
		
		public override function Validate():void {
			super.Validate();
			ValidateSizes();
		}
		
		private function ValidateSizes(): void {
			if (_fSizesValid) return;
			
			_fSizesValid = true;
			
			if (assetRef < 0) return;
			
			if (baseHeight < 1 || baseWidth < 1) {
				LoadSizesAndRotation();
			} else {
				UpdateSizes();
			}
		}
		
		private function UpdateSizes(): void {
			//document.DumpStatus(this + ".UpdateSizes(" + baseWidth + ")");
			_aobSizes = [];
			if (baseWidth < 1 || baseHeight < 1) {
				return;
			}
			
			// Make sure we are backwards compatible
			// Now that we have a real size, check to see if we have a fit size
			// If not, generate one assuming that the fit is the full size, exactly
			if (isNaN(fitWidth))
				fitWidth = baseWidth;
			if (isNaN(fitHeight))
				fitHeight = baseHeight;
			if (isNaN(fitMethod))
				fitMethod = FitMethod.SNAP_TO_EXACT_SIZE;
			
			var ptRealSize:Point = CalculateFitDims(rotatedBaseWidth / rotatedBaseHeight);
			SetUnscaledSize(ptRealSize.x, ptRealSize.y);
			
			for each (var nSize:Number in kanSizes) {
				var xSize:Number = nSize;
				var ySize:Number = nSize;
				if (rotatedBaseWidth > rotatedBaseHeight)
					ySize = Math.max(1,Math.round(xSize * rotatedBaseHeight / rotatedBaseWidth));
				else
					xSize = Math.max(1,Math.round(ySize * rotatedBaseWidth / rotatedBaseHeight));
				if ( ((xSize * 1.1) < rotatedBaseWidth) && ((ySize * 1.1) < rotatedBaseHeight) ) {
					_aobSizes.push({nSize:nSize, ptSize:new Point(xSize,ySize), url:GetAssetURL(nSize)});
				} else {
					break;
				}
			}
			_aobSizes.push({nSize:Math.max(rotatedBaseWidth, rotatedBaseHeight), ptSize:new Point(rotatedBaseWidth, rotatedBaseHeight), url:GetAssetURL()});

			if (parent is IDocumentObject)
				IDocumentObject(parent).Invalidate();
			
			LoadLargerSizeIfNeeded();
		}
		
		private function GetAssetURL(nSize:Number=0): String {
			var strRef:String = null;
			if (nSize > 0) strRef = "thumb" + nSize;
			return document.GetAssetURL(assetRef, strRef);
		}
		
		// Aspect ratio is width / height
		private function CalculateFitDims(nAspectRatio:Number): Point {
			if (isNaN(nAspectRatio) || nAspectRatio == 0)
				nAspectRatio = 1;
			var xSize:Number;
			var ySize:Number;
			
			switch (_nFitMethod) {
				case FitMethod.SNAP_TO_MIN_WIDTH_HEIGHT:
					// First, try setting xSize
					xSize = fitWidth;
					ySize = xSize / nAspectRatio;
					if (ySize < fitHeight) {
						ySize = fitHeight;
						xSize = ySize * nAspectRatio;
					}
					break;
				case FitMethod.SNAP_TO_MAX_WIDTH_HEIGHT:
					// First, try setting xSize
					xSize = fitWidth;
					ySize = xSize / nAspectRatio;
					if (ySize > fitHeight) {
						ySize = fitHeight;
						xSize = ySize * nAspectRatio;
					}
					break;
				case FitMethod.SNAP_TO_AREA:
					// Maintain aspect ratio and area
					var nArea:Number = fitWidth * fitHeight;
					// xSize * ySize = nArea
					// xSize / ySize = nAspectRatio
					// => nArea/ySize == nAspectRatio * ySize ==> ySize * ySize = nArea / nAspectRatio
					ySize = Math.sqrt(nArea / nAspectRatio);
					xSize = nArea / ySize;
					break;
				default:
					// fall through
				case FitMethod.SNAP_TO_EXACT_SIZE:
					xSize = fitWidth;
					ySize = fitHeight;
					break;
			}
			
			return new Point(xSize, ySize);
		}
		
		//
		// Photo
		//
		public function set assetRef(dai:int): void {
			if (_dai != dai) {
				_dai = dai;
				
				if (dai == -1) {
					// This case isn't used (has no use?) but it is a way to clear out a loaded image.
					// If it were used it would probably screw stuff up.
					Unload();
				} else {
					if (status != DocumentStatus.Preview)
						status = DocumentStatus.Loading;
					// When we set the asset ref, we need to get the real size and also start
					// loading whatever size we think we will want.
					// This is where we start our load. Get the sizes, whatever.
				}
				InvalidateSizes();
			}
			//document.DumpStatus(this + ".set asset ref");
		}
		
		private function BetterSizeAvailable(ptSize:Point): Boolean {
			if (!hasRealSize) return false;
			if (_pimgThumb && _pimgThumb.content == content) return true;
			return GetBestSize(ptSize).nSize > currentSize;
		}
		
		private function get currentSize(): Number {
			if (content == null || content.loaderInfo == null) return 0;
			if (_pimgThumb && _pimgThumb.content == content) return 0;
			return Math.max(content.loaderInfo.width, content.loaderInfo.height);
		}
		
		private function GetBestSize(ptAbsoluteSize:Point): Object {
			if (!hasRealSize) return null;
			
			var obSize:Object = null;
			for each (obSize in _aobSizes) {
				var ptSize:Point = obSize.ptSize;
				if (ptSize.x > ptAbsoluteSize.x && ptSize.y > ptAbsoluteSize.y)
					return obSize;
			}
			return obSize;
		}
			
		// Returns true if loading a new size
		private function LoadLargerSizeIfNeeded(): Boolean {
			var ptUnscaledSize:Point = new Point(unscaledWidth, unscaledHeight);
			
			var ptScale:Point = DocumentObjectUtil.GetDocumentScale(this);
			var ptAbsoluteSize:Point = new Point(ptUnscaledSize.x * ptScale.x, ptUnscaledSize.y * ptScale.y);
			
			if (isLoading) return false; // Already loading something
			if (BetterSizeAvailable(ptAbsoluteSize)) {
				LoadAssetForSize(ptAbsoluteSize);
				return true;
			} else {
				return false;
			}	
		}
		
		private function OnAbsoluteScaleChange(evt:Event=null): void {
			if (!content) return;
			LoadLargerSizeIfNeeded();
		}
		
		private function LoadAssetForSize(ptAbsoluteSize:Point): void {
			if (status >= DocumentStatus.Loaded)
				status = DocumentStatus.Preview;
			url = GetBestSize(ptAbsoluteSize).url;
			//document.DumpStatus(this + ".set url");
		}
		
		private function get hasRealSize(): Boolean {
			return _aobSizes != null && _aobSizes.length > 0;
		}
		
		override protected function OnLoadComplete(evt:Event):void {
			CancelThumbLoad();
			super.OnLoadComplete(evt);
			//document.DumpStatus(this + ".LoadComplete");
		}
		
		override protected function PostLoadSizeUpdate(ldr:SWFLoader):void {
			UpdateChildSize();
		}
		
		override protected function PostLoadStatusUpdate(): void {
			var nStatus:Number = DocumentStatus.Preview;
			if (hasRealSize && !LoadLargerSizeIfNeeded())
				nStatus = DocumentStatus.Loaded;
			status = nStatus;
			//document.DumpStatus("Post load status update: " + nStatus);
		}
		
		public function get assetRef(): int {
			return _dai;
		}

		private function OnLoadThumbError(evt:Event): void {
			RemoveThumbLoadEvents();
			// Thumb failed to load. Ignore it.
			trace("thumb load error: " + evt);
		}

		private function RemoveThumbLoadEvents(): void {
			if (!_pimgThumb) return;
			_pimgThumb.removeEventListener(IOErrorEvent.IO_ERROR, OnLoadThumbError);
			_pimgThumb.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, OnLoadThumbError);
			_pimgThumb.removeEventListener(Event.COMPLETE, OnLoadThumbComplete);
			_pimgThumb.removeEventListener(ProgressEvent.PROGRESS, OnLoadThumbProgress);
		}
		
		private function OnLoadThumbComplete(evt:Event): void {
			RemoveThumbLoadEvents();
			if (content == null) CompleteLoad(_pimgThumb);
		}
		
		private function OnLoadThumbProgress(evt:ProgressEvent): void {
			OnLoadProgress(evt);
		}
		
		public function set fitWidth(n:Number): void {
			if (_nFitWidth == n) return;
			_nFitWidth = n;
			UpdateChildSize();
		}
		
		public function get fitWidth(): Number {
			return _nFitWidth;
		}
		
		public function set fitHeight(n:Number): void {
			if (_nFitHeight == n) return;
			_nFitHeight = n;
			UpdateChildSize();
		}
		
		public function get fitHeight(): Number {
			return _nFitHeight;
		}
		
		// DEPRECATED: renamed to fitWidth
		public function set targetWidth(n:Number): void {
			fitWidth = n;
		}
		
		public function get targetWidth(): Number {
			return fitWidth;
		}
		
		// DEPRECATED: renamed to fitHeight
		public function set targetHeight(n:Number): void {
			fitHeight = n;
		}
		
		public function get targetHeight(): Number {
			return fitHeight;
		}
		
		public function set fitMethod(n:Number): void {
			if(_nFitMethod == n) return;
			_nFitMethod = n;
			UpdateChildSize();
		}
		
		public function get fitMethod(): Number {
			return _nFitMethod;
		}
		
		private function UpdateChildSize(): void {
			if (!content) return;
			var ptChildSize:Point = CalculateFitDims(contentWidth / contentHeight);
			SetUnscaledSize(ptChildSize.x, ptChildSize.y);
		}

		public static function Create(imgd:ImageDocument, asrc:IAssetSource, ptFitSize:Point, ptd:Point,
				nFitMethod:Number, nViewZoom:Number, strParentId:String=null, strMaskId:String=null): DisplayObject
		{ 
			var strThumbSource:String = asrc.thumbUrl;
			
 			var fnOnAssetCreated:Function = function(err:Number, strError:String, fidCreated:String=null): void {
 				if (err != PicnikService.errNone) {
 					phNew.status = DocumentStatus.Error;
 				}
 			}
 			
			var dai:int = imgd.CreateAsset(asrc, fnOnAssetCreated);
			var dctProperties:Object = {
				assetRef: dai,
				x: ptd.x, y: ptd.y, scaleX: 1, scaleY: 1, previewUrl: strThumbSource,
				fitWidth: ptFitSize.x, fitHeight: ptFitSize.y, fitMethod: nFitMethod,
				previewWidth: ptFitSize.x * nViewZoom, previewHeight: ptFitSize.y * nViewZoom
			};
			
			if (strParentId)
				dctProperties.parent = strParentId;

			// Create a Photo DocumentObject
			var coop:CreateObjectOperation = new CreateObjectOperation("Photo", dctProperties);
			coop.Do(imgd);

			// Select the newly created object
			var phNew:Photo = imgd.getChildByName(dctProperties.name) as Photo;
			if (strThumbSource) {
				phNew.LoadThumb(strThumbSource);
			} else {
				phNew.status = DocumentStatus.Loading;
			}
			
			phNew.LoadSizesAndRotation();
			
			return phNew;
		}
		
		private function LoadSizesAndRotation(): void {
			if (_fLoadingSizes) return;
			
			// Start the two requests
			document.GetAssetProperties(assetRef, "nWidth,nHeight,nRotation,strMimeType", OnGetFileProperties);
		}
		
		private function LoadThumb(strThumbSource:String): void {
			status = DocumentStatus.Loading;
			// We have a thumbnail, load it
			_pimgThumb = new ProxyImage();
			_pimgThumb.addEventListener(IOErrorEvent.IO_ERROR, OnLoadThumbError);
			_pimgThumb.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnLoadThumbError);
			_pimgThumb.addEventListener(Event.COMPLETE, OnLoadThumbComplete);
			_pimgThumb.addEventListener(ProgressEvent.PROGRESS, OnLoadThumbProgress);
			_pimgThumb.offscreen = true;
			_pimgThumb.source = strThumbSource;
		}
	}
}
