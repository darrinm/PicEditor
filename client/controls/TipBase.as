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
package controls
{
	import containers.TipCanvas;
	
	import dialogs.DialogManager;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.effects.Fade;
	import mx.events.FlexEvent;
	import mx.managers.ISystemManager;
	import mx.managers.PopUpManager;
	
	import util.RectUtil;

	public class TipBase extends TipCanvas {
		
		// True if the tip is all on or becoming on
		// False if the tip is hidden or hiding
		[Bindable] public var showing:Boolean = false;
		[Bindable] public var tipPath:String;
		[Bindable] public var efFadeInOut:Fade;
		
		[Bindable] public var _tr:TipRenderer;
		
		[Bindable] public var contentWidth:Number = 385;
		[Bindable] public var quasiModal:Boolean = false;
		[Bindable] public var draggable:Boolean = true;
		[Bindable] protected var footer:UIComponent;

		// objects that make up the tip might come looking for values for substitution. We put them here.
		[Bindable] public var dctTipTextSubstitutions:Object;
		
		
		private var _fPoppedUp:Boolean = false;
		private var _fListeningToStage:Boolean = false;
		
		private var _ptDragOffset:Point = null;
		private var _xmlContent:XML;

		
		//DYNAMIC POINTING:
		// private var _fDynamicThumb:Boolean = false;
	
		public var fixedPosition:Boolean = false;

		public function TipBase(): void {
			addEventListener(Event.CLOSE, OnClose);
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
		}
		
		protected function ShowFeedback(): void {
			Hide();
			DialogManager.Show("FeedbackDialog");
		}
		
		public function Show(strTipPath:String=null, uicFooter:UIComponent=null, xmlTip:XML=null, dctParams:Object=null): void {
			dctTipTextSubstitutions = dctParams;
			
			// If it is visible
			if (!showing) {
				if (strTipPath)
					tipPath = strTipPath;
				if (uicFooter) {
					footer = uicFooter;
				}
				if (xmlTip)
					content = xmlTip;

				// Don't position the tip until its creation is complete
				addEventListener(FlexEvent.CREATION_COMPLETE, RepositionTip);
				
				// This tip might resize vertically when its child TipRenderer parses the xml content
				addEventListener(Event.RESIZE, RepositionTip);
			
				AddStageListeners();
				showing = true;
				ApplyFade(1);
				AddPopup();
			}
		}

		public function Hide(fFade:Boolean=true): void {
			if (showing) {
				if (_fListeningToStage) {
					stage.removeEventListener(MouseEvent.MOUSE_DOWN, OnGlobalMouseDown, true);
					_fListeningToStage = false;
				}
				
				showing = false;
				if (fFade)
					ApplyFade(0);
				else
					RemovePopup();
			}
		}
		
		public function get tipId(): String {
			if (content == null)
				return null;
			return content.@id;
		}
		
		[Bindable]
		public function set content(xml:XML): void {
			_xmlContent = xml;
			if (_xmlContent) {
				if (_xmlContent.hasOwnProperty("@contentWidth"))
					contentWidth = _xmlContent.@contentWidth;
				if (_xmlContent.@quasiModal == "true")
					quasiModal = true;
				if (_xmlContent.@draggable == "false")
					draggable = false;
			}
		}
		
		public function get content(): XML {
			return _xmlContent;
		}
		
		protected function OnMouseDown(evt:MouseEvent): void {
			if (draggable && stage) {
				_ptDragOffset = new Point(evt.stageX - x, evt.stageY - y);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, OnDrag);
				stage.addEventListener(MouseEvent.MOUSE_UP, OnDragEnd);
			}
		}
		
		protected function OnDrag(evt:MouseEvent): void {
			if (_ptDragOffset) {
				x = evt.stageX - _ptDragOffset.x;
				y = evt.stageY - _ptDragOffset.y;
				//DYNAMIC POINTING:
				// if (_fDynamicThumb) _tipBg.UpdateThumb();
			}
		}
		
		protected function OnDragEnd(evt:MouseEvent): void {
			_ptDragOffset = null;
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnDrag);
			stage.removeEventListener(MouseEvent.MOUSE_UP, OnDragEnd);
		}
		
		private function OnClose(evt:Event=null): void {
			Hide();
		}
	
		protected function AddStageListeners(): void {
			if (!_fListeningToStage && showing && stage) {
				stage.addEventListener(MouseEvent.MOUSE_DOWN, OnGlobalMouseDown, true);
				_fListeningToStage = true;
			}
		}
		
		private function ApplyFade(nToAlpha:Number): void {
			var nFadeFrom:Number = alpha;
			endEffectsStarted();
			efFadeInOut.alphaFrom = nFadeFrom;
			efFadeInOut.alphaTo = nToAlpha;
			efFadeInOut.play();
		}
		
		protected function OnFadeFinished(): void {
			if (!showing) {
				RemovePopup();
			}
		}
		
		private function AddPopup(): void {
			if (!_fPoppedUp) PopUpManager.addPopUp(this, PicnikBase.app, false);
			_fPoppedUp = true;
		}
		
		private function RemovePopup(): void {
			if (_fPoppedUp) PopUpManager.removePopUp(this);
			_fPoppedUp = false;
		}
		
		protected function OnGlobalMouseDown(evt:MouseEvent): void {
			var dobTarg:DisplayObject = evt.target as DisplayObject;
			while (dobTarg) {
				// Check owner first - this helps for child popups (e.g. combo box lists)
				if ('owner' in dobTarg && dobTarg['owner']) {
					dobTarg = dobTarg['owner'];
				} else {
					dobTarg = dobTarg.parent;
				}
				if (dobTarg == this) {
					return; // Tip event				
				}
			}
			if (quasiModal) {
				dispatchEvent(new Event(Event.CLOSE));
				Hide();
			}
		}
		
		private static var s_dctPreferMap:Object = {
			"above": RectUtil.ABOVE, "below": RectUtil.BELOW, "left": RectUtil.LEFT, "right": RectUtil.RIGHT, "center": -1
		}
		
		public function PointThumbAt(uic:UIComponent): void {
			_tipBg.PointThumbAtUIC(uic);
		}
		
		//DYNAMIC POINTING:
		/*
		public function PointThumbAt(uic:UIComponent, fDynamic:Boolean): void {
			_tipBg.PointThumbAtUIC(uic, 0, fDynamic);
			_fDynamicThumb = (uic != null) && fDynamic;
		}
		*/
		
		public function RepositionTip(evt:Event=null, fAnimate:Boolean=false): void {
			// Is it too early?
			if (content == null)
				return;
			
			if (_tr == null)
				return;
				
			AddStageListeners(); // Make sure we have these
	
			var aobConstraints:Array = [];
			// These are all stage coordinates
	
			var pt:Point;
			var rcNear:Rectangle;
			
			// First, it must be on the app
			var rcApp:Rectangle = new Rectangle(0,0,PicnikBase.app.width,PicnikBase.app.height);
			aobConstraints.push({ rcInside: rcApp });
			
			// STL: removing this as an antiquated constraint.
			// Next, try to place it inside the image view
//			var rcBelowNav:Rectangle = rcApp.clone();
//			rcBelowNav.top += 96;
//			
//			aobConstraints.push({ rcInside: rcBelowNav });
			
			var obConstraints:Object = {};

			var obPadding:Object = null;
			
			// Position it as specified in the tip XML
			if (String(content.@position)) {
				var nPadding:Number = 0;
				var strPosition:String = content.@position;
				var astrParts:Array = strPosition.split(':', 2);
				if (astrParts.length == 2) {
					strPosition = astrParts[0];
					nPadding = Number(astrParts[1]);
				}
				var nPrefer:Number = s_dctPreferMap[strPosition];
				obConstraints.prefer = nPrefer;
				
				obPadding = {};
				obPadding[nPrefer] = nPadding;
			}
			if (String(content.@relativeTo) || String(content.@pointAt)) {
				// Walk the UIComponent hierarchy to find the UIComponent with the relativeTo or pointAt id
				var strContent:String = String(content.@relativeTo) ? content.@relativeTo : content.@pointAt;
				var uic:UIComponent = Util.GetChildById(Application.application as UIComponent, strContent);
				
				// if we didn't find it in the application, let's look in the popups as they are not
				// children of the application.		
				if (uic == null) {
					var sm:ISystemManager = systemManager;
					for (var i:int = 0;uic == null && i < sm.numChildren; i++) {
						var uicParent:UIComponent = sm.getChildAt(i) as UIComponent;
						if (uicParent)
							uic = Util.GetChildById(uicParent, strContent);
					}
				}
				
				if (uic) {
					// in some weird instances (currently, tip #4/7 for Show) the width and height
					// of uic will be seen as 800,000 pixels larger than they should be.  So, we
					// convert to stage coordinates manually.
					//var rc:Rectangle = uic.getBounds(stage);
					var p1:Point = uic.localToGlobal(new Point(0, 0));
					var p2:Point = uic.localToGlobal(new Point(uic.width, uic.height));
					var rc:Rectangle = new Rectangle( p1.x, p1.y, p2.x - p1.x, p2.y - p1.y );
					if (String(content.@pointAtPadding))
						rc.inflate(Number(content.@pointAtPadding) * 2, Number(content.@pointAtPadding) * 2);
					if (content.@position == "center") {
						obConstraints.rcInside = RectUtil.ApplyPadding(rc, obPadding, false);
					} else {
						obConstraints.rcOutside = RectUtil.ApplyPadding(rc, obPadding, true);
					}
					if (String(content.@pointAt)) {
						// Point at the pointAt component
						obConstraints.rcPointAt = RectUtil.ApplyPadding(rc, obPadding, true);
					} 
				} else {
					// Center within the app by default
					obConstraints.rcInside = new Rectangle(0, 0, rcApp.width, rcApp.height);
				}
			} else {
				// Center within the app by default
				obConstraints.rcInside = new Rectangle(0, 0, rcApp.width, rcApp.height);
			}
			aobConstraints.push(obConstraints);
	
			// HACK: databinding (initialization?) doesn't seem to be getting its job done
			// reliably so we do it manually when necessary.
			if (_tr.content != content)
				_tr.content = content;
			
			pt = RectUtil.PlaceRect(aobConstraints, new Point(width, height));
			
			if (!fixedPosition) {
				if (String(content.@position) == "canvasTip") {
					// Canvas tips are horizontally centered over the canvas and vertically positioned
					// a little bit above the zoom box.
					var rcImageView:Rectangle = PicnikBase.app.zoomView.getRect(stage);
					x = rcImageView.x + (rcImageView.width - width) / 2;
					y = rcImageView.bottom - PicnikBase.app.zoomView._cvsZoomBox.height - 10 - height;
				} else {
					x = Math.round(pt.x);
					y = Math.round(pt.y);
				}
			}
	
			if (uic && String(content.@pointAt) && !String(content.@hideThumb))
				_tipBg.PointThumbAtUIC(uic);
				
			validateNow();
		}
	}
}
