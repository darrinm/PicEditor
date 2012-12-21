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
package imagine.documentObjects.frameObjects
{
	import imagine.documentObjects.DocumentStatus;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	[Event(name="status_changed", type="documentObjects.frameObjects.FrameObjectEvent")]

	public class FrameLoader extends EventDispatcher
	{
		private var _nStatus:Number = DocumentStatus.Loaded;
		
		private var _aldr:Array = [];
		private var _obLoaders:Object = {};
		
		public function FrameLoader()
		{
			var ldr:Loader;
		}
		
		public function get status(): Number {
			return _nStatus;
		}
		
		public function set status(n:Number): void {
			if (_nStatus != n) {
				_nStatus = n;
				dispatchEvent(new FrameObjectEvent(FrameObjectEvent.STATUS_CHANGED));
			}
		}
		
		private function GetUrlArray(aobShapes:Array): Array {
			var obUrlsSeen:Object = {};
			var astrUrls:Array = [];
			
			for each (var obShape:Object in aobShapes) {
				var strUrl:String = obShape.url;
				if (!(strUrl in obUrlsSeen)) {
					obUrlsSeen[strUrl] = true;
					astrUrls.push(strUrl);
				}
			}
			return astrUrls;
		}
		
		public function UpdateShapes(aobShapes:Array): void {
			var astrUrls:Array = GetUrlArray(aobShapes);
			var obNewUrls:Object = {};
			var strUrl:String;
			for each (strUrl in astrUrls)
				obNewUrls[strUrl] = true;
				
			// First, remove unused loaders, keep used ones.
			var aldrPrev:Array = _aldr;
			_aldr = [];
			_obLoaders = {};
			for each (var ldr:ClipartLoader in aldrPrev) {
				if (ldr.url in obNewUrls)
					ReAddLoader(ldr);
				else
					DisposeLoader(ldr);
			}
			
			// Now add new loaders
			for each (strUrl in astrUrls) {
				if (!(strUrl in _obLoaders))
					AddNewLoader(strUrl);
			}
			UpdateStatus();
		}
		
		public function GetLoader(strUrl:String): ClipartLoader {
			return _obLoaders[strUrl];
		}

		private function AddNewLoader(strUrl:String): void {
			var ldr:ClipartLoader = new ClipartLoader(strUrl);
			ldr.addEventListener(FrameObjectEvent.STATUS_CHANGED, UpdateStatus);
			ReAddLoader(ldr);
		}

		private function ReAddLoader(ldr:ClipartLoader): void {
			_aldr.push(ldr);
			_obLoaders[ldr.url] = ldr;
		}
		
		private function DisposeLoader(ldr:ClipartLoader): void {
			ldr.removeEventListener(FrameObjectEvent.STATUS_CHANGED, UpdateStatus);
			try {
				ldr.unloadAndStop(true);
			} catch (e:Error) {
				// unloadAndStop failed. Do a basic unload
				ldr.unload();
			}
		}
		
		private function UpdateStatus(evt:Event=null): void {
			var nStatus:Number = DocumentStatus.Static;
			for each (var ldr:ClipartLoader in _aldr)
				nStatus = Math.min(nStatus, ldr.status);
			status = nStatus;
		}
	}
}