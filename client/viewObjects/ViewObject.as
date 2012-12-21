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
// ViewObject is the basis for Controllers that act on DocumentObjects.
// ViewObjects have one foot in the ImageDocument's coordinate space and the other in
// the ImageView's space. The intent is for them to be implemented and behave like
// like standard UIComponents but be tightly bound to DocumentObjects. They pan and
// zoom in sync with the ImageDocument but render themselves (via updateDisplayList)
// any way they choose, typically at a constant resolution independent of zoom.
//
// ViewObjects are not serialized as part of the ImageDocument.

package viewObjects {
	import imagine.documentObjects.IDocumentObject;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	import mx.events.PropertyChangeEvent;

	public class ViewObject extends Sprite {
		protected var _rcdLocal:Rectangle = new Rectangle();
		protected var _xd:Number, _yd:Number;
		protected var _imgv:ImageView;
		protected var _dob:DisplayObject;
		private var _fDisplayListInvalid:Boolean = false;
		private var _fListening:Boolean = false;
		
		// Concatenated scaling factors of all ancestors of a DisplayObject
		private var _nAncScaleX:Number;
		private var _nAncScaleY:Number;
		private var _nAncRotation:Number;
		
		public function ViewObject() {
			super();
			addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);
		}
		
		public function get docObject(): IDocumentObject {
			return IDocumentObject(_dob);
		}
		
		public function get target(): DisplayObject {
			return DisplayObject(_dob);
		}
		
		public function set target(dob:DisplayObject): void {
			if (dob == _dob) return;
			Unlisten();
			_dob = dob;
			Listen();
			InitializeFromDisplayObjectState();
		}
		
		public function get docLocalRect(): Rectangle {
			return _rcdLocal.clone();
		}
		
		public function set docLocalRect(rcd:Rectangle): void {
			Debug.Assert(view != null, "ViewObject's view must be set before its coords");
			Debug.Assert(!isNaN(rcd.width) && !isNaN(rcd.height) && !isNaN(rcd.x) && !isNaN(rcd.y));
			_rcdLocal = rcd.clone();
			InvalidateDisplayList();
		}
		
		public function get docX(): Number {
			return _xd;
		}
		
		public function set docX(xd:Number): void {
			_xd = xd;
			UpdateViewCoords();
		}
		
		public function get docY(): Number {
			return _yd;
		}
		
		public function set docY(yd:Number): void {
			_yd = yd;
			UpdateViewCoords();
		}
		
		public function get view(): ImageView {
			return _imgv;
		}
		
		public function set view(imgv:ImageView): void {
			_imgv = imgv;
			InvalidateDisplayList();
		}
		
		protected function InitializeFromDisplayObjectState(): void {
			_nAncScaleX = 1.0;
			_nAncScaleY = 1.0;
			_nAncRotation = 0.0;
			// UNDONE: Move this to DocumentObjectUtils, see DocumentObjectUtils.GetDocumentScale
			for (var dobAnc:DisplayObject = target.parent; dobAnc != null; dobAnc = dobAnc.parent) {
				_nAncScaleX *= dobAnc.scaleX;
				_nAncScaleY *= dobAnc.scaleY;
				_nAncRotation += dobAnc.rotation;
			}
			
			docX = LocalToGlobalX(_dob, 0);
			docY = LocalToGlobalY(_dob, 0);
			rotation = LocalToGlobalRotation(_dob, _dob.rotation);
			/* UNDONE: 3D objects
			// UNDONE: localtoglobalrotationXY
			rotationX = _dob.rotationX;
			rotationY = _dob.rotationY;
			*/
			docLocalRect = ScaleFromTarget(IDocumentObject(_dob).localRect);
			visible = _dob.visible;
		}
		
		// This is meant to be overridden
		protected function OnTargetPropertyChange(evt:PropertyChangeEvent): void {
//			trace("propchange: " + evt.source + ", " + evt.property + ": " + evt.oldValue + " -> " + evt.newValue);
			switch (evt.property) {
			case "localRect":
				docLocalRect = ScaleFromTarget(Rectangle(evt.newValue));
				InvalidateDisplayList();
				break;
				
			case "x":
				_xd = Number(evt.newValue);
				InvalidateDisplayList();
				break;
				
			case "y":
				_yd = Number(evt.newValue);
				InvalidateDisplayList();
				break;
				
			case "rotation":
				rotation = LocalToGlobalRotation(target, Number(evt.newValue));
				break;
			
			/* UNDONE: 3D objects
			case "rotationX":
				// UNDONE: localtoglobalrotationX
				rotationX = Number(evt.newValue);
				break;
				
			case "rotationY":
				// UNDONE: localtoglobalrotationY
				rotationY = Number(evt.newValue);
				break;
			*/
				
			// Match the visibility of the target
			// NOTE: This doesn't always work since the target may be hidden by virtue of being
			// a child of another object being made invisible, in which case its visible property
			// doesn't change.
			case "visible":
				visible = evt.newValue;
				break;
			}
		}
		
		private function LocalToGlobalRotation(dob:DisplayObject, degRotation:Number): Number {
			return degRotation + _nAncRotation;
		}

		private function LocalToGlobalX(dob:DisplayObject, x:Number): Number {
			return dob.localToGlobal(new Point(x, 0)).x;
		}

		private function LocalToGlobalY(dob:DisplayObject, y:Number): Number {
			return dob.localToGlobal(new Point(0, y)).y;
		}
		
		protected function ScaleToTarget(rc:Rectangle): Rectangle {
			return new Rectangle(rc.left / _nAncScaleX, rc.top / _nAncScaleY, rc.width / _nAncScaleX, rc.height / _nAncScaleY);
		}

		protected function ScaleFromTarget(rc:Rectangle): Rectangle {
			return new Rectangle(rc.left * _nAncScaleX, rc.top * _nAncScaleY, rc.width * _nAncScaleX, rc.height * _nAncScaleY);
		}

		protected function Listen(): void {
			if (_dob) {
				_fListening = true;
				_dob.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnTargetPropertyChange);
				_dob.addEventListener(Event.REMOVED, OnTargetRemoved);
			}
		}
		
		private function Unlisten(): void {
			if (_dob && _fListening) {
				_dob.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnTargetPropertyChange);
				_dob.removeEventListener(Event.REMOVED, OnTargetRemoved);
				_fListening = false;
			}
		}
		
		protected function OnTargetRemoved(evt:Event): void {
			// Do nothing. Subclasses override.
			// CONSIDER: removing self
		}
		
		protected function OnAddedToStage(evt:Event): void {
			if (!_fListening) Listen();
			// We'll get called for all children added to this instance but we don't want
			// to act on them.
			if (evt.target != this)
				return;
				
			InvalidateDisplayList(true);
		}
		
		protected function OnRemovedFromStage(evt:Event): void {
			// We'll get called for all children removed from this instance but we don't want
			// to act on them.
			if (evt.target != this)
				return;
				
			Unlisten();
		}

		// The ImageView calls this method on every child ViewObject whenever it updates
		// its display list (e.g. when its ImageDocument or zoom changes or anything else
		// that causes its updateDisplayList to be called). UpdateDisplayList is meant
		// to be overridden by subclasses.
		public function UpdateDisplayList(): void {
			_fDisplayListInvalid = false;
			UpdateViewCoords();
		}
		
		protected function get hide(): Boolean {
			return false; // Override in sub-classes
		}
		
		private function UpdateViewCoords(): void {
//			if (target is RoundedRectangle && !(this is StatusViewObject))
//				trace("docX,docY: " + docX + "," + docY);
 			// Changes to the view's zoom require recalculation of the doco's position
 			if (hide) {
 				x = -100000;
 				y = -100000;
 			} else {
	 			var ptv:Point = view.PtvFromPtd(new Point(docX, docY));
				x = ptv.x;
				y = ptv.y;
			}
		}
		
		// Make sure this ViewObject's UpdateDisplayList will be called
		protected function InvalidateDisplayList(fForce:Boolean=false): void {
			if (!_fDisplayListInvalid || fForce) {
				_fDisplayListInvalid = true;
				
				// Make sure the UIComponent (ImageView) containing this ViewObject will redraw
				var dob:DisplayObject = parent;
				while (dob) {
					if (dob is UIComponent) {
						UIComponent(dob).invalidateDisplayList();
						break;
					}
					dob = dob.parent;
				}
			}
		}
	}
}
