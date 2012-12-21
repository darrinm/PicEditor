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
package {
	import bridges.basket.Basket;
	
	import containers.sectionList.SectionList;
	
	import controls.HSBColorPicker;
	import controls.HSliderPlus;
	import controls.ResizingButton;
	import controls.Tip;
	
	import dialogs.*;
	
	import imagine.documentObjects.DocumentObjectContainer;
	import imagine.documentObjects.DocumentObjectUtil;
	import imagine.documentObjects.DocumentStatus;
	import imagine.documentObjects.FitMethod;
	import imagine.documentObjects.Photo;
	import imagine.documentObjects.PhotoGrid;
	import imagine.documentObjects.Target;
	import imagine.documentObjects.Text;
	
	import events.*;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	import imagine.imageOperations.ImageOperation;
	import imagine.imageOperations.RasterizeImageOperation;
	import imagine.imageOperations.ResizeImageOperation;
	
	import imageUtils.*;
	
	import imagine.ImageDocument;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.collections.CursorBookmark;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.core.Application;
	import mx.events.ChildExistenceChangedEvent;
	import mx.events.ColorPickerEvent;
	import mx.events.DropdownEvent;
	import mx.events.FlexEvent;
	import mx.events.SliderEvent;
	import mx.events.SliderEventClickTarget;
	import mx.resources.ResourceBundle;
	
	import imagine.objectOperations.CreateObjectOperation;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	import imagine.objectOperations.SetUIModeObjectOperation;
	
	import overlays.*;
	
	import util.IAssetSource;
	import util.ImagePropertiesUtil;
	import util.LocUtil;
	import util.TipManager;
	import util.VBitmapData;
	
	public class CollageBase extends Canvas implements IActivatable {
		private static const kcDefaultRows:int = 2;
		private static const kcDefaultColumns:int = 2;
		private static const kcxDefaultGap:int = 50;
		public static const kcxNormalResolution:int = 1024;
		public static const kcyNormalResolution:int = 1024;
		[Bindable] public var _cxPrintResolution:int;
		[Bindable] public var _cyPrintResolution:int;
		
		// MXML-defined variables
		[Bindable] public var _cvsTemplate:Canvas;
		[Bindable] public var _btnAutoFill:Button;
		[Bindable] public var _btnShuffle:Button;
		[Bindable] public var _btnClear:Button;
		[Bindable] public var _btnInfo:Button;
		[Bindable] public var _btnUndo:Button;
		[Bindable] public var _btnRedo:Button;
		[Bindable] public var _btnDone:Button;
		[Bindable] public var _btnPrint:Button;
		[Bindable] public var _btnNormalResolution:Button;
		[Bindable] public var _btnPrintResolution:Button;
		[Bindable] public var _btnUpgrade:ResizingButton;
		[Bindable] public var hasDocument:Boolean;
		[Bindable] public var _zmv:ZoomView;
		[Bindable] public var _cpkrBackground:HSBColorPicker;
		[Bindable] public var _sldrGapSize:HSliderPlus;
		[Bindable] public var _sldrRows:HSliderPlus;
		[Bindable] public var _sldrColumns:HSliderPlus;
		[Bindable] public var _sldrKookiness:HSliderPlus;
		[Bindable] public var _sldrRoundedness:HSliderPlus;
		[Bindable] public var _sldrProportions:HSliderPlus;
		[Bindable] public var canAutoFill:Boolean = false;
		[Bindable] public var _slCollages:SectionList;
		
		[Bindable] public var _phgd:PhotoGrid;
		[Bindable] public var _imgd:ImageDocument;
		[Bindable] public var collection:ICollectionView = null;
		[Bindable] public var populatedTargetCount:int = 0;
  		[Bindable] [ResourceBundle("Collage")] protected var _rb:ResourceBundle;

		private var _fActive:Boolean;
		private var _urs:UndoRedoSave;
		private var _fLiveColorChanging:Boolean = false;
		private var _tip:Tip;

		private var _bsy:IBusyDialog;
		
		private var _cwAutoResizeMode:ChangeWatcher;
		
		public function CollageBase() {
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
			
			UpdatePrintResolution(); // Update the print resolution
			
			// Make sure we update the print resolution whenever the auto resize mode changes
			_cwAutoResizeMode = ChangeWatcher.watch(AccountMgr.GetInstance(), "autoResizeMode", UpdatePrintResolution);
		}
		
		private function UpdatePrintResolution(evt:Event=null): void {
			var nMaxSize:Number = 2400;
			AccountMgr.GetInstance().autoResizeMode
			if (AccountMgr.GetInstance().GetMaxArea() >= (3600 * 3600))
				nMaxSize = 3600;

			_cxPrintResolution = Math.min(Util.GetMaxImageWidth(), nMaxSize); // 12"x300 DPI
			_cyPrintResolution = Math.min(Util.GetMaxImageHeight(), nMaxSize);
		}
		
		//
		// Initialization (not including state restoration)
		//
		
		private function OnInitialize(evt:Event): void {
			_urs = new UndoRedoSave(_btnUndo, _btnRedo, null);
			_btnAutoFill.addEventListener(MouseEvent.CLICK, OnAutoFillClick);
			_btnShuffle.addEventListener(MouseEvent.CLICK, OnShuffleClick);
			_btnNormalResolution.addEventListener(MouseEvent.CLICK, OnNormalResolutionClick);
			_btnPrintResolution.addEventListener(MouseEvent.CLICK, OnPrintResolutionClick);
			_btnClear.addEventListener(MouseEvent.CLICK, OnClearClick);
			_btnInfo.addEventListener(MouseEvent.CLICK, OnInfoClick);
			//_btnUpgrade.addEventListener(MouseEvent.CLICK, OnUpgradeClick);
			
			if (_sldrGapSize) _sldrGapSize.addEventListener(SliderEvent.CHANGE, OnGapSliderChange);
			if (_sldrGapSize) _sldrGapSize.addEventListener(SliderEvent.THUMB_RELEASE, OnPendingTransactionSliderThumbRelease);
			if (_sldrKookiness) _sldrKookiness.addEventListener(SliderEvent.CHANGE, OnKookinessSliderChange);
			if (_sldrKookiness) _sldrKookiness.addEventListener(SliderEvent.THUMB_RELEASE, OnSealableSliderThumbRelease);
			if (_sldrRoundedness) _sldrRoundedness.addEventListener(SliderEvent.CHANGE, OnRoundednessSliderChange);
			if (_sldrRoundedness) _sldrRoundedness.addEventListener(SliderEvent.THUMB_RELEASE, OnSealableSliderThumbRelease);
			if (_sldrProportions) _sldrProportions.addEventListener(SliderEvent.CHANGE, OnProportionsSliderChange);
			if (_sldrProportions) _sldrProportions.addEventListener(SliderEvent.THUMB_RELEASE, OnPendingTransactionSliderThumbRelease);
			if (_sldrRows) _sldrRows.addEventListener(SliderEvent.CHANGE, OnRowsSliderChange);
			if (_sldrRows) _sldrRows.addEventListener(SliderEvent.THUMB_RELEASE, OnPendingTransactionSliderThumbRelease);
			if (_sldrColumns) _sldrColumns.addEventListener(SliderEvent.CHANGE, OnColumnsSliderChange);
			if (_sldrColumns) _sldrColumns.addEventListener(SliderEvent.THUMB_RELEASE, OnPendingTransactionSliderThumbRelease);
			if (_cpkrBackground) _cpkrBackground.addEventListener(ColorPickerEvent.CHANGE, OnBackgroundColorChange);
			if (_cpkrBackground) _cpkrBackground.addEventListener(DropdownEvent.OPEN, OnBackgroundColorOpen);
			_btnDone.addEventListener(MouseEvent.CLICK, OnDoneClick);
			if (_btnPrint) _btnPrint.addEventListener(MouseEvent.CLICK, OnPrintClick);
			if (_slCollages) _slCollages.addEventListener(Event.CHANGE, OnSectionListChange);
			
			ChangeWatcher.watch(GetBasket(), "collection", OnBasketCollectionChange);
			OnBasketCollectionChange();
			PicnikBase.app.addEventListener(LoginEvent.RESTORE_COMPLETE, OnRestoreComplete);
		}
		
		private function OnCreationComplete(evt:FlexEvent): void {
			if (_fActive)
				ShowTips();
		}
		
		private function OnBasketCollectionChange(evt:Event=null): void {
			collection = GetBasket().collection;
		}
		
		private function OnSectionListChange(evt:Event): void {
			SelectTemplate(_slCollages.selectedItem);
		}

		protected function SelectTemplate(obItem:Object): void {
			var strTemplate:String = ("template" in obItem) ? obItem.template as String: null;
			var ptSize:Point = ("dims" in obItem) ? obItem.dims as Point : new Point(1, 1);
			var strTemplateName:String = ("templateName" in obItem) ? obItem.templateName : (strTemplate ? strTemplate : (ptSize.x + "x" + ptSize.y));
			var strAssetRefs:String = ("strAssetRefs" in obItem) ? obItem.strAssetRefs as String: "";
			var nProportions:Number = obItem.props as Number;
			
			if (strTemplate != _phgd.template || ptSize.x != _phgd.numColumns || ptSize.y != _phgd.numRows ||
					nProportions != _phgd.proportions) {
				NewCollage(ptSize.x, ptSize.y, nProportions, strTemplate, true, NaN, strAssetRefs, obItem.nWidth, obItem.nHeight);
				
				_phgd.templateName = strTemplateName;
				Util.UrchinLogReport("/" + collageType + "/viewed/" + _phgd.templateName);
			}
		}
		
		protected function get collageType(): String {
			return "collage"; // Override in subclasses
		}
		
		protected function DoRasterize(): void {
			// Called within a transaction. Override in sub-classes to add custom operations to the transaction
			var rop:RasterizeImageOperation = new RasterizeImageOperation(
					_imgd.documentObjects.name, _imgd.width, _imgd.height, true);
			rop.Do(_imgd);
		}
		
		private function OnPrintClick(evt:MouseEvent): void {
			Customize(PicnikBase.OUT_BRIDGES_TAB, '_brgPrinterOut');
		}
		
		protected function OnDoneClick(evt:MouseEvent): void {
			Customize();
		}
		
		protected function Customize(strTab:String="CREATE_TAB", strSubTab:String=null): void {
			// HACK: Compiler didn't like setting a default param to an external constant
			// This is a simple workaround.
			if (strTab == "CREATE_TAB")
				strTab = PicnikBase.EDIT_CREATE_TAB;
				
			// See if we can rasterize or if we need to wait
			
			var fCanceled:Boolean = false;
			var nTotalChildren:Number = 0; // Total children currently loading
			
			var fnBusyMessage:Function = function(nChildrenLeft:Number): String {
				var nImportItem:Number = 1 + nTotalChildren - nChildrenLeft;
				return LocUtil.rbSubst('Collage', "LoadingXOfY", nImportItem, nTotalChildren);
			}
			
			// Make a local copy so we know it is controlled locally.
			var bsy:IBusyDialog = _bsy;
			
			var fnHideBusy:Function = function(): void {
				if (bsy)
					bsy.Hide()
				bsy = null;
			}
			
			var fnHandleChildError:Function = function(): void {
				fnCancel();
				// Display the "blargh - fix your error" dialog

				var dlg1:EasyDialog =
					EasyDialogBase.Show(
						PicnikBase.app,
						[Resource.getString('Collage', 'ok')],
						Resource.getString("Collage", "blargh"),
						Resource.getString("Collage", "couldNotProcessSomePhotos"));
			}

			var fnOnChildLoaded:Function = function(nChildrenLeft:Number): void {
				if (fCanceled) return;
				if (_imgd.childStatus == DocumentStatus.Error) {
					fnHandleChildError();
				} else {
					if (nChildrenLeft > 0) {
						if (bsy)
							bsy.message = fnBusyMessage(nChildrenLeft);
					} else {
						Util.UrchinLogReport("/" + collageType + "/applied/" + _phgd.templateName);
						
						// Rasterize
						// NOTE: The exact string "Flatten Collage" must be used because ImageDocument.Serialize
						// and ImageDocument.GetOptimizedAssetMap search through the history for it.
						_imgd.BeginUndoTransaction("Flatten Collage", false, true, true);
						
						// Render a new background bitmap from all the DocumentObjects
						DoRasterize();
			
						// This is how we transition the UI from Collage to PhotoEdit mode such that
						// undo and redo will automagically transition back and forward.			
						var suimop:SetUIModeObjectOperation = new SetUIModeObjectOperation(PicnikBase.kuimPhotoEdit,
								strTab, strSubTab);
						suimop.Do(_imgd);
						
						_imgd.EndUndoTransaction();
						fnHideBusy();
					}
				}
			}
			
			var fnCancel:Function = function(dctResult:Object=null): void {
				fCanceled = true;
				fnHideBusy();
			}
			
			if (_imgd.childStatus == DocumentStatus.Error) {
				fnHandleChildError();
			} else {
				nTotalChildren = WaitForAssetsToLoad(fnOnChildLoaded);
				if (nTotalChildren > 0) {
					fnHideBusy();
					bsy = BusyDialogBase.Show(this, fnBusyMessage(nTotalChildren), BusyDialogBase.OTHER, "", 0.5, fnCancel);
				}
			}
		}
		
		// Returns number of assets left to load
		// Calls callback whenever another asset loads
		// var fnOnAssetLoaded:Function = function(nAssetsLeft:Number): void {
		protected function WaitForExtraAssetsToLoad(fnOnAssetLoaded:Function): Number {
			fnOnAssetLoaded(0);
			return 0; // Override in sub-classes
		}
		
		// Returns number of assets left to load
		// Calls callback whenever another asset loads
		// var fnOnAssetLoaded:Function = function(nAssetsLeft:Number): void {
		protected function WaitForAssetsToLoad(fnOnAssetLoaded:Function): Number {
			var nDocAssetsRemaining:Number = 1;
			var nExtraAssetsRemaining:Number = _imgd.numChildrenLoading;
			var fAllDone:Boolean = false;
			
			var fnReportStatus:Function = function(): void {
				if (fAllDone) return;
				fAllDone = (nDocAssetsRemaining + nExtraAssetsRemaining) == 0;
				fnOnAssetLoaded(nDocAssetsRemaining + nExtraAssetsRemaining);
			}
			
			var fnOnDocAssetLoaded:Function = function(nAssetsLeft:Number): void {
				nDocAssetsRemaining = nAssetsLeft;
				fnReportStatus();
			}
			var fnOnExtraAssetLoaded:Function = function(nAssetsLeft:Number): void {
				nExtraAssetsRemaining = nAssetsLeft;
				if (nAssetsLeft == 0) {
					nDocAssetsRemaining = _imgd.WaitForChildrenToLoad(fnOnDocAssetLoaded);
				}
				fnReportStatus();
			}
			
			nExtraAssetsRemaining = WaitForExtraAssetsToLoad(fnOnExtraAssetLoaded);
			
			return nDocAssetsRemaining + nExtraAssetsRemaining;
		}
		
		protected function get defaultGridBackgroundAlpha(): Number {
			return 1.0; // Override in subclasses as needed.
		}

		protected function get defaultGridBackgroundColor(): Number {
			return 0x333333;
		}
		
		protected function NewCollage(cColumns:int, cRows:int, nProportions:Number=50, strTemplate:String=null,
				fUndoable:Boolean=true, nGap:Number=NaN, strAssetRefs:String="", cxPreferred:Number=NaN, cyPreferred:Number=NaN): void {
			_imgd = PicnikBase.app.activeDocument as ImageDocument;
			if (_imgd == null) {
				_imgd = new ImageDocument();
				_imgd.Init(kcxNormalResolution, kcyNormalResolution, 0xffffff);
				_imgd.properties.title = Resource.getString("Collage", "new_collage_title");
				_imgd.properties.description = "";
				PicnikBase.app.activeDocument = _imgd;
			}
			
			// numColumns == 0 if it's the MXML-defined dummy PhotoGrid we're looking at
			if (_phgd == null || _phgd.numColumns == 0) {
				if (fUndoable)
					_imgd.BeginUndoTransaction("Create Photo Grid", false);
				
				if (isNaN(nGap)) nGap = 0.01;
				// Create a PhotoGrid DocumentObject
				var dctProperties:Object = {
					x: _imgd.width / 2, y: _imgd.height / 2,
					backgroundColor: defaultGridBackgroundColor,
					gap: nGap,
					backgroundAlpha: defaultGridBackgroundAlpha,
					proportions: nProportions,
					template: strTemplate,
					fitWidth: _imgd.width, fitHeight: _imgd.height, fitMethod: FitMethod.SNAP_TO_MAX_WIDTH_HEIGHT,
					templateName: "default"
				};
				
				var coop:CreateObjectOperation = new CreateObjectOperation("PhotoGrid", dctProperties);
				coop.Do(_imgd);
				
				// Retain the newly created object
				_phgd = PhotoGrid(_imgd.getChildByName(dctProperties.name));
//				_phgd.mouseEnabled = false;
//				_phgd.mouseChildren = true;
			} else {
				if (fUndoable)
					_imgd.BeginUndoTransaction("Resize Photo Grid", false);
			}
			
			var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(_phgd.name,
					{ numRows: cRows, numColumns: cColumns, proportions: nProportions, appliedTemplate: strTemplate, assetRefs:strAssetRefs });
			spop.Do(_imgd);
			
			var bmdOrigBackground:BitmapData = _imgd.background;
			FitDocumentToPhotoGrid(cxPreferred, cyPreferred);
			
			if (fUndoable)
				_imgd.EndUndoTransaction();
			else if (bmdOrigBackground != null)
				VBitmapData.SafeDispose(bmdOrigBackground);
		}
		
		private static const kcCellsMax:int = 64;

		private function OnRowsSliderChange(evt:SliderEvent): void {
			if (_imgd == null || _phgd.numRows == evt.value)
				return;
				
			// Preserve these because the EndUndoTransaction below might revert them to prior values
			var cRows:int = _sldrRows.value;
			var cCols:int = _sldrColumns.value;
			_imgd.EndUndoTransaction(false); // Cancel in-progress transaction, if any
			_imgd.BeginUndoTransaction("Change " + DocumentObjectUtil.objectTypeName(_phgd) + " Rows", false, true, false);
			
			// Allow collages up to kcCellsMax cells big, reducing the other dimension if necessary to satisfy this one
			if (cRows * cCols > kcCellsMax) {
				cCols = int(kcCellsMax / cRows);
				_sldrColumns.value = cCols;
			}
			var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(_phgd.name,
					{ numRows: cRows, numColumns: cCols });
			spop.Do(_imgd);
			
			FitDocumentToPhotoGrid();
			
			if (evt.clickTarget == SliderEventClickTarget.TRACK)
				_imgd.EndUndoTransaction();
		}

		private function OnPendingTransactionSliderThumbRelease(evt:SliderEvent): void {
			_imgd.EndUndoTransaction();
		}
		
		private function OnColumnsSliderChange(evt:SliderEvent): void {
			if (_imgd == null || _phgd.numColumns == evt.value)
				return;
				
			// Preserve these because the EndUndoTransaction below might revert them to prior values
			var cRows:int = _sldrRows.value;
			var cCols:int = _sldrColumns.value;
			_imgd.EndUndoTransaction(false); // Cancel in-progress transaction, if any
			_imgd.BeginUndoTransaction("Change " + DocumentObjectUtil.objectTypeName(_phgd) + " Columns", false, true, false);
			
			// Allow collages up to kcCellsMax cells big, reducing the other dimension if necessary to satisfy this one
			if (cRows * cCols > kcCellsMax) {
				cRows = int(kcCellsMax / cCols);
				_sldrRows.value = cRows;
			}
			var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(_phgd.name,
					{ numRows: cRows, numColumns: cCols });
			spop.Do(_imgd);
			
			FitDocumentToPhotoGrid();
			
			if (evt.clickTarget == SliderEventClickTarget.TRACK)
				_imgd.EndUndoTransaction();
		}
		
		private function OnGapSliderChange(evt:SliderEvent): void {
			var nCookedGap:Number = evt.value / 1000; // Results in a gap size from 0 to 0.1 (0 - 10%)
			if (_imgd == null || _phgd.gap == nCookedGap)
				return;

			_imgd.EndUndoTransaction(false); // Cancel in-progress transaction, if any
			_imgd.BeginUndoTransaction("Change " + DocumentObjectUtil.objectTypeName(_phgd) + " Spacing", false, true, false);

			var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(_phgd.name,
					{ gap: nCookedGap });
			spop.Do(_imgd);
					
			FitDocumentToPhotoGrid();
			
			if (evt.clickTarget == SliderEventClickTarget.TRACK)
				_imgd.EndUndoTransaction();
		}
		
		private function OnKookinessSliderChange(evt:SliderEvent): void {
			var nKookiness:Number = evt.value / 100;
			if (nKookiness == _phgd.kookiness)
				return;
			DocumentObjectUtil.AddPropertyChangeToUndo("Change " + DocumentObjectUtil.objectTypeName(_phgd) + " Kookiness",
					_imgd, _phgd, { kookiness: nKookiness }, true);
			
			if (evt.clickTarget == SliderEventClickTarget.TRACK)
				DocumentObjectUtil.SealUndo(_imgd);
		}
		
		private function OnProportionsSliderChange(evt:SliderEvent): void {
			if (_imgd == null || _phgd.proportions == evt.value)
				return;
			
			_imgd.EndUndoTransaction(false); // Cancel in-progress transaction, if any
			_imgd.BeginUndoTransaction("Change " + DocumentObjectUtil.objectTypeName(_phgd) + " Proportions", false, true, false);
			
			var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(_phgd.name,
					{ proportions: evt.value });
			spop.Do(_imgd);
			
			FitDocumentToPhotoGrid();
			
			if (evt.clickTarget == SliderEventClickTarget.TRACK)
				_imgd.EndUndoTransaction();
		}
		
		private function OnRoundednessSliderChange(evt:SliderEvent): void {
			var nRoundedPct:Number = evt.value / 10;
			if (nRoundedPct == _phgd.roundedPct)
				return;
			DocumentObjectUtil.AddPropertyChangeToUndo("Change " + DocumentObjectUtil.objectTypeName(_phgd) + " Rounded Percent",
					_imgd, _phgd, { roundedPct: nRoundedPct }, true);
			
			if (evt.clickTarget == SliderEventClickTarget.TRACK)
				_imgd.EndUndoTransaction();
		}
		
		private function OnSealableSliderThumbRelease(evt:SliderEvent): void {
			DocumentObjectUtil.SealUndo(_imgd);
		}
		
		private function OnBackgroundColorOpen(evt:DropdownEvent): void {
			_fLiveColorChanging = true;
		}
		
		private function OnBackgroundColorChange(evt:ColorPickerEvent): void {
			_fLiveColorChanging = false;
			DocumentObjectUtil.SealUndo(_imgd);
		}
		
		public function OnBackgroundLiveColorChange(evt:Event): void {
			if (!_fLiveColorChanging)
				return;
			DocumentObjectUtil.AddPropertyChangeToUndo("Change " + DocumentObjectUtil.objectTypeName(_phgd) + " Background Color",
					_imgd, _phgd, { backgroundColor: _cpkrBackground.liveColor }, true);
		}
		
		private function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			if (_imgd) {
				_imgd.removeEventListener(ChildExistenceChangedEvent.CHILD_ADD, OnDocumentChildAddRemove);
				_imgd.removeEventListener(ChildExistenceChangedEvent.CHILD_REMOVE, OnDocumentChildAddRemove);
			}
			_imgd = PicnikBase.app.activeDocument as ImageDocument;
			
			if (_imgd) {
				_imgd.addEventListener(ChildExistenceChangedEvent.CHILD_ADD, OnDocumentChildAddRemove);
				_imgd.addEventListener(ChildExistenceChangedEvent.CHILD_REMOVE, OnDocumentChildAddRemove);
				OnDocumentChildAddRemove();
				
				// HACK: Find a PhotoGrid and bind to it
				for (var i:int = 0; i < _imgd.documentObjects.numChildren; i++) {
					var dob:DisplayObject = _imgd.documentObjects.getChildAt(i);
					if (dob is PhotoGrid) {
						_phgd = PhotoGrid(dob);
						break;
					}
				}
			}
		}
		
		private function OnDocumentChildAddRemove(evt:ChildExistenceChangedEvent=null): void {
			populatedTargetCount = Target.GetPopulatedTargetCount(_imgd.documentObjects);
		}
		
		private function OnRestoreComplete(evt:LoginEvent): void {
			if (!_fActive || PicnikBase.app.activeDocument != null)
				return;
				
			// If application state restoration failed to produce an ImageDocument
			// go ahead and create one from scratch.
			NewCollage(kcDefaultColumns, kcDefaultRows, kcxDefaultGap, null, false);
		}
		
		//
		// IActivatable implementation
		//
		
		protected function SetupNewCollageState(): void {
			NewCollage(kcDefaultColumns, kcDefaultRows, kcxDefaultGap, null, false);
		}
		
		public function OnActivate(strCmd:String=null): void {
			Debug.Assert(!_fActive, "CollageBase.OnActivate already active!");
			
			_fActive = true;
			PicnikBase.app.addEventListener(ActiveDocumentEvent.CHANGE, OnActiveDocumentChange);
			if (!PicnikBase.app.restoringState && PicnikBase.app.activeDocument == null) {
				_phgd = null;
				SetupNewCollageState();
			}
			
			OnActiveDocumentChange(new ActiveDocumentEvent(ActiveDocumentEvent.CHANGE, null,
					PicnikBase.app.activeDocument));
			
			AttachZoomView();
			_zmv.imageView.targetsEnabled = true;
			_zmv.imageView.FilterSelection(ImageView.kNoSelection);
			_zmv.allowDropOntoCanvas = false;
			
			// Hook up undo/redo/save to the current ImageDocument
			_urs.Activate();
			
			// Do this after the ZoomView, which the tips are positioned relative to, is attached
			// UNDONE: this sucks. We should establish and enforce a rule that OnActivate calls
			// ALWAYS come after CREATION_COMPLETE
			if (initialized)
				ShowTips(); // Only shows tips if the user hasn't closed them yet
		}
		
		public function OnDeactivate(): void {
			HideTips();
			
			PicnikBase.app.removeEventListener(ActiveDocumentEvent.CHANGE, OnActiveDocumentChange);
			_fActive = false;
			PicnikBase.app.DetachZoomView(this);
			_zmv.allowDropOntoCanvas = true;
			_zmv.imageView.targetsEnabled = false;
			_zmv.imageView.ReparentObjectPalette(_zmv);
			_zmv = null;
			
			// Detach undo/redo/save from the current ImageDocument
			_urs.Deactivate();
		}
		
		public function get active(): Boolean {
			return _fActive;
		}
		
		private function AttachZoomView(): void {
			// Show the master view but apply the template view's style to it
			_zmv = PicnikBase.app.AttachZoomView(this, _cvsTemplate);
			_zmv.imageView.ReparentObjectPalette(Application.application as DisplayObjectContainer);
		}
		
		//
		// Top level user interface
		//
		
		private function GetAutoFillTargets(): Array {
			var atgt:Array = [];
			if (_phgd) {
				atgt = _phgd.GetAutoFillTargets();
			}
			return atgt;
		}
		
		private function CreateAssetSources(nTargets:Number):Array {
			var csr:IViewCursor = collection.createCursor();
			csr.seek(CursorBookmark.FIRST);
			return ImagePropertiesUtil.GetAssetSourceArray(csr, nTargets);
		}

		private function SetPhoto(tgt:Target, asrc:IAssetSource): void {
			var dob:DisplayObject = Photo.Create(_imgd, asrc, new Point(100,100), new Point(0,0),
					FitMethod.SNAP_TO_MIN_WIDTH_HEIGHT, _zmv.imageView.zoom, tgt.name);
		}
		
		public function GetBasket(): Basket {
			return PicnikBase.app.basket;
		}
		
		private function OnUpgradeClick(evt:MouseEvent): void {
			DialogManager.ShowUpgrade("/collage/upgrade_button", this);
		}
		
		private function OnInfoClick(evt:MouseEvent): void {
			if (_btnInfo.selected)
				ShowTips(true);
			else
				HideTips(true);				
		}
		
		private function OnShuffleClick(evt:MouseEvent): void {
			if (_phgd == null) return;
			
			_imgd.BeginUndoTransaction("Shuffle Collage", false, false);
			
			// Make a list of the Targets
			var atgt:Array = _phgd.GetAutoFillTargets();
			
			// Run through the list, picking a random Target to provide its Photo
			var atgtNew:Array = new Array(atgt.length);
			for (var i:int = 0; i < atgt.length; i++)
				atgtNew[i] = atgt[Math.round(Math.random() * (atgt.length - 1))];
				
			// Assign the Target's contents to their new parents
			for (i = 0; i < atgt.length; i++) {
				var tgt:Target = Target(atgt[i]);
				var tgtNew:Target = Target(atgtNew[i]);
				if (tgt.populated && tgt != tgtNew)
					Target.MoveOrSwapTargetContents(tgt, tgtNew);
			}
			
			_imgd.EndUndoTransaction();
		}
		
		protected function OnNormalResolutionClick(evt:MouseEvent=null): void {
			if (_imgd == null)
				return;
			ChangeResolution(kcxNormalResolution, kcyNormalResolution);
		}
		
		protected function OnPrintResolutionClick(evt:MouseEvent=null): void {
			if (_imgd == null)
				return;
			var cx:Number = _cxPrintResolution;
			var cy:Number = _cyPrintResolution;
			if (_phgd) {
				if (_phgd.preferredWidth > 0) cx = _phgd.preferredWidth;
				if (_phgd.preferredHeight > 0) cy = _phgd.preferredHeight;
			}
			ChangeResolution(cx, cy);
		}
		
		private function ChangeResolution(cx:int, cy:int): void {
			_imgd.BeginUndoTransaction("Change " + DocumentObjectUtil.objectTypeName(_phgd) + " Resolution", false, true, false);
			
			var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(_phgd.name,
					{ fitWidth: cx, fitHeight: cy });
			spop.Do(_imgd);
			
			FitDocumentToPhotoGrid();
			_imgd.EndUndoTransaction();
		}
		
		private function OnClearClick(evt:MouseEvent): void {
			if (_phgd == null) return;
			
			_imgd.BeginUndoTransaction("Clear Collage", false, false);
			DestroyTargetContents(_imgd.documentObjects);
			_imgd.EndUndoTransaction();
		}
		
		// Recurse into all child DisplayObjectContainers to find all Targets.
		private function DestroyTargetContents(dobc:DisplayObjectContainer): void {
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var dob:DisplayObject = dobc.getChildAt(i);
				if (dob is Target) {
					var tgt:Target = Target(dob);
					if (tgt.populated)
						tgt.DestroyContents();
				}
				
				// Recurse to find all Targets
				if (dob is DisplayObjectContainer)
					DestroyTargetContents(DisplayObjectContainer(dob));
			}
		}
		
		private function OnAutoFillClick(evt:MouseEvent): void {
			if (_phgd == null) return;
			
			var cRows:Number = _phgd.numRows;
			var cCols:Number = _phgd.numColumns;
			var tgt:Target;
			
			// Now take a look at the current bridge
			var atgt:Array = GetAutoFillTargets();
			if (collection && collection.length > 0 && atgt.length > 0) {
				var fTargetsPopulated:Boolean = false;
				for each (tgt in atgt) {
					if (tgt.populated) {
						fTargetsPopulated = true;
						break;
					}
				}
				
				// Now start our transaction
				_imgd.BeginUndoTransaction("Auto fill Collage", false, false);
				
				if (fTargetsPopulated) {
					for each (tgt in atgt) {
						if (tgt.populated)
							tgt.DestroyContents();
					}
				}
				
				var aasrc:Array = CreateAssetSources(atgt.length);
	
				// Now create these items and drop them into the correct places
				for (var i:Number = Math.min(atgt.length, aasrc.length) - 1; i >= 0; i--)
					SetPhoto(atgt[i], aasrc[i]);

				_imgd.EndUndoTransaction();
			} else {
				trace("no collection");
			}
		}

		// Resize the document to match the size of the PhotoGrid. Typically done inside an
		// UndoTransaction.
		private function FitDocumentToPhotoGrid(cxPreferred:Number=NaN, cyPreferred:Number=NaN): Boolean {
			// Make sure the PhotoGrid has validated its dimensions
			_phgd.Validate();
			
			// Resize the document to match the PhotoGrid
			var cx:int = _phgd.unscaledWidth;
			var cy:int = _phgd.unscaledHeight;
			
			if (!isNaN(cxPreferred) && !isNaN(cyPreferred) && _btnPrintResolution.selected) {
				// If we are loading a template with preferred dimensions and we are in print view,
				// make sure we resize the document to the preferred dimensions of the template.
				cx = cxPreferred;
				cy = cyPreferred;
			}
			
			var op:ImageOperation = new ResizeImageOperation(cx, cy, true, false, false);
			if (!op.Do(_imgd, true, false))
				return false;
			
			// Center the PhotoGrid within the resized document
			var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(_phgd.name, { x: cx / 2, y: cy / 2 });
			spop.Do(_imgd);
			
			// Force the composite to be generated ahead of any sneaky display updates
			var bmdComposite:BitmapData = _imgd.composite;
			return true;
		}
		
		protected function get tipsName(): String {
			return "collage_1";
		}
		
		private function ShowTips(fForce:Boolean=false): void {
			_tip = TipManager.ShowTip(tipsName, fForce);
			if (_tip != null) {
				_btnInfo.selected = true;
				_tip.addEventListener(Event.REMOVED, OnTipHide);
			}
		}
		
		private function HideTips(fClose:Boolean=false): void {
			if (_tip)
				TipManager.HideTip(_tip.id, false, fClose); // don't fade out the tip
		}
		
		private function OnTipHide(evt:Event): void {
			// Distinguish between the REMOVED event we care about and bubbled up events
			if (evt.target != _tip)
				return;
				
			if (_tip) {
				_tip.removeEventListener(Event.REMOVED, OnTipHide);
				_tip = null;
			}
			_btnInfo.selected = false;
		}
	}
}
