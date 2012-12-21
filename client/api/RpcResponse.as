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
	public class RpcResponse
	{
		public var errorCode:Number = PicnikService.errNone;
		public var errorMessage:String = null;
		public var data:Object = null;
		public var method:String = null;
		
		public function RpcResponse(strMethod:String, err:Number, strError:String, obData:Object)
		{
			method = strMethod;
			errorCode = err;
			errorMessage = strError;
			data = obData;
			
			if ((errorCode != PicnikService.errNone) && (errorMessage == null))
				errorMessage = "Unknown";
		}
		
		public function get isError(): Boolean {
			return errorCode != PicnikService.errNone;
		}
		
		public function toString(): String {
			return "RpcResponse[" + (isError ? (errorCode + ", "  + errorMessage) : data) + "]";
		}
	}
}