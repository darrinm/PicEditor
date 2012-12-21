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
// DOML: Document Operation Markup Language is an MXML-like language for expressing a series of
// operations to be performed on a document. Typical operations would be applying ImageOperations,
// creating DocumentObjects, and setting properties on DocumentObjects.

// Operation descriptors describe desired ImageOperation and ObjectOperations with a set of properties.
// Some are passed through and set directly on the created Operation. Others are  used to define
// Operation properties after performing layout and other tasks.

// Classes
// - Create
// - Border
//
// Special properties (all others are assumed to be passed through to the created Operation)
// - type
// - alignmentBounds
// - width, height
// - left, top, right, bottom
// - horizontalCenter, verticalCenter
// - font (fontSize also gets a little special treatment)
// - CONSIDER: min/maxWidth/Height, baseline
//
// Values for width, height, left, top, right, bottom, horizontalCenter, verticalCenter can be
// expressed in pixels or % of alignmentBounds (which defaults to the whole image size)

// Operations are created from descriptors in two phases:
// 1. expression evaluation + conditionals + instantiation of DocumentObjects for measurement purposes
// UNDONE: expression evaluation
// UNDONE: conditionals
// 2. layout + Operation generation
//
// In order to perform layout we must be able to measure objects' width & height. In order to do that
// we instantiate them and wait for them to load (e.g. shape, photo, or font) and reach their final
// dimensions. Therefore, phase 1 is asynchronous and can fail of any of the objects fail to load.
// When it fails, CreateOperationsFromDescriptors passes null to its fnComplete.
//
// UNDONE: NestedImage/ObjectOperations -- not needed yet

package doml {
	import imagine.documentObjects.DocumentObjectBase;
	import imagine.documentObjects.DocumentStatus;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.geom.Rectangle;
	
	import imageDocument.DisplayObjectPool;

	import imagine.imageOperations.ImageOperation;
	import imagine.imageOperations.BorderImageOperation;
	
	import imagine.ImageDocument;
	
	import mx.events.PropertyChangeEvent;
	
	import imagine.objectOperations.CreateObjectOperation;
	
	import util.FontManager;
	
	public class DOML {
		private static var s_dctDOMLProperties:Object = {
			type: 0, alignmentBounds: 1, width: 2, height: 2, left: 2, top: 2, right: 2, bottom: 2,
			horizontalCenter: 2, verticalCenter: 2, bold: 0, italic: 0, name: 0
		}
		private var _imgd:ImageDocument;
		private var _aop:Array;
		private var _aobAllDescriptors:Array;
		private var _aobCreateDescriptors:Array;
		private var _adctCreateProperties:Array;
		private var _adob:Array;
		private var _aaDobDims:Array;

		// fnComplete(fSuccess:Boolean)		
		public function Init(aobDescriptors:Array, fnComplete:Function): void {
			DisplayObjectPool.Clear();
			_aaDobDims = null;
			_aobAllDescriptors = aobDescriptors;
			
			// Create a temporary ImageDocument to manage the measurement DocumentObjects.
			// Make it small so we don't waste much memory on its bitmaps.
			_imgd = new ImageDocument();
			_imgd.Init(1, 1);
			_imgd.baseStatus = DocumentStatus.Static;

			// UNDONE: Filter out descriptors based on conditionals
			
			// Add all Create Descriptors to their own list.
			_aobCreateDescriptors = [];

			for each (var obDescriptor:Object in _aobAllDescriptors) {
				if (obDescriptor is Create) {
					_aobCreateDescriptors.push(obDescriptor);
				}
			}
			
			// Create DocumentObjects for measurement purposes
			_adob = [];
			_adctCreateProperties = [];
			for each (obDescriptor in _aobCreateDescriptors) {
				var strType:String = obDescriptor.type;

				// Remove special DOML properties
				var dctProperties:Object = {};
				for (var strProperty:String in obDescriptor) {
					// Collect the non-DOML properties
					if (!(strProperty in s_dctDOMLProperties)) {
						dctProperties[strProperty] = obDescriptor[strProperty];
						
						// Translate font string, e.g. "Trebuchet MS", into a PicnikFont instance
						if (strProperty == "font") {
							var fBold:Boolean = ("bold" in obDescriptor) && obDescriptor.bold;
							var fItalic:Boolean = ("italic" in obDescriptor) && obDescriptor.italic;
		  					dctProperties[strProperty] = FontManager.FindFontByName(obDescriptor[strProperty], fBold, fItalic, true);
		  					Debug.Assert(dctProperties[strProperty] != null, "Font " + obDescriptor[strProperty] + " not found");
						}
					}
				}
				_adctCreateProperties.push(dctProperties);

				// UNDONE: expression evaluation
				// UNDONE: exception handling

				var dob:DisplayObject = _imgd.CreateDocumentObject(strType, dctProperties) as DisplayObject;
				_imgd.addChild(dob);
				
				// CONSIDER: need this? could use _imgd.documentObjects
				_adob.push(dob);
			}

			var fnOnDocumentStatusChange:Function = function (evt:PropertyChangeEvent): void {
				if (evt.property != "status")
					return;
					
				if (evt.newValue != DocumentStatus.Error && evt.newValue < DocumentStatus.Loaded)
					return;

				_imgd.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, fnOnDocumentStatusChange);

				if (evt.newValue == DocumentStatus.Error) {
					_imgd.Dispose();
					_imgd = null;
					fnComplete(false);
					return;
				}
				
				fnFinished();
			}
			
			var fnFinished:Function = function (): void {
				_imgd.documentObjects.Validate();

				// Snapshot the DisplayObject's dimensions and its content's dimensions (if it has content)
				// so they can be used for layout and to resent the content going into the DisplayObjectPool.			
				_aaDobDims = [];
				for (var i:int = 0; i < _adob.length; i++) {
					dob = _adob[i];
					var aDims:Array = [ dob.width, dob.height ];
					_aaDobDims.push(aDims);
				}
				
				fnComplete(true);
			}
			
			// Wait until the DocumentObjects have completed loading, then we can work with them
			if (_imgd.status < DocumentStatus.Loaded)
				_imgd.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, fnOnDocumentStatusChange);
				
			// Many DocumentObjects don't need any loading (e.g. PShapes)
			else
				fnFinished();
		}
		
		public function get initialized(): Boolean {
			return _aaDobDims != null;
		}
		
		// Produce an array of Image/ObjectOperations from an array of operation descriptors
		public function CreateOperationsFromDescriptors(rcDefaultAlignmentBounds:Rectangle): Array {
			DisplayObjectPool.Clear();
			
			// Generate CreateObjectOperations w/ parameters based on bounds + DocumentObject
			// measurements + style-specific layout logic
			_aop = [];
			var op:ImageOperation;
			
			for each (var obDescriptor:Object in _aobAllDescriptors) {
				if (obDescriptor is Border) {
					op = new BorderImageOperation();
					CopyUpgradedProperties(obDescriptor, op, rcDefaultAlignmentBounds);
					_aop.push(op);
				}
			}
			
			// UNDONE: layout test cases
			// - inset alignmentBounds (10, 50, 290, 180)
			// - default, non-default alignmentBounds
			// - values
			// - percents
			// - width, height
			// - top, left, right, bottom
			// - horizontalCenter, verticalCenter
			// - Text, Photo, PSWFLoader, PShape
			
			// Layout all the objects, calculating a bounding rectangle for each.
			// Objects may align with a default bounds, with any precalculated rectangle,
			// or with each other's calculated bounds.
			var arcObjects:Array = LayoutObjects(_aobCreateDescriptors, _aaDobDims, rcDefaultAlignmentBounds);
			
			for (var i:int = 0; i < _aobCreateDescriptors.length; i++) {
				var rcObject:Rectangle = arcObjects[i];
				obDescriptor = _aobCreateDescriptors[i];
				
				// We need to leave _adctCreateProperties objects unchanged so copy them as we go.
// UNDONE: why doesn't ObjectUtil.copy work here?
//				var dctProperties:Object = ObjectUtil.copy(_adctCreateProperties[i]);
				var dctProperties:Object = {};
				var dctPropertiesSrc:Object = _adctCreateProperties[i];
				for (var strProperty:String in dctPropertiesSrc)
					dctProperties[strProperty] = dctPropertiesSrc[strProperty];
				var aDims:Array = _aaDobDims[i];
				
				// Convert the calculated object bounds into x, y, scaleX, scaleY values 
				var x:Number = rcObject.x + rcObject.width / 2;
				var y:Number = rcObject.y + rcObject.height / 2;
				var scaleX:Number = 1, scaleY:Number = 1;
				
				// HACK: for dealing with the Text object's odd approach to height
				if (obDescriptor.type == "Text") {
					if (!("fontSize" in dctProperties))
						dctProperties.fontSize = rcObject.height;
				} else {
					scaleX = rcObject.width / aDims[0];
					scaleY = rcObject.height / aDims[1];
				}
				
				// Don't override explict x, y, scaleX, scaleY properties
				if (!("x" in dctProperties))	
					dctProperties.x = x;
				if (!("y" in dctProperties))
					dctProperties.y = y;
				if (!("scaleX" in dctProperties))
					dctProperties.scaleX = scaleX;
				if (!("scaleY" in dctProperties))
					dctProperties.scaleY = scaleY;
				
				// Add any preloaded content to the DisplayObjectPool that DocumentObjects look
				// to before loading from their url property.
				var doco:DocumentObjectBase = _adob[i] as DocumentObjectBase;
				if (doco && doco.content != null && doco.content is Loader && ("url" in _aobCreateDescriptors[i])) {
					// Reset content's dimensions every time it goes in the pool
					var ldr:Loader = doco.content as Loader;
					ldr.x = 0;
					ldr.y = 0;
					ldr.scaleX = 1;
					ldr.scaleY = 1;
					DisplayObjectPool.Add(dctProperties.url, ldr);
				}
				
				// Layout complete, create the CreateObjectOperation!
				op = new CreateObjectOperation(obDescriptor.type, dctProperties);
				_aop.push(op);
			}
			
			return _aop;
		}
		
		public function Dispose(): void {
			
		}
		
		private static function LayoutObjects(aobDescriptors:Array, aaDobDims:Array,
				rcDefaultAlignmentBounds:Rectangle): Array {
			// Sort the descriptors so objects follow the ones they're dependent on.
			// First build an unsorted list of [object index, dependency index, fSorted]
			var aaDependencies:Array = [];
			for (var i:int = 0; i < aobDescriptors.length; i++) {
				var obDescriptor:Object = aobDescriptors[i];
				var iDependency:int = -1;
				if (("alignmentBounds" in obDescriptor) && obDescriptor.alignmentBounds is String)
					iDependency = FindObject(obDescriptor.alignmentBounds, aobDescriptors);
				aaDependencies.push([i, iDependency, false]);
			}
			
			// Sort them
			var aaSorted:Array = [];
			for (i = 0; i < aaDependencies.length; i++) {
				var aDependency:Array = aaDependencies[i];
				if (!aDependency[2])
					SortDependency(aaDependencies, aaSorted, aDependency);
			}

			var arcObjects:Array = new Array(aobDescriptors.length);
			
			for (i = 0; i < aobDescriptors.length; i++) {
				var j:int = aaSorted[i][0];
				obDescriptor = aobDescriptors[j];
				var aDims:Array = aaDobDims[j];
				
				// Layout objects as directed by DOML properties (e.g. top, horizontalCenter)
				// using the dimensions of the instantiated DocumentObjects
				
				var rcAlignment:Rectangle = rcDefaultAlignmentBounds;
				if ("alignmentBounds" in obDescriptor) {
					// An object's id can be given as an alignmentBounds. The object is found
					// and its bounding rectangle is used.
					if (obDescriptor.alignmentBounds is String) {
						rcAlignment = arcObjects[aaSorted[i][1]];
					} else {
						// UNDONE: anchors (top, horizontalCenter, etc), percents of default
						rcAlignment = obDescriptor.alignmentBounds;
					}
				}
				
				var rcObject:Rectangle = new Rectangle(0, 0, aDims[0], aDims[1]);
				
				// Use the layout properties to calculate a bounding rect for the object.
				// We match MXML's equivalent property precedence.
				
				// First, define the bounds width & height
				
				if ("width" in obDescriptor) {
					rcObject.width = GetValueOrPercent(obDescriptor.width, rcAlignment.width);
				} else if ("left" in obDescriptor && "right" in obDescriptor) {
					rcObject.x = rcAlignment.x + GetValueOrPercent(obDescriptor.left, rcAlignment.width);
					rcObject.width = rcAlignment.width - GetValueOrPercent(obDescriptor.right, rcAlignment.width);
				}
				// If the height isn't set explicitly, scale it to match the width
				if (!("height" in obDescriptor) && !("top" in obDescriptor && "bottom" in obDescriptor))
					rcObject.height = aDims[1] * (rcObject.width / aDims[0]);
				
				if ("height" in obDescriptor) {
					rcObject.height = GetValueOrPercent(obDescriptor.height, rcAlignment.height);
				} else if ("top" in obDescriptor && "bottom" in obDescriptor) {
					rcObject.y = rcAlignment.y + GetValueOrPercent(obDescriptor.top, rcAlignment.height);
					rcObject.height = rcAlignment.height - GetValueOrPercent(obDescriptor.bottom, rcAlignment.height);
				}
				// If the width isn't set explicitly, scale it to match the height
				if (!("width" in obDescriptor) && !("left" in obDescriptor && "right" in obDescriptor))
					rcObject.width = aDims[0] * (rcObject.height / aDims[1]);
					
				// Second, define the bounds x & y
				
				if ("horizontalCenter" in obDescriptor) {
					var xCenter:Number = rcAlignment.x + (rcAlignment.width / 2) +
							GetValueOrPercent(obDescriptor.horizontalCenter, rcAlignment.width);
					rcObject.x = xCenter - rcObject.width / 2;
				} else if ("left" in obDescriptor && !("right" in obDescriptor)) {
					rcObject.x = rcAlignment.x + GetValueOrPercent(obDescriptor.left, rcAlignment.width);
				} else if ("right" in obDescriptor && !("left" in obDescriptor)) {
					rcObject.x = rcAlignment.x + rcAlignment.width -
							GetValueOrPercent(obDescriptor.right, rcAlignment.width) - rcObject.width;
				}
				
				if ("verticalCenter" in obDescriptor) {
					var yCenter:Number = rcAlignment.y + (rcAlignment.height / 2) +
							GetValueOrPercent(obDescriptor.verticalCenter, rcAlignment.height);
					rcObject.y = yCenter - rcObject.height / 2;
				} else if ("top" in obDescriptor && !("bottom" in obDescriptor)) {
					rcObject.y = rcAlignment.y + GetValueOrPercent(obDescriptor.top, rcAlignment.height);
				} else if ("bottom" in obDescriptor && !("top" in obDescriptor)) {
					rcObject.y = rcAlignment.y + rcAlignment.height -
							GetValueOrPercent(obDescriptor.bottom, rcAlignment.height) - rcObject.height;
				}
				
				arcObjects[j] = rcObject;
			}
			
			return arcObjects;
		}
		
		private static function SortDependency(aaUnsorted:Array, aaSorted:Array, aDependency:Array): void {
			if (aDependency[1] != -1 && !aaUnsorted[aDependency[1]][2])
				SortDependency(aaUnsorted, aaSorted, aaUnsorted[aDependency[1]]);
			aDependency[2] = true;
			aaSorted.push(aDependency);
		}
		
		private static function FindObject(strId:String, aobDescriptors:Array): int {
			for (var i:int = 0; i < aobDescriptors.length; i++) {
				if (aobDescriptors[i].name == strId)
					return i;
			}
			return -1;
		}
		
		private static function GetValueOrPercent(ob:*, nRange:Number): Number {
			if (ob is String) {
				var strT:String = ob as String;
				if (strT.charAt(strT.length - 1) == "%") {
					strT = strT.slice(0, -1);
					return nRange * (Number(strT) / 100);
				}
			}
			return Number(ob);
		}
		
		private static function CopyUpgradedProperties(dctProperties:Object, op:ImageOperation, rcAlignment:Rectangle): void {
			for (var strProperty:String in dctProperties) {
				var obValue:* = dctProperties[strProperty];
				switch (strProperty) {
				case "captionheight":
					obValue = GetValueOrPercent(obValue, rcAlignment.height);
					break;
				}
			
				if (strProperty in op)
					op[strProperty] = obValue;
			}
		}
	}
}
