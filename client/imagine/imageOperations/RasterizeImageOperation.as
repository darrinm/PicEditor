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
// Render a tree of DocumentObjects (optionally including the current background
// image) into a bitmap and move the tree out of the document's display list to
// the rasterizedObject container.
//
// This is a crude approximation of where we're headed which is to be able to
// perform ImageOperations on DocumentObjects by rasterizing them first.

package imagine.imageOperations {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.StageQuality;
	import flash.geom.Matrix;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.documentObjects.RasterizedObjectContainer;
	
	import mx.core.Application;
	
	import util.BitmapCache;
	import util.DrawUtil;
	import util.VBitmapData;
	
	[RemoteClass]
	public class RasterizeImageOperation extends BlendImageOperation {
		private var _cx:Number = 0;
		private var _cy:Number = 0;
		private var _fHiQuality:Boolean = true;
		private var _fIncludeBackground:Boolean = false;
		private var _idRoot:String;
		private var _nUndoIndex:int;
		private var _idUndoParent:String;
		private var _fSelfCaching:Boolean;
		private var _astrUndoDynamicChildren:Array=null;
		private var _idRasterizedContainer:String;
		private var _cChildrenToRasterize:Number=-1; // Default, -1, means all children
		
		public function RasterizeImageOperation(idRoot:String=null, cx:Number=NaN, cy:Number=NaN,
				fIncludeBackground:Boolean=false,cChildrenToRasterize:Number=-1,fHiQuality:Boolean=true) {
			// ImageOperation constructors are called with no arguments during Deserialization
			if (isNaN(cx))
				return;
				
			_cx = cx;
			_cy = cy;
			_idRoot = idRoot;
			_cChildrenToRasterize = cChildrenToRasterize;
			_fIncludeBackground = fIncludeBackground;
			_fHiQuality = fHiQuality;
		}
		
		public function set includeBackground(fInclude:Boolean): void {
			_fIncludeBackground = fInclude;
		}
		
		public function set childrenToRasterize(val:Number): void {
			_cChildrenToRasterize = val;
		}
		
		public function get childrenToRasterize(): Number {
			return _cChildrenToRasterize;
		}
		
		public function set width(val:Number): void {
			_cx = Math.max(1, val);
		}
		
		public function get width(): Number {
			return _cx;
		}
	
		public function set height(val:Number): void {
			_cy = Math.max(1, val);
		}
		
		public function get height(): Number {
			return _cy;
		}
		
		public function set hiQuality( f:Boolean ): void {
			_fHiQuality = f;
		}
				
		// RasterizeImageOp generates a fresh serialization for itself every time, so caching
		// it is very difficult.  We want to make it manage its own cache so that subsequent
		// children can receive the same parent bitmap and get better caching performance.
		public function set selfCaching( f:Boolean ): void {
			_fSelfCaching = f;
		}
		
		public function set rasterizedContainerId(strId:String): void {
			_idRasterizedContainer = strId;
		}
	
		public function get rasterizedContainerId(): String {
			return _idRasterizedContainer;
		}
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			
			var obVals:Object = {};
			obVals.width = _cx;
			obVals.height = _cy;
			obVals.includeBackground = _fIncludeBackground;
			obVals.childrenToRasterize = _cChildrenToRasterize;
			obVals.hiQuality = _fHiQuality;
			obVals.selfCaching = _fSelfCaching;
			obVals.root = _idRoot;
			obVals.rasterizedContainerId = _idRasterizedContainer;
			obVals.undoParentId = _idUndoParent;
			obVals.undoIndex = _nUndoIndex;
			obVals.undoDynamicChildren = _astrUndoDynamicChildren;
			
			output.writeObject(obVals);
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			var obVals:Object = input.readObject();

			_cx = obVals.width;
			_cy = obVals.height;
			_fIncludeBackground = obVals.includeBackground;
			_cChildrenToRasterize = obVals.childrenToRasterize;
			_fHiQuality = obVals.hiQuality;
			_fSelfCaching = obVals.selfCaching;
			_idRoot = obVals.root;
			_idRasterizedContainer = obVals.rasterizedContainerId;
			_idUndoParent = obVals.undoParentId;
			_nUndoIndex = obVals.undoIndex;
			_astrUndoDynamicChildren = obVals.undoDynamicChildren;
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@width, "RasterizeImageOperation width argument missing");
			_cx = Number(xmlOp.@width);
			Debug.Assert(xmlOp.@height, "RasterizeImageOperation height argument missing");
			_cy = Number(xmlOp.@height);
			if (xmlOp.hasOwnProperty("@includeBackground"))
				_fIncludeBackground = xmlOp.@includeBackground == "true";
			else
				_fIncludeBackground = false;
			if (xmlOp.hasOwnProperty("@childrenToRasterize"))
				_cChildrenToRasterize = Number(xmlOp.@childrenToRasterize);
			else
				_cChildrenToRasterize = -1;
			if (xmlOp.hasOwnProperty("@root")) // UNDONE: "root" confusing? containerId, rootId
				_idRoot = xmlOp.@root;
			if (xmlOp.hasOwnProperty("@rasterizedContainerId"))
				_idRasterizedContainer = xmlOp.@rasterizedContainerId;
			if (xmlOp.hasOwnProperty("@undoParentId"))
				_idUndoParent = xmlOp.@undoParentId;
			if (xmlOp.hasOwnProperty("@undoIndex"))
				_nUndoIndex = int(xmlOp.@undoIndex);
			if (xmlOp.hasOwnProperty("@undoDynamicChildren"))
				_astrUndoDynamicChildren = String(xmlOp.@undoDynamicChildren).split(',');
			else
				_astrUndoDynamicChildren = null;
			if (xmlOp.hasOwnProperty("@hiQuality"))
				_fHiQuality = Boolean(xmlOp.@hiQuality == "true");
			else
				_fHiQuality = true;
			if (xmlOp.hasOwnProperty("@selfCaching"))
				_fSelfCaching = Boolean(xmlOp.@selfCaching == "true");
			else
				_fSelfCaching = false;
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			var xml:XML = <Rasterize width={_cx} height={_cy} includeBackground={_fIncludeBackground} childrenToRasterize={_cChildrenToRasterize} hiQuality={_fHiQuality} selfCaching={_fSelfCaching}/>;
			if (_idRoot != null)
				xml.@root = _idRoot;
			if (_idRasterizedContainer) {
				xml.@rasterizedContainerId = _idRasterizedContainer;
				if (_idUndoParent)
					xml.@undoParentId = _idUndoParent;
				xml.@undoIndex = _nUndoIndex;
			}
			if (_astrUndoDynamicChildren != null && _astrUndoDynamicChildren.length > 0)
				xml.@undoDynamicChildren = _astrUndoDynamicChildren.join(',');
			return xml;
		}
		
		override public function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean,
				fUseCache:Boolean): BitmapData {
			return Rasterize(imgd, bmdSrc, fDoObjects, _idRoot, _cx, _cy, _fIncludeBackground, _cChildrenToRasterize,_fHiQuality,_fSelfCaching);
		}
		
		// Restore the rasterizedObjects to the document's main documentObjects and remove them from rasterizedObjects
		override public function Undo(imgd:ImageDocument): Boolean {
			//  remove the rasterizedObjects sub-container
			var dobcRasterized:DisplayObjectContainer = imgd.rasterizedObjects.getChildByName(_idRasterizedContainer) as DisplayObjectContainer;
			imgd.rasterizedObjects.removeChild(dobcRasterized);
			
			// restore the contents of the rasterizedObjects sub-container to documentObjects
			if (_idUndoParent == null) {
				for (var i:int = dobcRasterized.numChildren - 1; i >=0; i--) {
					var dob:DisplayObject = dobcRasterized.getChildAt(i);
					imgd.documentObjects.addChildAt(dob, 0);
				}
			} else {
				var dobcRasterize:DisplayObjectContainer = dobcRasterized.getChildAt(0) as DisplayObjectContainer;
				var dobc:DisplayObjectContainer = imgd.getChildByName(_idUndoParent) as DisplayObjectContainer;
				dobc.addChildAt(dobcRasterize, _nUndoIndex);
				
				if (_astrUndoDynamicChildren != null && _astrUndoDynamicChildren.length > 0) {
					// Move these children back into the container
					// The last child in the array should be the first child added
					while (_astrUndoDynamicChildren.length > 0) {
						var strName:String = _astrUndoDynamicChildren.pop();
						
						var dobChild:DisplayObject = dobcRasterize.parent.getChildByName(strName);
						dobChild.parent.removeChild(dobChild);
						dobcRasterize.addChild(dobChild);
						dobChild.x -= dobcRasterize.x;
						dobChild.y -= dobcRasterize.y;
						// UNDONE: Support rotation and scale of container
					}
				}
			}	
			return true;
		}
		
		private function calcCacheKey(): String {
			return SerializeSelf().toXMLString();
		}
		
		// Create a new bitmap and draw the document, complete with DocumentObjects, into it.
		// Then delete all DocumentObjects and return the new bitmap.
		private function Rasterize(imgd:ImageDocument, bmdOrig:BitmapData, fDoObjects:Boolean,
				idRoot:String, cx:Number, cy:Number, fIncludeBackground:Boolean=true, cChildrenToRasterize:Number=-1,
				fHiQuality:Boolean=true,fSelfCaching:Boolean=false): BitmapData {
			// Create a new VBitmapData w/ the resized dimensions
			// UNDONE: transparent if fIncludeBackground=false?
			var bmdNew:BitmapData;
			if (fIncludeBackground)
				bmdNew = DrawUtil.GetResizedBitmapData(bmdOrig, cx, cy, true, 0x00000000, false, true);
			else
				bmdNew = VBitmapData.Construct(cx, cy, true, imgd.backgroundColor);
			if (!bmdNew)
				return null;

			// The post-rasterized container				
			var dobcRasterized:DisplayObjectContainer = null;
			
			// The pre-rasterized container
			var dobcRasterize:DisplayObjectContainer;
			
			if (idRoot == null || idRoot == "$root")
				dobcRasterize = imgd.documentObjects;
			else
				dobcRasterize = imgd.getChildByName(idRoot) as DisplayObjectContainer;

			// If this operation is being played back from the history at load or undo time
			// then the objects have already been moved to the rasterizedObjects tree. If so,
			// use them from there. At Do and Redo time they'll not be there yet and so we
			// must transfer them.
			if (_idRasterizedContainer != null)
				dobcRasterized = imgd.rasterizedObjects.getChildByName(_idRasterizedContainer) as DisplayObjectContainer;
				
			var dobChild:DisplayObject;
			
			if (dobcRasterized == null) {
				// remember the parent id and index of the object tree to be rasterized
				if (dobcRasterize.parent) {
					_idUndoParent = dobcRasterize.parent.name;
					_nUndoIndex = dobcRasterize.parent.getChildIndex(dobcRasterize);
					_astrUndoDynamicChildren = [];
					
					// If we have a parent and a child limit, move extra children to the parent (after this object)
					if (cChildrenToRasterize > -1 && dobcRasterize.numChildren > cChildrenToRasterize) {
						var nInsertPos:Number = _nUndoIndex + 1; 
						while (dobcRasterize.numChildren > cChildrenToRasterize) {
							dobChild = dobcRasterize.removeChildAt(dobcRasterize.numChildren-1); // Start with the last child
							dobcRasterize.parent.addChildAt(dobChild, nInsertPos);
							dobChild.x += dobcRasterize.x;
							dobChild.y += dobcRasterize.y;
							// UNDONE: Support rotation and scale on containers
							_astrUndoDynamicChildren.push(dobChild.name);
						}
					}
				} else {
					_astrUndoDynamicChildren = null;
					_idUndoParent = null;
					_nUndoIndex = 0;
				}
				
				// create a uniquely named sub-container of rasterizedObjects
				dobcRasterized = new RasterizedObjectContainer();
				imgd.rasterizedObjects.addChild(dobcRasterized);
				
				// remember the id of the new sub-container for undo purposes
				_idRasterizedContainer = dobcRasterized.name;
				
				// move the tree of objects to be rasterized to the rasterizedObjects subcontainer
				// This is a bit of a hack for rasterizing from the root which is special (don't want
				// to move it to rasterizedObjects because of listeners attached to it and other concerns).
				if (dobcRasterize.parent == null) {
					while (imgd.documentObjects.numChildren != 0) {
						dobChild = imgd.documentObjects.removeChildAt(0);
						dobcRasterized.addChild(dobChild);
					}
				} else {
					dobcRasterized.addChild(dobcRasterize);
				}
			}
			
			var mat:Matrix = new Matrix(cx / bmdOrig.width, 0, 0, cy / bmdOrig.height);
			VBitmapData.RepairedDraw(bmdNew, dobcRasterized, mat, null, null, null, true);
			return bmdNew;
		}
	}
}
