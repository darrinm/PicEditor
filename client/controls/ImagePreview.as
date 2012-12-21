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
package controls
{
	/** ImagePreview
	 * This class takes an image properties and displays the thumnbail.
	 * It is smart about checking to see if the imgae is in progress and if so
	 * displaying a progress bar instead of a thumbnail.
	 * In the case of an error, it will continue to display a progress bar.
	 * The container should detect error and handle them accordingly.
	 */
	import bridges.basket.BasketProgressBar;
	
	import imagine.documentObjects.DocumentStatus;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	
	import mx.controls.ProgressBar;
	
	import util.IPendingFile;
	import util.ImagePropertiesUtil;
	import util.PendingFileWrapper;
	import util.ThrottledPendingFileWrapper;
	
	[Event(name="showingSomethingChange", type="flash.events.Event")]

	public class ImagePreview extends ImagePlus
	{
		private var _imgp:ImageProperties = null;
		private var _pf:IPendingFile = null;
		
		private var _prgb:ProgressBar = null;
		private var _fThumbDone:Boolean = false;
		private var _fThumbLoadFailed:Boolean = false;
		
		public var forceLoad:Boolean = false;
		private var _fShowingSomething:Boolean = false;
		
		[Bindable ("showingSomethingChange")]
		public function set showingSomething(f:Boolean): void {
			if (_fShowingSomething != f) {
				_fShowingSomething = f;
				dispatchEvent(new Event("showingSomethingChange"));
			}
		}
		public function get showingSomething(): Boolean {
			return _fShowingSomething;
		}
		
		public function ImagePreview()
		{
			super();
			_pf = new PendingFileWrapper();
			addEventListener(Event.COMPLETE, OnThumbLoaded);
			addEventListener(IOErrorEvent.IO_ERROR, OnThumbError);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnThumbError);
		}
		
		private function OnThumbLoaded(evt:Event): void {
			thumbDone = true;
			ResetPendingFile();
		}
		
		private function OnThumbError(evt:Event): void {
			thumbDone = true;
			_fThumbLoadFailed = true;
			UpdateShowingSomething();
		}
		
		private function set thumbDone(f:Boolean): void {
			if (_fThumbDone == f) return;
			_fThumbDone = f;
			UpdateShowingSomething();
			UpdateProgress();
		}
		
		[Bindable]
		public function set imageProperties(imgp:ImageProperties): void {
			if (_imgp == imgp) return;
			_imgp = imgp;

			_fThumbLoadFailed = false; // Reset our state
			UpdateShowingSomething();
			
			// Check for dynamic load bits
			pendingFile = ImagePropertiesUtil.GetPendingFile(imgp, true);
		}
		
		private function set pendingFile(pf:IPendingFile): void {
			if (_pf != pf) {
				Debug.Assert(pf != null);
				_pf.removeEventListener(ProgressEvent.PROGRESS, OnPendingProgress);
				_pf.removeEventListener("statusupdate", OnPendingStatusUpdate);
				_pf.Unwatch();
				_pf = pf;
				_pf.addEventListener(ProgressEvent.PROGRESS, OnPendingProgress);
				_pf.addEventListener("statusupdate", OnPendingStatusUpdate);
				RemoveProgressBar();
			}
			UpdateProgress();
		}
		
		private function UpdateThumbnailUrl(): void {
			if (_fThumbLoadFailed)
				return;
			var strSource:String = (_pf.status >= DocumentStatus.Loaded && imageProperties != null) ? imageProperties.thumbnailurl : null;
			if (strSource != super.source) {
				super.source = strSource;
				if (forceLoad && strSource != null) load(strSource);
			}
		}
		
		private function OnPendingStatusUpdate(evt:Event): void {
			UpdateProgress();
		}
		
		private function OnPendingProgress(evt:Event): void {
			UpdateProgress();
		}
		
		protected function CreateProgressBar(): ProgressBar {
			return new BasketProgressBar();
		}
		
		protected override function measure():void {
			super.measure();
			if (_prgb) {
				if (isNaN(explicitWidth) && !isNaN(maxWidth))
					measuredWidth = maxWidth;
				if (isNaN(explicitHeight) && !isNaN(maxHeight))
					measuredHeight = maxHeight;
			}
		}
		
		private function RemoveProgressBar(): void {
			if (_prgb) {
				invalidateSize();
				// Remove it
				_prgb.parent.removeChild(_prgb);
				_prgb = null;
				UpdateShowingSomething();
			}
		}
		
		private function UpdateProgress(): void {
			var fShowProgBar:Boolean;
			
			// Logic:
			if (_prgb) {
				// If we are showing a progress bar, show it until the thumbnail loads
				fShowProgBar = !_fThumbDone;
			} else {
				// Not currently showing the progress bar.
				// Only start showing it if we are pending
				fShowProgBar = _pf.status == DocumentStatus.Loading && _pf.progress > 0;
			}
			
			var nPctLoaded:Number = 0;
			if (fShowProgBar) {
				// UNDONE: Displaying the thumbnail happens in three steps:
				// 1. Upload the bits
				// 2. Server resizes, returns upload complete
				// 3. Download the thumbnail
				
				// If the server is the bottleneck, item 2 (server resizes) is the slowest part
				// We could, in this case, start a timer and keep the progress bar moving.
				 nPctLoaded = _pf.progress;
				if (!_prgb) {
					invalidateSize();
					_prgb = CreateProgressBar();
					UpdateShowingSomething();
					addChild(_prgb);
					_prgb.validateNow();
					PositionProgressBar();
				}
				_prgb.setProgress(nPctLoaded * 100, 100);
			} else {
				if (_prgb) {
					RemoveProgressBar();
				}
			}
			UpdateThumbnailUrl();
		}
		
		protected function PositionProgressBar(): void {
			if (!_prgb) return;
			_prgb.x = 5;
			_prgb.width = width - 10;
			_prgb.y = (height - _prgb.height) / 2;
		}
		
		private function UpdateShowingSomething(): void {
			showingSomething = (_fThumbDone || _fThumbLoadFailed || _prgb);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			PositionProgressBar();
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
		public function get imageProperties(): ImageProperties {
			return _imgp;
		}
		
		private function ResetPendingFile(): void {
			// Make sure we clean up any throttled pending files
			if (_pf != null && (_pf is ThrottledPendingFileWrapper)) {
				pendingFile = new PendingFileWrapper();
			}
		}
		
		override public function set source(value:Object):void {
			thumbDone = false;
			if (value is ImageProperties) {
				imageProperties = value as ImageProperties;
			} else if (value is ItemInfo) {
					imageProperties = (value as ItemInfo).asImageProperties();
			} else {
				super.source = value;
				if (forceLoad && super.source != null) load(super.source);
				ResetPendingFile();
			}
		}
	}
}