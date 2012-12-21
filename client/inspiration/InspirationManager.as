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
package inspiration
{
	import api.PicnikRpc;
	import api.RpcResponse;
	
	import controls.InspirationTipBase;

	public class InspirationManager
	{
		[Bindable]
		public static var inst:InspirationManager = new InspirationManager(); // Default is dummy
		
		private static var intp:InspirationTipBase = null; // Hard coded reference to tip base so that it gets compiled into PicnikBase.
		
		public function InspirationManager(aobData:Array=null, fTest:Boolean=false)
		{
			if (aobData != null) {
				ParseData(aobData, fTest);
			}
		}
		
		private var _obMapKeyToInspiration:Object = {};
		
		public function GetInspiration(strKey:String): Inspiration {
			strKey = strKey.toLowerCase();
			if (strKey in _obMapKeyToInspiration)
				return _obMapKeyToInspiration[strKey];
			trace("inspiration not found:", strKey);
			return null; // None found
		}
		
		private function ParseData(aobData:Array, fTest:Boolean): void {
			_obMapKeyToInspiration = {};
			for each (var obInsp:Object in aobData) {
				if (obInsp.fLive || fTest) {
					var insp:Inspiration = new Inspiration(obInsp);
					for each (var strTag:String in insp.tags) {
						_obMapKeyToInspiration[strTag.toLocaleLowerCase()] = insp;
					}
				}
			}
		}
		
		private static var _fLoaded:Boolean = false;
		public static function Load(fTest:Boolean=false): void {
			if (!fTest && _fLoaded)
				return; // Ignore double loads
			
			PicnikRpc.GetInspiration(fTest, function(rpcresp:RpcResponse): void {
				if (!rpcresp.isError) {
					inst = new InspirationManager(rpcresp.data.adInspiration as Array, fTest);
				} else {
					_fLoaded = false; // Failed to load
				}
			});
			
			var inspMgr:InspirationManager = new InspirationManager();
			_fLoaded = true;
		}
	}
}