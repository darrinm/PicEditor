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
package api
{
	import com.adobe.crypto.MD5;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.NetConnection;
	import flash.net.ObjectEncoding;
	import flash.net.Responder;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;

	/**
	 * This class imlements a custom version of AMF rpc.
	 * It is different from the AmfRpcConnector as follows:
	 *  - Custom code is easier to figure out what is going on
	 *  - Makes it possible to do checksums
	 *  - Is not built in which makes things a tad more complicated and possibly less efficient
	 **/
	public class PicnikAmfConnector implements IRpcConnector
	{
		private var _fUseGet:Boolean;
		public function PicnikAmfConnector(fUseGet:Boolean=false)
		{
			_fUseGet = fUseGet;
		}

		public function GetType(): String {
			return "Picnik AMF";
		}
		
		// fnSuccess = function(obResult:Object <may be null if error>): void
		// fnError = function(strError:String): void
		public function CallMethod(strMethod:String, obParams:Object, fnSuccess:Function, fnError:Function, fSecure:Boolean): void {
			var strUrl:String = null;
			var urll:URLLoader;

			fnError("PicnikAmfConnector.CallMethod not yet implemented", PicnikService.errNotYetImplemented);
		}
	}
}