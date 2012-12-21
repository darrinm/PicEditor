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
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.core.Application;
	
	public class TemplateManager
	{
		private static var _sm:TemplateManager = new TemplateManager();
		private var _strError:String = null;
		
		private var _ts:TemplateStructure = null;
		
		private var _afnCallbacks:Array = [];
		private var _nNoCacheKey:Number;
		
		// Loads Templates.xml and calls a callback.
		// Retuns true if the callback was called because Templates were already loaded.
		// fnComplete signature:
		//   void OnGetTemplateList(atsect:ArrayCollection): void {
		public static function GetTemplateList(astrCMSStages:Array, fShowHiddenGroups:Boolean, fnComplete:Function): Boolean {
			return TemplateManager._sm._GetTemplateList(astrCMSStages, fShowHiddenGroups, fnComplete);
		}
		
		public static function get templateStructure(): TemplateStructure {
			return _sm._ts;
		}
		
		public function TemplateManager(): void {
			_nNoCacheKey = Math.random();
		}
		
		// Loads Templates.xml and calls a callback.
		// Retuns true if the callback was called because Templates were already loaded.
		private function _GetTemplateList(astrCMSStages:Array, fShowHiddenGroups:Boolean, fnComplete:Function): Boolean {
			var adctPropsResult:Array = null;
			var fReturned:Boolean = false;
			
			var fnOnGotEverything:Function = function(): void {
				if (fReturned) return;
				fReturned = true;
				fnComplete(_ts.GetStructuredList(adctPropsResult, fShowHiddenGroups));
			}
			
			var fnOnGotTemplateStructure:Function = function(ts:TemplateStructure): void {
				if (fReturned) return; // Already returned an error
				
				if (_strError || !ts) {
					fReturned = true;
					fnComplete(null); // There was an error
				} else {
					if (adctPropsResult != null)
						fnOnGotEverything(); // All done
				}
			}
			
			var fnOnGetTemplateList:Function = function(err:Number, strError:String, adctProps:Array=null): void {
				if (fReturned) return; // Already returned an error
				
				if (err != PicnikService.errNone) {
					fReturned = true;
					trace("error getting templates: " + err + ", " + strError);
					fnComplete(null);
				}
				adctPropsResult = adctProps;
				if (_ts) {
					fnOnGotEverything();
				}
				
			}
			
			PicnikService.GetTemplateList(astrCMSStages, fnOnGetTemplateList);
			
			GetTemplateStructure(fnOnGotTemplateStructure);
			return false;
		}
		
		private static function TemplatesBasePath(): String {
			return "../app/" + CONFIG::locale + "/";
		}

		// fnDone = function(ts:TemplateStructure)
		private function GetTemplateStructure(fnDone:Function): void {
			_afnCallbacks.push(fnDone);
			
			if (_ts != null) {
				Application.application.callLater(CallTemplateStructureLoadedCallbacks);
				return;
			}
			
			// Load a new one each time the client loads. This makes our template groups more dynamic.
			var strUrl:String = PicnikBase.StaticUrl( TemplateManager.TemplatesBasePath() + "templates.xml?nocache=" + _nNoCacheKey );

			var urlr:URLRequest = new URLRequest(strUrl);

			// Add the URLLoader event listeners before firing off the load so we will
			// be sure to catch any up-front errors (e.g. URLRequest validation)			
			var urll:URLLoader = new URLLoader();
			urll.addEventListener(Event.COMPLETE, OnTemplateStructureLoaded);
			urll.addEventListener(IOErrorEvent.IO_ERROR, OnTemplateStructureError);
			urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnTemplateStructureError);
			urll.load(urlr);
		}
		
		private function OnTemplateStructureLoaded(evt:Event): void {
			_strError = null;
			//try {
				_ts = new TemplateStructure(new XML((evt.target as URLLoader).data));
			//} catch (e:Error) {
			//	_strError = e.toString();
			//}
			CallTemplateStructureLoadedCallbacks();
		}
		
		private function OnTemplateStructureError(evt:Event): void {
			var strError:String = "";
			if ("text" in evt) strError = evt["text"];
			_strError = strError;
			CallTemplateStructureLoadedCallbacks();
		}
		
		private function CallTemplateStructureLoadedCallbacks(): void {
			while (_afnCallbacks.length > 0) {
				var fnDone:Function = _afnCallbacks.pop();
				fnDone(_ts);
			}
		}
	}
}
