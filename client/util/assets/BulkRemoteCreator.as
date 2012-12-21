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
package util.assets
{
	public class BulkRemoteCreator implements ICreator
	{
		private var _brfp:BulkRemoteFilePeers;
		private var _nIndex:Number;
		
		public function BulkRemoteCreator(brfp:BulkRemoteFilePeers, nIndex:Number)
		{
			_brfp = brfp;
			_nIndex = nIndex;
		}

		//   fnCreated(err:Number, strError:String, fidAsset:String=null, strImportUrl:String=null): void
		public function Create(fnCreated:Function):void
		{
			_brfp.Create(fnCreated, _nIndex);
		}
	}
}