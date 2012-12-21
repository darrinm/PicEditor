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
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	
	import mx.core.MovieClipLoaderAsset;

	public class InternalSwfLoader
	{
		private var _obInfo:Object;
		
		public function InternalSwfLoader(obInfo:Object)
		{
			_obInfo = obInfo;
		}
		
		// fnComplete(): void {}
		public function Load(fnComplete:Function): void {
			var cls:Class = _obInfo['class'];
			var dob:DisplayObject = new cls();
			_obInfo.dob = dob;
			var doc:DisplayObjectContainer = dob as DisplayObjectContainer;
			var ldr:Loader = dob as Loader;
			
			if (ldr == null && doc != null && doc.numChildren > 0)
				ldr = doc.getChildAt(0) as Loader;
			
			if (ldr != null) {
				var fnOnSwfInit:Function = function (evt:Event): void {
					LoaderInfo(evt.target).removeEventListener(Event.INIT, fnOnSwfInit);
					fnComplete();
				};
				ldr.contentLoaderInfo.addEventListener(Event.INIT, fnOnSwfInit);
			} else {
				fnComplete();
			}
		}
			
	}
}