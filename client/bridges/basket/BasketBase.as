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
package bridges.basket {
	import bridges.Bridge;
	import bridges.IAutoFillSource;
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceRegistry;
	
	import containers.ActivatableModuleLoader;
	
	import controls.ResizingComboBox;
	import controls.list.PicnikTileList;
	
	import events.AccountEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.containers.Canvas;
	import mx.containers.ViewStack;
	import mx.controls.Button;
	import mx.core.Application;
	import mx.core.ContainerCreationPolicy;
	import mx.core.UIComponent;
	import mx.effects.AnimateProperty;
	import mx.effects.easing.Cubic;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	import mx.resources.ResourceBundle;
	
	import util.IconAndLabel;
	import util.PhotoBasketVisibility;

	public class BasketBase extends Canvas {
		private static const kcxyDefaultTileSize:int = 64;
	
		[Bindable] public var _cmboService:ResizingComboBox;
		[Bindable] public var _vstk:ViewStack;
		[Bindable] public var _btnSizer:Button;
		[Bindable] public var _cyShown:Number;
		[Bindable] public var _cyDefault:Number;
  		[Bindable] [ResourceBundle("Basket")] protected var rb:ResourceBundle;
  		[Bindable] public var collection:ICollectionView = null;
  		private var _afs:IAutoFillSource = null;
  		
  		private var _ysMouseDown:int;
  		private var _yBasketMouseDown:int;
  		private var _fMoved:Boolean;
  		private var _fActive:Boolean = false;
  		private var _fDisabled:Boolean = false;
  		private var _fOpened:Boolean = false;
  		private var _fMulti:Boolean = false;
  		private var _strPendingBridge:String = null;
  		
  		public static var _clsBasketDragImage:Class = BasketDragImage;
  		
		public function BasketBase() {
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
		}

  		[Bindable]
  		public function set autoFillSource(afs:IAutoFillSource): void {
  			if (_afs == afs) return;
  			if (_afs)
  				_afs.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnAutoFillSourcePropertyChange);
  			_afs = afs;
  			if (_afs) {
  				_afs.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnAutoFillSourcePropertyChange);
  				collection = autoFillSource.collection;
  			}
  		}
  		
  		public function get autoFillSource(): IAutoFillSource {
  			return _afs;
  		}
  		
  		private function OnAutoFillSourcePropertyChange(evt:PropertyChangeEvent=null): void {
  			if (evt.property == "collection")
  				collection = autoFillSource.collection;
  		}
		
		private function OnInitialize(evt:FlexEvent): void {
			_cmboService.addEventListener(Event.CHANGE, OnServiceComboChange);
			_btnSizer.addEventListener(MouseEvent.MOUSE_DOWN, OnSizerMouseDown);
			AccountMgr.GetInstance().addEventListener(AccountEvent.USER_CHANGE, OnUserChange);
			UpdateState(false);

			// hide any bridges that should be hidden			
			for each (var dobChild:DisplayObject in _vstk.getChildren()) {
				var strService:String = null;
				var brgChild:Bridge = dobChild as Bridge;
				if (brgChild != null) {
					strService = brgChild.serviceid;
				} else {
					var actChild:ActivatableModuleLoader = dobChild as ActivatableModuleLoader;
					if (actChild && actChild.initParams && "serviceId" in actChild.initParams) {
						strService = actChild.initParams['serviceId'];
					}
				}
				if (strService) {
					var obInfo:Object = StorageServiceRegistry.GetStorageServiceInfo(strService);
					if (obInfo != null && "visible" in obInfo && !obInfo.visible) {
						HideBridge(dobChild.name);
					}
				}
			}
			
			// Waiting around for the state change to accomplish this results in a crappy
			// redraw situation so force it here.
			if (!opened)
				height = 0;
		}

		private function HideBridge( strBridge:String ):void {
			var arc:ArrayCollection = ArrayCollection(_cmboService.dataProvider);
			for (var j:int = 0; j < arc.length; j++) {
				var ial:IconAndLabel = arc.getItemAt(j) as IconAndLabel;
				if (ial.data == strBridge) {
					arc.removeItemAt(j);
					break;
				}
			}			
		}

		public function Toggle(): void {
			opened = !opened;
			if (opened)
				Activate();
			
			PhotoBasketVisibility.ReportToggle(opened);
		}

		// Ideally we would use the 'enabled' property but when we do the base Container does
		// drawing we can't override. 		
		[Bindable]
		public function set disabled(fDisabled:Boolean): void {
			_fDisabled = fDisabled;
		}
		
		public function get disabled(): Boolean {
			return _fDisabled;
		}
		
		[Bindable]
		public function set opened(fOpened:Boolean): void {
			_fOpened = fOpened;
			UpdateState();	
		}

		public function get opened(): Boolean {
			return _fOpened;
		}
		
		public function Open(): void {
			if (!opened) {
				opened = true;
				Activate();
			}
		}
		
		public function InstantOpen(): void {
			// open without playing a transition
			_fOpened = true;
			UpdateState(false);	
		}

		public function InstantClose(): void {
			// open without playing a transition
			_fOpened = false;
			UpdateState(false);	
		}

		public function Close(): void {
			if (opened)
				opened = false;
		}
		
		[Bindable]
		public function get multi(): Boolean {
			return _fMulti;
		}

		public function set multi( fMulti:Boolean): void {
			_fMulti = fMulti;
			if (_fMulti) {
				_fOpened = true;	// open it up if we're in multi mode
				ActivateDefaultBridge();
			}
			UpdateState();	
		}
		
		private function UpdateState(fPlayTransition:Boolean = true): void {
			setCurrentState((_fOpened ? "up" : "down") + (_fMulti ? "multi" : ""), fPlayTransition);
		}		
		
		public function Hide(): void {
			if (!visible)
				return;
			visible = false;
			includeInLayout = false;
			
			PhotoBasketVisibility.HideTip();
		}
		
		public function Show(): void {
			if (visible)
				return;
			visible = true;
			includeInLayout = true;

			CompleteCreation();			
			
			if (opened)
				Activate();
			
			switch (PhotoBasketVisibility.GetStrategy()) {
				case PhotoBasketVisibility.STRATEGY_NONE:
					break;
				case PhotoBasketVisibility.STRATEGY_MAXIMIZE:
					Open();
					break;
				default:
					// ???!!!
			}
		}
		
		private function Activate(): void {
			if (_fActive) {
				CompleteCreation();
							
				// Force a refresh of the currently active bridge
				ActivateBridge(_vstk.selectedChild as IActivatable);
				return;
			}
			_fActive = true;
			
			ActivateDefaultBridge();
		}
		
		// If the Basket hasn't been initialized yet, complete its creation
		private function CompleteCreation(): void {
			if (creationPolicy == ContainerCreationPolicy.NONE) {
				creationPolicy = ContainerCreationPolicy.AUTO;
				createComponentsFromDescriptors();
			}
		}
		
		private function OnUserChange(evt:AccountEvent): void {
			// Reset the Basket
			opened = false;
			if (_fActive)
				ActivateDefaultBridge();
		}

		private function ActivateDefaultBridge(): void {
			if (!_vstk)
				return;
			if (multi) {
				var brg:IActivatable = _vstk.getChildByName("_brgMultiIn") as IActivatable;
				ActivateBridge(brg);			
			} else if (PicnikBase.app._brgcIn) {
				// Choose the default bridge. For now, use the InBridgeContainer rules.			
				var strBridge:String = (_strPendingBridge != null) ? _strPendingBridge : PicnikBase.app._brgcIn.defaultTab;
				_strPendingBridge = null;
				
				// HACK: There is no Basket equivalent to the projects in bridge
				if (strBridge == "_brgProjects")
					strBridge = "_brgMyComputerIn";
					
				var ibrg:IActivatable = _vstk.getChildByName(strBridge) as IActivatable;
				if (null == ibrg) {
					ibrg = _vstk.getChildByName("_brgMyComputerIn") as IActivatable;
					if (null == ibrg) {
						return;
					}
				}
					
				ActivateBridge(ibrg);
			}
		}

		private function OnServiceComboChange(evt:Event): void {
			var strName:String = _cmboService.selectedItem.data;
			var ibrg:IActivatable = _vstk.getChildByName(strName) as IActivatable;
			ActivateBridge(ibrg);
		}
		
		private function getTileList(brg:IActivatable):PicnikTileList {
			if ("_tlst" in brg) {
				return brg["_tlst"] as PicnikTileList;
			} else if ("getChildByName" in brg) {
				return brg["getChildByName"]("_tlst") as PicnikTileList;
			}
			return null;
		}
		
		// If the bridge being activated hasn't completed initialization yet, wait
		// until it has then activate it. Also deactivate any currently active bridge
		// and make sure the combobox is in sync with the newly activated bridge.
		private function ActivateBridge(brg:IActivatable): void {
			var nSize:int = kcxyDefaultTileSize;
			var brgPrev:IActivatable = _vstk.selectedChild as IActivatable;
			if (brgPrev && brgPrev.active) {
				var tlst:PicnikTileList = getTileList(brgPrev);
				if (tlst)
					nSize = tlst.tileSizeInWidth;
				brgPrev.OnDeactivate();
			}
				
			var dobBridge:DisplayObject = brg as DisplayObject;
			var i:int = _vstk.getChildIndex(dobBridge);
			
			// Find the matching comboService item
			var arc:ArrayCollection = ArrayCollection(_cmboService.dataProvider);
			for (var j:int = 0; j < arc.length; j++) {
				var ial:IconAndLabel = arc.getItemAt(j) as IconAndLabel;
				if (ial.data == dobBridge.name) {
					_cmboService.selectedIndex = j;
					break;
				}
			}
			_vstk.selectedIndex = i;
			
			var uic:UIComponent = brg as UIComponent;
			if (!uic.initialized) {
				uic.addEventListener(FlexEvent.INITIALIZE, function (evt:FlexEvent): void {
					if (!brg.active)
						CompleteBridgeActivation(brg, nSize);
				});
			} else {
				CompleteBridgeActivation(brg, nSize);
			}
			autoFillSource = brg as IAutoFillSource;
		}
		
		private function CompleteBridgeActivation(brg:IActivatable, cxyTileSize:int): void {
			brg.OnActivate();
			if (cxyTileSize != kcxyDefaultTileSize)
				var tlst:PicnikTileList = getTileList(brg);
				if (tlst)
					tlst.tileSizeInWidth = cxyTileSize;
		}
		
		//
		// Handle Basket resizing
		//
		
		private function OnSizerMouseDown(evt:MouseEvent): void {
			endEffectsStarted();
			_ysMouseDown = evt.stageY;
			_yBasketMouseDown = y;
			_fMoved = false;
			
			Util.CaptureMouse(stage, OnSizerMouseMove, OnSizerMouseUp);
		}
		
		// Used for animating snap effects
		public function set yDrag(yNew:Number): void {
			SetY(yNew);
		}
		
		protected function SetTileSize(nSize:Number): void {
			var brgActive:IActivatable = _vstk.selectedChild as IActivatable;
			if (!brgActive) return;
			
			var fOneRow:Boolean = false;
			
			var tlst:PicnikTileList = getTileList(brgActive);
			if (tlst) {
				// Check for # of rows showing before we change the row height
				fOneRow = Math.round(numRowsShowing) == 1;
				tlst.tileSizeInWidth = nSize;
			}
			
			// Animate resize
			AnimateSnap(true, fOneRow);
		}
		
		private function AnimateSnap(fNeverCollapse:Boolean=false, fSnapToOneRow:Boolean=false): void {
			var yNew:Number = SnapY(y, fNeverCollapse, fSnapToOneRow);
			if (y != yNew) {
				var eff:AnimateProperty = new AnimateProperty(this);
				eff.property = "yDrag";
				eff.fromValue = y;
				eff.toValue = yNew;
				eff.easingFunction = Cubic.easeOut;
				
				var nDTest:Number = 70;
				var nTTest:Number = 300;
				var nATest:Number = -2 * nDTest / (nTTest * nTTest);
				var nVTest:Number = 2 * nDTest / nTTest;
				
				// Now, calculate d
				var nD2:Number = Math.abs(y - yNew);
				var nT2:Number; // = ? Calculate this
				
				// Method 1: constant initial velocity, based on nVTest
				nT2 = 2 * nD2 / nVTest;
				
				// Method 2: constant acceleration, based on nATest
				// nT2 = Math.sqrt(Math.abs(2 * d2 / nATest))
				
				eff.duration = nT2;
				eff.play();
			}
		}
		
		private function OnSizerMouseUp(evt:MouseEvent): void {
			if (_fMoved) {
				// Snap
				AnimateSnap();
				return;
			} else {
				if (hitTestPoint(stage.mouseX, stage.mouseY))
					Toggle();
			}
		}
		
		private function get numRowsShowing(): Number {
			var brgActive:IActivatable = _vstk.selectedChild as IActivatable;
			if (!brgActive) return 0;
			
			var tlst:PicnikTileList = getTileList(brgActive);
			if (!tlst) return 0;
			
			return 1 + (tlst.height - tlst.singleRowHeight) / tlst.rowHeight;
		}
		
		private function SnapY(yNew:Number, fNeverCollapse:Boolean=false, fSnapToOneRow:Boolean=false): Number {
			var nHeight:Number = parent.height - yNew;
			
			var brgActive:IActivatable = _vstk.selectedChild as IActivatable;
			if (!brgActive) return yNew;
			
			var tlst:PicnikTileList = getTileList(brgActive);
			
			if (!tlst) return yNew;
			
			var nBridgeHeaderHeight:Number = tlst.y;
			
			var nRowHeight:Number = tlst.rowHeight;
			var nSingleRowHeight:Number = tlst.singleRowHeight;
			var nTwoRowHeight:Number = nRowHeight * 2;
			
			var nTileSpace:Number = nHeight - nBridgeHeaderHeight;
			
			// If we have less than half the space we need for a single row...
			if (nTileSpace < 1 && !fNeverCollapse) return parent.height;
			
			// If we are closer to the first row, snap there
			if (fSnapToOneRow || (nTileSpace < ((nSingleRowHeight + nTwoRowHeight)/2))) {
				return parent.height - nBridgeHeaderHeight - nSingleRowHeight;
			}
			
			// Now we know we have room for 2+ rows. Snap to a row
			var cTileRows:Number = nTileSpace / nRowHeight;
			var iTileRows:Number = Math.round(cTileRows);
			
			var nSnapOffset:Number = (cTileRows - iTileRows) * nRowHeight;
			return yNew + nSnapOffset;
		}

		
		private function OnSizerMouseMove(evt:MouseEvent): void {
			// Differentiate a simple click from a move by whether the mouse
			// has moved from the mouse-down point by at least 5 pixels.
			if (!_fMoved) {
				if (Math.abs(evt.stageY - _ysMouseDown) > 5) {
					// It's a move
					_fMoved = true;
				} else {
					// Not a move, might just be a click
					return;
				}
			}
			
			var yNew:int = _yBasketMouseDown + evt.stageY - _ysMouseDown;
			if (yNew > parent.height) {
				yNew = parent.height;
			} else if (yNew < 170) {
				yNew = 170;
			}
			
			// Snap yNew
			SetY(yNew);
		}
		
		private function SetY(yNew:Number): void {
			y = yNew;
			height = parent.height - yNew;
			if (height == 0) {
				// figure out what a non-zero height should look like
				// and save it for later
				_cyShown = yNew - SnapY( y - 1, true, true );
				opened = false;
			} else {
				_cyShown = height;
				InstantOpen();
				if (!_fActive)
					Activate();
			}
		}
		
		public function SelectBridge( strBridge:String ): void {
			_strPendingBridge = strBridge;
			if (_fActive)
				ActivateDefaultBridge();
		}
	}
}
