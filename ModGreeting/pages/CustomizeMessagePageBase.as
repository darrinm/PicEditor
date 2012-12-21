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
package pages {
	import containers.SendGreetingPageBase;
	
	import controls.TextAreaPlus;
	import controls.TextInputPlus;
	
	import imagine.documentObjects.DocumentObjectContainer;
	import imagine.documentObjects.IDocumentObject;
	import imagine.documentObjects.Text;
	
	import flash.events.Event;
	
	import imagine.ImageDocument;
	
	import mx.containers.VBox;
	
	import views.StatusAwareView;

	public class CustomizeMessagePageBase extends SendGreetingPageBase {
		[Bindable] public var _imgv:StatusAwareView;
		[Bindable] public var _taPrimary:TextAreaPlus;
		[Bindable] public var _taSecondary:TextAreaPlus;
		[Bindable] public var _vbxSecondary:VBox;
		
		private var _imgd:ImageDocument;
		private var _tobPrimary:Text;
		private var _tobSecondary:Text;
		
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			
			// Grab the ImageDocument from the parent and initialize our view of it.
			if (_imgv.imageDocument == null) {
				_imgd = greetingParent.imageDocument;
				_imgv.imageDocument = _imgd;
				_imgv.zoom = _imgv.zoomMin;
				_imgv.setStyle("color", null); // Otherwise the background of the view is orange!!!
				
				// Add some event handlers at first-time initialization.
				_taPrimary.addEventListener(Event.CHANGE, OnPrimaryTextChange);
				_taSecondary.addEventListener(Event.CHANGE, OnSecondaryTextChange);
			}

			// Initialize the message fields from the ImageDocument's Text DocumentObjects.
			var adob:Array = [];
			GetTextDocumentObjects(_imgd.documentObjects, adob);
			_vbxSecondary.visible = adob.length >= 2;
			if (adob.length > 0) {
				_tobPrimary = adob[0] as Text;
				_taPrimary.text = _tobPrimary.text;
				_imgd.properties.title = _taPrimary.text;
			}
			if (adob.length > 1) {
				_tobSecondary = adob[1] as Text;
				_taSecondary.text = _tobSecondary.text;
			}
		}
		
		private function OnPrimaryTextChange(evt:Event): void {
			_tobPrimary.text = _taPrimary.text;
			_imgd.isDirty = true;
			_imgd.properties.title = _taPrimary.text;
		}
		
		private function OnSecondaryTextChange(evt:Event): void {
			_tobSecondary.text = _taSecondary.text;
			_imgd.isDirty = true;
		}
		
		private function GetTextDocumentObjects(dobc:DocumentObjectContainer, adob:Array): void {
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var dob:IDocumentObject = dobc.getChildAt(i) as IDocumentObject;
				if (!dob)
					continue;
				if (dob is DocumentObjectContainer)
					GetTextDocumentObjects(dob as DocumentObjectContainer, adob);
				if (dob is Text)
					adob.push(dob);
			}
		}
	}
}
