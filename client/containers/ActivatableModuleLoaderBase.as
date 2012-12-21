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
package containers {
	import creativeTools.ICreativeTool;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.utils.setTimeout;
	
	import mx.containers.ViewStack;
	import mx.controls.ProgressBar;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ModuleEvent;
	import mx.modules.IModuleInfo;
	import mx.modules.ModuleLoader;
	import mx.modules.ModuleManager;
	
	import util.ITabContainer;
	import util.ModulePreloadEvent;
	import util.ModulePreloader;

	public class ActivatableModuleLoaderBase extends ModuleLoader implements IActivatable, IActionListener {
		static public var READY:String = "activatableModuleLoaderBaseReady";
		
		[Bindable] public var activatableId:String;
		[Bindable] public var _vstk:ViewStack;
		[Bindable] public var _pb:ProgressBar;
		[Bindable] public var initParams:Object = null;
		
		public var googlePlus:Boolean = false;
		public var googlePlusExclusive:Boolean = false;
		
		// prevents this bridge from appearing in the navbar, even if it's selected
		[Bindable] public var NoNavBar:Boolean = false;
		
		private var _fActive:Boolean = false;
		private var _act:Object;
		private var _cRetries:int = 0;
		private var _strPendingUrl:String = null;
		private var _strCmd:String = null;
		
		public function ActivatableModuleLoaderBase() {
			currentState = "Preloading";
			addEventListener(ModuleEvent.READY, OnReady);
	        addEventListener(ModuleEvent.PROGRESS, OnProgress);
	        addEventListener(ModuleEvent.SETUP, OnSetup);
	        addEventListener(ModuleEvent.ERROR, OnError);
			ModulePreloader.Instance.addEventListener(
				ModulePreloadEvent.COMPLETE, OnPreloadComplete);
			
			addEventListener(FlexEvent.ADD, OnAdd);
			addEventListener(FlexEvent.REMOVE, OnRemove);
		}
		
		static private var s_strExtraSpaces:String = "";
		
		private var _strPendingTabSelection:String = null;
		
		private var _clTabIcon:Class = null;
		private var _fAdded:Boolean = false;
		private var _fPendingIconStyleChange:Boolean = false;
		
		private function OnAdd(evt:FlexEvent): void {
			_fAdded = true;
			if (_fPendingIconStyleChange) {
				this.icon = _clTabIcon;
				_fPendingIconStyleChange = false;
			}
		}
		
		private function OnRemove(evt:FlexEvent): void {
			_fAdded = false;
		}
		
		override public function styleChanged(strStyleProp:String):void
		{
			var clTabIcon:Class = getStyle("tabIcon") as Class;
			if (_clTabIcon != clTabIcon) {
				_clTabIcon = clTabIcon;
				if (_fAdded)
					this.icon = _clTabIcon;
				else
					_fPendingIconStyleChange = true;
			}
		}
		
	    override public function set url(value:String):void {
	    	if (value == null) {
	    		// always let NULL urls pass through
	    		super.url = null;
	    		return;
	    	}
	    	
			_strPendingUrl = value;
			var module:IModuleInfo = ModuleManager.getModule(_strPendingUrl);
			if (_fActive || module.loaded) {
				LoadPendingUrl();
			}
		}

		private function LoadPendingUrl():void {
			currentState = "Loading";
			super.url = _strPendingUrl;
			_strPendingUrl = null;
		}
	   
	   	protected function OnVersionMismatch(strStamp1:String, strStamp2:String): void {
			// Log the failed load to the server
			PicnikService.Log("Module load from " + url + " version mismatch. Module:" + strStamp1 + "; Client:" + strStamp2, PicnikService.knLogSeverityMonitor);					
			currentState = "VersionMismatch";
	   	}
	   
		private function OnReady(evt:ModuleEvent): void {
			// check child for timestamp match with our build
			var obChild:Object = child as Object;
			if (obChild.hasOwnProperty("getVersionStamp")) {
				if (obChild.getVersionStamp() != PicnikBase.getVersionStamp()) {
					child = null;
					currentState = "Loading";

					// we retry 3 times in case we're in mid-deploy.  Hopefully
					// we'll hit a server with a good version
					if (_cRetries < 3) {
						_cRetries++;
						var strNewUrl:String = AppendRetriesToURL(url, _cRetries);
						setTimeout(Reload, 4000, strNewUrl);
						return;
					}

					OnVersionMismatch( obChild.getVersionStamp(), PicnikBase.getVersionStamp() );
					return;
				}
			}
			if (_pb) _pb.setProgress(100,100);
			child.addEventListener(FlexEvent.CREATION_COMPLETE, OnChildCreationComplete);
		}
		
		static private function AppendRetriesToURL(strUrl:String, cRetries:int): String {
			strUrl += (strUrl.indexOf("?") == -1 ? "?" : "&");						
			return strUrl + "retry=" + cRetries;
		}

		private function OnChildCreationComplete(evt:FlexEvent): void {
			try {
				var obChild:Object = child as Object;
				if (obChild.hasOwnProperty("GetActivatableChild") || obChild.hasOwnProperty("GetCreativeTool")) {
					if (obChild.hasOwnProperty("GetActivatableChild"))
						_act = obChild.GetActivatableChild(activatableId);
					if (!_act && obChild.hasOwnProperty("GetCreativeTool"))
						_act = obChild.GetCreativeTool(activatableId);
						// Creative tools should have their name set to our name ("_ctType", "_ctShape", etc) -
						// code in ObjectToolBase.as and TextToolBase.as assumes that it can check the creative tool's name
						// against the selected tab name
						DisplayObject(_act).name = this.name;
				}
				else {
					_act = child[activatableId];
				}
				
				if (initParams) {
					for (var k:String in initParams) {
						if (k in _act) {
							_act[k] = initParams[k];
						}
					}
				}

				if (_act == null)
					throw new Error("_act is null");
				UIComponent(_act).includeInLayout = true;
				UIComponent(_act).visible = true;
				try {
					_vstk = ViewStack(Object(_act)["_vstk"]);
				} catch (err:Error) {
					// steveler: _vstk is not required, so don't pollute the console with this message
					//trace(err.message);
				}
				
				/* No good, causes awful TabNavigator tab redrawing
				// Replace self with activatable child
				var vstk:ViewStack = parent as ViewStack;
				Debug.Assert(vstk != null, "ActivatableModuleLoader's parent must be a ViewStack");
				var i:int = vstk.getChildIndex(this);
				vstk.addChildAt(DisplayObject(_act), i);
				vstk.validateProperties();
				vstk.selectedChild = Container(_act);
				vstk.removeChildAt(i + 1);
				*/
	
				if (_fActive && _act is IActivatable)
					(_act as IActivatable).OnActivate();
					
				// reveal!
				currentState = "";
				dispatchEvent(new Event(READY));
				
				if (_strPendingTabSelection != null)
					callLater(callLater, [LoadTab, [_strPendingTabSelection]]);
			} catch (e:Error) {
				// Log the error
				PicnikService.LogException("Exception in ActivatableModuleLoader[" + id + "].OnChildCreationComplete, actid = " + activatableId, e);
				throw e; // and re-throw it
			}
		}
		
		public function get defaultTab(): String {
			if (_act && _act is PageContainer)
				return (_act as PageContainer).defaultTab;
			return null;
		}
		
		public function LoadTab(strTab:String, strCmd:String=null): void {
			_strCmd = strCmd;
			if (strTab == null) return;
			if (_act) {
				if (_act is ITabContainer)
					(_act as ITabContainer).LoadTab(strTab);
			} else {
				_strPendingTabSelection = strTab;
			}
		}
		
		public function get creativeTool(): ICreativeTool {
			return _act ? _act as ICreativeTool : null;
		}
		
		private function OnProgress(evt:ModuleEvent): void {
			if (evt.bytesTotal > 0) {
				currentState = "LoadingWithProgress";						
				if (_pb) _pb.setProgress(evt.bytesLoaded, evt.bytesTotal);
			}
		}
		
		private function OnSetup(evt:ModuleEvent): void {
			// Nothing for now
		}
		
		// Retry 3 times, then show the LoadingError (w/ retry button)
		private function OnError(evt:ModuleEvent=null): void {
			if (evt) {
				if (_cRetries < 3) {
					_cRetries++;
					Reload();
					return;
				}
				
				// Log the failed load to the server
				PicnikService.Log("Module load from " + url + " failed: " + evt.errorText, PicnikService.knLogSeverityError);				
			}
			
			currentState = "LoadingError";
		}
		
		private function OnPreloadComplete(evt:ModulePreloadEvent): void {
			if (evt.url == this._strPendingUrl) {
				trace("ActivatableModuleLoaderBase: preload complete: " + evt.url);
				LoadPendingUrl();
			}
		}

		protected function OnReloadClick(): void {
 			currentState = "Loading";
 			_cRetries = 0;
 			Reload();
 		}
 		
		protected function OnRefreshClick(): void {
			PicnikBase.app.NavigateToURL( new URLRequest(PicnikBase.gstrSoMgrServer + "/appfresh?nav=/create" ) );
 		} 		
 		
 		private function Reload(strNewUrl:String = null): void {
 			if (!strNewUrl) strNewUrl = url;

 			// Hacky but it works
			super.url = null;
			super.url = AppendRetriesToURL(strNewUrl, _cRetries);
 		}
		
		// Try to make the ActivatableModuleLoader transparent to anyone looking for
		// specific child objects.
		public override function getChildByName(strName:String): DisplayObject {
			if (_act == null)
				return super.getChildByName(strName);
			else
				return DisplayObjectContainer(_act).getChildByName(strName);
		}		
		
		//
		// IActivatable implementation
		//
		
		// When the ActivatableModuleLoader is activated, activate its contained module		
		public function OnActivate(strCmd:String=null): void {
			_fActive = true;
			if (_act && _act is IActivatable) {
				(_act as IActivatable).OnActivate(_strCmd);
				_strCmd = null;
			} else if (_strPendingUrl)
				url = _strPendingUrl;
		}
		
		// When the ActivatableModuleLoader is deactivated, deactivate its contained module		
		public function OnDeactivate(): void {
			_fActive = false;
			if (_act && _act is IActivatable)
				(_act as IActivatable).OnDeactivate();
		}
		
		public function get active(): Boolean {
			return _fActive;
		}
		
		//
		// IActionListener implementation. Relay PerformActionIfSafe to child module
		//
		
		public function PerformActionIfSafe(actn:IAction): void {
			if (_act && _act is IActionListener)
				IActionListener(_act).PerformActionIfSafe(actn);
			else
				actn.Do();
		}
		
		public function PerformAction(actn:IAction): void {
			if (_act && _act is IActionListener)
				IActionListener(_act).PerformAction(actn);
			else
				actn.Do();
		}
	}
}
