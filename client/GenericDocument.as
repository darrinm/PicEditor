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

	import errors.*;
	
	import events.*;
	
	import flash.events.*;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.utils.ObjectUtil;
	
	import util.AssetMgr;
	import util.IAssetSource;
	import util.IPendingAsset;
	
	public class GenericDocument extends EventDispatcher {
  		
  		// Constants that define the kinds of access that users can have to a document
		public static const kAccessNone:Number = 0;
		public static const kAccessReadOnly:Number = 1;
		public static const kAccessLimited:Number = 2;
		public static const kAccessFull:Number = 4;		
  		
		public static const errNone:Number = 0;
		
		private static const kfidError:String = "-1";
  		
  		// Serialized document state
		protected var _dctAssets:Object = {};
		protected var _fDirty:Boolean = false;
		protected var _fPublic:Boolean = false;
		protected var _fInitialized:Boolean = false;
		private var _fnRestoreProgress:Function;
		private var _fnRestoreDone:Function;

		// undo functionality
		protected var _iutHistoryTop:Number = 0;
		[ArrayElementType("UndoTransaction")] protected var _autHistory:Array;

		public function GenericDocument() {
			// Initialize _aaopHistory in the constructor so we don't get bit by having
			// each ImageDocument instance referencing the same class-initialized array.
			CreateEmptyUndoHistory();
		}
		
		// Derived classes must override this to specify their type
		public function get type(): String {
			return "generic";
		}
		
		protected function CreateEmptyUndoHistory(): void {
			_autHistory = new Array();
			_iutHistoryTop = 0;
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.UNDO_CHANGE, 0, 0));
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.REDO_CHANGE, 0, 0));
		}
		
       	public function Revert(): void {
       		CreateEmptyUndoHistory();
       		isDirty = false;
       	}		
		
		public function GetState(): Object {
			var obState:Object = {
				strType: getQualifiedClassName(this),
				strAssetMap: SerializeLoadedAssetMap(_dctAssets, true),				
				fDirty: _fDirty
			};
			return obState;
		}
		
		// fnProgress(nPercentDone:Number, strStatus:String)
		public function RestoreStateAsync(sto:Object, fnProgress:Function, fnDone:Function): void {			
			if (sto.fDirty)
				isDirty = sto.fDirty;

			if (sto.strAssetMap)
				_dctAssets = DeserializeAssetMap(sto.strAssetMap);
				
			fnDone( errNone, "" );
		}
		
		public function OnUserChange(): void {
			// for subclasses to override
		}
		
		// Free up bitmaps right away.  Afterwards the document is useless!
		public function Dispose(): void {
			// NOP -- right now only ImageDocument has disposable resources
		}

		// undo functionality

		public function Undo(): void {
			Debug.Assert(_iutHistoryTop > 0, "Attempting Undo when there is nothing to undo");
			
			var nUndoDepthOld:Number = undoDepth;
			var nRedoDepthOld:Number = redoDepth;
			
			var ut:UndoTransaction = _autHistory[_iutHistoryTop - 1];
			_Undo(ut);
			
			// Move this transaction from the undo to the redo side of the history stack
			_iutHistoryTop--;
			
			isDirty = ut.fDirty;
			
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.UNDO_CHANGE, nUndoDepthOld, undoDepth));
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.REDO_CHANGE, nRedoDepthOld, redoDepth));
			if (ut.fLog)
				PicnikService.Log("Client undoing " + ut.strName);
		}

		public function Redo(): void {
			Debug.Assert(_iutHistoryTop < _autHistory.length,
					"Attempting Redo when there is nothing to redo (history len: " + _autHistory.length +
					", history top: " + _iutHistoryTop + ")");
				
			var nUndoDepthOld:Number = undoDepth;
			var nRedoDepthOld:Number = redoDepth;
			
			var ut:UndoTransaction = _autHistory[_iutHistoryTop];
			
			_Redo(ut);
			_iutHistoryTop++;
			isDirty = true;
			
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.UNDO_CHANGE, nUndoDepthOld, undoDepth));
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.REDO_CHANGE, nRedoDepthOld, redoDepth));
			if (ut.fLog)
				PicnikService.Log("Client redoing " + ut.strName);
		}

		// trim the undo/redo list so there's nothing to redo
		public function ClearRedo(): void {
			var nUndoDepthOld:Number = undoDepth;
			var nRedoDepthOld:Number = redoDepth;
			_autHistory = _autHistory.slice(0, _iutHistoryTop);
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.UNDO_CHANGE, nUndoDepthOld, undoDepth));
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.REDO_CHANGE, nRedoDepthOld, redoDepth));
		}
		
		// Completely clear the undo/redo list.
		public function ClearUndo(): void {
			var nUndoDepthOld:Number = undoDepth;
			var nRedoDepthOld:Number = redoDepth;
			_autHistory = [];
			_iutHistoryTop = 0;
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.UNDO_CHANGE, nUndoDepthOld, undoDepth));
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.REDO_CHANGE, nRedoDepthOld, redoDepth));
		}
		
		// _Undo/_Redo: actually carry out the execution/reversion of the transaction
		// called only by Undo/Redo above, which manage the revision history
		protected function _Undo(ut:UndoTransaction): void {
			Debug.Assert(false, "GenericDocument._Undo() must be overridden");			
		}
				
		protected function _Redo(ut:UndoTransaction): void {
			Debug.Assert(false, "GenericDocument._Redo() must be overridden");			
		}
		
		public function get undoDepth():Number {
			return _iutHistoryTop;
		}
		
		public function get redoDepth():Number {
			return _autHistory.length - _iutHistoryTop;
		}

		public function AddToHistory(ut:UndoTransaction): void {
			var nUndoDepthOld:Number = undoDepth;
			var nRedoDepthOld:Number = redoDepth;
			
			// If there is a redo history, clear it out
			if (_iutHistoryTop < _autHistory.length) {
				for (var i:Number = _iutHistoryTop; i < _autHistory.length; i++) {
					_autHistory[i].Dispose();
				}
			}
			_autHistory = _autHistory.slice(0, _iutHistoryTop);
			_autHistory.push(ut);
			_iutHistoryTop++;
			
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.UNDO_CHANGE, nUndoDepthOld, undoDepth));
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.REDO_CHANGE, nRedoDepthOld, redoDepth));
		}
		
						
		//
		// Public properties
		//
	
		[Bindable]
		public function get isDirty():Boolean {
			return _fDirty;
		}
		
		public function set isDirty(fDirty:Boolean): void {
			_fDirty = fDirty;
		}
			
		[Bindable]
		public function get isPublic():Boolean {
			return _fPublic;
		}
		
		public function set isPublic(fPublic:Boolean): void {
			_fPublic = fPublic;
		}

		[Bindable]
		public function get isInitialized():Boolean {
			return _fInitialized;
		}
		
		public function set isInitialized(fInitialized:Boolean): void {
			_fInitialized = fInitialized;
		}
		
		//
		// Asset management stuff
		//
		public function get assets(): Object {
			return ObjectUtil.copy(_dctAssets); // Make a copy so caller can't mess it up
		}
		
		public function set assets(dctAssets:Object): void {
			_dctAssets = dctAssets;
		}
		
		// Returns an unordered comma-separated list of asset index/asset file id pairs,
		// e.g. "0:12345,1:453121,4:343431" or an empty string "" if the document references
		// no assets.
		public function GetSerializedAssetMap(fDiscardPreFlattenedHistory:Boolean): String {
			// Clean up asset map before serializing it
			var dctAssets:Object = GetOptimizedAssetMap(fDiscardPreFlattenedHistory);
			return SerializeLoadedAssetMap(dctAssets);
		}
		
		protected function SerializeLoadedAssetMap(dctAssets:Object, fIgnorePending:Boolean=false): String {
			var strAssets:String = "";
			for (var strAssetIndex:String in dctAssets) {
				var fid:String;
				if (dctAssets[strAssetIndex] is IPendingAsset) {
					if (!fIgnorePending)
						throw new Error("Trying to serialize pending asset ref");
					fid = kfidError;
				} else {
					fid = dctAssets[strAssetIndex];
				}
				strAssets += strAssetIndex + ":" + fid + ",";
			}
			if (strAssets != "")
				strAssets = strAssets.slice(0, -1);
			return strAssets;
		}
		
		// Converts an unordered comma-separated list of asset index/asset file id pairs
		// into an dictionary of file ids, indexed by asset index.
		// Returns null if the asset list is an empty string.
		static public function DeserializeAssetMap(strAssets:String): Object {
			var dctAssets:Object = {};
			if (strAssets == null || strAssets == "")
				return dctAssets;
			var astrPairs:Array = strAssets.split(",");
			for each (var strPair:String in astrPairs) {
				var ichColon:int = strPair.indexOf(":");
				dctAssets[strPair.slice(0, ichColon)] = strPair.slice(ichColon + 1);
			}
			return dctAssets;
		}

		/** GetAssetProperties
		 * Get file properties for an asset
		 * fnComplete looks like this:
		 * function OnGetFileProperties(err:Number, strError:String, dctProps:Object=null): void {
		 * 		if (err != PicnikService.errNone) { ...
		 * 		if (dctProps.nWidth == undefined || dctProps.nHeight == undefined) {
		 */
		public function GetAssetProperties(dai:int, strProps:String, fnComplete:Function): void {
			if (!(dai in _dctAssets)) throw new Error("undefined asset reference: " + dai);
			if (_dctAssets[dai] == kfidError) {
				fnComplete(PicnikService.errFail, "Create failed");
			} else {
				if (_dctAssets[dai] is IPendingAsset) {
					(_dctAssets[dai] as IPendingAsset).GetFileProperties(strProps, fnComplete);
				} else {
					AssetMgr.GetFileProperties(_dctAssets[dai], strProps, fnComplete);
					return;
				}
			}
		}
		
		// Convert 2 into "http://www.mywebsite.com/file/2?userkey=..."
		public function GetAssetURL(dai:int, strRef:String=null, fNeedsScriptAccess:Boolean=false): String {
			if (!(dai in _dctAssets))
				return "/asset_index_" + dai + "_not_in_map";
				
			// The FlashRenderer has a special asset map that already contains asset URLs
			if (_dctAssets[dai] == kfidError)
				return "/fid_error";
			if (Application.application.name == "FlashRenderer" || Application.application.name == "ClientTestRunner")
				return _dctAssets[dai];
				
 			return PicnikService.GetFileURL(_dctAssets[dai], null, strRef, null, fNeedsScriptAccess);
 		}
 		
 		public function CreateAsset(asrc:IAssetSource, fnDone:Function, fGuaranteedFreshFids:Boolean): int {
 			var fnOnAssetCreated:Function = function(err:Number, strError:String, fidCreated:String=null): void {
				// Under some circumstances, the fnOnAssetCreated callback is called
				// right away - before we have time to set _dctAssets[i].
 				if (err != PicnikService.errNone) {
 					// Asset failed to create. Delete it
 					_dctAssets[i] = kfidError;
 				} else {
 					// Asset created. Set it up
 					_dctAssets[i] = fidCreated;
 				}
 				if (fnDone != null)
	 				Application.application.callLater(fnDone, [err, strError, fidCreated]);
 			}
 			
 			var i:int = 0;
			while (_dctAssets[i] != undefined) {
				i++;
			}
			
			// Start the import
			var ipa:IPendingAsset = asrc.CreateAsset(fnOnAssetCreated, fGuaranteedFreshFids); // Returns null if the callback
			if (ipa != null && _dctAssets[i] == undefined)
				_dctAssets[i] = ipa;

			return i; 			
 		}
 		
		// Add to the asset map and return its index. If the asset is already in the map,
		// return the existing index.
 		public function AddAsset(fid:String): int {
			var i:int = 0;
			while (_dctAssets[i] != undefined) {
				if (_dctAssets[i] == fid)
					return i;
				i++;
			}
			_dctAssets[i] = fid;
			return i; 			
 		}	
 		
 		public function GetAsset(dai:int):String {
 			return _dctAssets[dai];
 		}
 		
 		// Remove any unreferenced assets from the asset map. Do this by creating an empty
 		// asset map and copying all referenced assets to it. Find out which assets are
 		// referenced by enumerating all ImageOperations in the UndoTransaction history,
 		// including redo transactions.
 		protected function GetOptimizedAssetMap(fDiscardPreFlattenedHistory:Boolean=false): Object {
 			return _dctAssets;

 		}
	

		// return a displayable object that represents this document, or null if inapplicable.
		// could be a thumbnail of the image being worked on, a composite of images from a
		// slideshow, possibly even a SWFLoader or something fancy in future.
		public function GetDocumentThumbnail(): UIComponent {
			return null;			// no thumbnail for generics.
		}
	}
}
