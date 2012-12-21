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
package util
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class CollageDocTemplateLoader
	{
		private var _fnComplete:Function = null; // When null, this is canceled.
		private var _urll:URLLoader = null;
		private var _fid:String = null;
		private var _dctProps:Object = null;
		private static var _obTemplatePropsCache:Object = {};
		
		// Start the load right away
		// fnComplete(nError:Number, strError:String, xmlTemplate:XML=null, dctProperties:Object=null): void
		public function CollageDocTemplateLoader(fid:String, dctProps:Object, fnComplete:Function)
		{
			_dctProps = dctProps;
			if (_dctProps == null && fid in _obTemplatePropsCache) _dctProps = _obTemplatePropsCache[fid];
			if (fnComplete != null && fid != null) {
				_fid = fid;
				_fnComplete = fnComplete;
				StartLoad();
			}
		}

		private function StartLoad(): void {
			var fnOnGetFileProperties:Function = function(err:Number, strError:String, dctProps:Object=null): void {
				if (_fnComplete == null) return; // Canceled
				if (err != PicnikService.errNone) {
					_fnComplete(err, strError);
					return; // Error
				}
				// If we get here, we have properties and the load call has not been canceled.
				_dctProps = dctProps;
				_obTemplatePropsCache[dctProps.nFileId] = dctProps; // Add it to our cache

				// Now load the pik file
				_urll = new URLLoader();
				AddLoaderEvents();
				var strTemplateUrl:String = PicnikService.GetFileURL(_fid);
				_urll.load(new URLRequest(strTemplateUrl));
			}
			if (_dctProps != null) {
				fnOnGetFileProperties(PicnikService.errNone, null, _dctProps);
			} else {
				PicnikService.GetFileProperties(_fid, null, null, fnOnGetFileProperties);
			}
		}

		private function OnDocTemplateLoaded(evt:Event): void {
			// Done loading. Do something
			if (_fnComplete == null) return; // canceled
			
			var nError:Number = PicnikService.errNone;
			var strError:String = null;
			
			var xmlDocTemplate:XML = null;
			
			try {
				var strData:String = evt.target.data;
				xmlDocTemplate = new XML(strData);
				
			} catch (e:Error) {
				trace("Error parsing document: " + e);
				nError = PicnikService.errFail;
				strError = e.toString();
			}

			RemoveLoaderEvents();
			_urll = null;
			
			_fnComplete(nError, strError, xmlDocTemplate, _dctProps);
		}

		private function OnDocTemplateError(evt:Event): void {
			RemoveLoaderEvents();
			_urll = null;
			if (_fnComplete == null) return; // canceled
			
			trace("error loading doc template: " + evt.toString());
			
			_fnComplete(PicnikService.errFail, evt.toString());
		}

		// Stop any loading. Don't do any callbacks
		public function Cancel(): void {
			_fnComplete = null;
			if (_urll == null) return;
			RemoveLoaderEvents();
			_urll.close();
			_urll = null;
		}

		private function AddLoaderEvents(): void {
			_urll.addEventListener(Event.COMPLETE, OnDocTemplateLoaded);
			_urll.addEventListener(IOErrorEvent.IO_ERROR, OnDocTemplateError);
			_urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnDocTemplateError);
		}
		
		private function RemoveLoaderEvents(): void {
			_urll.removeEventListener(Event.COMPLETE, OnDocTemplateLoaded);
			_urll.removeEventListener(IOErrorEvent.IO_ERROR, OnDocTemplateError);
			_urll.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, OnDocTemplateError);
		}

	}
}