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
	import mx.core.Application;
	
	public class AlreadyCreated implements ICreator
	{
		private var _aobParams:Array;
		
		public function AlreadyCreated(err:Number, strError:String, fidAsset:String=null, strImportUrl:String=null)
		{
			Debug.Assert(strImportUrl != null);
			Debug.Assert(fidAsset != null);
			_aobParams = [err, strError, fidAsset, strImportUrl];
		}

		// Can be called multiple times - will always return the same results (and create only one file)
		//   fnCreated(err:Number, strError:String, fidAsset:String=null, strImportUrl:String=null): void
		public function Create(fnCreated:Function):void
		{
			Application.application.callLater(fnCreated, _aobParams);
		}
	}
}