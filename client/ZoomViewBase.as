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
	import com.adobe.utils.StringUtil;
	
	import containers.CanvasPlus;
	import containers.ResizingDialog;
	
	import controls.MiniView;
	import controls.MouseFollowingPremiumNag;
	import controls.MouseFollowingPremiumNagBase;
	import controls.ResizingButton;
	import controls.ResizingText;
	import controls.Tip;
	
	import dialogs.DialogManager;
	
	import events.*;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.utils.*;
	
	import imagine.ImageDocument;
	import imagine.documentObjects.DocumentStatus;
	import imagine.documentObjects.FitMethod;
	import imagine.documentObjects.Photo;
	import imagine.imageOperations.ResizeImageOperation;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.Canvas;
	import mx.controls.CheckBox;
	import mx.controls.HSlider;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.effects.easing.Quadratic;
	import mx.events.DragEvent;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	import mx.events.StyleEvent;
	import mx.managers.DragManager;
	import mx.managers.IHistoryManagerClient;
	import mx.resources.ResourceBundle;
	
	import overlays.*;
	
	import picnik.util.Animator;
	
	import util.GooglePlusUtil;
	import util.IDragImage;
	import util.LocUtil;
	import util.PerformanceManager;
	import util.SessionTransfer;
	import util.TipManager;
	
	import viewObjects.TargetViewObject;
	import viewObjects.ViewObject;
	
	import views.TargetAwareView;

	public class ZoomViewBase extends CanvasPlus implements IHistoryManagerClient {
		public static const kcFreePhotoLimit:int = 2;
		
		// MXML-defined variables
		[Bindable] public var _imgv:TargetAwareView;
		[Bindable] public var _sldrZoom:HSlider;
		[Bindable] public var _lbZoom:Label;
		[Bindable] public var _imgZoomOut:Image;
		[Bindable] public var _imgZoomIn:Image;
		[Bindable] public var _btnZoomOut:ResizingButton;
		[Bindable] public var _btnZoomIn:ResizingButton;
		[Bindable] public var _lbDimensions:Label;
		[Bindable] public var _imgPremiumBanner:Image;
		[Bindable] public var _cvsZoomBox:Canvas;
		[Bindable] public var _cvsMiniView:Canvas;
		[Bindable] public var _txtUpsellHelpLogin:ResizingText;
		[Bindable] public var _minv:MiniView;
		[Bindable] public var uimode:String = "";

   		[Bindable] [ResourceBundle("ZoomView")] protected var rb:ResourceBundle;
   		[Bindable] [ResourceBundle("Picnik")] protected var rbPicnik:ResourceBundle;
		
		[Bindable] public var _imgd:ImageDocument;
		
		private var _stateInit:Object;
		private var _fPremiumPreview:Boolean = false;
		private var _chwIsPaid:ChangeWatcher;
		private var _chwHasCredentials:ChangeWatcher;
		private var _chwLiteUI:ChangeWatcher;
		private var _voDragTarget:ViewObject;
		private var _fAllowDropOntoCanvas:Boolean = true;

		private var _fHidden:Boolean = false;

		// Resize warning states
		protected static const NO_PROBLEM:Number = 0; // Image is small enough that we don't care
		protected static const LARGE_IMAGE:Number = 1; // Image is large, but not slow
		protected static const LARGE_AND_SLOW:Number = 2; // Image is large and slow
		
		[Bindable] protected var _nImagePerformanceState:Number = NO_PROBLEM;

		private var _tp:Tip = null;
		
		private static const knLargePhotoSize:Number = 2500; // Warn on photos equal to or larger than this
		private static const knResizeDownToMaxDimension:Number = 2000; // Resize so max widht/height is this number
		private static const knResizeDownToMaxDimensionSquare:Number = 1800; // Resize square-ish images down to this max size (square is aspect ratio > 0.825)

		private var _aobVisibleWatchers:Array = null; // Array of changewatchers and display objects we are listening to.
		
		private var _fAutoShown:Boolean = false;
		
		public function ZoomViewBase() {
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			PicnikBase.app.skin.addEventListener( StyleEvent.COMPLETE, OnSkinChange );
			PerformanceManager.Inst().addEventListener("change", OnPerformanceChange);
			UpdateLiteZoomUI();
		}
		
		private function OnPerformanceChange(evt:Event): void {
			UpdatePerformanceState();
		}
		
		private function UpdatePerformanceState(): void {
			var nNewState:Number = NO_PROBLEM;
			if (_imgd != null && !_imgd.isCollage && !_imgd.isFancyCollage && (_imgd.width >= knLargePhotoSize || _imgd.height >= knLargePhotoSize)) {
				// Large image
				nNewState = (PerformanceManager.Inst().isSlow) ? LARGE_AND_SLOW : LARGE_IMAGE;
			}
			if (nNewState == LARGE_AND_SLOW && _nImagePerformanceState != LARGE_AND_SLOW && ResizeWarningOn())
				ShowResizeTip(true);
			_nImagePerformanceState = nNewState;
		}
		
		private function OnVisibleChange(evt:Event): void {
			if (!_tp.showing) return;
			var fVisible:Boolean = true;
			var dob:DisplayObject = this;
			while (fVisible && dob != null && !(dob is Stage)) {
				if (!dob.visible) fVisible = false;
				dob = dob.parent;
			}
			if (dob == null) fVisible = false;
			if (!fVisible) _tp.Hide(false);
		}

		protected function ShowResizeTip(fAutoShow:Boolean=false): void {
			if (_nImagePerformanceState == NO_PROBLEM) return;
			if (_aobVisibleWatchers == null) {
				_aobVisibleWatchers = [];
				var dob:DisplayObject = this;
				while (dob != null && !(dob is Stage)) {
					_aobVisibleWatchers.push(ChangeWatcher.watch(dob, "visible", OnVisibleChange));
					_aobVisibleWatchers.push(dob);
					dob.addEventListener(Event.REMOVED_FROM_STAGE, OnVisibleChange, false, 0, true);
					dob = dob.parent;
				}
			}
			if (fAutoShow) {
				Util.UrchinLogReport("/AutoResizeDialog/Show");
				_fAutoShown = true;
			}
			if (_tp == null) {
				_tp = TipManager.ShowTip("resize_warning", true);
				_tp.contentWidth = 314;
				_tp._tr.actionTarget = this;
			} else if (!_tp.showing) {
				_tp.Show();
			}
		}
		
		public function ResizeWarningOn(): Boolean {
			return AccountMgr.GetInstance().GetUserAttribute("ZoomView.AutoShowResizeTip", true);
		}
		
		public function OnResizeWarningClick(evt:Event): void {
			var cb:CheckBox = evt.target as CheckBox;
			if (cb) {
				AccountMgr.GetInstance().SetUserAttribute("ZoomView.AutoShowResizeTip", cb.selected);
			}
		}
		
		private function DoResize(): void {
			if (_imgd != null) {
				// UNDONE: What if we are in the middle of an effect? Need to close effects, etc.
				var nScale:Number = 1;
				nScale = Math.min(nScale, knResizeDownToMaxDimension / _imgd.width, knResizeDownToMaxDimension / _imgd.height);
				
				// Square-ish images get smaller.
				if ((Math.min(_imgd.width, _imgd.height) /  Math.max(_imgd.width, _imgd.height)) > 0.825)
					nScale = nScale * knResizeDownToMaxDimensionSquare / knResizeDownToMaxDimension;
				
				if (nScale < 1) {
					_imgd.BeginUndoTransaction("Auto Resize");
					var op:ResizeImageOperation = new ResizeImageOperation(Math.round(_imgd.width * nScale), Math.round(_imgd.height * nScale));
					if (!op.Do(_imgd, true, false))
						_imgd.AbortUndoTransaction();
					_imgd.EndUndoTransaction();
				}
			}
			_tp.Hide(true);
		}
		
		public function ResizePhotoSmaller(): void {
			if (_fAutoShown) {
				Util.UrchinLogReport("/AutoResizeDialog/Resize");
				_fAutoShown = false;
			}
			
			if (_imgd != null) {
		    	var actl:IActionListener = PicnikBase.app._tabn.selectedChild as IActionListener;
		    	if (actl)
					actl.PerformActionIfSafe(new Action(DoResize));
				else
					DoResize();
			} else {
				_tp.Hide(true);
			}
		}
		
		protected function getHelpText(fIsPaid:Boolean, fHasCredentials:Boolean, pas:PicnikAsService, fSuperLite:Boolean): String {
			if (pas == null) return "";			
			var strPartner:String = pas.GetServiceParameter( "_host_name" );
			
			// BUGBUG we should create a default _host_name for flickrlite
			if (PicnikBase.app.flickrlite && strPartner.length == 0)
				strPartner = "Flickr";
				
			var strPoweredByPicnik:String = "";
			// we've decided that the "powered by picnik" stuff is no longer necessary
			//			if (strPartner == "Photobox")
			//				strPoweredByPicnik = LocUtil.rbSubst('ZoomView', 'powered_by_picnik2', strPartner) + ' ';
			//			else
			//				strPoweredByPicnik = LocUtil.rbSubst('ZoomView', 'powered_by_picnik', strPartner) + ' ';
			if (fSuperLite) {
				return "";
			}
				
			if (fIsPaid) {
				if (!fHasCredentials) {
					return strPoweredByPicnik +
						   htmlLink(Resource.getString('Picnik', 'get_picnik_login'), 'register') + ' &nbsp;&nbsp;' +
						   LocUtil.rbSubst('ZoomView', 'help', PicnikBase.app.skin.GetColor(".liteUrlColor")) + ' &nbsp;&nbsp;' +
						   htmlLink(Resource.getString('Picnik', 'open_in_picnik'), 'openInPicnik');
				} else {
					return strPoweredByPicnik + 
						   LocUtil.rbSubst('ZoomView', 'help', PicnikBase.app.skin.GetColor(".liteUrlColor")) + ' &nbsp;&nbsp;' +
						   htmlLink(Resource.getString('Picnik', 'open_in_picnik'), 'openInPicnik');
				}
			} else {
				return strPoweredByPicnik + 
					   LocUtil.rbSubst('ZoomView', 'upsell', PicnikBase.app.skin.GetColor(".liteUrlColor")) + ' ' +
					   LocUtil.rbSubst('ZoomView', 'help', PicnikBase.app.skin.GetColor(".liteUrlColor")) + ' &nbsp;&nbsp;' + 
					   htmlLink(Resource.getString('Picnik', 'open_in_picnik'), 'openInPicnik');
			}
		}
		
		private function htmlLink(strText:String, strEvent:String): String {
			return "<font color=\"#" + PicnikBase.app.skin.GetColor(".liteUrlColor") +
					"\"><u><a href=\"event:" + strEvent + "\">" + strText + "</a></u></font>";	
		}
		
		private function OnInitialize(evt:Event): void {
			UpdateLiteZoomUI();
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			if (imgd != null)
				MonitorImageDocument(imgd)
				
			PicnikBase.app.addEventListener(ActiveDocumentEvent.CHANGE, OnActiveDocumentChange);
			_sldrZoom.addEventListener(Event.CHANGE, OnZoomSliderChange);
			_imgv.Constructor();
			_imgv.addEventListener(ImageViewEvent.ZOOM_CHANGE, OnViewZoomChange);
			_imgv.addEventListener("layoutChange", OnViewLayoutChange);
			
			_imgZoomIn.addEventListener(MouseEvent.CLICK, OnZoomInClick);
			_imgZoomOut.addEventListener(MouseEvent.CLICK, OnZoomOutClick);
			_btnZoomIn.addEventListener(MouseEvent.CLICK, OnZoomInClick);
			_btnZoomOut.addEventListener(MouseEvent.CLICK, OnZoomOutClick);
			
			_chwIsPaid = ChangeWatcher.watch(AccountMgr.GetInstance(), "isPremium", OnIsPaidChange);
			_chwHasCredentials = ChangeWatcher.watch( AccountMgr.GetInstance(), "hasCredentials", OnHasCredentialsChange);
			_chwLiteUI= ChangeWatcher.watch(PicnikBase.app, "liteUI", UpdateLiteZoomUI);
			addEventListener(DragEvent.DRAG_ENTER, OnDragEnter);
			addEventListener(DragEvent.DRAG_OVER, OnDragOver);
			addEventListener(DragEvent.DRAG_DROP, OnDragDrop);
			addEventListener(DragEvent.DRAG_EXIT, OnDragExit);
			_txtUpsellHelpLogin.addEventListener(TextEvent.LINK, OnUpsellHelpLoginClick);
			_minv.imageView = _imgv;
			
			if (_stateInit != null)
				loadState(_stateInit);
			UpdatePerformanceState();
		}
		
		// Support drag-drops from the Basket
		private function OnDragEnter(evt:DragEvent): void {
			if (_imgd == null)
				return;
				
			// If dragging over a ViewObject, send it a VIEW_DRAG_ENTER event. Remember it so
			// we can send it a VIEW_DRAG_EXIT event at the appropriate time.
			_voDragTarget = null;
			var vo:ViewObject = imageView.HitTestViewObjects(evt.stageX, evt.stageY);
			if (vo != null) {
				var evtEnter:ViewDragEvent = NewViewDragEvent(ViewDragEvent.VIEW_DRAG_ENTER, evt);
				vo.dispatchEvent(evtEnter);
				if (evtEnter.targetDisplayObject != null) {
					_voDragTarget = vo;
//					DragManager.showFeedback(DragManager.COPY);
					DragManager.acceptDragDrop(this);
				}
				if (evtEnter.isDefaultPrevented()) {
					evt.preventDefault();
					return;
				}
			}
		
			if (_fAllowDropOntoCanvas) {
				if (IsAtFreeLimit()) {
					DragManager.showFeedback(DragManager.NONE);
					
					// When DragManager is in feedback mode NONE it doesn't send a DRAG_DROP
					// event. We need to know when dragging is finished so we can clear out
					// the nag.
					evt.dragInitiator.addEventListener(DragEvent.DRAG_COMPLETE, OnDragComplete);
					ShowPremiumNag();
				} else {
					// Set scale function
					var dgimg:IDragImage = evt.dragSource.dataForFormat("dragImage") as IDragImage;
					if (dgimg) dgimg.getDropScaleFunction = _imgv.GetDropSize;
					DragManager.showFeedback(DragManager.COPY);
				}
				DragManager.acceptDragDrop(this);
				evt.preventDefault();
			} else {
				DragManager.showFeedback(DragManager.NONE);
			}
		}
		
		private function OnDragExit(evt:DragEvent): void {
			HidePremiumNag();
			
			// If already dragging over a ViewObject, send it a DRAG_EXIT event.
			if (_voDragTarget != null) {
				var evtExit:ViewDragEvent = NewViewDragEvent(ViewDragEvent.VIEW_DRAG_EXIT, evt);
				_voDragTarget.dispatchEvent(evtExit);
				_voDragTarget = null;
			}
			
			if (_fAllowDropOntoCanvas) {
				// Clear scale function
				var dgimg:IDragImage = evt.dragSource.dataForFormat("dragImage") as IDragImage;
				if (dgimg) dgimg.getDropScaleFunction = null;
			}
		}
		
		private function OnDragOver(evt:DragEvent): void {
			if (_imgd == null)
				return;
				
			// Send Enter, Exit, and Over events to ViewObjects
			var vo:ViewObject = imageView.HitTestViewObjects(evt.stageX, evt.stageY);
			if (vo != _voDragTarget) {
				if (_voDragTarget != null) {
					// Dispatch VIEW_DRAG_EXIT event to old drag target
					_voDragTarget.dispatchEvent(NewViewDragEvent(ViewDragEvent.VIEW_DRAG_EXIT, evt));
					//evt.preventDefault();
					
					// If there is no new drag target send a DRAG_ENTER to the background.
					if (vo == null)
						dispatchEvent(NewViewDragEvent(DragEvent.DRAG_ENTER, evt));
				}
				
				_voDragTarget = null;
				
				if (vo != null) {
					// Dispatch VIEW_DRAG_ENTER event to new drag target
					var evtEnter:ViewDragEvent = NewViewDragEvent(ViewDragEvent.VIEW_DRAG_ENTER, evt);
					vo.dispatchEvent(evtEnter);
					if (evtEnter.targetDisplayObject != null) {
						_voDragTarget = vo;
//						DragManager.showFeedback(DragManager.COPY);
						evt.preventDefault();
					}
				}
			} else if (vo != null) {
				// Dispatch VIEW_DRAG_OVER event to _voDragTarget
				vo.dispatchEvent(NewViewDragEvent(ViewDragEvent.VIEW_DRAG_OVER, evt));
//				DragManager.showFeedback(DragManager.COPY);
				evt.preventDefault();
			} else {
				if (_fAllowDropOntoCanvas && !IsAtFreeLimit())
					DragManager.showFeedback(DragManager.COPY);
				else
					DragManager.showFeedback(DragManager.NONE);
			}
			
			if (_fAllowDropOntoCanvas)
				evt.preventDefault();
		}
		
		private function OnDragComplete(evt:DragEvent): void {
			evt.dragInitiator.removeEventListener(DragEvent.DRAG_COMPLETE, OnDragComplete);
			HidePremiumNag();
		}

		static private function NewViewDragEvent(strType:String, evt:DragEvent): ViewDragEvent {
			return new ViewDragEvent(strType, false, false,
					evt.dragInitiator, evt.dragSource, evt.action, evt.ctrlKey, evt.altKey, evt.shiftKey);
		}
		
		private function OnDragDrop(evt:DragEvent): void {
			var dgimg:IDragImage = evt.dragSource.dataForFormat("dragImage") as IDragImage;
			if (!dgimg) {
				if (!(evt.dragSource.dataForFormat("TargetViewObject") as TargetViewObject)) {
					trace("Error: missing basket drag image");
					return;
				}
			}

			// If dragging over a ViewObject, send it the DRAG_DROP event.
			if (_voDragTarget != null) {
				_voDragTarget.dispatchEvent(NewViewDragEvent(ViewDragEvent.VIEW_DRAG_DROP, evt));
			} else if (_fAllowDropOntoCanvas) {

				var ptTargetSize:Point = _imgv.GetDropSize(dgimg.aspectRatio, dgimg.scaleWeight, dgimg.groupScale != 0.0);
				if (dgimg.groupScale != 0.0) {
					ptTargetSize.x *= dgimg.groupScale;
					ptTargetSize.y *= dgimg.groupScale;
				}
				
				imageView.imageDocument.BeginUndoTransaction("Create " + dgimg.createType, true, false);
				SelectWhenLoaded(dgimg.DoAdd(imageView.imageDocument, ptTargetSize, imageView, FitMethod.SNAP_TO_AREA, _imgv.zoom));
				imageView.imageDocument.EndUndoTransaction();
			}
		}
		
		// Watch the object's status and select it when it has loaded. In the meantime,
		// if any other object is selected forget that we were planning to select this one.
		// UNDONE: leaks?
		public function SelectWhenLoaded(dob:DisplayObject): void {
			if (_dobSelectWhenLoaded) {
				_dobSelectWhenLoaded.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnSelectWhenLoadedPropertyChange);
				_imgd.removeEventListener(ImageDocumentEvent.SELECTED_ITEMS_CHANGE, OnDocumentSelectedItemsChange);
			}
			_dobSelectWhenLoaded = dob;
			
			// Listen for when the object's status changes to Loaded
			_dobSelectWhenLoaded.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnSelectWhenLoadedPropertyChange);
			
			// Listen for other objects being selected. That will cause us to lose interest
			// in selecting this object after it loads.
			_imgd.addEventListener(ImageDocumentEvent.SELECTED_ITEMS_CHANGE, OnDocumentSelectedItemsChange);
		}
		
		private var _dobSelectWhenLoaded:DisplayObject = null;
		
		// If the object we are planning to select finishes loading and nothing has happened
		// in the meantime to change our mind (e.g. a new object starts loading or the user
		// manually selects something else), select it.
		private function OnSelectWhenLoadedPropertyChange(evt:PropertyChangeEvent): void {
			if (evt.property == "status") {
				if (Number(evt.newValue) != DocumentStatus.Loading) {
					evt.target.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnSelectWhenLoadedPropertyChange);
					_imgd.removeEventListener(ImageDocumentEvent.SELECTED_ITEMS_CHANGE, OnDocumentSelectedItemsChange);
					if (_dobSelectWhenLoaded == evt.target) {
						_imgd.selectedItems = [ _dobSelectWhenLoaded ];
						_dobSelectWhenLoaded = null;
					}
				}
			}
		}
		
		// If another object is selected, forget about the one we wanted to select.
		private function OnDocumentSelectedItemsChange(evt:GenericDocumentEvent): void {
			RemoveSelectWhenLoadedListener();
		}
		
		private function RemoveSelectWhenLoadedListener(): void {
			if (_dobSelectWhenLoaded == null)
				return;
			_dobSelectWhenLoaded.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnSelectWhenLoadedPropertyChange);
			_imgd.removeEventListener(ImageDocumentEvent.SELECTED_ITEMS_CHANGE, OnDocumentSelectedItemsChange);
			_dobSelectWhenLoaded = null;
		}
		
		protected function OnUpsellHelpLoginClick(evt:TextEvent): void {
			switch (evt.text) {
			case "upsell":
				var strEvent:String = "/flickr_learn_about/" + PicnikBase.app.selectedTabName;
				strEvent = StringUtil.replace(strEvent, ' ', '_');
				DialogManager.ShowUpgrade(strEvent, UIComponent(Application.application));
				break;
				
			case "help":
				DialogManager.Show("HelpDialog", null, null, {navigate:"help"});
				break;
			
			case "login":
				DialogManager.ShowLogin(UIComponent(Application.application));
				break;
			
			case "register":
				DialogManager.ShowRegister(UIComponent(Application.application));
				break;
			
			case "openInPicnik":
				SessionTransfer.TransferSession();
				break;
			}
		}
		
		//
		// Public properties
		//
		
		[Bindable]
		public function get imageView(): TargetAwareView {
			return _imgv;
		}
		
		public function set imageView(imgv:TargetAwareView): void {
			// do nothing
		}
		
		[Bindable]
		public function set premiumPreview(f:Boolean): void {
			_fPremiumPreview = f;
			if (f)
				OnViewLayoutChange();
		}
		
		public function get premiumPreview(): Boolean {
			return _fPremiumPreview;
		}
		
		[Bindable] public var liteZoomUI:Boolean = false;
		
		private function UpdateLiteZoomUI(evt:Event=null): void {
			// This gets called before _pas is initialized
			liteZoomUI =  PicnikBase.app.liteUI && !GooglePlusUtil.UsingGooglePlusAPIKey(PicnikBase.app.parameters);
		}
		
		[Bindable]
		public function get isPaid(): Boolean {
			return AccountMgr.GetInstance().isPremium;
		}
		
		public function set isPaid(f:Boolean): void {
			// Not needed, except to shut up MXMLC
			// change events are propagated by OnIsPaidChange
		}
		
		[Bindable]
		public function get hasCredentials(): Boolean {
			return AccountMgr.GetInstance().hasCredentials;
		}
		
		public function set hasCredentials(f:Boolean): void {
			// Not needed, except to shut up MXMLC
			// change events are propagated by OnHasCredentialsChange
		}
				
		[Bindable]
		public function set allowDropOntoCanvas(f:Boolean): void {
			_fAllowDropOntoCanvas = f;
		}
		
		public function get allowDropOntoCanvas(): Boolean {
			return _fAllowDropOntoCanvas;
		}
		
		//
		// IHistoryManagerClient implementation
		//
	
		public function loadState(state:Object): void {
			if (_imgv == null) {
				_stateInit = state;
				return;
			}
			_imgv.zoom = state.zoom;
			_imgv.viewX = state.viewX;
			_imgv.viewY = state.viewY;
		}
		
		public function saveState(): Object {
			if (_imgv == null)
				return null;
			return { viewX: _imgv.viewX, viewY: _imgv.viewY, zoom: _imgv.zoom };
		}
		
		//
		// Respond to internal events of interest
		//
		
		private function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			var imgdOld:ImageDocument = evt.docOld as ImageDocument;
			var imgdNew:ImageDocument = evt.docNew as ImageDocument;
			if (imgdOld != null)
				UnmonitorImageDocument(imgdOld);
			if (imgdNew != null)
				MonitorImageDocument(imgdNew);
				
			// maybe we're here after restoring, when previously a premium-only
			// effect was selected.  At this point, no effect will be selected,
			// so ensure that the premium preview banner is hidden.
			premiumPreview = false;
			PerformanceManager.Reset();
			_fAutoShown = false;
			UpdatePerformanceState();
			OnViewLayoutChange(null);
		}
				
		//
		// Keep an eye on the ImageDocument so we can reflect changes to it in the UI
		//
		private function MonitorImageDocument(imgd:ImageDocument): void {
			Debug.Assert(_imgd != imgd, "ZoomViewBase.MonitorImageDocument already monitoring this ImageDocument!");
			_imgd = imgd;
			_imgv.imageDocument = _imgd;
			_imgv.zoom = _imgv.zoomMin;

			_imgd.addEventListener(ImageDocumentEvent.BITMAPDATA_CHANGE, OnBitmapDataChange);
			
			SetZoomSliderRange();
		}
		
		private function UnmonitorImageDocument(imgd:ImageDocument): void {
			Debug.Assert(imgd == _imgd, "Uh, we're not monitoring this document?");

			RemoveSelectWhenLoadedListener();			
			_imgd.removeEventListener(ImageDocumentEvent.BITMAPDATA_CHANGE, OnBitmapDataChange);
			_imgv.imageDocument = null;
			_imgd = null;
		}
		
		protected function OnViewLayoutChange(evt:Event=null): void {
			var fShowMiniView:Boolean = !_imgv.IsEntireImageVisible() && zoomOpen;
			if (fShowMiniView != _cvsMiniView.visible)
				ShowMiniView(fShowMiniView);
			
			if (!_imgPremiumBanner) return;
			
			var fWillBeVisible:Boolean = _fPremiumPreview && !AccountMgr.GetInstance().isPremium;
			
			// BST: bug 32428: _imgd may be null when signing out. Test for this.
			if (_imgd && _fPremiumPreview && _imgPremiumBanner.content && fWillBeVisible) {
				var cxBitmap:Number = _imgd.width * _imgv.zoom;
				var cyBitmap:Number = _imgd.height * _imgv.zoom;
				var nScale:Number = Math.min(cxBitmap / 300, cyBitmap / 300);
				if (nScale > 1.0)
					nScale = 1.0;
				_imgPremiumBanner.scaleX = _imgPremiumBanner.scaleY = nScale;
				Bitmap(_imgPremiumBanner.content).smoothing = true;
				_imgPremiumBanner.validateNow(); // update _imgPremiumBanner's height before using below
					
				_imgPremiumBanner.x = Math.max(_imgv.bitmapX, 0);
				_imgPremiumBanner.y = Math.min(_imgv.bitmapY + (cyBitmap - _imgPremiumBanner.contentHeight), height - _imgPremiumBanner.contentHeight);	
			}
			_imgPremiumBanner.visible = fWillBeVisible;
		}
		
		// Update the premiumPreview when the user's isPaid state changes. This necessary when
		// a guest user starts an premium operation, gets the upgrade message, and remembers to
		// sign in to an existing Premium account.
		private function OnIsPaidChange(evt:PropertyChangeEvent): void {
			premiumPreview = _fPremiumPreview;
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "isPaid", evt.oldValue, evt.newValue));
		}
		
		// Update the premiumPreview when the user's hassPaid state changes.
		private function OnHasCredentialsChange(evt:PropertyChangeEvent): void {
			premiumPreview = _fPremiumPreview;
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "hasCredentials", evt.oldValue, evt.newValue));
		}
		
		// Update the colors of the bottom text when the skin changes
		private function OnSkinChange(evt:StyleEvent): void {
			// we fire an "isPaid" change just to force the text to reload
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "isPaid", isPaid, isPaid));
		}
		
		//
		// Zoom UI
		//

		private var _amtr:Animator;
		[Bindable] protected var zoomOpen:Boolean = true;
				
		protected function ToggleZoomBoxOpenClose(strProperty:String, cxyOpen:Number, cxyClose:Number, cmsDuration:Number=333): void {
			if (_amtr)
				_amtr.Dispose();
			var cxyDst:Number;
			if (_cvsZoomBox.getStyle(strProperty) == cxyOpen) {
				cxyDst = cxyClose;
				zoomOpen = false;
				if (_cvsMiniView.visible)
					ShowMiniView(false);
			} else {
				cxyDst = cxyOpen;
				zoomOpen = true;
				if (!_imgv.IsEntireImageVisible())
					ShowMiniView(true);
			}
			_amtr = new Animator(_cvsZoomBox, strProperty, NaN, cxyDst, cmsDuration, Quadratic.easeOut);
		}
		
		private var _amtrMiniView:Animator;
		
		private function ShowMiniView(fShow:Boolean): void {
			if (_amtrMiniView)
				_amtrMiniView.Dispose();
			_amtrMiniView = new Animator(_cvsMiniView, "alpha", NaN, fShow ? 1.0 : 0.0, 150, null, false, true,
					function (): void { if (!fShow) _cvsMiniView.visible = false });
			if (fShow)
				_cvsMiniView.visible = true;
		}
		
		private function OnZoomSliderChange(evt:Event): void {
			_imgv.zoom = evt.target.value;
		}
	
		private function OnViewZoomChange(evt:ImageViewEvent): void {
			var nZoom:Number = Number(evt.obNew);
			
			// This test is to avoid infinite recursion bouncing back and forth between the slider firing
			// an onChange event (and setting the ImageView's zoom) and the ImageView firing a zoom event
			// (thus firing this OnViewZoomChange).
			if (_sldrZoom.value != nZoom) {
				_sldrZoom.value = nZoom;
				SetZoomSliderRange();
			}
		}
		
		private function SetZoomSliderRange(): void {
			_sldrZoom.minimum = _imgv.zoomMin;
			_sldrZoom.maximum = _imgv.zoomMax;
			var imgd:ImageDocument = _imgv.imageDocument;
			_lbDimensions.text = imgd ? LocUtil.width_by_height(imgd.width, imgd.height) : "";
		}

		private function OnBitmapDataChange(evt:GenericDocumentEvent): void {
			var bmdOld:BitmapData = BitmapData(evt.obOld);
			var bmdNew:BitmapData = BitmapData(evt.obNew);
			var fRangeChange:Boolean;
			try {
				fRangeChange =  (bmdNew.width != bmdOld.width || bmdNew.height != bmdOld.height);
			} catch (e:Error) {
				fRangeChange = true;
			}
			if (fRangeChange)
				SetZoomSliderRange();
			
			UpdatePerformanceState();
		}
		
		private static var s_anZoomSteps:Array = [
			1, 1.5, 2, 3, 4, 5, 6.25, 8.33, 12.5, 16.67, 25, 33.33, 50, 66.67,
			100, 150, 200, 300, 400, 500, 600, 800
		];
		
		// Find the next closest zoom up the scale and apply it
		private function OnZoomInClick(evt:MouseEvent): void {
			var nZoomPct:Number = _imgv.zoom * 100;
			for (var i:Number = 0; i < s_anZoomSteps.length; i++) {
				if (s_anZoomSteps[i] > nZoomPct) {
					_imgv.zoom = s_anZoomSteps[i] / 100;
					return;
				}
			}
		}
		
		// Find the next closest zoom down the scale and apply it
		private function OnZoomOutClick(evt:MouseEvent): void {
			var nZoomPct:Number = _imgv.zoom * 100;
			for (var i:Number = s_anZoomSteps.length; i >= 0; --i) {
				if (s_anZoomSteps[i] < nZoomPct) {
					_imgv.zoom = s_anZoomSteps[i] / 100;
					return;
				}
			}
		}
		
		protected function NavigateTo(strTab:String, strSubTab:String=null): void {
			PicnikBase.app.NavigateTo(strTab, strSubTab);
		}
		
		private function IsAtFreeLimit(): Boolean {
			if (isPaid)
				return false;

			return GetPhotoCount(_imgd.documentObjects) >= kcFreePhotoLimit;				
		}
		
		private static function GetPhotoCount(dobc:DisplayObjectContainer): int {
			var cPhotos:int = 0;
			
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var dob:DisplayObject = dobc.getChildAt(i);
				if (dob is Photo)
					cPhotos++;
				
				// Recurse to find all Photos
				if (dob is DisplayObjectContainer)
					cPhotos += GetPhotoCount(DisplayObjectContainer(dob));
			}
			
			return cPhotos;
		}
		
		private var _mfn:MouseFollowingPremiumNag;
		
		private function ShowPremiumNag(): void {
			_mfn = MouseFollowingPremiumNagBase.Show();
		}
		
		private function HidePremiumNag(): void {
			if (_mfn == null)
				return;
			_mfn.Hide();
			_mfn = null;
		}
	}
}
