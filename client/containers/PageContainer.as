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
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceRegistry;
	
	import controls.OverflowMenu;
	import controls.ThumbToggleButtonBar;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.containers.Canvas;
	import mx.containers.ViewStack;
	import mx.core.Container;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.IndexChangedEvent;
	
	import pages.Page;
	
	import util.AdManager;
	import util.NextNavigationTracker;

	public class PageContainer extends Canvas implements IActivatable {
		[Bindable] public var _vstk:ViewStack;
		[Bindable] public var _tbbar:ThumbToggleButtonBar;
		[Bindable] public var _oflw:OverflowMenu;
		[Bindable] public var NoNavBar:Boolean = false;
		
		public var urlkit:String; // used by UrlKit to compose the URL including this 'page'
		
		protected var _pgActive:IActivatable = null;
		protected var _fIndexChangeListening:Boolean = false;
		protected var _fSelectedStartTab:Boolean = false;
		private var _fActive:Boolean = false;
		private var _strPendingTab:String = null;
		private var _fPendingActivate:Boolean = false;
		private var _adctViewStackOrder:Array = null;
		
		public function PageContainer() {
			//trace("PageContainer constructor: " + className);
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete );
			addEventListener(FlexEvent.SHOW, OnShow);
			addEventListener(FlexEvent.HIDE, OnHide);
			verticalScrollPolicy = ScrollPolicy.OFF;
			horizontalScrollPolicy = ScrollPolicy.OFF;
		}
		
		protected function OnInitialize(evt:FlexEvent): void {
			for each (var dobChild:DisplayObject in _vstk.getChildren()) {
				var strService:String = null;
				var pgChild:Page = dobChild as Page;
				if (pgChild != null && 'serviceid' in pgChild) {
					strService = pgChild['serviceid'];
				} else {
					var actChild:ActivatableModuleLoader = dobChild as ActivatableModuleLoader;
					if (actChild && actChild.initParams && "serviceId" in actChild.initParams) {
						strService = actChild.initParams['serviceId'];
					}
				}
				if (strService) {
					var obInfo:Object = StorageServiceRegistry.GetStorageServiceInfo(strService);
					if (obInfo != null && "visible" in obInfo && !obInfo.visible) {
						HidePage(strService);
					}
				}
			}
		}
		
		private function OnCreationComplete(evt:FlexEvent): void {			
			// save the current order of all the page elements
			// (as specified in the mxml file) so that they get pushed
			// to the end of the list (and back) in the same order
			_adctViewStackOrder = new Array();
			var index:Number = 0;
			for each (var ob:DisplayObject in _vstk.getChildren()) {
				var data:Object = { display: ob, page:null, service:null }
				var pg:Page = ob as Page;
				if (pg) {
					data.page = pg.name;
					data.service = pg.urlkit;
				}
				var aml:ActivatableModuleLoader = ob as ActivatableModuleLoader;
				if (aml) {
					data.page = aml.name;
					data.service = aml.urlkit;
				}
				if ("serviceName" in ob) {
					data.service = ob["serviceName"];
				}
				_adctViewStackOrder.push( data );				
				index++;				
			}
			
			UpdatePages();	
			
			if (_fPendingActivate) {
				OnActivate();
			}			
		}		
		
		public function DoPrev(): void {
			_vstk.selectedIndex--;
		}
		
		public function DoNext(): void {
			_vstk.selectedIndex++;
		}			
		
		public function DoFirst(): void {
			_vstk.selectedIndex = 0;
		}
				
		public function get activePage(): IActivatable {
			return _pgActive;
		}
		
		protected function ServiceToPage(strService:String): String {
			// Override in child classes
			return null;
		}
						
		protected function HidePage(strService:String): void {
			var strPage:String = ServiceToPage(strService);
			HideChildByName(strPage);			
		}
								
		protected function HideChildByName(strPage:String): void {
			var childPage:DisplayObject = _vstk.getChildByName(strPage);
			if (childPage)
				_vstk.removeChild(childPage);
				
			// remove this child from our info list, and re-index all the
			// children that come after it.
			if (_adctViewStackOrder) {
				for (var i:Number = 0; i <_adctViewStackOrder.length; i++) {
					if (_adctViewStackOrder[i].page == strPage) {
						_adctViewStackOrder.splice(i,1);
						break;
					}
				}					
			}				
		}		
		
		public function UpdatePages():void {
			if (null == _adctViewStackOrder)
				return;
			
			// find the first third party page in our list of child pages
			var firstThirdPartyPage:Number = 0;
			for (var i:Number = 0; i < _adctViewStackOrder.length; i++ ) {
				var info:Object = _adctViewStackOrder[i];
				if (info && info.service) {
					var tpa:ThirdPartyAccount = AccountMgr.GetThirdPartyAccount(info.service);
					if (tpa) {
						firstThirdPartyPage = i;
						break;
					}
				}
			}
				
			// examine all our child pages and see if they (can) have credentials
			// if they can, and they don't, then move 'em to the back
			// non-third party (i.e. our) pages stay in their original positions,
			// and are not bumped up just because they don't have a third party account
			// also animate the thumb slider if we're moving the selected one around
			var selectedChild:DisplayObject = _vstk.selectedChild;
			var adctViewStackNewOrder:Array = new Array();
			var cFirst:Number = 0;
			for (i = 0; i < _adctViewStackOrder.length; i++) {
				info = _adctViewStackOrder[i];
				if (!info || !info.page || !info.service) {
					adctViewStackNewOrder.push( info );
					continue;
				}
				
				tpa = AccountMgr.GetThirdPartyAccount(info.service);
				
				if (tpa && !tpa.IsPrimary() && !tpa.HasCredentials() ||
				    !tpa && i > firstThirdPartyPage) {
					adctViewStackNewOrder.push( info );					
				} else {
					adctViewStackNewOrder.splice( cFirst, 0, info );
					cFirst++;
				}
			}
			
			var fChange:Boolean = false;
			
			for (i=0; i < adctViewStackNewOrder.length; i++) {
				if (i != _vstk.getChildIndex(adctViewStackNewOrder[i].display)) {
					fChange = true;
					break;
				}					
			}
			
			if (fChange) {
				i = 0;
				while (i < _vstk.numChildren) {
					// Figure out which child should go here
					if (i < adctViewStackNewOrder.length) {
						// We want the child at adctViewStackNewOrder[i].display
						if (_vstk.getChildAt(i) != adctViewStackNewOrder[i].display) {
							try {
								_vstk.swapChildren(_vstk.getChildAt(i), adctViewStackNewOrder[i].display);
							} catch (e:Error) {
								// swapChildren can fail for some obscure reason. 
								// When it does, it seems that we can safely ignore it.
							}
						}
					} else {
						// Remove it
						_vstk.removeChildAt(i);
						i--;
					}
					i++;
				}				
				
				// update the selected index if it has changed.  This'll move the thumb tab around
				_tbbar.dataProvider = _vstk;
				UpdateToggleButtons( _vstk.getChildIndex( selectedChild ) );
			}
		}
		
		private function UpdateToggleButtons( newSelectedIndex:Number ) : void {
			_vstk.selectedIndex = newSelectedIndex;
			_vstk.validateProperties();
						
			_tbbar.SelectIndex(newSelectedIndex);
			
			// Force the ToggleButtonBar to update its selectedIndex or (due to a bug) it will fail
			// to update when the final index is selected.
			_tbbar.validateProperties();
			
			if (_oflw)
				callLater(_oflw.HideClippedSubTabs);
		}
				
		// Set the selected tab.
		public function NavigateToService(strService:String): void {		
			NavigateTo(ServiceToPage(strService));			
		}		
				
		// Set the selected tab.
		// This is smart about dealing with pre-init calls and overriding
		// the default tab.
		public function NavigateTo(strTab:String): void {
			if (strTab == null || strTab.length == 0) return; // Do nothing for "empty" tab
			
			var ctrNewChild:Container = null;
			if (_vstk != null && _tbbar != null) {
				ctrNewChild = _vstk.getChildByName(strTab) as Container;
			}
			if (ctrNewChild != null) {
				NavigateToChild( ctrNewChild );
			} else {
				// Pre-init. Delayed selection.
				_strPendingTab = strTab;
			}
			selectedStartTab = true;
		}

		protected function NavigateToChild(ctrNewChild:Container): void {
			if (ctrNewChild != null) {
				_vstk.selectedChild = ctrNewChild;
				_tbbar.SelectIndex(_vstk.selectedIndex);
			}
		}

		public function set selectedStartTab(fSelectedStartTab:Boolean): void {
			_fSelectedStartTab = fSelectedStartTab;
		}

		public function get defaultTab(): String {
			// Override in child classes
			return null;
		}
		
		// Only track ViewStack index changes while the container is visible. This keeps
		// us from doing a lot of behind the scenes BS when application state is being
		// restored and both the In and Out page container's ViewStack indices are
		// being set.
		private function OnShow(evt:FlexEvent): void {
			_vstk.addEventListener(IndexChangedEvent.CHANGE, OnViewStackIndexChange);
			_fIndexChangeListening = true;
		}
		
		private function OnHide(evt:FlexEvent): void {
			_vstk.removeEventListener(IndexChangedEvent.CHANGE, OnViewStackIndexChange);
			_fIndexChangeListening = false;
		}
		
		public function get viewStack(): ViewStack {
			return _vstk;
		}
		
		//
		// IActivatable implementation
		//

		// When the page container is activated, activate its selected child		
		public function OnActivate(strCmd:String=null): void {
			//trace("PageContainer.OnActivate (" + id + ")");
			Debug.Assert(!_fActive, "PageContainer.OnActivate already active!");
			if (!initialized) {
				_fPendingActivate = true;
				return;
			}
			_fPendingActivate = false;
			_fActive = true;
			
			// At load time it is possible to be shown without receiving an
			// FlexEvent.SHOW. This is a problem for us because that's when
			// we add the _vstk IndexChangedEvent.CHANGE listener. OnActivate
			// IS called at load time so we recover from this situation here.
			if (!_fIndexChangeListening) {
				_vstk.addEventListener(IndexChangedEvent.CHANGE, OnViewStackIndexChange);
				_fIndexChangeListening = true;
			}

			if (_strPendingTab) {
				NavigateTo(_strPendingTab);
				_strPendingTab = null;
			} else if (!_fSelectedStartTab) {
				NavigateTo(defaultTab);
			}
			
//			trace("PageContainer.OnActivate: (" + id + ") _vstk.selectedIndex: " + _vstk.selectedIndex);
			_pgActive = _vstk.selectedChild as IActivatable;
			if (_pgActive && !_pgActive.active)
				ActivatePage(_pgActive);
		}
		
		// If the page being activated hasn't completed initialization yet, wait
		// until it has then activate it.
		private function ActivatePage(pg:IActivatable): void {
			var uic:UIComponent = pg as UIComponent;
			Debug.Assert(uic != null, "Pages must also be UIComponents");
			if (!uic.initialized) {
				uic.addEventListener(FlexEvent.INITIALIZE, function (evt:FlexEvent): void {
					// UNDONE: removeEventListener?
					pg.OnActivate();
				});
			} else {
				pg.OnActivate();
			}
		}
		
		// When the page container is deactivated, deactivate its selected child		
		public function OnDeactivate(): void {
//			trace("PageContainer.OnDeactivate");
			_fActive = false;
			
			if (_pgActive != null) {
				_pgActive.OnDeactivate();
				// Make sure we don't deactivate this twice
				_pgActive = null;
			}
		}
		
		public function get active(): Boolean {
			return _fActive;
		}
		
		//
		//
		//
		
		protected function OnViewStackIndexChange(evtT:Event): void {
			// HACK: UITextFields fire a bubbling Event.CHANGE when their htmlText IMGs are loaded.
			// Unfortunately they look just like IndexChangedEvent.CHANGE due to an Event namespace collision.
			// Disambiguate them here and stop their propagation so they don't bother any other components
			// in the bubble chain.
			var evt:IndexChangedEvent = evtT as IndexChangedEvent;
			if (evt == null) {
				evtT.stopImmediatePropagation();
				return;
			}
		
			// trace(this + ".OnViewStackIndexChange (" + id + ") oldIndex: " + evt.oldIndex + ", newIndex: " + evt.newIndex + ", name: " + name);
			_fSelectedStartTab = true;
			var vstk:ViewStack = ViewStack(evt.target);
			var pgTarget:IActivatable = vstk.getChildAt(evt.newIndex) as IActivatable;
			if (_pgActive != null && _pgActive != pgTarget) {
				// Don't deactivate a page if we are simply going to reactivate it.
				_pgActive.OnDeactivate();
			}
			_pgActive = pgTarget;
			if (_pgActive && !_pgActive.active) {
				_pgActive.OnActivate();
				if ('id' in _pgActive)
					NextNavigationTracker.OnClick('/sub_tab/' + _pgActive['id']);
				else if ('name' in _pgActive)
					NextNavigationTracker.OnClick('/sub_tab/' + _pgActive['name']);
			}

			OnChildActivate(_pgActive);
				
			// show a new add
			AdManager.GetInstance().LoadNewAd();	
		}
		
		protected function OnChildActivate(pg:IActivatable): void {
			// for subs to override if they want
		}				
	}
}
