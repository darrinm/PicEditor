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
	import imagine.imageOperations.SwfOverlayImageOperation;
	import imagine.imageOperations.paintMask.DisplayObjectBrush;

	public class InternalAssetLoader
	{
		public var loading:Boolean = false;
		public var loaded:Boolean = false;
		private var _afnCallbacks:Array = [];
		
		public function InternalAssetLoader()
		{
		}
		
		// fnComplete(): void {}
		public function Load(fnComplete:Function=null): void {
			_afnCallbacks.push(fnComplete);
			if (loaded) {
				DoCallbacks();
			} else if (!loading) {
				StartLoading();
			}
		}
		
		private function DoCallbacks(): void {
			while (_afnCallbacks.length > 0) {
				var fnCallback:Function = _afnCallbacks.pop();
				if (fnCallback != null)
					fnCallback();
			}
		}
		
		private function StartLoading(): void {
			loading = true;
			var afnLoaders:Array = GetInternalLoaders();
			var cLoaded:Number = 0;
			var fnOnLoaded:Function = function(): void {
				cLoaded++;
				if (cLoaded >= afnLoaders.length) {
					loaded = true;
					loading = false;
					DoCallbacks();
				}
			}
			for each (var fnLoad:Function in afnLoaders) {
				fnLoad(fnOnLoaded);
			}
		}

		private function GetInternalLoaders(): Array {
			var afnLoaders:Array = [];
			// Array elements are functions like this:
			// function Load(fnComplete:Function): void {}
			// fnComplete = function(): void {}
			SwfOverlayImageOperation.GetInternalLoaders(afnLoaders);
			
			var fnLoadBrushes:Function = function(fnOnLoaded:Function): void {
				DisplayObjectBrush.Init(function (err:Number, strError:String): void {
					fnOnLoaded();
				});
			}
			afnLoaders.push(fnLoadBrushes);
			return afnLoaders;
		}
	}
}