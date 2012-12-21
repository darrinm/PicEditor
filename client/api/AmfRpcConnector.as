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
	/*
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.NetConnection;
	import flash.net.Responder;

	public class AmfRpcConnector implements IRpcConnector
	{
		public function AmfRpcConnector()
		{
		}

		public function GetType(): String {
			return "AMF RPC";
		}
		
		// fnSuccess = function(obResult:Object <may be null if error>): void
		// fnError = function(strError:String, err:Number=PicnikService.errFail): void
		public function CallMethod(strMethod:String, obParams:Object, fnSuccess:Function, fnError:Function, fSecure:Boolean): void {
			var nc:NetConnection = null;
			
			var fnCloseConnection:Function = function(): void {
				try {
					if (nc != null && nc.connected)
						nc.close();
					nc = null;
				} catch (e:Error) {
					trace("Ignoring error closing network connection: " + e);
				}
			}
			
			var fnOnError:Function = function(strError:String): void {
				fnCloseConnection();
				fnError(strError);
			};

			var fnOnSuccessResponse:Function = function(obResponse:Object): void {
				fnCloseConnection();
				fnSuccess(obResponse);
			};
			
			var fnNetConnectionError:Function = function(evt:Event): void {
				var strError:String = null;
				if (evt is NetStatusEvent) {
					var obInfo:Object = NetStatusEvent(evt).info;
					if (obInfo != null) {
						if ('level' in obInfo && obInfo.level == 'status')
							return; // Not a failure
						if ('code' in obInfo)
							strError = "NetStatusEvent[" + obInfo.code + "]";
					}
				}
				if (strError == null)
					strError = String(evt);
				fnOnError("NetConnection failure: " + strError);
			};
			
			var fnOnErrorResponse:Function = function(obErrorInfo:Object): void {
				var strError:String = "";

				if ('code' in obErrorInfo)
					strError += obErrorInfo.code;
				if ('description' in obErrorInfo)
					strError += ", " + obErrorInfo.description;

				trace("Call faulted: " + strError);
				if ('details' in obErrorInfo)
					trace("    " + obErrorInfo.details);

				if (strError.length == 0)
					strError = "Unknown";
				fnOnError("Call faulted: " + strError);
			}
			
			try {
				fnCloseConnection(); // Clear any previous connection
				nc = new NetConnection();
				
				// Listen for net connection failure events
				nc.addEventListener(IOErrorEvent.IO_ERROR, fnNetConnectionError);
				nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, fnNetConnectionError);
				nc.addEventListener(NetStatusEvent.NET_STATUS, fnNetConnectionError);
				nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnNetConnectionError);
				
				// Establish the connection
				// UNDONE: Support HTTPS
				if (fSecure)
					throw new Error("Secure connections not yet implemented");
				var strUrl:String = PicnikService.serverURL + "/api/amfrpc";
				nc.connect(strUrl);
				
				// Set responder property to the object and methods that will receive the
				// result or fault condition that the service returns.
				var rspndr:Responder = new Responder( fnOnSuccessResponse, fnOnErrorResponse );
				
				// Call remote service to fetch data
				trace("Call: " + strMethod);
				nc.call( strMethod, rspndr, obParams);
			} catch (e:Error) {
				fnOnError("Exception making rpc call: " + e.toString());
			}
		}
	}
	*/
}