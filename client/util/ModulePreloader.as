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
	import flash.events.Event;
	import flash.events.EventDispatcher;

	import mx.events.ModuleEvent;
	import mx.modules.IModuleInfo;
	import mx.modules.ModuleManager;

	public class ModulePreloader extends EventDispatcher {
		static private var instance:ModulePreloader = null;
		static private var requests:Array = new Array();

		static public var COMPLETE:String = "modulePreloadComplete";

		public function ModulePreloader() {
			if (instance != null) {
				throw new Error(
					"ModulePreloader can only be accessed through ModulePreloader.Instance");
			}
		}

		static public function get Instance() : ModulePreloader {
			if (instance == null) {
				instance = new ModulePreloader();
			}
			return instance;
		}

		public function AddModule(url:String, priority:int): void {
			var found:Boolean = false;
			for each (var request:Object in requests) {
				if (request.url == url) {
					if (request.priority == priority) {
						// duplicate
						return;
					}
					else {
						trace("ModulePreloader: AddModule: " + url + ": adjusting priority: " +
							request.priority.toString() + " => " + priority.toString());
						request.priority = priority;
						found = true;
						break;
					}
				}
			}
			if (!found) {
				trace("ModulePreloader: AddModule: " + url + ": priority: " + priority.toString());
				requests.push({ url : url, priority : priority});
			}
			requests.sortOn("priority", Array.NUMERIC);
		}

		public function Start() : void {
			trace("ModulePreloader: Start");
			LoadNextModule();
		}

		private function LoadNextModule() : void {
			while (requests.length > 0) {
				var request:Object = requests.pop();
				var module:IModuleInfo = ModuleManager.getModule(request.url);
				if (module.loaded) {
					trace("ModulePreloader: LoadNextModule: " + request.url + ": already loaded");
					continue;
				}
				trace("ModulePreloader: LoadNextModule: " + request.url + ": priority: " +
					request.priority.toString());
				module.addEventListener(ModuleEvent.SETUP, function (evt:Event) : void {
					trace("ModulePreloader: LoadNextModule: " + request.url + ": setup complete");
					dispatchEvent(new ModulePreloadEvent(ModulePreloadEvent.COMPLETE, request.url));
					LoadNextModule();
				});
				module.addEventListener(ModuleEvent.ERROR, function (evt:Event) : void {
					trace("ModulePreloader: LoadNextModule: " + request.url + ": load error");
					LoadNextModule();
				});
				module.load();
				break;
			}
		}
	}

	// TODO: possible to get information from ModuleManager about when it's busy?
	//       possible to remove modules from our list when ModuleManager has loaded them?
}