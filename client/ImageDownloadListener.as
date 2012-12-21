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
package {
	// ImageDownloadListener converts a variety of image Loader callbacks into
	// unified progress and done callbacks.
	
	// ImageDownloadListener has no dependencies other than on its passed-in args.
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.*;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	import imagine.ImageDocument;
	
	public class ImageDownloadListener {
		private var _fnProgress:Function;
		private var _fnDone:Function;
		private var _obData:Object;
		private var _ldr:Loader;
		private var _nOnInitDelayTimer:uint;
		private var _fAutoDispose:Boolean = true;
		
		// Callback signatures:
		//   fnProgress(ldr:Loader, cbLoaded:Number, cbTotal:Number, obData:Object): void
		//   fnDone(ldr:Loader, err:Number, strError:String, obData:Object): void
		public function ImageDownloadListener(ldr:Loader, fnProgress:Function, fnDone:Function, obData:Object=null) {
			_ldr = ldr;
			_fnProgress = fnProgress;
			_fnDone = fnDone;
			_obData = obData;
			
			with (ldr.contentLoaderInfo) {
				addEventListener(Event.COMPLETE, OnComplete);
				addEventListener(IOErrorEvent.IO_ERROR, OnIOError);
				addEventListener(ProgressEvent.PROGRESS, OnProgress);
				addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnSecurityError);
				addEventListener(HTTPStatusEvent.HTTP_STATUS, OnHTTPError);
			}
		}
		
		// some objects want to hold onto the loader for a while, so we don't automatically
		// dispose ourselves when we're complete.  Instead, we'll let them call Dispose() for us.
		public function get autoDispose():Boolean {
			return _fAutoDispose;
		}
		
		public function set autoDispose( f:Boolean ):void {
			_fAutoDispose = f;
		}
		
		public function Dispose(): void {			
			if (_ldr && _ldr.contentLoaderInfo) {
				with (_ldr.contentLoaderInfo) {
					removeEventListener(Event.COMPLETE, OnComplete);
					removeEventListener(IOErrorEvent.IO_ERROR, OnIOError);
					removeEventListener(ProgressEvent.PROGRESS, OnProgress);
					removeEventListener(SecurityErrorEvent.SECURITY_ERROR, OnSecurityError);
					removeEventListener(HTTPStatusEvent.HTTP_STATUS, OnHTTPError);
				}
				try {
					_ldr.unload();
					_ldr.close();
				} catch (e:Error) {}
				_ldr = null;
			}
			_fnProgress = null;
			_fnDone = null;
			_obData = null;
		}
		
		public function CancelDownload(): void {
			if (_fAutoDispose)
				Dispose();			
		}
		
		private function OnComplete(evt:Event): void {
			// Delay the callback for 1/10th of a second so any progress bar will be updated at 100%
			_nOnInitDelayTimer = setTimeout(OnDelayedComplete, 100);
		}
		
		private function OnDelayedComplete():void {
			// Note that between the time OnComplete is called and the time this function is called,
			// we may have been cancelled and disposed. 
			if (null != _fnDone) _fnDone(_ldr, ImageDocument.errNone, "no error", _obData);
			clearTimeout( _nOnInitDelayTimer );
			if (_fAutoDispose)
				Dispose();			
		}
		
		private function OnProgress(evt:ProgressEvent): void {
			if (_fnProgress != null)
				_fnProgress(_ldr, evt.bytesLoaded, evt.bytesTotal, _obData);
		}
		
		private function OnSecurityError(evt:SecurityErrorEvent): void {
			trace("ImageDownloadListener.onSecurityError: " + evt.target.name + " strError: " + evt.text);
			_fnDone(null, ImageDocument.errBaseImageDownloadFailed, evt.text, _obData);
			if (_fAutoDispose)
				Dispose();			
		}
		
		// We hit this error under the following circumstances:
		// - the server is not running
		private function OnIOError(evt:IOErrorEvent): void {
			trace("ImageDownloadListener.onIOError: " + evt.text);
			_fnDone(null, ImageDocument.errBaseImageDownloadFailed, evt.text, _obData);
			if (_fAutoDispose)
				Dispose();			
		}
	
		private function OnHTTPError(evt:HTTPStatusEvent): void {
			if (evt.status != 0 && evt.status != 200) {
				trace("ImageDownloadListener.onHTTPError: " + LoaderInfo(evt.target).url + ", error " + evt.status);
				// We will receive OnIOError callbacks for failures. We don't want to
				// call _fnDone twice so we'll leave it to to the OnIOError handler.
//				_fnDone(null, ImageDocument.errBaseImageDownloadFailed, "HTTP error " + evt.status, _obData);
			}
		}
	}
}
