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
package views {
	import imagine.documentObjects.DocumentObjectContainer;
	import imagine.documentObjects.DocumentStatus;
	import imagine.documentObjects.IDocumentObject;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import imagine.ImageDocument;
	
	import viewObjects.StatusViewObject;
	
	public class StatusAwareView extends ImageView {
		private var _fStatusViewObjectsDirty:Boolean = false;

		override public function set imageDocument(imgd:ImageDocument): void {
			var imgdOld:ImageDocument = imageDocument;
			
			UnmonitorDocumentObjects();
			super.imageDocument = imgd;
			MonitorDocumentObjects();
		}

		private function MonitorDocumentObjects(): void {
			if (imageDocument) {
			 	imageDocument.documentObjects.addEventListener(Event.ADDED, OnDocumentObjectAdded);
			 	imageDocument.documentObjects.addEventListener(Event.REMOVED, OnDocumentObjectRemoved);
				InvalidateStatusViewObjects();
			}
		}
		
		private function UnmonitorDocumentObjects(): void {
			if (imageDocument) {
			 	imageDocument.documentObjects.removeEventListener(Event.ADDED, OnDocumentObjectAdded);
			 	imageDocument.documentObjects.removeEventListener(Event.REMOVED, OnDocumentObjectRemoved);
				ClearStatusViewObjects();
			}
		}
		
		// NOTE: we rely on event bubbling to capture all nested DocumentObject adds & removes		
		private function OnDocumentObjectAdded(evt:Event): void {
			InvalidateStatusViewObjects();
		}
		
		private function OnDocumentObjectRemoved(evt:Event): void {
			InvalidateStatusViewObjects();
		}
		
		// This is our crude means of coalescing the many status changes that can happen during an update.
		private function InvalidateStatusViewObjects(): void {
			if (_fStatusViewObjectsDirty)
				return;
				
			_fStatusViewObjectsDirty = true;
			callLater(RefreshStatusViewObjects);			
		}

		// 1. make a dictionary of all existing StatusViewObjects, indexed by DocumentObject
		// 2. for each Status
		//  a. if Target is in the dictionary, remove it from the dictionary
		//  b. else create a StatusViewObject for the DocumentObject
		// 3. destroy any StatusViewObjects remaining in the dictionary
		private function RefreshStatusViewObjects(): void {
			if (!_fStatusViewObjectsDirty || imageDocument == null)
				return;
			_fStatusViewObjectsDirty = false;
			
			var dctStatusViewObjects:Dictionary = new Dictionary();
			var dobc:DisplayObjectContainer = viewObjects;
			
			// 1. make a dictionary of all existing StatusViewObjects, indexed by Status
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var vo:StatusViewObject = dobc.getChildAt(i) as StatusViewObject;
				if (vo)
					dctStatusViewObjects[vo.target] = vo;
			}
			
			// 2. for each Target in the ImageDocument if it already has a StatusViewObject
			// remove it from the dictionary. Otherwise create a StatusViewObject for it.
			AddStatusViewObjects(DisplayObjectContainer(imageDocument.documentObjects), dctStatusViewObjects);
			
			// 3. destroy any StatusViewObjects remaining in the dictionary
			for each (vo in dctStatusViewObjects) {
				dobc.removeChild(vo);
			}
			
			validateDisplayList();
		}
		
		// Add StatusViewObjects corresponding to each DocumentObject child of the passed-in
		// DisplayObjectContainer. Recurse into all child DisplayObjectContainers to find all DocumentObjects.
		private function AddStatusViewObjects(dobc:DisplayObjectContainer, dctStatusViewObjects:Object): void {
			// Document object containers can hide their child status (e.g. frames)
			if (dobc is DocumentObjectContainer && !DocumentObjectContainer(dobc).showChildStatus)
				return;
				
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var dob:DisplayObject = dobc.getChildAt(i);
				if (!(dob is IDocumentObject))
					continue;
				if (IDocumentObject(dob).status == DocumentStatus.Static)
					continue;
					
				if (dob in dctStatusViewObjects) {
					delete dctStatusViewObjects[dob];
				} else {
					var voStatus:StatusViewObject = new StatusViewObject(this, dob);
					
					// This seemingly unnecessary cast is required to differentiate the viewObjects
					// property from the viewObjects package
					DisplayObjectContainer(viewObjects).addChild(voStatus);
				}
				
				// Recurse to find all Targets
				if (dob is DisplayObjectContainer)
					AddStatusViewObjects(DisplayObjectContainer(dob), dctStatusViewObjects);
			}
		}
		
		// Remove all view-based controllers
		private function ClearStatusViewObjects(): void {
			var dobc:DisplayObjectContainer = viewObjects;
			
			// Back to front so we can remove as we go
			for (var i:Number = dobc.numChildren - 1; i >= 0; i--) {
				var vo:StatusViewObject = dobc.getChildAt(i) as StatusViewObject;
				if (vo)
					dobc.removeChildAt(i);
			}
		}
	}
}
