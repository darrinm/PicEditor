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
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;

	public class ImageBundle  {
        private var _aCallbacks:Array = [];
        private var _loaderInfo:LoaderInfo = null;
        private var _fLoaded:Boolean = false;

        public function ImageBundle(strUrl:String):void {
            var request:URLRequest = new URLRequest(strUrl);
            var loader:Loader = new Loader();
           
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, OnComplete);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, OnIOError);
            loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR , OnSecurityError);
            loader.load(request);
        }

        private function OnComplete(event:Event):void {
            _loaderInfo = LoaderInfo(event.target);
			DoCallbacks();
        }

        private function OnIOError(event:IOErrorEvent):void {
            _loaderInfo = null;
			DoCallbacks();
        }

        private function OnSecurityError(event:SecurityErrorEvent):void {
            _loaderInfo = null;
			DoCallbacks();
        }

		private function DoCallbacks(): void {
            _fLoaded = true;
			for each( var oCallback:Object in _aCallbacks ) {
				var id:String = oCallback.id;
				var fn:Function = oCallback.callback;
				GetClass( id, fn );
			}				
		}
		
        public function GetClass(id:String, fnCallback:Function):void {
        	if (!_fLoaded) {
        		// store the callback for later
        		_aCallbacks.push( {id: id, callback: fnCallback } );
        		return;
        	}        	
        	fnCallback(_GetImageClass(id));
        }
       
        private function _GetImageClass(id:String):Class {
        	var oBundle:Object = _loaderInfo ? _loaderInfo.applicationDomain.getDefinition("Bundle") as Object : null;
        	if (oBundle && id in oBundle) {
        		return oBundle[id] as Class;
        	}
        	return null;
        }
    }
}
