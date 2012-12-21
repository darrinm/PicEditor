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
package imagine.documentObjects {
	import events.DocumentObjectEvent;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import imagine.ImageDocument;
	
	import mx.events.PropertyChangeEvent;

	[Event(name="absolute_scale_change", type="events.DocumentObjectEvent")]

/*
CONSIDER: rewrite this so ImageDocument derives from DocumentObjectContainer and listens
for ADDED and REMOVED events and triggers invalidation that way. Most of thse overrides
go away then. Plus third-parties (e.g. ImageView, CollageBase) can do the same if they
want to act as DocumentObjects, no matter how deeply nested, are added and removed.
*/
	[RemoteClass]
	public class DocumentObjectContainer extends Sprite implements IDocumentStatus {
		private var _imgd:ImageDocument;
		protected var _ffInvalid:Number = 0;
		private var _nStatus:Number = DocumentStatus.Static;
		private var _fLoadComplete:Boolean = true;
		
		public function DocumentObjectContainer() {
			super();
			name = Util.GetUniqueId();
			addEventListener(DocumentObjectEvent.ABSOLUTE_SCALE_CHANGE, ForwardEventToChildren);
			addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnPropertyChange, false, 0, true);
		}
		
		public function get showChildStatus(): Boolean {
			return true;
		}
		
		private function OnPropertyChange(evt:PropertyChangeEvent): void {
			if (evt.property == "scaleX" || evt.property == "scaleY")
				dispatchEvent(new DocumentObjectEvent(DocumentObjectEvent.ABSOLUTE_SCALE_CHANGE));
		}
		
		private function ForwardEventToChildren(evt:DocumentObjectEvent): void {
			for (var i:Number = 0; i < numChildren; i++) {
				getChildAt(i).dispatchEvent(new DocumentObjectEvent(evt.type));
			}
		}
		
		public function set document(imgd:ImageDocument): void {
			_imgd = imgd;
		}
		
		public function get document(): ImageDocument {
			return _imgd;
		}
		
		// IDocumentStatus methods
		[Bindable]
		public function set status(nStatus:Number): void {
			if (_nStatus == nStatus)
				return;
				
			_nStatus = nStatus;
			Invalidate();
			
			if (parent && parent is DocumentObjectContainer)
				DocumentObjectContainer(parent).OnChildStatusChanged(this);
		}
		
		// An object's status is the minimum of its own and all its children's statuses
		public function get status(): Number {
			return  DocumentStatus.Aggregate(_nStatus, childStatus);
		}
		
		public override function set visible(value:Boolean):void {
			if (super.visible != value) {
				super.visible = value;
				// Changing visible impacts the numChildrenLoading - we need to
				// let the document know about this.
				if (parent && parent is DocumentObjectContainer)
					DocumentObjectContainer(parent).OnChildStatusChanged(this);
			}
		}
		
		public function get numElementsLoading(): Number {
			if (!visible) return 0;
			var nNumElementsLoading:Number = (_nStatus >= DocumentStatus.Loaded || _nStatus == DocumentStatus.Error) ? 0 : 1;
			for (var i:Number = 0; i < numChildren; i++) {
				var dococ:DocumentObjectContainer = getChildAt(i) as DocumentObjectContainer;
				if (dococ) nNumElementsLoading += dococ.numElementsLoading;
			}
			return nNumElementsLoading;
		}
		
		public function get childStatus(): Number {
			var nStatus:Number = DocumentStatus.Static;
			for (var i:Number = 0; i < numChildren; i++) {
				var dococ:DocumentObjectContainer = getChildAt(i) as DocumentObjectContainer;
				if (dococ) nStatus = DocumentStatus.Aggregate(nStatus, dococ.status);
			}
			return nStatus;
		}
		
		protected function OnChildStatusChanged(dococChild:DocumentObjectContainer): void {
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "status", null, status));
			
			if (parent && parent is DocumentObjectContainer)
				DocumentObjectContainer(parent).OnChildStatusChanged(this);
		}
		
		//
		
		public function Invalidate(ff:uint=0xffffffff): void {
			_ffInvalid = ff;
			
			// Invalidate child DocumentObjects too. Not always necessary but often is, e.g.
			// when parent resizes.
			for (var i:int = 0; i < numChildren; i++) {
				var doco:IDocumentObject = getChildAt(i) as IDocumentObject;
				if (doco != null)
					doco.Invalidate(ff);
			}
		}
		
		// Validate child DocumentObjects
		public function Validate(): void {
			ValidateChildren();
		}

		public function ValidateChildren(): void {		
			for (var i:int = 0; i < numChildren; i++) {
				var doco:IDocumentObject = getChildAt(i) as IDocumentObject;
				if (doco != null)
					doco.Validate();
			}
		}
		
		override public function addChild(child:DisplayObject): DisplayObject {
			var dob:DisplayObject = super.addChild(child);
			if (dob is IDocumentObject && _imgd)
				_imgd.AddChildHelper(dob);
			return dob;
		}
		
		override public function addChildAt(child:DisplayObject, index:int): DisplayObject {
			var dob:DisplayObject = super.addChildAt(child, index);
			if (dob is IDocumentObject && _imgd)
				_imgd.AddChildHelper(dob);
			return dob;
		}
		
		override public function removeChild(child:DisplayObject): DisplayObject {
			var dob:DisplayObject = super.removeChild(child);
			if (dob is IDocumentObject && _imgd)
				_imgd.RemoveChildHelper(dob);
			return dob;
		}
		
		override public function removeChildAt(index:int): DisplayObject {
			var dob:DisplayObject = super.removeChildAt(index);
			if (dob is IDocumentObject && _imgd)
				_imgd.RemoveChildHelper(dob);
			return dob;
		}

		override public function setChildIndex(child:DisplayObject, index:int): void {
			super.setChildIndex(child, index);
			if (child is IDocumentObject && _imgd)
				_imgd.InvalidateComposite();
		}

		// Special behavior -- recurse through all child container objects		
		override public function getChildByName(strName:String): DisplayObject {
			for (var i:int = 0; i < numChildren; i++) {
				var dob:DisplayObject = getChildAt(i);
				if (dob.name == strName)
					return dob;
				var dobc:DisplayObjectContainer = dob as DisplayObjectContainer;
				if (dobc == null)
					continue;
				dob = dobc.getChildByName(strName);
				if (dob != null)
					return dob;
			}
			return null;
		}
		
		override public function swapChildren(child1:DisplayObject, child2:DisplayObject): void {
			super.swapChildren(child1, child2);
			if ((child1 is IDocumentObject || child2 is IDocumentObject) && _imgd)
				_imgd.InvalidateComposite();
		}
		
		override public function swapChildrenAt(index1:int, index2:int): void {
			super.swapChildrenAt(index1, index2);
			if ((super.getChildAt(index1) is IDocumentObject || super.getChildAt(index2) is IDocumentObject) && _imgd)
				_imgd.InvalidateComposite();
		}
	}
}
