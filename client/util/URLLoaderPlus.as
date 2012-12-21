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
package util {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	public class URLLoaderPlus extends URLLoader {
		public var fnComplete:Function;
		public var obContext:Object;
		
		protected var _nLogId:Number;
		protected var _timer:Timer = null;
		protected var _fnTimeout:Function = null;
		protected var _fCancelled:Boolean = false;
		protected var _fnComplete:Function = null;
		protected var _fnIOError:Function = null;
		protected var _fnProgress:Function = null;
		protected var _fnSecurityError:Function = null;
		
		private var _fLog:Boolean = true;
		
		
		public function URLLoaderPlus(request:URLRequest = null, fLog:Boolean=true) {
			_fLog = fLog;		
			addEventListener( Event.COMPLETE, _OnComplete )
			addEventListener( IOErrorEvent.IO_ERROR, _OnIOError )
			addEventListener( SecurityErrorEvent.SECURITY_ERROR, _OnSecurityError )
			if (request) load(request);
		}
		
		override public function load(request:URLRequest):void {
			// IE can only handle URLs that are < 2083 chars long.  We
			// want to know if we're trying to ask for something longer than that.
			if (request.url.length > 2000) {	
				var strLog:String = "URLLoaderPlus: URL is really long: " + request.url;
				PicnikService.Log(strLog, PicnikService.knLogSeverityError);
			}
			
			// Log the request and save the log id so we can log the response
			if (_fLog) _nLogId = URLLogger.LogRequest( request.url, request.data );
			super.load(request);		
		}
	
		private function _OnComplete(evt:Event): void {
			if (_fLog) URLLogger.LogResponse( _nLogId, "ok", this.data );
			CancelTimeout();
		}
		
		private function _OnIOError(evt:IOErrorEvent): void {
			if (_fLog) URLLogger.LogResponse( _nLogId, "ioerror", this.data );
			CancelTimeout();
		}
		
		private function _OnSecurityError(evt:Event): void {
			if (_fLog) URLLogger.LogResponse( _nLogId, "securityerror", this.data );
			CancelTimeout();
		}
		
		public function SetTimeout( cmsDelay:Number, fnTimeout:Function ) : void {
			_timer = new Timer( cmsDelay, 1 );
			_timer.addEventListener("timer", _OnTimeout);
			_fnTimeout = fnTimeout;
			_timer.start();
		}
		
		public function _OnTimeout( event:TimerEvent ) : void {		
			this.close();
			if (_fLog) URLLogger.LogResponse( _nLogId, "timeouterror", this.data );
			if (_fnTimeout != null) {
				_fnTimeout( event, this );
			}
		}
	
		public function CancelTimeout() : void {
			if (_timer != null) _timer.reset();
			_fnTimeout = null;
		}
	}
}