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
	import imagine.documentObjects.Target;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	
	import imagine.ImageDocument;
	
	import viewObjects.TargetViewObject;
	import viewObjects.UploadTargetViewObject;
	
	public class TargetAwareView extends StatusAwareView {
		private var _fTargetViewObjectsDirty:Boolean = false;
		private var _fTargetsEnabled:Boolean = false;
		private var _strTargetViewObjectClass:String = "viewObjects.TargetViewObject";

		[Bindable]		
		public function set targetsEnabled(fEnabled:Boolean): void {
			UnmonitorDocumentObjects();
			_fTargetsEnabled = fEnabled;
			_fTargetViewObjectsDirty = false;
			MonitorDocumentObjects();
		}
		
		public function get targetsEnabled(): Boolean {
			return _fTargetsEnabled;
		}
		
		// NOTE: it is assumed this is set before any TargetViewObjects are instanced
		[Bindable]
		public function set targetViewObjectClass(strClass:String): void {
			_strTargetViewObjectClass = strClass;
		}
		
		public function get targetViewObjectClass(): String {
			return _strTargetViewObjectClass;
		}
		
		override public function set imageDocument(imgd:ImageDocument): void {
			var imgdOld:ImageDocument = imageDocument;
			
			UnmonitorDocumentObjects();
			super.imageDocument = imgd;
			MonitorDocumentObjects();
		}

		private function MonitorDocumentObjects(): void {
			if (imageDocument && _fTargetsEnabled) {
			 	imageDocument.documentObjects.addEventListener(Event.ADDED, OnDocumentObjectAdded);
			 	imageDocument.documentObjects.addEventListener(Event.REMOVED, OnDocumentObjectRemoved);
				InvalidateTargetViewObjects();
			}
		}
		
		private function UnmonitorDocumentObjects(): void {
			if (imageDocument && _fTargetsEnabled) {
			 	imageDocument.documentObjects.removeEventListener(Event.ADDED, OnDocumentObjectAdded);
			 	imageDocument.documentObjects.removeEventListener(Event.REMOVED, OnDocumentObjectRemoved);
				ClearTargetViewObjects();
			}
		}
		
		// NOTE: we rely on event bubbling to capture all nested DocumentObject adds & removes		
		private function OnDocumentObjectAdded(evt:Event): void {
			InvalidateTargetViewObjects();
		}
		
		private function OnDocumentObjectRemoved(evt:Event): void {
			InvalidateTargetViewObjects();
		}
		
		// This is our crude means of coalescing the many target changes that can happen during an update.
		private function InvalidateTargetViewObjects(): void {
			if (_fTargetViewObjectsDirty)
				return;
				
			_fTargetViewObjectsDirty = true;
			callLater(RefreshTargetViewObjects);			
		}
		
		// 1. make a dictionary of all existing TargetViewObjects, indexed by Target
		// 2. for each Target
		//  a. if Target is in the dictionary, remove it from the dictionary
		//  b. else create a TargetViewObject for the Target
		// 3. destroy any TargetViewObjects remaining in the dictionary
		private function RefreshTargetViewObjects(): void {
			if (!_fTargetViewObjectsDirty)
				return;
			_fTargetViewObjectsDirty = false;
			
			if (imageDocument == null)
				return;
			
			var dctTargetViewObjects:Dictionary = new Dictionary();
			var dobc:DisplayObjectContainer = viewObjects;
			
			// 1. make a dictionary of all existing TargetViewObjects, indexed by Target
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var vo:TargetViewObject = dobc.getChildAt(i) as TargetViewObject;
				if (vo) {
					dctTargetViewObjects[vo.target] = vo;
				}
			}
			
			// 2. for each Target in the ImageDocument if it already has a TargetViewObject
			// remove it from the dictionary. Otherwise create a TargetViewObject for it.
			AddTargetViewObjects(DisplayObjectContainer(imageDocument.documentObjects), dctTargetViewObjects);
			
			// 3. destroy any TargetViewObjects remaining in the dictionary
			for each (vo in dctTargetViewObjects) {
				dobc.removeChild(vo);
			}
			
			validateDisplayList();
		}
		
		// Add TargetViewObjects corresponding to each Target DocumentObject child of the passed-in
		// DisplayObjectContainer. Recurse into all child DisplayObjectContainers to find all Targets.
		private function AddTargetViewObjects(dobc:DisplayObjectContainer, dctTargetViewObjects:Object): void {
			// Reference each TargetViewObject class to force it to be compiled in.
			var ob1:TargetViewObject, ob2:UploadTargetViewObject;
			
			var clsTargetViewObject:Class = getDefinitionByName(_strTargetViewObjectClass) as Class;
			
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var dob:DisplayObject = dobc.getChildAt(i);
				if (dob is Target) {
					var tgt:Target = Target(dob);
					if (tgt in dctTargetViewObjects) {
						delete dctTargetViewObjects[tgt];
					} else {
						var voTarget:TargetViewObject = new clsTargetViewObject(this, tgt);
						
						// The TargetViewObject's visibility should match that of its Target
						// UNDONE: uh, how does the TargetViewObject's visibility get updated when the Target's is?
						voTarget.visible = Util.IsVisible(tgt);
						
						// This seemingly unnecessary cast is required to differentiate the viewObjects
						// property from the viewObjects package
						DisplayObjectContainer(viewObjects).addChild(voTarget);
					}
				}
				
				// Recurse to find all Targets
				if (dob is DisplayObjectContainer)
					AddTargetViewObjects(DisplayObjectContainer(dob), dctTargetViewObjects);
			}
		}
		
		// Remove all view-based controllers
		private function ClearTargetViewObjects(): void {
			var dobc:DisplayObjectContainer = viewObjects;
			
			// Back to front so we can remove as we go
			for (var i:Number = dobc.numChildren - 1; i >= 0; i--) {
				var vo:TargetViewObject = dobc.getChildAt(i) as TargetViewObject;
				if (vo)
					dobc.removeChildAt(i);
			}
		}
	}
}
