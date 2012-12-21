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
package imagine {
	import bridges.Downloader;
	import bridges.FileTransferBase;
	
	import com.adobe.utils.StringUtil;
	
	import errors.*;
	
	import events.*;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.LoaderInfo;
	import flash.events.*;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	import imagine.documentObjects.*;
	import imagine.imageOperations.*;
	import imagine.imageOperations.engine.BitmapReference;
	import imagine.imageOperations.paintMask.DisplayObjectBrush;
	import imagine.objectOperations.*;
	import imagine.serialization.SerializationUtil;
	
	import mx.controls.Image;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.ChildExistenceChangedEvent;
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import util.BitmapCache;
	import util.InternalAssetLoader;
	import util.URLLoaderPlus;
	import util.VBitmapData;
	
	// All non-blank documents are named. The name serves as the document's per-user unique id.
	// Documents are stored and loaded by name. When a document is created from a DisplayObject,
	// as in the case of a newly uploaded image, it is given a name derived from the uploaded
	// image's file name. It is up to ImageDocument's callers to come up with unique names.
	// Attempting to Save a file with an in-use name will fail unless overwrite is specified.
	
	/**
	* @brief The ImageDocument class is Picnik's core data structure.
	*
	* ImageDocument is responsible for document I/O, management, and rendering to
	* a BitmapData buffer but is NOT responsible for presenting the document or its
	* status during load/save to the user. The ImageView class handles ImageDocument
	* presentation.
	*
	* @see ImageView
	*/
	public class ImageDocument extends GenericDocument implements IDocumentStatus {
		// Version 3 (12/20/2009) changes:
		// - DropShadowImageOperation backgroundColor alpha is used. Prior versions weren't explicit about it.
		public static const DOCUMENT_VERSION:int = 3;
		
		public static const errNone:Number = 0;
		public static const errPikDownloadFailed:Number = 1;
		public static const errPikUploadFailed:Number = 2;
		public static const errBaseImageDownloadFailed:Number = 3;
		public static const errBaseImageUploadFailed:Number = 4;
		public static const errOutOfMemory:Number = 5;
		public static const errChildObjectFailedToLoad:Number = 6;
		public static const errInitFailed:Number = 7;
		public static const errDocumentError:Number = 8;
		public static const errBaseImageLocalLoadFailed:Number = 9;
		public static const errUploadExceedsSizeLimit:Number = 10;
		public static const errUnsupportedFileFormat:Number = 11;
		public static const errNewerFlashPlayerRequired:Number = 12;
		public static const errAwaitingBackgroundUpload:Number = 13;
		public static const errInitFailedOutOfMemory:Number = 14;
		
		public static const kfidAwaitingBackgroundUpload:String = "awaiting_background_upload";
		public static const kcchFileNameMax:Number = 128;
		
//  		[Bindable] [ResourceBundle("ImageDocument")] protected var _rb:ResourceBundle;
  		
  		// Serialized document state
  		private var _coBackground:uint = 0x000000;
  		private var _cxOriginal:int, _cyOriginal:int; // Document dims before any ImageOperations act on it
		private var _daiBaseImage:int = -1; // Document Asset Index (-1 == no base image)
		private var _strETag:String;
		private var _fSaved:Boolean = false;
		private var _dobc:DocumentObjectContainer;
		private var _dobcRasterized:DocumentObjectContainer;
		
		private var _fCompositeInvalid:Boolean = true;
		private var _abmdOldBackgrounds:Array = []; // Keep around old backgrounds until we validate our composite.
		private var _bmdComposite:BitmapData;
		private var _fCompositeNeedsDisposing:Boolean = false; // Use this to track a composite we created
		private var _bmdBackground:BitmapData;
		private var _bmdOriginal:BitmapData;
		private var _fDisposeOriginal:Boolean = false;
		private var _strId:String;
		private var _strMinorId:String;	// the id without any etag qualifiers
		private var _imgp:ImageProperties;
	
		private var _fListeningForRender:Boolean = false;
		
		private var _xmlPik:XML;
		
		private var _fnProgress:Function;
		private var _fnDone:Function;
		private var _fOverwrite:Boolean;
		private var _fnRestoreProgress:Function;
		private var _fnRestoreDone:Function;
		
		// For the FlashRenderer's use only
		private var _ldr:URLLoader;
		
		// UNDONE: remove after server no longer relies on rendering w/ base images in /upload dir
		private var _strLocalBaseImagePath:String;
		private var _nStatus:Number = DocumentStatus.Loading;
		private var _nChildStatus:Number = DocumentStatus.Loaded; // Default for no children
		private var _nBaseStatus:Number = DocumentStatus.Loading; // Default for no children
		private var _imgpLastSaveInfo:ImageProperties = null;

		private var _nNumChildrenLoading:Number = 0; // True when all descendants have loaded or error states
		private var _afnOnChildLoaded:Array = [];
		private var _frFailedBaseImageUpload:FileReference;
		private var _ftbBaseImage:FileTransferBase;

		// Tiny bit of reference counting used by the new operation pipeline
		private var _bmdrInteractiveBackground:BitmapReference = null;
		private var _fInteractiveSet:Boolean = false;
		private var _bmdrComposite:BitmapReference = null;
		
		[Bindable] public var baseImageLoading:Boolean = false;
		
		static private var s_ialdr:InternalAssetLoader = new InternalAssetLoader();
		
		override public function get type(): String {
			return "image";
		}
		
		//
		// IDocumentStatus interface
		//
		
		[Bindable]
		public function set status(nStatus:Number): void {
			_nStatus = nStatus;
		}
		public function get status(): Number {
			return _nStatus;
		}
		
		// Dump children status
		public static function DumpStatus(dobc:DocumentObjectContainer=null, strPrefix:String=""): void {
			if (dobc == null) {
				var imgd:ImageDocument = activeDocument;
				if (imgd)
					dobc = imgd._dobc;
			}
			if (dobc == null)
				return;
			
			trace(strPrefix + dobc.status + ", " + dobc.childStatus + ", " + dobc.toString());
			for (var i:Number = 0; i < dobc.numChildren; i++) {
				var dobcChild:DocumentObjectContainer = dobc.getChildAt(i) as DocumentObjectContainer;
				if (dobcChild != null)
					DumpStatus(dobcChild, strPrefix + "  ");
			}
		}
		
		/*
		public function DumpStatus(str:String): void {
			trace(str);
			DumpChildStatus(_dobc, "  ");
			if (_dobcRasterized) {
				trace("-- rasterized --");
				DumpChildStatus(_dobcRasterized, "  ");
			}
		}
		
		private function DumpChildStatus(doco:IDocumentStatus, strPrefix:String): void {
			if (doco == null) return;
			trace(strPrefix + "- " + doco.status + ": " + String(doco));
			var dobc:DocumentObjectContainer = doco as DocumentObjectContainer;
			if (dobc != null) {
				for (var i:Number = 0; i < dobc.numChildren; i++) {
					DumpChildStatus(dobc.getChildAt(i) as IDocumentStatus, strPrefix + "  ");
				}
			}
		}
		*/
		
		//
		//
		//

		[Bindable]
		public function set baseStatus(nStatus:Number): void {
			_nBaseStatus = nStatus;
			status = DocumentStatus.Aggregate(_nBaseStatus, childStatus);
		}
		
		public function get baseStatus(): Number {
			return _nBaseStatus;
		}
		
		[Bindable]
		public function set numChildrenLoading(nNumChildrenLoading:Number): void {
			if (_nNumChildrenLoading == nNumChildrenLoading) return;
			_nNumChildrenLoading = nNumChildrenLoading;
			DoChildLoadedCallbacks();
		}
		
		public function get numChildrenLoading(): Number {
			return _nNumChildrenLoading;
		}
		
		[Bindable]
		public function set childStatus(nStatus:Number): void {
			_nChildStatus = nStatus;
			UpdateStatus();
		}
		
		public function get childStatus(): Number {
			return _nChildStatus;
		}
		
		// This is called by the local loader when its attempt to background upload the base
		// image fails. We use this to retry the upload at ImageDocument save time.
		[Bindable]
		public function set failedUpload(fr:FileReference): void {
			_frFailedBaseImageUpload = fr;
			baseStatus = fr != null ? DocumentStatus.Error : DocumentStatus.Loaded;
		}
		
		public function get failedUpload(): FileReference {
			return _frFailedBaseImageUpload;
		}
		
		[Bindable]
		public function set uploaderInProgress(ftb:FileTransferBase): void {
			_ftbBaseImage = ftb;
		}
		
		public function get uploaderInProgress(): FileTransferBase {
			return _ftbBaseImage;
		}
		
		public function ImageDocument() {
			_imgp = new ImageProperties();
			isDirty = false;
			_dobc = new DocumentObjectContainer();
			_dobc.name = "$root";
			_dobc.document = this;
			_dobc.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnDocoPropertyChange);
			
			_dobcRasterized = new DocumentObjectBase();
			_dobcRasterized.name = "$rasterized";
			_dobcRasterized.document = this;
			s_ialdr.Load(OnInternalAssetsLoaded);

			isInitialized = true;
		}
		
		private function UpdateStatus(): void {
			var nInternalAssetStatus:Number = s_ialdr.loaded ? DocumentStatus.Loaded : DocumentStatus.Loading;
			status = DocumentStatus.Aggregate(nInternalAssetStatus, baseStatus, _nChildStatus);
		}
		
		private function OnInternalAssetsLoaded(): void {
			UpdateStatus();
		}
		
		public function GetCommittedImageSize(): Point {
			if (_imgut && _imgut.bmdBackground) {
				var vbmdBackground:VBitmapData = _imgut.bmdBackground as VBitmapData;
				if (vbmdBackground &&!vbmdBackground.valid) {
					OnMemoryError( new Error( "GetCommitedImageSize invalid bitmap") );
				}
				return new Point(_imgut.bmdBackground.width, _imgut.bmdBackground.height);
			} else {
				return new Point(width, height);
			}
		}
		
		private var _strLoadFailures:String = null;
		
		public function LogLoadFailure(strMessage:String): void {
			if (_strLoadFailures != null)
				_strLoadFailures += ", " + strMessage;
			else
				_strLoadFailures = strMessage;
		}
		
		public function get loadFailures(): String {
			return _strLoadFailures;
		}
		
		override public function GetState(): Object {
			var vbmdComposite:VBitmapData = _bmdComposite as VBitmapData;
			if (!_bmdComposite || (vbmdComposite && !vbmdComposite.valid)) {
				OnMemoryError();
				return null;
			}
			
			var obState:Object = super.GetState();
			
			obState.strXml = Serialize(false, false).toXMLString();
			obState.strXmlProperties = _imgp.Serialize().toXMLString();
			obState.strName = _strId;
			obState.cxBmd = _bmdComposite.width;
			obState.cyBmd = _bmdComposite.height;

/*			
			// Compress the serialized ImageDocument because they're getting big
			var ba:ByteArray = new ByteArray();
			ba.writeInt(1); // Thinking ahead -- version #
			ba.writeObject(obState);
			trace("ba uncompressed: " + ba.length);
			ba.compress();
			trace("ba compressed: " + ba.length);
			return ba;
*/			
			return obState;
		}
		
		// fnProgress(nPercentDone:Number, strStatus:String)
		override public function RestoreStateAsync(sto:Object, fnProgress:Function, fnDone:Function): void {
			var fnMyInit:Function = function (err:Number, strErr:String): void {
				var xmlDocument:XML = sto.strXml ? new XML(sto.strXml) : null;
								
				// Maybe the state is FP 10 specific but attempting to be restored under FP 9.
				// If so, drop it and jump straight to RestoreState_OnDone.
				if (Util.GetFlashPlayerMajorVersion() < 10) {
					var ptLimited:Point = Util.GetLimitedImageSize(sto.cxBmd, sto.cyBmd);
					if (ptLimited.x != sto.cxBmd || ptLimited.y != sto.cyBmd) {
						RestoreState_OnDone(ImageDocument.errNewerFlashPlayerRequired, "FP9 trying to load FP10 content");
						return;
					}
	
					if (sto.strXml) {
						if (xmlDocument.hasOwnProperty("@FPVersion")) {
							if (Number(xmlDocument.@FPVersion) >= 10) {
								RestoreState_OnDone(ImageDocument.errNewerFlashPlayerRequired, "FP9 trying to load FP10 content");
								return;
							}
						}
					}
				}
				
				// Create a temp BitmapData for use while we wait for the base image (if any) to load
				Init(sto.cxBmd, sto.cyBmd);
				
				if (sto.strName)
					_strId = sto.strName;
				
				// The asset map and pik.baseImageAsset replace strTempBaseImageName
				if (sto.strTempBaseImageName) {
					// We don't care to try to restore such old documents any more.
					RestoreState_OnDone(ImageDocument.errDocumentError, "Discarding legacy temporary document");
					return;
				}
				
				if (sto.strXmlProperties) {
					_imgp = new ImageProperties();
					_imgp.Deserialize(new XML(sto.strXmlProperties));
				}
				
				if (xmlDocument)
					Deserialize(_strId, xmlDocument, RestoreState_OnProgress, RestoreState_OnDone, "RestoreState");
				
				if (sto.fDirty)
					isDirty = sto.fDirty;
			}
				
			_fnRestoreProgress = fnProgress;
			_fnRestoreDone = fnDone;
				
			super.RestoreStateAsync(sto, fnProgress, fnMyInit);
		}
		
		protected function RestoreState_OnProgress(nPercentDone:Number, strStatus:String): void {
			_fnRestoreProgress(nPercentDone, strStatus);
		}
		
		protected function RestoreState_OnDone(err:Number, strError:String): void {
			_fnRestoreDone(err, strError);
		}
			
		public function Init(cx:int, cy:int, co:uint=0xffffffff): Boolean {
			_strId = null;
			_coBackground = co;
			_cxOriginal = cx;
			_cyOriginal = cy;
			try {
				_bmdBackground = VBitmapData.Construct(cx, cy, true, _coBackground, "imgd.init");
				SetOriginalToBackground();
			} catch (e:InvalidBitmapError) {	
				OnMemoryError(e);
			}
			
			if (!_bmdBackground)
				return false;
			InvalidateComposite();
			return true;
		}
		
		/**
		* @method 		InitFromDisplayObject
		* @description 	Initialize a new ImageDocument with an image rendered from the specified DisplayObject.
		* The DisplayObject can contain anything less <= 2880x2880 in size.  Currently it is only called by
		* MenuBar.Open after it loads a user-selected base image.
		*
		* @usage		InitFromDisplayObject is sync operation
		* @param		strId	The unique id of the ImageDocument, typically derived from the base image
		* name and service (if this is a PerfectMemory document). It must be unique within the user's directory.
		* @param		fidBaseImage	File id of the base image (or null if none)
		* @return		false if anything goes wrong.
		**/
		public function InitFromDisplayObject(strId:String, fidBaseImage:String, dob:DisplayObject, imgp:ImageProperties): Number {
			try {
				if (strId == null || strId.length == 0) strId = "untitled";
				Debug.Assert(strId != "undefined" && strId != null, "strId must be defined (not " + strId + ")");
				Debug.Assert(strId.length <= ImageDocument.kcchFileNameMax, "strId is too long (" + strId.length +
						" chars, limit is " + ImageDocument.kcchFileNameMax + " chars)");
				Debug.Assert(strId.length > 0, "strId must be non-empty");

				var err:Number = errNone;
				_strId = strId;
				_imgp = imgp;
				_dctAssets = { 0: fidBaseImage };
				_daiBaseImage = 0;
				baseStatus = fidBaseImage == kfidAwaitingBackgroundUpload ? DocumentStatus.Loading : DocumentStatus.Loaded;
			 	err = _InitFromDisplayObject(dob);
				
				if (err == errNone) {
					// Post-load operations
					var aops:Array = [];
					var astrOpNames:Array = [];

					// Auto resize if needed
					var nMaxArea:Number = AccountMgr.GetInstance().GetMaxArea();
					var nArea:Number = dob.width * dob.height;

					// 5% bonus area allowed. Don't size down if we are only going 5% smaller
					// or the photo is coming from Flickr
					
					// BST: Removed test for flickr in:
					//if ((properties.serviceid != 'flickr') &&
					if ((nArea * .95) > nMaxArea) {
						// Need to size down
						var nScaleDownFactor:Number = Math.sqrt(nMaxArea / nArea);
						var nNewWidth:Number = Math.round(dob.width * nScaleDownFactor);
						var nNewHeight:Number = Math.round(dob.height * nScaleDownFactor);
						var opScaleDown:ResizeImageOperation = new ResizeImageOperation(nNewWidth, nNewHeight);
						astrOpNames.push("Auto resize down");
						aops.push(opScaleDown);
					}
					
					// Rotate if necessary			
					if (!isNaN(properties.flickr_rotation) && properties.flickr_rotation != 0) {
						/* UNDONE: Don't rotate non-original flickr images. They have already been rotated */
						var opRotate:RotateImageOperation = new RotateImageOperation(Util.RadFromDeg(properties.flickr_rotation));
						astrOpNames.push("Rotate to match Flickr rotation");
						aops.push(opRotate);
					}
					
					if (aops.length > 0) {
						// UNDONE: Ideally, we would not let a user undo this
						// See GenericDocumentUndoRedoSaver minUndoDepth for more
						BeginUndoTransaction("Post load: " + astrOpNames.join(", "));
						var fOpError:Boolean = false;
						for each (var op:ImageOperation in aops) {
							if (!op.Do(this, true, false)) {
								trace("post load operation failed");
								fOpError = true;
								break;
							}
						}
						
						if (fOpError)
							AbortUndoTransaction();
						EndUndoTransaction();
						isDirty = false;
					}
				}
				return err;
			} catch (e:Error) {
				PicnikService.Log("Client Exception: " + e + ", " + e.getStackTrace(), PicnikService.knLogSeverityError);
				throw e;
			}
			return errNone; // won't be reached but is needed to keep the compiler happy
		}
		
		private function _InitFromDisplayObject(dob:DisplayObject): Number {
			if (_bmdBackground) {
				var bmdDispose:BitmapData = _bmdBackground;
				_bmdBackground = null;
				VBitmapData.SafeDispose(bmdDispose);
				if (_bmdComposite != null && _bmdComposite != bmdDispose)
					VBitmapData.SafeDispose(_bmdComposite);
				clearComposite();
			}
			
			if (dob.width == 0 || dob.height == 0) {			
				try {
					var li:LoaderInfo = dob.loaderInfo;
					PicnikService.Log("Client _InitFromDisplayObject fail: loaded: " + li.bytesLoaded + ", total: " + li.bytesTotal + ", " + li.contentType + ", " + li.url, PicnikService.knLogSeverityError);
				} catch (e:Error) {
					PicnikService.Log("Client _InitFromDisplayObject fail: (no log data) " + e + ", " + e.getStackTrace(),  PicnikService.knLogSeverityError);
				}
				return errInitFailed;
			} else {
				_cxOriginal = dob.width;
				_cyOriginal = dob.height;				
				try {
					if (Util.GetFlashPlayerMajorVersion() < 10) {
						var ptLimited:Point = Util.GetLimitedImageSize(dob.width, dob.height);
						if (ptLimited.x != dob.width || ptLimited.y != dob.height) {
							return errNewerFlashPlayerRequired;
						}
					}
					// UNDONE: to retain transparency use color 0x00ffffff
					_bmdBackground = VBitmapData.Construct(dob.width, dob.height, true, 0xffffffff, "imgd.init from dispob");
					SetOriginalToBackground();
				} catch (e:InvalidBitmapError) {
					OnMemoryError(e);
					return errInitFailedOutOfMemory;
				}
			}
			if (!_bmdBackground)
				return errInitFailedOutOfMemory;
			_bmdBackground.draw(dob);
			InvalidateComposite();
			UpdateChildStatus();
			return errNone;
		}
		
		// We may invalidate the composite many times before it is actually needed for display.
		// As an optimization to avoid excessive composite generation we add RENDER and
		// ENTER_FRAME listeners and regenerate the composite when those events occur.
		public function InvalidateComposite(): void {
			if (!_fListeningForRender && Application.application.stage) {
				_fListeningForRender = true;
				Application.application.stage.addEventListener(Event.RENDER, OnRender);
				Application.application.stage.addEventListener(Event.ENTER_FRAME, OnRender);
				Application.application.stage.invalidate();
			}
			_fCompositeInvalid = true;
		}

		// Both RENDER and ENTER_FRAME events end up here to signal that it's time to
		// validate the composite prior to its being drawn.		
		private function OnRender(evt:Event): void {
			Application.application.stage.removeEventListener(Event.RENDER, OnRender);
			Application.application.stage.removeEventListener(Event.ENTER_FRAME, OnRender);
			_fListeningForRender = false;
			if (_fCompositeInvalid)
				ValidateComposite();
		}

		private function ValidateComposite(): void {
			try {
				if (_fCompositeNeedsDisposing)
					var bmdDispose:BitmapData = _bmdComposite; // Composite we created last time
				var bmdOld:BitmapData = _bmdComposite;
				var bmdrOld:BitmapReference = _bmdrComposite;
				if (bmdrOld)
					bmdrOld = bmdrOld.copyRef("imgd composite temp backup for update event");
				
				// Optimization: if there are no DocumentObjects, use the background as the composite
				if (_dobc.numChildren == 0) {
					setCompositeToBackground();
					_fCompositeNeedsDisposing = false;
				} else {
					// Reuse the composite if possible to reduce memory thrashing and allocation failures.
					// Only reuse the composite if:
					// 1. it isn't the background (because we'll be drawing into it)
					// 2. it is the dimensions we need
					// 3. it was created by ValidateComposite (i.e. it isn't in the BitmapCache)
					if (_bmdComposite && _bmdComposite != _bmdBackground && _fCompositeNeedsDisposing &&
							_bmdComposite.width == _bmdBackground.width && _bmdComposite.height == _bmdBackground.height) {
						/* UNDONE: track the invalid background and DocumentObject rectangle and only update it.
						var rcDirty:Rectangle = ???; // _bmdBackground.rect.intersection(_dobc.getBounds(null));
						_bmdComposite.copyPixels(_bmdBackground, rcDirty, rcDirty.topLeft);
						*/
						_bmdComposite.copyPixels(_bmdBackground, _bmdBackground.rect, new Point(0, 0));
						bmdDispose = null;
					} else {
						setCompositeToBackgroundClone();
						_fCompositeNeedsDisposing = true;
					}
					
					// Validate all the DocumentObjects before drawing them
					_dobc.Validate();

					// Use our repaired draw function that can deal with DisplayObjects that draw beyond 4096 pixels					
					VBitmapData.RepairedDraw(_bmdComposite, _dobc);
				}
				
				_fCompositeInvalid = false;
							
				// Refresh the View(s) -- notify document changed listeners
				dispatchEvent(new ImageDocumentEvent(ImageDocumentEvent.BITMAPDATA_CHANGE, bmdOld, _bmdComposite));
				
				if (bmdrOld)
					bmdrOld.dispose(); // We kept an old copy of the composite around for the data change event.
				
				// If we're replacing a rendered composite, dispose of it
				if (bmdDispose)
					bmdDispose.dispose();

				while (_abmdOldBackgrounds.length > 0) {
					bmdDispose = _abmdOldBackgrounds.pop();
					if (bmdDispose != _bmdComposite && bmdDispose != _bmdBackground) {
						try {
							VBitmapData.SafeDispose(bmdDispose);
						} catch (e:Error) {
							// Ignore errors
						}
					}
				}
			} catch (e:InvalidBitmapError) {	
				OnMemoryError(e);
			}
		}
		
		/* Handy debugging function to dump the DisplayObject tree.
		public function DumpDisplayObject(dob:DisplayObject, strIndent:String=""): void {
			trace(strIndent + dob.name + " [" + getQualifiedClassName(dob) + "]");
			var dobc:DisplayObjectContainer = dob as DisplayObjectContainer;
			if (dobc == null)
				return;
			for (var i:int = 0; i < dobc.numChildren; i++) {
				DumpDisplayObject(dobc.getChildAt(i), strIndent + "  ");
			}
		}
		*/

		// Free up bitmaps right away. Afterwards the ImageDocument is useless!
		override public function Dispose(): void {
			super.Dispose();
			
			// Clear out the selection
			selectedItems = null;
			
			// Remove any DocumentObjects
			while (numChildren > 0)
				removeChildAt(0);
			
			// Remove rasterized
			for (var i:Number = 0; i < _dobcRasterized.numChildren; i++)
				if (_dobcRasterized.getChildAt(i) is IDocumentObject)
					IDocumentObject(_dobcRasterized.getChildAt(i)).Dispose();

			var bmdDispose:BitmapData;			
			if (_bmdBackground) {
				if (_bmdBackground != _bmdComposite) {
					bmdDispose = _bmdBackground;
					_bmdBackground = null;
					ClearOriginal();
					try {
						// HACK: Some frames are returning bitmaprefs instead of bitmaps and
						// we're incorrectly disposing of them, resulting in an exception on signout.
						// To repro: open a photo, open reflection frame effect, then sign out.
						// Wrap this call in an exception handler for now to mask the leaked bitmap.
						VBitmapData.SafeDispose(bmdDispose);
					} catch (e1:Error) {
						trace("WARNING: masking potential bitmap leeak in ImageDocument.Dispose()")
					}
				}
			}
			if (_bmdComposite) {
				bmdDispose = _bmdComposite;
				clearComposite();
				try {
					// HACK: Some frames are returning bitmaprefs instead of bitmaps and
					// we're incorrectly disposing of them, resulting in an exception on signout.
					// To repro: open a photo, open reflection frame effect, then sign out.
					// Wrap this call in an exception handler for now to mask the leaked bitmap.
					VBitmapData.SafeDispose(bmdDispose);
				} catch (e2:Error) {
					trace("WARNING: masking potential bitmap leeak in ImageDocument.Dispose()")
				}
			}
			
			FreeUndoBitmaps(true);
			
			// Do this last because prior dispose steps, particularily the removal of DocumentObjects
			// can invalidate the composite which is what adds this render event listening.
			_fCompositeInvalid = false;
			if (_fListeningForRender) {
				_fListeningForRender = false;
				Application.application.stage.removeEventListener(Event.RENDER, OnRender);
				Application.application.stage.removeEventListener(Event.ENTER_FRAME, OnRender);
			}
			ClearOriginal();
			
			if (uploaderInProgress != null)
				uploaderInProgress.Cancel(); // Make sure we stop any pending uploads - so that we are ready to upload the next photo.
		}
		
		/**
		 * NOTE: For the FlashRenderer's use only
		 *
		 * InitFromLocalFile is an async operation so the caller passes in progress and
		 * completion callback functions.
		 *
		 * fnProgress(h)
		 * fnDone(err:Number, strError:String)
		 */
		public function InitFromLocalFile(strLocalBaseImagePath:String, strLocalPikFilePath:String,
				strAssetMap:String, fnProgress:Function, fnDone:Function):Boolean {
			_strId = "RenderServerDoc";
			// UNDONE: remove this after server is no longer trying to render files from the /upload dir
			// NOTE: server/tests/resttests.py relies on that functionality
			if (strLocalBaseImagePath)
				_strLocalBaseImagePath = EscapePercents(strLocalBaseImagePath);
			_fnProgress = fnProgress;
			_fnDone = fnDone;
			baseStatus = DocumentStatus.Loading;
			if (strAssetMap)
				_dctAssets = DeserializeAssetMap(strAssetMap);
			
			if (_fnProgress != null)
				_fnProgress(0, Resource.getString("ImageDocument", "Loading_Picnik_file"));
			_ldr = new URLLoaderPlus();
			_ldr.addEventListener(Event.COMPLETE, InitFromLocalFile_OnLoadComplete);
			_ldr.addEventListener(IOErrorEvent.IO_ERROR, InitFromLocalFile_OnIOError);
			_ldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, InitFromLocalFile_OnSecurityError);
			strLocalPikFilePath = EscapePercents(strLocalPikFilePath);
			
			// ClientTestRunner has test files relative to its directory. Don't
			// mess it up by prepending "file:///" to their paths.
			var strT:String = Application.application.name;
			if (Application.application.name != "ClientTestRunner")
				strLocalPikFilePath = "file:///" + strLocalPikFilePath;

//			trace("loading " + strLocalPikFilePath);
			_ldr.load(new URLRequest(strLocalPikFilePath));
			return true;
		}
	
		private function EscapePercents(str:String):String {
			var rx:RegExp = /%/g;
			return str.replace(rx, "%25");
		}
		
		private function InitFromLocalFile_OnLoadComplete(evt:Event):void {
			if (_fnProgress != null)
				_fnProgress(5, Resource.getString("ImageDocument", "Picnik_file_loaded"));
			XML.ignoreWhitespace = true;
			var xml:XML = XML(_ldr.data);
			_InitFromXml(xml, true, "LocalFile");
			
			_ldr.removeEventListener(Event.COMPLETE, InitFromLocalFile_OnLoadComplete);
			_ldr.removeEventListener(IOErrorEvent.IO_ERROR, InitFromLocalFile_OnIOError);
			_ldr.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, InitFromLocalFile_OnSecurityError);			
		}
		
		private function InitFromLocalFile_OnIOError(evt:IOErrorEvent):void {
			trace("InitFromLocalFile_OnIOError: evt: " + evt);
			baseStatus = DocumentStatus.Error;
			_fnDone(ImageDocument.errPikDownloadFailed, evt.text);
		}
		
		private function InitFromLocalFile_OnSecurityError(evt:SecurityErrorEvent):void {
			trace("InitFromLocalFile_OnSecurityError: evt: " + evt);
			baseStatus = DocumentStatus.Error;
			_fnDone(ImageDocument.errPikDownloadFailed, evt.text);
		}
		
		/**
		* @method 		InitFromPicnikFile
		* @description 	xxx
		* @usage		InitFromPicnikFile is an async operation so the caller passes in functions to
		* be notified of progress and completion.
		* @param		fidPik			The file id of the ImageDocument
		* @param		strAssetMap		An unordered list of index:fid pairs
		* @param		imgp			ImageProperties to be associated with the document
		* @param		fnProgress		Callback parameters are nPercentDone:Number, strStatus:String
		* @param		fnDone			Callback parameters are err:Number, strError:String
		* @return		false if anything goes wrong
		**/
		public function InitFromPicnikFile(fidPik:String, strAssetMap:String, imgp:ImageProperties,
				fnProgress:Function=null, fnDone:Function=null, strBridge:String=null): Boolean {
			_fnProgress = fnProgress;
			_fnDone = fnDone;
			baseStatus = DocumentStatus.Loading;
			_dctAssets = DeserializeAssetMap(strAssetMap);
			_imgp = imgp;
			
			if (_fnProgress != null)
				_fnProgress(0, Resource.getString("ImageDocument", "Loading_Picnik_file"));
				
			var urlr:URLRequest = new URLRequest(PicnikService.GetFileURL(fidPik));
			var urll:URLLoader = new URLLoader();
			
			var fnOnLoadIOError:Function = function (evt:IOErrorEvent): void {
				// UNDONE: retrying
				if (fnDone != null)
					fnDone(ImageDocument.errPikDownloadFailed, "Failed to load");
			}
			
			var fnOnLoadProgress:Function = function (evt:ProgressEvent): void {
				InitFromName_OnReadPikProgress(evt.bytesLoaded, evt.bytesTotal);
			}
			
			var fnOnLoadComplete:Function = function (evt:Event): void {
				if (_fnProgress != null)
					_fnProgress(5, Resource.getString("ImageDocument", "Picnik_file_loaded"));
					
				XML.ignoreWhitespace = true;
				var xml:XML = XML(urll.data);
				
				// Handle old (pre-asset map) History entries
				if (xml.@hasBaseImage == "true" && !xml.hasOwnProperty("@baseImageAsset"))
					xml.@baseImageAsset = "0";

				_InitFromXml(xml, true, strBridge);
			}
			
			urll.addEventListener(IOErrorEvent.IO_ERROR, fnOnLoadIOError);
			urll.addEventListener(Event.COMPLETE, fnOnLoadComplete);
			urll.addEventListener(ProgressEvent.PROGRESS, fnOnLoadProgress);
			
			urll.load(urlr);
			return true;
		}
				
		/**
		* @method 		InitFromId
		* @description 	Create
		* @usage		InitFromId is an async operation so the caller passes in functions to
		* be notified of progress and completion.
		* @param		strId	The unique id of the ImageDocument, typically derived from the base image
		* name and service (if this is a shadow document). It must be unique within the user's directory.
		* @param		fnProgress		Callback parameters are nPercentDone:Number, strStatus:String
		* @param		fnDone			Callback parameters are err:Number, strError:String. If null, pik will not be read.
		* @return		false if anything goes wrong
		**/
		private function InitFromId(strId:String, fnProgress:Function=null, fnDone:Function=null): Boolean {
			Debug.Assert(strId != "undefined" && strId != null, "strId must be defined (not " + strId + ")");
			Debug.Assert(strId.length <= ImageDocument.kcchFileNameMax, "strId is too long (" + strId.length +
					" chars, limit is " + ImageDocument.kcchFileNameMax + " chars)");
						
			_strId = strId;
			_strMinorId = strId;
			_fnProgress = fnProgress;
			_fnDone = fnDone;
			baseStatus = DocumentStatus.Loading;
			
			if (_fnDone != null) {
				if (_fnProgress != null)
					_fnProgress(0, Resource.getString("ImageDocument", "Loading_Picnik_file"));
				return PicnikService.ReadPik(_strId, InitFromId_OnReadPikDone, InitFromName_OnReadPikProgress);
			} else {
				return true;
			}
		}
			
		private function InitFromId_OnReadPikDone(err:Number, strError:String, xml:XML=null): void {
			if (err == PicnikService.errNone) {
				if (_fnProgress != null)
					_fnProgress(5, Resource.getString("ImageDocument", "Picnik_file_loaded"));
					
				// If we've been given an "updated" timestamp check if the pik's timestamp matches what we've got
				if (xml.hasOwnProperty("@updated") && _imgp.last_update && _imgp.last_update.getTime() / 1000 > xml.@updated) {
					// the file has been updated more recently than we know about, so bail
					baseStatus = DocumentStatus.Error;
					_fnDone(ImageDocument.errPikDownloadFailed, strError);
					trace("InitFromId_OnReadPikDone: Base file updated: " + strError);
				} else {					
					_InitFromXml(xml, false, "OldPerfectMemory");
				}
			} else {
				baseStatus = DocumentStatus.Error;
				_fnDone(ImageDocument.errPikDownloadFailed, strError);
				trace("InitFromId_OnReadPikDone: Error: " + strError);
			}
		}
			
		/**
		* @method 		InitFromIdWithMetadata
		* @description  Create
		* @usage		Works like InitFromId, but takes into account the values of some extra fields to determine validity
		* @param		strId	The unique id of the ImageDocument, typically derived from the base image
		* name and service (if this is a shadow document). It must be unique within the user's directory.
		* @param		imgp			ImageProperties to be associated with the document
		* @param		fnProgress		Callback parameters are nPercentDone:Number, strStatus:String
		* @param		fnDone			Callback parameters are err:Number, strError:String. If null, pik will not be read.
		* @return		false if anything goes wrong
		**/
		public function InitFromIdWithMetadata(strId:String, imgp:ImageProperties, fnProgress:Function=null, fnDone:Function=null):Boolean {
			Debug.Assert(strId != "undefined" && strId != null, "strId must be defined (not " + strId + ")");
			Debug.Assert(strId.length <= ImageDocument.kcchFileNameMax, "strId is too long (" + strId.length +
					" chars, limit is " + ImageDocument.kcchFileNameMax + " chars)");
			_imgp = imgp;
					
			if (!_imgp.etag || _imgp.etag.length == 0)
				return InitFromId(strId, fnProgress, fnDone);
					
			_strMinorId = strId;					
			_strId = strId + "etag" + _imgp.etag;
			_fnProgress = fnProgress;
			_fnDone = fnDone;
			baseStatus = DocumentStatus.Loading;
			
			if (_fnDone != null) {
				if (_fnProgress != null)
					_fnProgress(0, Resource.getString("ImageDocument", "Loading_Picnik_file"));
				return PicnikService.ReadPik(_strId, InitFromIdWithMetadata_OnReadPikDone, InitFromName_OnReadPikProgress);
			} else {
				return true;
			}
		}
		
		private function InitFromIdWithMetadata_OnReadPikDone(err:Number, strError:String, xml:XML=null): void {
			if (err == PicnikService.errNone) {
				if (_fnProgress != null)
					_fnProgress(5, Resource.getString("ImageDocument", "Picnik_file_loaded"));
				_InitFromXml(xml, false, "NewPerfectMemory");
			} else {
				// we weren't able to find one with matching etag, so try again without the etag
				InitFromId( _strMinorId, _fnProgress, _fnDone );
			}
		}
		
		private function InitFromName_OnReadPikProgress(cbLoaded:Number, cbTotal:Number): void {
			_fnProgress((cbLoaded / cbTotal) * 5, Resource.getString("ImageDocument", "Loading_Picnik_file"));
		}
		
		public function Deserialize(strId:String, xml:XML, fnProgress:Function, fnDone:Function, strBridge:String=null):Boolean {
			_strId = strId;
			_fnProgress = fnProgress;
			_fnDone = fnDone;
			baseStatus = DocumentStatus.Loading;
			_InitFromXml(xml, false, strBridge);
			return true;
		}
		
		// NOTE: we don't need to update this with new constrained ImageOperations because those
		// operations should be initializing serialized constraint properties upon instantiation.
		static private var s_dctConstrainedOps:Object = {
			SimpleBorder: null, Border: null, DropShadow: null, FramedGetVar: null, Glow: null, PostalFrame: null,
			Rotate: null
		}
		
		// All documents are upgraded to the lastest version before use. We do this up front in one
		// centralized place so none of the rest of the code has to concern itself with backwards
		// compatibility. An important side-effect of this is that after a version change only new
		// version documents are created. Even re-saved docs will have been upgraded.
		static private function UpgradeDocument(xmlPik:XML): void {
			var nDocVersion:Number = xmlPik.hasOwnProperty("@version") ? xmlPik.@version : 1;
			
			// We upgrade VERY old documents (< 9/5/07) from before we added UndoTransactions.
			// Wrap their Operations inside UndoTransactions so they look like new docs.
			
			var xmlUndoTransactions:XML = xmlPik.UndoTransactions[0];
			if (xmlUndoTransactions == null) {
				var cut:int = 0;
				xmlUndoTransactions = <UndoTransactions/>;
				for each (var xmlOp:XML in xmlPik.Operations.*) {
					var xmlUt:XML = <UndoTransaction name="legacy"/>;
					xmlUt.appendChild(xmlOp);
					xmlUndoTransactions.appendChild(xmlUt);
					cut++;
				}
				xmlUndoTransactions.@redoStart = cut;
				delete xmlPik.Operations;
				xmlPik.appendChild(xmlUndoTransactions);
			}
			
			// We want all documents to have maxWidth, maxHeight, and maxPixel constraint properties
			// on ImageOperations that might increase the size of the document. This ensures the server
			// will always render the document exactly the same way the client did (WYSIWYG).
			// - New (>= 11/26/08) ImageDocuments get them as ImageOperations are instantiated
			// - Old documents with no FPVersion are assumed to be constrained by Flash 9 limits
			// - Documents with FPVersion == 9 are assumed to be constrained by Flash 9 limits
			// - Documents with FPVersion >= 10 are assumed to be constrained by Flash 10 limits
			// - It is assumed that the Flash Player version the client is currently running under
			//   is >= the version of the document
			// - We also assume that if any the maxWidth property is missing then all the related
			//   properties are missing
			
			var nDocFPVersion:Number = xmlPik.hasOwnProperty("@FPVersion") ? xmlPik.@FPVersion : 9;
			var cxMax:int, cyMax:int, cPixelsMax:int;
			if (nDocFPVersion == 9) {
				cyMax = cxMax = 2800;
				cPixelsMax = 2800 * 2800;
			} else {
				cyMax = cxMax = 8000;
				cPixelsMax = 4000 * 4000;
			}
			
			for each (xmlUt in xmlUndoTransactions.*)
				UpgradeOperations(xmlUt.*, cxMax, cyMax, cPixelsMax, nDocVersion);
				
			// The document has been upgraded to the latest and greatest version.
			xmlPik.@version = DOCUMENT_VERSION;
		}
		
		static private function UpgradeOperations(xmlOps:XMLList, cxMax:int, cyMax:int, cPixelsMax:int, nDocVersion:int): void {
			for each (var xmlOp:XML in xmlOps) {
				var strName:String = xmlOp.name();
				if (strName == "Nested") {
					UpgradeOperations(xmlOp.*, cxMax, cyMax, cPixelsMax, nDocVersion);
					continue;
				}
				
				if (strName in s_dctConstrainedOps) {
					if (!xmlOp.hasOwnProperty("@maxWidth")) {
						xmlOp.@maxWidth = cxMax;
						xmlOp.@maxHeight = cyMax;
						xmlOp.@maxPixels = cPixelsMax;
					}
				}
				
				// ImageDocument versions <= 2 were not explicit about the alpha portion of the
				// DropShadowImageOperation's backgroundColor property. No matter what the alpha
				// value was it would be ignored. In versions >= 3 backgroundColor's alpha is
				// honored and defaults to 255.
				if (strName == "DropShadow" && nDocVersion < 3) {
					var co:uint = uint(xmlOp.@backgroundColor);
					co = (co & 0x00ffffff) | 0xff000000;
					xmlOp.@backgroundColor = co;
				}
				
				// ImageDocument versions <= 2 ignored the alpha portion of the RotateImageOperation's
				// borderColor property. It was set to 255. In versions >= 3 borderColor's alpha is
				// honored and defaults to 255.
				if (strName == "Rotate" && nDocVersion < 3) {
					var co2:uint = uint(xmlOp.@borderColor);
					co2 = (co2 & 0x00ffffff) | 0xff000000;
					xmlOp.@borderColor = co2;
				}
			}
		}
		
		// Four cases we _InitFromXml:
		// - restoring an ImageDocument from the local SharedObject (strBridge == "RestoreState")
		// - loading a PerfectMemory document (strBridge == "<service>")
		// - loading a History document (strBridge == "Picnik")
		// - FlashRenderer (via InitFromLocalFile, strBridge == "LocalFile")
		private function _InitFromXml(xml:XML, fForRender:Boolean=false, strBridge:String=null): void {
			try {
				// First thing, upgrade the document to conform to modern expectations
				UpgradeDocument(xml);
				
				_xmlPik = xml;
				
				// Don't initialize a document created under Flash Player >= 10 if the client is
				// running under Flash Player < 10.
				if (xml.hasOwnProperty("@FPVersion")) {
					if (Number(xml.@FPVersion) >= 10 && Util.GetFlashPlayerMajorVersion() < 10) {
						_fnDone(errNewerFlashPlayerRequired, "Document requires Flash Player >= 10");
						return;
					}
				}
				
				var fHasBaseImage:Boolean = xml.@hasBaseImage == "true";
				_fSaved = xml.@docSaved == "true";
				if (xml.hasOwnProperty("@baseImageAsset"))
					_daiBaseImage = int(xml.@baseImageAsset);
				if (xml.hasOwnProperty("@backgroundColor"))
					_coBackground = uint(xml.@backgroundColor);
				if (xml.hasOwnProperty("@originalWidth"))
					_cxOriginal = int(xml.@originalWidth);
				if (xml.hasOwnProperty("@originalHeight"))
					_cyOriginal = int(xml.@originalHeight);
				
				// If the document has a base image, load it (and use its dimensions).
				// Otherwise, use the document-specified dimensions.
				
				// These cases either produce a fidBaseImage or a URL. If a URL then the base
				// image fid will be created by Downloader. In any case we end up with an asset
				// map based ImageDocument that all the SaveToXXX, etc APIs are happy with.
				if (fHasBaseImage || _daiBaseImage != -1 || _strLocalBaseImagePath != null) {
					if (_fnProgress != null)
						_fnProgress(5, Resource.getString("ImageDocument", "Loading_base_image"));
						
					var strBaseImagePath:String = null;
					var fidBaseImage:String = null;
					
					// Our new-fangled way to get the base image.
					if (_daiBaseImage != -1) {
						if (strBridge == null)
							strBridge = "SharedObject|History|PerfectMemory";
						fidBaseImage = _dctAssets[_daiBaseImage];
						if (fidBaseImage == kfidAwaitingBackgroundUpload) {
							_fnDone(errAwaitingBackgroundUpload, "Can't restore base image that never finished uploading");
							return;
						}
					} else {
						// UNDONE: remove this when FlashRenderer is only passing images w/ asset maps
						// DWM: Are legacy Perfect Memory files the only hold-back?
						// _strLocalBaseImagePath is used by the Flash Renderer only
						if (_strLocalBaseImagePath != null) {
							fidBaseImage = "file:///" + _strLocalBaseImagePath;
							strBridge = "LegacyFlashRenderer";

						// Derive the base image name from the pik doc name (legacy PerfectMemory)
						} else {
							strBaseImagePath = PicnikService.BuildBaseImageURL(_strId);
							strBridge = "PerfectMemory";
						}
					}
					if (strBridge == null)
						strBridge = "ImageDocument";
					
					// UNDONE: canceling?
					var dnldr:Downloader = new Downloader(ItemInfo.FromImageProperties(new ImageProperties(strBridge, strBaseImagePath)), "/" + strBridge,
							InitFromName_OnDownloadBaseImageDone, InitFromName_OnDownloadBaseImageProgress, 0, false);
					dnldr.fid = fidBaseImage;
					dnldr.StartWithRetry();
					
				} else {
					var cx:Number = _cxOriginal ? _cxOriginal : Number(xml.@width);
					var cy:Number = _cyOriginal ? _cyOriginal : Number(xml.@height);
					if (cx == 0 || cy == 0 || isNaN(cx) || isNaN(cy)) {
						baseStatus = DocumentStatus.Error;
						_fnDone(errPikDownloadFailed, "Document invalid. Must have baseImage OR width/height");
						return;
					}
		
					if (!Init(cx, cy, _coBackground)) {
						baseStatus = DocumentStatus.Error;
						_fnDone(errOutOfMemory, "Failed to create in-memory image");
						return;
					}
		
					// Parse and playback operations, will call _fnDone when done
					InitFromName_ParseAndPlaybackOperations();
				}
			} catch (e:Error) {
				trace("_InitFromXml exception: " + e.message + ", " + e.getStackTrace());
				_fnDone(ImageDocument.errInitFailed, "Exception, _InitFromXml failed");
			}
		}
		
		private function InitFromName_OnDownloadBaseImageProgress(strStatus:String, nFractionDone:Number): void {
			if (_fnProgress != null)
				_fnProgress(5 + (nFractionDone * 95), Resource.getString('ImageDocument', 'Loading_base_image'));
		}
		
		private function InitFromName_OnDownloadBaseImageDone(err:Number, strError:String, dnldr:FileTransferBase): void {
			if (err != ImageDocument.errNone) {
				baseStatus = DocumentStatus.Error;
				_fnDone(errPikDownloadFailed, "Failed to download base image. " + strError);
				return;
			}
			
			// Always set the base image asset index to the loaded file. This makes no difference
			// for up-to-date ImageDocuments that already have a _daiBaseImage but will upgrade
			// legacy docs (e.g. SharedObject, PerfectMemory, History).
			_daiBaseImage = AddAsset(dnldr.fid);
			
			// If this document's ImageProperties has no metadata (e.g. Exif) try to pull it from
			// the loaded image.
			if (_imgp.metadata == null && dnldr.itemInfo.metadata != null)
				_imgp.metadata = dnldr.itemInfo.metadata;
				
			err = _InitFromDisplayObject(DisplayObject(dnldr.content));
			if (err != errNone) {
				baseStatus = DocumentStatus.Error;
				_fnDone(err, "Failed to create in-memory image");
				return;
			}
	
			// Parse and playback operations, will call _fnDone when done
			InitFromName_ParseAndPlaybackOperations();
		}
		
		private function InitFromName_ParseAndPlaybackOperations(): void {
			if (_fnProgress != null)
				_fnProgress(100, Resource.getString("ImageDocument", "Reconstituting"));
			
			// Parse DocumentObjects
			var xmlObs:XML = _xmlPik.Objects[0];
			if (xmlObs != null) {
				DeserializeDocumentObjects(_dobc, xmlObs);
				_dobc.Validate();
			}

			// Parse rasterized DocumentObjects
			xmlObs = _xmlPik.RasterizedObjects[0];
			if (xmlObs != null) {
				DeserializeDocumentObjects(_dobcRasterized, xmlObs);
				_dobcRasterized.Validate();
				
				// If we have any rasterized objects we have to wait until they
				// are fully loaded before playing back the ImageOperations. This
				// is because they need to be ready when a RasterizeImageOperation
				// is hit.
				if (_dobcRasterized.numChildren != 0) {
					if (_dobcRasterized.status < DocumentStatus.Loaded) {
						var fnOnPropertyChange:Function = function (evt:PropertyChangeEvent): void {
							if (evt.property != "status")
								return;
							_dobcRasterized.Validate();
							
							if (evt.newValue >= DocumentStatus.Loaded || evt.newValue == DocumentStatus.Error) {
								// OK, we're ready to go
								_dobcRasterized.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, fnOnPropertyChange);
								
								if (evt.newValue == DocumentStatus.Error) {
									_fnDone(ImageDocument.errChildObjectFailedToLoad, "Rasterized child object failed to load");
								} else {
									InitFromName_PlaybackOperations();
								}
							}
						}
						_dobcRasterized.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, fnOnPropertyChange);
						return;
					}			
				}
			}
			
			InitFromName_PlaybackOperations();
		}
		
		private function InitFromName_PlaybackOperations(): void {
			var xmlOps:XML = _xmlPik.UndoTransactions[0];
			
			// It is valid for a document to have no Operations. Blank documents are created this way.
			if (!xmlOps) {
				baseStatus = DocumentStatus.Loaded;
				_fnDone(errNone, "Complete");
				return;
			}
			
			// If this is the renderer, clone the background to the original before altering it
			if (_strId == "RenderServerDoc" && _bmdBackground != null)
				SetOriginalToBackgroundClone();
			
			// Parse operations
			PopulateOperationHistory(xmlOps);
			
			UpdateChildStatus();
		}

		// This sucks but we have to reference each ImageOperation to force
		// it to be compiled in to the FlashRenderer. Doing so kind of defeats
		// the clever dynamic class lookup below because we still have to
		// remember to add any new ImageOperations to this list.
		private static var s_aopRef:Array = [
			// ImageOperations
			PaletteMapImageOperation, RotateImageOperation, SharpenImageOperation,
			ResizeImageOperation, ColorMatrixImageOperation, CropImageOperation,
			BlendImageOperation, BlurImageOperation, PerlinNoiseImageOperation,
			GlowImageOperation, BWImageOperation, IRImageOperation,
			SimpleColorMatrixImageOperation, BorderImageOperation, TintImageOperation,
			NestedImageOperation, EdgeDetectionBImageOperation, BlemishImageOperation,
			ShineImageOperation, GooifyImageOperation, DoodleImageOperation, DoodlePlusImageOperation,
			FillColorMatrixImageOperation, GradientMapImageOperation, TwoToneImageOperation,
			HSVGradientMapImageOperation, MultiplyColorMatrixImageOperation, GetVarImageOperation,
			LocalContrastImageOperation, AutoFixImageOperation, DropShadowImageOperation,
			AdjustCurvesImageOperation, GlowingEdgesImageOperation, NoiseImageOperation,
			GaussianImageOperation, EdgeDetectionSobelImageOperation, EdgeDetectionLaplaceImageOperation,
			SimpleBorderImageOperation, AlphaMapImageOperation, EdgeDetectionAImageOperation,
			QuantizePaletteImageOperation, RadialBlurImageOperation, VibranceImageOperation,
			RasterizeImageOperation, ScatteredPartsImageOperation, PuzzleImageOperation,
			FramedGetVarImageOperation, PixelateImageOperation, TelevisionImageOperation,
			ShaderImageOperation, PostalFrameImageOperation, OperationStrokeImageOperation,
			HalftoneScreenImageOperation, ColorReduceImageOperation, ReflectionImageOperation,
			OffsetImageOperation, BeforeAfterImageOperation, FillColorImageOperation,
			LightningImageOperation, FishEyeImageOperation, GradientShapeImageOperation, OverlayGetVarImageOperation,
			ShapeImageOperation, BokehImageOperation, PerlinSpotsImageOperation,
			ExposureImageOperation, FacePaintImageOperation, MultiColorImageOperation, SimpleTintImageOperation,
			SwfOverlayImageOperation,
			//MaskImageOperation,
						
			// ObjectOperations
			SetPropertiesObjectOperation, DestroyObjectOperation, ObjectOperation,
			SetDepthObjectOperation, CreateObjectOperation, StraightenObjectOperation,
			FlipObjectOperation, RemoveDistortionObjectOperation, SetUIModeObjectOperation,
			NestedObjectOperation
		]
		
		private function PopulateOperationHistory(xmlOps:XML): void {
			var fDirty:Boolean = _fDirty;
			
			_autHistory = new Array();
			_iutHistoryTop = 0;
			
			var iut:Number = 0;
			var iutRedoStart:Number = Number.MAX_VALUE;
			if (xmlOps.@redoStart != undefined)
				iutRedoStart = Number(xmlOps.@redoStart);

			// Create an array of UndoTransaction instances from a list of UndoTransaction XML elements.
			var aut:Array = [];
			var imgut:ImageUndoTransaction;
			var xmlOp:XML;
			var op:ImageOperation;
			
			for each (var xmlUt:XML in xmlOps.children()) {
				imgut = new ImageUndoTransaction(null, false, xmlUt.@name.toString(), []);
				imgut.coalescable = false;
				for each (xmlOp in xmlUt.children()) {
					op = ImageOperation.XMLToImageOperation(xmlOp);
					if (!op) {
						baseStatus = DocumentStatus.Error;
						_fnDone(errPikDownloadFailed, "Pik document is invalid");
						return;
					}
					imgut.aop.push(op);
				}
				aut.push(imgut);
			}
			
			// If this is the renderer

			PopulateOperationHistory_DoWork(iut, iutRedoStart, fDirty, aut);
		}

		// Process image ops for some period of time
		private function PopulateOperationHistory_DoWork(iut:Number, iutRedoStart:Number, fDirty:Boolean, aut:Array): void {
			// loop for 1 seconds
			var cmsStopTime:uint = getTimer() + 1000;
			while (aut.length > 0 && getTimer() <= cmsStopTime) {
				var imgut:ImageUndoTransaction = aut.shift();

				// If this was a done operation in the original document, do it in an undoable way
				if (iut < iutRedoStart && !imgut.objectOperationsOnly) {
					// HACK: the render server never needs to undo so it can save memory
					// and BitmapData cloning time by not encapsulating the Do inside of
					// Begin/EndUndoTransaction.
					if (_strId == "RenderServerDoc") {
						// UndoTransaction.Do() w/ these parameters cleans up after itself
						// leaving only the new imgd.background undisposed.
						imgut.Do(this, false);
					} else {
						// DWM: I've changed this to not rely on Begin/EndTransaction any more
						// to construct the undo history. This way we can directly copy the
						// undo state contained within the deserialized UndoTransaction which
						// means its OK for us to mix ObjectOperations and ImageOperations
						// within a single transaction. Before it wasn't because we had to pass
						// ut.Do(fDoObjects=false) to prevent DocumentObject state from being
						// altered but that also meant that the resultant UndoTransaction wouldn't
						// contain undo state for any ObjectOperations.
						FreeUndoBitmaps();
						imgut.bmdBackground = _bmdBackground;
						
						// fDontDisposeInitialBackground = true so the _bmdBackground we
						// placed in the UndoTransaction won't be disposed (that is the job of
						// future FreeUndoBitmap calls).
						imgut.Do(this, false, true);
						AddToHistory(imgut);
					}
				// Otherwise it was a redo operation in the original document so capture it as a redo
				} else {
					AddToHistory(imgut);
				}
				iut++;
			}

			if (aut.length > 0)
				Application.application.callLater(PopulateOperationHistory_DoWork, [iut, iutRedoStart, fDirty, aut]);
			else
				Application.application.callLater(PopulateOperationHistory_OnDone, [iut, iutRedoStart, fDirty]);
		}

		/// Cleanup and call _fnDone
		private function PopulateOperationHistory_OnDone(iut:Number, iutRedoStart:Number, fDirty:Boolean): void {
			// If there are redo operations, pull back the HistoryTop beneath them
			if (iutRedoStart < _iutHistoryTop)
				_iutHistoryTop = iutRedoStart;
				
			// We don't want history population to affect the dirty state of the document.
			// This important when a dirty document is restored from the SharedObject.
			isDirty = fDirty;
			
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.UNDO_CHANGE, undefined, undoDepth));
			dispatchEvent(new GenericDocumentEvent(GenericDocumentEvent.REDO_CHANGE, undefined, redoDepth));
			baseStatus = DocumentStatus.Loaded;
			_fnDone(errNone, "Complete");
		}
	
		public function Serialize(fDiscardPreFlattenedHistory:Boolean, fSnapshotDeviceText:Boolean=true): XML {
			var xmlDoc:XML = <PicnikDocument version={DOCUMENT_VERSION} width={_bmdComposite.width} height={_bmdComposite.height} backgroundColor={_coBackground}/>;
			
			// The FPVersion attribute designates the minimum Flash Player version required
			// to open the document. We assume all documents created under Flash Player 10
			// require Flash Player 10 or greater.
			xmlDoc.@FPVersion = Util.GetFlashPlayerMajorVersion() >= 10 ? "10" : "9";
			
			if (_daiBaseImage != -1) {
				xmlDoc.@baseImageAsset = _daiBaseImage;
				if (_imgp.etag)
					xmlDoc.@etag = _imgp.etag;
			}
			if (_fSaved)
				xmlDoc.@docSaved = "true";
			if (_cxOriginal != 0 && _cyOriginal != 0) {
				xmlDoc.@originalWidth = _cxOriginal;
				xmlDoc.@originalHeight = _cyOriginal;
			}

			if (_dobc.numChildren > 0) {
				var xmlObs:XML = <Objects/>
				for (var i:Number = 0; i < _dobc.numChildren; i++) {
					var doco:IDocumentObject = _dobc.getChildAt(i) as IDocumentObject;
					
					// darrinm: When debugging I sometimes add DisplayObjects (not DocumentObjects) straight
					// to the document. This keeps them from wreaking too much havok.
					if (doco == null)
						continue;
					
					var xmlOb:XML = DocumentObjectToXML(doco);
					xmlObs.appendChild(xmlOb);
				}
				xmlDoc.appendChild(xmlObs);
			}
			
			// Serialize rasterizedObjects. Its children are DocumentObjectContainers with a
			// unique id and an arbitrary number of child DocumentObjects.
			if (_dobcRasterized.numChildren > 0) {
				xmlObs = <RasterizedObjects/>
				for (i = 0; i < _dobcRasterized.numChildren; i++) {
					doco = _dobcRasterized.getChildAt(i) as IDocumentObject;
					xmlOb = DocumentObjectToXML(doco, fDiscardPreFlattenedHistory);
					xmlObs.appendChild(xmlOb);
				}
				xmlDoc.appendChild(xmlObs);
			}
			
			var imgut:ImageUndoTransaction;
			
			// If we're meant to discard the pre-flattened history find the flattening transaction
			// to use as the new beginning of the serialized UndoTransactions. Also, pull the
			// rasterized width and height from it to use as the new document originalWidth/Height.
 			var iut:int = 0;
 			if (fDiscardPreFlattenedHistory) {
	 			iut = FindFlattenCollageUndoTransaction();
	 			if (iut != 0) {
	 				imgut = _autHistory[iut];
	 				var rop:RasterizeImageOperation = null;
					// Find the rasterize operation. In fancy collages with dynamic objects,
					// it will occur after we set props to move the dynamic objects out of the photo grid
	 				for (var iRop:Number = 0; iRop < imgut.aop.length; iRop++) {
	 					rop = imgut.aop[iRop] as RasterizeImageOperation;
	 					if (rop != null) break; // Found it
	 				}
	 				if (rop != null) {
						xmlDoc.@originalWidth = rop.width;
						xmlDoc.@originalHeight = rop.height;
					}
	 			}
	 		}

			var xmlUts:XML = <UndoTransactions redoStart={_iutHistoryTop - iut}/>
			
			// Enumerate UndoTransaction history and add each transaction to the output
			for (; iut < _autHistory.length; iut++) {
				imgut = _autHistory[iut];
				var xmlOps:XML = <UndoTransaction name={imgut.strName}/>
				for (var iop:Number = 0; iop < imgut.aop.length; iop++) {
					var op:ImageOperation = imgut.aop[iop];
					var xmlOp:XML = op.Serialize();
					xmlOps.appendChild(xmlOp);
				}
				xmlUts.appendChild(xmlOps);
			}
			xmlDoc.appendChild(xmlUts);
			
			if (fSnapshotDeviceText) {
				// Enumerate all the device font using Text DocumentObjects and incorporate bitmap snapshots of the
				// text as embedded assets.
				var aobSnapshots:Array = [];
				SnapshotDeviceText(_dobc, aobSnapshots);
				
				if (aobSnapshots.length > 0) {
					var xmlEmbeddedAssets:XML = <EmbeddedAssets/>;
					for each (var ob:Object in aobSnapshots) {
						var xmlAsset:XML = <Asset id={ob.id} metadata={ob.metadata}/>;
						var enc:Base64Encoder = new Base64Encoder();
						enc.encodeBytes(ob.data);
						xmlAsset.appendChild(new XML(enc.drain()));
						xmlEmbeddedAssets.appendChild(xmlAsset);
					}
					xmlDoc.appendChild(xmlEmbeddedAssets);
				}
			}
			
			return xmlDoc;
		}
		
		// Recurse down the DocumentObject tree capturing images of text using device
		// fonts. These images are added to the document and sent to the server so it
		// has what it needs to render.
		private function SnapshotDeviceText(dobc:DocumentObjectContainer, aobSnapshots:Array): void {
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var doco:IDocumentObject = dobc.getChildAt(i) as IDocumentObject;
				if (!doco)
					continue;
				if (doco is DocumentObjectContainer)
					SnapshotDeviceText(doco as DocumentObjectContainer, aobSnapshots);
				
				// Only snapshot text objects.
				var txt:Text = doco as Text;
				if (!txt)
					continue;
				
				// Only if they're using a device font.
				if (!txt.font.isDevice)
					continue;
				
				// And only if some portion of the text is inside the document bounds.
				var ob:Object = txt.GetContentSnapshot();
				if (!ob)
					continue;
				
				aobSnapshots.push(ob);
			}
		}
		
		// Used by documentObjects.Text.
		public function GetEmbeddedAsset(id:String): Object {
			var xmlAsset:XML = _xmlPik.EmbeddedAssets.Asset.(@id == id)[0];
			if (!xmlAsset)
				return null;
			
			var dec:Base64Decoder = new Base64Decoder();
			dec.decode(String(xmlAsset));
			var ba:ByteArray = dec.drain();
			
			return { id: id, metadata: String(xmlAsset.@metadata), data: ba };
		}
 		
		private function FindFlattenCollageUndoTransaction(): int {
			// NOTE: the flatten transaction CAN'T be on the redo history because the user
			// has no way to save while in the pre-flattened state. But just in case we add
			// a way to do that in the future, and it would probably be bad to discard
			// everything the user is in the middle of, we only scan up to the redo base.
			for (var iut:int = 0; iut < _iutHistoryTop; iut++) {
				var imgut:ImageUndoTransaction = _autHistory[iut];
				if (imgut.strName == "Flatten Collage")
					break;
			}
			
			// Not present, serialize as usual from the beginning
			if (iut == _iutHistoryTop)
				iut = 0;
				
			return iut;
		}
 		
 		// Remove any unreferenced assets from the asset map. Do this by creating an empty
 		// asset map and copying all referenced assets to it. Find out which assets are
 		// referenced by enumerating all ImageOperations in the UndoTransaction history,
 		// including redo transactions. Also find all assets referenced by DocumentObjects
 		// on the documentObjects and rasterizedObjects lists.
 		override protected function GetOptimizedAssetMap(fDiscardPreFlattenedHistory:Boolean=false): Object {
 			var dctAssetsNew:Object = {};
 			
 			var iut:int = fDiscardPreFlattenedHistory ? FindFlattenCollageUndoTransaction() : 0;
 			
 			// for each UndoTransaction
			for (; iut < _autHistory.length; iut++) {
				var imgut:ImageUndoTransaction = _autHistory[iut];
				
	 			// for each ImageOperation
	 			for (var iop:int = 0; iop < imgut.aop.length; iop++) {
	 				var op:ImageOperation = imgut.aop[iop];
	 				var adai:Array = op.assetRefs;
	 				if (adai == null)
	 					continue;

	 				// for each asset
	 				for (var i:int = 0; i < adai.length; i++) {
	 					// add to new asset dict
	 					var dai:int = adai[i];
						if (dctAssetsNew[dai] == undefined)
							dctAssetsNew[dai] = _dctAssets[dai];	 					
	 				}
	 			}
			}

			// Not all asset references can be found in the Undo history because it can be truncated, e.g.
			// when saving a collage/fancy collage. Scan the rasterizedObjects and documentObjects for
			// assetRefs too. Assets that are found multiple times are coalesced, so no worries.
			AddDocumentObjectAssetRefsToMap(_dobcRasterized, dctAssetsNew);
			AddDocumentObjectAssetRefsToMap(_dobc, dctAssetsNew);
			
			// Copy the base image asset reference over too.
			if (_daiBaseImage != -1)
				dctAssetsNew[_daiBaseImage] = _dctAssets[_daiBaseImage];	 					
			
			return dctAssetsNew;
 		}

		// CONSIDER: is this robust enough? What if we come up with objects that reference more than one asset? 		
 		private function AddDocumentObjectAssetRefsToMap(dobc:DocumentObjectContainer, dctAssets:Object): void {
 			if (dobc == null)
 				return;
 				
			for (var i:int = 0; i < dobc.numChildren; i++) {
				var doco:IDocumentObject = dobc.getChildAt(i) as IDocumentObject;
				if (doco == null)
					continue;
					
				// HACK: don't consider invisible rasterized objects. They're temporary.
				if (!DisplayObject(doco).visible)
					continue;
					
				if ("assetRef" in doco) {
					var ob:* = doco["assetRef"];
					if (ob != undefined)
						dctAssets[int(ob)] = _dctAssets[int(ob)];
				}
				
				// Recurse into containers
				AddDocumentObjectAssetRefsToMap(doco as DocumentObjectContainer, dctAssets);
			}
 		}
		
		// Optimize the ImageDocument. The result is as reduced as possible while still
		// producing the same end result. If the document only creates and manipulates
		// DocumentObjects then its optimized form will have no history, no rasterizedObjects;
		// just documentObjects.
		//
		// NOTE: further optimization could be done (e.g. coallescing ObjectOperations
		// even if non-ObjectOperations are present) but not worth the effort for our
		// current use case (optimizing Fancy Collages).
		//
		// 1. remove all redo UndoTransactions
		// 2. remove all undo UndoTransactions IF they're exclusively ObjectOperations
		// 3. rebuild the asset map to only include the remaining assets
		// - return true if undo & redo history is completely cleared
		public function Optimize(): Boolean {
			ClearRedo();

			// If the history of UndoTransactions only contains object manipulations and
			// no base image, then we don't need the history at all. The documentObjects
			// hierarchy contains all the necessary state.
			var fClearUndo:Boolean = baseImageFileId == null;
			if (fClearUndo) {
				for each (var imgut:ImageUndoTransaction in _autHistory) {
					// Skip UndoTransactions that only manipulate objects. documentObject's state is
					// already the result of these.
					if (!imgut.objectOperationsOnly) {
						fClearUndo = false;
						break;
					}
				}
				if (fClearUndo)
					ClearUndo();
			}

			assets = GetOptimizedAssetMap();
			return undoDepth == 0 && redoDepth == 0;
		}
		
		//
		// High-level helpers for users of ImageDocuments
		//
		
		//
		// Public properties
		//
	
		[Bindable (event="bitmapDataChange")]
		public function get composite(): BitmapData {
			if (_fCompositeInvalid)
				ValidateComposite();
			return _bmdComposite;
		}
		
		[Bindable (event="bitmapDataChange")]
		public function get original(): BitmapData {
			return _bmdOriginal;
		}

		private function ClearOriginal(): void {
			if (_fDisposeOriginal && _bmdOriginal != null)
				VBitmapData.SafeDispose(_bmdOriginal);
			_bmdOriginal = null;
			_fDisposeOriginal = false;
		}
		
		// Collage & Fancy Collage set the original to a clone of the post-"Done"
		// background to lay the foundation for before/after viewing.		
		public function SetOriginalToBackgroundClone(): void {
			ClearOriginal();
			_bmdOriginal = _bmdBackground.clone();
			_fDisposeOriginal = true;
		}
		
		public function SetOriginalToBackground(): void {
			ClearOriginal();
			_bmdOriginal = _bmdBackground;
		}
		
		// We are apply an effect
		// This means leaving interactive mode. We will take control
		// of the background bitmap and clear the cache.
		private function TakeReferences(): void {
			if (_bmdrComposite != null) {
				_bmdrComposite.MakeExternal();
				_bmdrComposite = null;
			}
			
			if (_bmdrInteractiveBackground != null) {
				_bmdrInteractiveBackground.MakeExternal();
				_bmdrInteractiveBackground = null;
			}
		}
		
		// Clear the composite. If it is a reference, dispose the reference.
		private function clearComposite(): void {
			_bmdComposite = null;
			if (_bmdrComposite) {
				_bmdrComposite.dispose();
				_bmdrComposite = null;
			}
		}
		
		// Set the composite to our background
		// Handle references appropriately
		private function setCompositeToBackground(): void {
			clearComposite();
			if (_bmdrInteractiveBackground) {
				_bmdrComposite = _bmdrInteractiveBackground.copyRef("imgd.composite");
			}
			_bmdComposite = _bmdBackground;
		}
		
		// Set the composite to our background
		// Handle references appropriately.
		// The composite will NOT end up a reference.
		private function setCompositeToBackgroundClone(): void {
			clearComposite();
			_bmdComposite = _bmdBackground.clone();
		}
		
		public function set interactiveBackground(bmdr:BitmapReference): void {
			var bmdrPrev:BitmapReference = _bmdrInteractiveBackground;
			if (bmdr == null) {
				_bmdrInteractiveBackground = null;
			} else {
				_bmdrInteractiveBackground = bmdr.copyRef("imgd.interactive background");
				_fInteractiveSet = true;
				background = _bmdrInteractiveBackground._bmd;
				_fInteractiveSet = false;
			}
			if (bmdrPrev != null)
				bmdrPrev.dispose();
		}
		
		public function get background(): BitmapData {
			return _bmdBackground;
		}

		// For use by ImageOperations only. Sets _bmdBackground
		public function set background(bmd:BitmapData): void {
			var bmdrPrev:BitmapReference = null;
			if (!_fInteractiveSet) {
				bmdrPrev = _bmdrInteractiveBackground;
				if (bmdrPrev != null) {
					bmdrPrev = bmdrPrev.copyRef("set background temp");
					interactiveBackground = null;
				}
			}
				
			Debug.Assert(bmd is BitmapData, "Invalid BitmapData", bmd);
			bmd.width; // Catch an invalid background sooner than later
			
			// Some users of ImageDocument.background try to keep memory usage
			// down by disposing of the prior background bitmap after replacing
			// it. Unbeknownst to them the background bitmap may still be in use
			// as the composite (optimization when there are no DocumentObjects).
			// It is bad to dispose the in-use composite so here we preemptively
			// force a new composite to be created if the background and composite
			// bitmaps are the same.
			if (_bmdBackground == _bmdComposite && !_fSuspendValidation) {
				_bmdBackground = bmd;
				ValidateComposite();
			} else {
				_bmdBackground = bmd;
				InvalidateComposite();
			}
			ValidateBitmaps();
			if (bmdrPrev != null)
				bmdrPrev.dispose();
		}
		
		public function get backgroundColor(): uint {
			return _coBackground;
		}
		
		public function get width():Number {
			if (!ValidateCompositeAndHandleMemoryError())
				return 0;
			return _bmdComposite.width;
		}
		
		public function get height():Number {
			if (!ValidateCompositeAndHandleMemoryError())
				return 0;
			return _bmdComposite.height;
		}
	
		public function get dimensions():Point {
			if (!ValidateCompositeAndHandleMemoryError())
				return undefined;
			return new Point(_bmdComposite.width, _bmdComposite.height);
		}
		
		private function ValidateCompositeAndHandleMemoryError(): Boolean {
			if (_fCompositeInvalid)
				ValidateComposite();
				
			// check for validity, just in case.
			var vbmdComposite:VBitmapData = _bmdComposite as VBitmapData;
			if (!_bmdComposite || (vbmdComposite && !vbmdComposite.valid)) {
				OnMemoryError();
				return false;
			}
			return true;
		}
		
		[Bindable]
		public function get id():String {
			return _strId;
		}
		
		public function set id(strId:String): void {
			Debug.Assert(strId != null && strId != "undefined" && strId != "", "strId must be defined (not " + strId + ")");
			Debug.Assert(strId.length <= ImageDocument.kcchFileNameMax, "strId is too long (" + strId.length +
					" chars, limit is " + ImageDocument.kcchFileNameMax + " chars)");
			_strId = strId;
		}
		
		/* DWM: Not used anymore?
		public function get baseName(): String {
			return _strTempBaseImageName ? _strTempBaseImageName : "user/" + _strId;
		}
		
		public function set baseName(strBaseName:String): void {
			_imgp.fCanLoadDirect = false;
		}
		*/
		
		// UNDONE: when ImageProperties is fully supplanted by ItemInfo, this accessor/mutator
		// should be renamed appropriately, and likely promoted up to GenericDocument.
		[Bindable]
		public function get properties(): ImageProperties {
			return _imgp;
		}

		public function set properties(imgp:ImageProperties): void {
			var oldItemInfo:ItemInfo = ItemInfo.FromImageProperties(_imgp);
			_imgp = imgp;
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "itemInfo", oldItemInfo, ItemInfo.FromImageProperties(imgp)));				
		}

		// Returns null if document has no base image
		public function get baseImageFileId(): String {
			if (_daiBaseImage == -1)
				return null;
			return _dctAssets[_daiBaseImage];
		}
		
		public function set baseImageFileId(fid:String): void {
			if (_daiBaseImage == -1)
				_daiBaseImage = AddAsset(fid);
			else
				_dctAssets[_daiBaseImage] = fid;
			baseStatus = DocumentStatus.Loaded;
			UpdateChildStatus();
		}
		
		public function get baseImageAssetIndex(): int {
			return _daiBaseImage;
		}
		
		public function get documentObjects(): DocumentObjectContainer {
			return _dobc;
		}
		
		public function get rasterizedObjects(): DocumentObjectContainer {
			return _dobcRasterized;
		}
		
		//
		// DisplayObjectContainer-ish methods
		//
		
		public function get numChildren(): Number {
			return _dobc.numChildren;
		}
		
		public function addChild(child:DisplayObject): DisplayObject {
			return _dobc.addChild(child);
		}
		
		public function addChildAt(child:DisplayObject, index:int): DisplayObject {
			return _dobc.addChildAt(child, index);
		}
		
		public function removeChild(child:DisplayObject): DisplayObject {
			var dob:DisplayObject = _dobc.removeChild(child);
			if (dob is IDocumentObject)
				IDocumentObject(dob).Dispose();
			return dob;
		}
		
		public function removeChildAt(index:int): DisplayObject {
			var dob:DisplayObject = _dobc.removeChildAt(index);
			if (dob is IDocumentObject)
				IDocumentObject(dob).Dispose();
			return dob;
		}
		
		public function setChildIndex(child:DisplayObject, index:int): void {
			_dobc.setChildIndex(child, index);
		}
		
		public function getChildIndex(child:DisplayObject): Number {
			return _dobc.getChildIndex(child);
		}
		
		public function getChildByName(strName:String): DisplayObject {
			if (strName == _dobc.name) return _dobc;
			return _dobc.getChildByName(strName);
		}
		
		public function getChildAt(index:int): DisplayObject {
			return _dobc.getChildAt(index);
		}
		
		public function swapChildren(child1:DisplayObject, child2:DisplayObject): void {
			_dobc.swapChildren(child1, child2);
		}
		
		public function swapChildrenAt(index1:int, index2:int): void {
			_dobc.swapChildrenAt(index1, index2);
		}
		
		public function contains(child:DisplayObject): Boolean {
			return _dobc.contains(child);
		}
		
		public function AddChildHelper(dob:DisplayObject): void {
			if (dob is IDocumentObject)
				IDocumentObject(dob).document = this;
			dob.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnDocoPropertyChange);
			InvalidateComposite();
			UpdateChildStatus();
			dispatchEvent(new ChildExistenceChangedEvent(
					ChildExistenceChangedEvent.CHILD_ADD, false, false, dob));
		}
		
		public function RemoveChildHelper(dob:DisplayObject): void {
			dob.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnDocoPropertyChange);
			RemoveFromSelection(dob);
			InvalidateComposite();
			UpdateChildStatus();
			dispatchEvent(new ChildExistenceChangedEvent(
					ChildExistenceChangedEvent.CHILD_REMOVE, false, false, dob));
		}
		
		private function UpdateChildStatus(): void {
			var nStatus:Number = DocumentStatus.Loaded;
			for (var i:Number = 0; i < _dobc.numChildren; i++) {
				var doco:IDocumentObject = _dobc.getChildAt(i) as IDocumentObject;
				if (doco) nStatus = DocumentStatus.Aggregate(nStatus, doco.status);
			}
			childStatus = nStatus;
			
			// Count a background image that isn't finished uploading as an unloaded child
			baseImageLoading = _daiBaseImage != -1 && _dctAssets[_daiBaseImage] == kfidAwaitingBackgroundUpload;
			numChildrenLoading = _dobc.numElementsLoading + (baseImageLoading ? 1 : 0);
		}
		
		private function OnDocoPropertyChange(evt:PropertyChangeEvent): void {
			if (evt.property == "status")
				UpdateChildStatus();
			InvalidateComposite();
		}
		
		// Returns the number of descendants not errored or loaded (preview or loading)
		// calls fnLoaded(nChildrenLoading:Number): void {} whenever a child loads
		public function WaitForChildrenToLoad(fnOnChildLoaded:Function): Number {
			_afnOnChildLoaded.push(fnOnChildLoaded);
			DoChildLoadedCallbacks();
			return numChildrenLoading;
		}
		
		private function DoChildLoadedCallbacks(): void {
			var fnOnChildLoaded:Function;
			if (numChildrenLoading == 0) {
				while (_afnOnChildLoaded.length > 0) {
					fnOnChildLoaded = _afnOnChildLoaded.pop(); // Remove them before we call them - in case they trigger a callback
					fnOnChildLoaded(numChildrenLoading);
				}
			} else {
				for each (fnOnChildLoaded in _afnOnChildLoaded) {
					fnOnChildLoaded(numChildrenLoading);
				}
			}
		}
		
		//
		// All about DocumentObjects
		//
		
		public function GetObjectsUnderPoint(ptTest:Point, fPixelTest:Boolean=false): Array {
			/* UNDONE: don't know why but this doesn't work for some shapes (e.g. heart, all the summer shapes)
					   but does work for others (e.g. all procedural shapes, ribbon, bow)
			var pt:Point = new Point(Math.round(ptTest.x), Math.round(ptTest.y));
			var adob:Array = _dobc.getObjectsUnderPoint(pt);
			trace(adob.length + ", " + _dobc.areInaccessibleObjectsUnderPoint(pt));

			var adobHit:Array = [];
			for each (var dob:DisplayObject in adob) {
				// We only want to return DocumentObjects at the point, not whatever DisplayObject
				// children they might be comprised of.
				while (!(dob is IDocumentObject) && dob != null)
					dob = dob.parent;
				if (dob == null)
					continue;

				// Objects normally ordered in draw order, bottom to top. For hit testing
				// top to bottom order is appropriate.
				if (fPixelTest) {				
					if (dob.hitTestPoint(pt.x, pt.y, true))
						adobHit.unshift(dob);
				} else {
					adobHit.unshift(dob);
				}
			}
			return adobHit;
			*/

			// UNDONE: doesn't deal with nested DocumentObjects
			var pt:Point = new Point(Math.round(ptTest.x), Math.round(ptTest.y));
			var adob:Array = new Array();
			for (var i:Number = 0; i < _dobc.numChildren; i++) {
				var dob:DisplayObject = _dobc.getChildAt(i);
				if (!Util.IsVisible(dob))
					continue;
				if (dob.hitTestPoint(pt.x, pt.y, fPixelTest))
					adob.unshift(dob);
			}
			return adob;
		}
		
		private var _adobSelected:Array = null;
		
		// Always return an array so callers don't have to if (!= null && length != 0), etc
		public function get selectedItems(): Array {
			return _adobSelected ? _adobSelected.slice() : []; // make a copy (don't trust caller)
		}
		
		public function set selectedItems(adobSelected:Array): void {
			// Make copies (don't trust caller)
			var adobOld:Array = _adobSelected ? _adobSelected.slice() : null;
			var adobNew:Array = adobSelected ? adobSelected.slice() : null;
			_adobSelected = adobNew;
			if (adobOld == null && adobNew == null)
				return;
			dispatchEvent(new ImageDocumentEvent(ImageDocumentEvent.SELECTED_ITEMS_CHANGE, adobOld, adobNew));
		}
		
		private function RemoveFromSelection(dob:DisplayObject): void {
			if (_adobSelected == null)
				return;
			var i:Number = _adobSelected.indexOf(dob);
			if (i == -1)
				return;
			
			var adobOld:Array = _adobSelected.slice();
			_adobSelected.splice(i, 1);
			var adobNew:Array = _adobSelected.slice();
			dispatchEvent(new ImageDocumentEvent(ImageDocumentEvent.SELECTED_ITEMS_CHANGE, adobOld, adobNew));
		}
		
		public function get isCollage():Boolean {
			for (var i:int = 0; i < _dobc.numChildren; i++) {
				if (_dobc.getChildAt(i) is PhotoGrid) {
					return true;
				}
			}
			return false;
		}		
		
		public function get isFancyCollage():Boolean {
			for (var i:int = 0; i < _dobc.numChildren; i++) {
				var pg:PhotoGrid = _dobc.getChildAt(i) as PhotoGrid;
				if (pg && pg.template != null && StringUtil.beginsWith(pg.template, "fid:")) {
					return true;
				}
			}
			return false;
		}		
		
		public function CreateDocumentObject(strType:String, dctProperties:Object=null): IDocumentObject {
			var doco:IDocumentObject = InstantiateDocumentObject(strType);
			doco.document = this;
			if (dctProperties) {
				for (var strProp:String in dctProperties) {
					// The parent property is the string id of a DisplayObject. Because CreateDocumentObject
					// is not meant to actually add the DocumentObject to the ImageDocument it must leave
					// the handling of the parent property to its callers.
					if (strProp == "parent" || strProp == "zIndex")
						continue;
					doco[strProp] = dctProperties[strProp];
				}
			}
			return doco;
		}
		
		private static function InstantiateDocumentObject(strType:String): IDocumentObject {
			// Create DocumentObject instances by looking up their class
			// ("documentObjects." + ob name) dynamically
			var strClassName:String = "imagine.documentObjects." + strType;
			var clsDocumentObject:Class;
			try {
				clsDocumentObject = getDefinitionByName(strClassName) as Class;
			} catch (err:ReferenceError) {
				Debug.Assert(false, "Unknown DocumentObject " + strType);
				return null;
			}
			return new clsDocumentObject();
		}

		public function DeserializeDocumentObjects(dobc:DisplayObjectContainer, xmlObs:XML, iIndex:int=0): Boolean {
			return _DeserializeDocumentObjects(_dobc, dobc, xmlObs, iIndex);
		}

		public static function DeserializeDocumentObjects2(dobc:DisplayObjectContainer, xmlObs:XML, iIndex:int=0): Boolean {
			return _DeserializeDocumentObjects(dobc, dobc, xmlObs, iIndex);
		}
		
		private static function _DeserializeDocumentObjects(dobcAncestor:DisplayObjectContainer, dobc:DisplayObjectContainer, xmlObs:XML, iIndex:int=0): Boolean {
			// This sucks but we have to reference each DocumentObject class to force
			// it to be compiled in to the FlashRenderer. Doing so kind of defeats
			// the clever dynamic class lookup below because we still have to
			// remember to add any new DocumentObjects to this list.
			var ob1:Text, ob2:Clipart, ob3:Circle, ob4:Square, ob5:Star, ob6:Burst, ob7:Polygon;
			var ob8:RoundedRectangle, ob9:RoundedSquare, ob10:Ellipse, ob11:PRectangle, ob12:Glyph;
			var ob13:PSWFLoader, ob14:Photo, ob15:PhotoGrid, ob16:Target, ob17:FrameObject, ob18:FrameClipart;
			var ob19:GalleryThumb, ob20:SpiderWeb, ob21:StretchAndSqueezeDocumentObject, ob22:EmbeddedBitmap;
			
			for each (var xmlOb:XML in xmlObs.children()) {
				// DestroyObjectOperation reuses DeserializeDocumentObjects for Undo.
				// Objects it deserializes may be attached to a non-root parent.
				var dobcParent:DisplayObjectContainer = dobc;
				if (xmlOb.hasOwnProperty("@parent"))
					dobcParent = dobcAncestor.getChildByName(xmlOb.@parent) as DisplayObjectContainer;

				var doco:IDocumentObject = InstantiateDocumentObject(xmlOb.localName());
				if (doco == null)
					return false;
				var dob:DisplayObject = doco as DisplayObject;
				dobcParent.addChildAt(dob, iIndex++); // addChild now so any getChildByName calls will work
					
				// Recursively deserialize child DocumentObjects, if any
				var xmlChildObjects:XML = xmlOb.Objects[0];
				if (xmlChildObjects != null)
					_DeserializeDocumentObjects(dobcAncestor, dob as DisplayObjectContainer, xmlChildObjects);
					
				// Finish initialization of parent object. Do this AFTER children have been
				// instantiated so the parent can reference them, e.g. for masking.
				// UNDONE: uh, but what if the children want to reference their parent? [we don't have this case yet]
				
				// DocumentObjects can override the default deserialization if they want.
				if ("Deserialize" in dob)
					dob["Deserialize"](xmlOb);
				else
					Util.ObFromXmlProperties(xmlOb, dob);
			}
			return true;
		}
		
		// DEPRECATED: use DeserializeDocumentObjects instead because it can handle arbitrarily
		// deeply nested child DocumentObjects. XMLToDocumentObject is retained only to support
		// compatibility with older stored documents.
		public static function XMLToDocumentObject(xmlOb:XML, imgd:ImageDocument=null): IDocumentObject {
			var dob:IDocumentObject = InstantiateDocumentObject(xmlOb.localName());
			dob.document = imgd;
			Util.ObFromXmlProperties(xmlOb, dob);
			return dob;
		}
		
		public static function DocumentObjectToXML(doco:IDocumentObject, fDiscardInvisibleChildren:Boolean=false): XML {
			// Serialize the requested object
			var xml:XML = Util.XmlPropertiesFromOb(doco, GetDocumentObjectType(doco), doco.serializableProperties);
			var dobc:DisplayObjectContainer = doco as DisplayObjectContainer;
			if (dobc == null)
				return xml;
			
			// Serialize child DocumentObjects
			var xmlChildren:XML = <Objects/>;
			for (var i:int = 0; i < dobc.numChildren; i++) {
				// All child DisplayObjects are not necessarily DocumentObjects
				var docoChild:IDocumentObject = dobc.getChildAt(i) as IDocumentObject;
				if (docoChild == null)
					continue;
					
				// HACK: Not all child DocumentObjects are meant to be serialized
				// CONSIDER: add Serialize/Deserialize methods to IDocumentObject such
				// that they can overide serialization of certain child objects.
				if (DisplayObject(docoChild).name == "$cropMask")
					continue;
					
				// HACK: don't serialize invisible objects. They're temporary and
				// might contain asset references.
				if (fDiscardInvisibleChildren)
					if (!DisplayObject(docoChild).visible)
						continue;
					
				var xmlChild:XML = DocumentObjectToXML(docoChild, fDiscardInvisibleChildren);
				xmlChildren.appendChild(xmlChild);
			}
			if (xmlChildren.length() > 0)
				xml.appendChild(xmlChildren);
			
			return xml;
		}
		
		public static function GetDocumentObjectType(doco:IDocumentObject): String {
			var strClassName:String = getQualifiedClassName(doco);
			return strClassName.slice(strClassName.lastIndexOf(":") + 1);
		}
		
		/*
		 * Analyze the document to see what features have been used. Report them as a
		 * maskable string: (s|m|l|x)EeTdSFPtprACcXf12345678. Feature legend (index, feature):
		0	s-mall (<=800)
			m-edium (801-1600)
			l-arge (1601-2800)
			x-large (>2800)
		1	E-dit				-- Everything on the Edit tab
		2	e-ffects			-- All creative effects (excludes Text, Stickers, Frames)
		3	T-ext
		4	d-evice Text 		-- Text using a device font
		5	S-tickers
		6	F-rames
		7	P-hotos layered
		8	t-ouch Up			-- Effects under the Touchup sub-tab and other places they show up
		9	p-ixel Bender
		10	r-Texture
		11	A-dvanced Effects	-- The Advanced subset of effects
		12	C-ollage
		13	c-Fancy Collage
		14	X-Seasonal			-- Effects under the Seasonal sub-tab and seasonal Featured effects
		15	f-Combine Everything (flatten)
		16	1-Autofix
		17	2-Rotate
		18	3-Crop
		19	4-Resize
		20	5-Exposure
		21	6-Colors
		22	7-Sharpen
		23	8-Red-eye
		*/
		public function GetFeatureUsageString(): String {
			var dctFeatureFlags:Object = {
				"AutoFix": "1E", "Rotate": "2E", "Crop": "3E", "Resize": "4E", "Exposure": "5E",
				"Color": "6E", "Sharpen": "7E", "Pet-eye Removal": "8E", "Red-eye Removal": "8E",
				"Flatten": "f", "Create Text": "T", "Create Clipart": "S",
				"Create Photo": "P", "Flatten Collage": "C"
			}
				
			var dctUsage:Object = {};
			for (var iut:int = 0; iut < _iutHistoryTop; iut++) {
				var imgut:ImageUndoTransaction = _autHistory[iut];
				if (imgut.strName in dctFeatureFlags) {
					var astrFlags:Array = dctFeatureFlags[imgut.strName].split("");
					for each (var strFlag:String in astrFlags)
						dctUsage[strFlag] = true;
				}
				
				/* Two more UndoTransactions we could track if we care to.
				// Result of automatic resizing of too-big-for-good-performance images.
				"Auto Resize"
			
				// Result of automatic post-load resizing & rotating.
				"Post load:*" -- note the dynamic specifics past the ':'
				*/
				
				if (imgut.strName == "Create Text") {
					try {
						var coop:CreateObjectOperation = imgut.aop[0] as CreateObjectOperation;
						if (coop) {
							if (coop.props.font.isDevice)
								dctUsage["d"] = true;
						}
					} catch (err:Error) {}
					
				} else if (imgut.strName == "Change Font") {
					try {
						var spop:SetPropertiesObjectOperation = imgut.aop[0] as SetPropertiesObjectOperation;
						if (spop) {
							if (spop.props.font.isDevice)
								dctUsage["d"] = true;
						}
					} catch (err:Error) {}
					
				} else if (imgut.strName.indexOf("ShaderEffect") == 0) {
					dctUsage["p"] = true;
					
				} else {
					var i:int = imgut.strName.indexOf(":");
					if (i != -1) {
						var strTags:String = imgut.strName.slice(i + 1);
						var astrTags:Array = strTags.split(",");
						for each (var strTag:String in astrTags) {
							if (strTag == "effect")
								dctUsage["e"] = true;
							else if (strTag == "seasonal")
								dctUsage["X"] = true;
							else if (strTag == "frame")
								dctUsage["F"] = true;
							else if (strTag == "touchup")
								dctUsage["t"] = true;
							else if (strTag == "advanced")
								dctUsage["A"] = true;
							else if (strTag == "texture")
								dctUsage["r"] = true;
						}
					}
				}
			}
			
			// small, medium, large, x-large
			var strUsage:String = "x";
			if (width <= 800 && height <= 800)
				strUsage = "s";
			else if (width <= 1600 && height <= 1600)
				strUsage = "m";
			else if (width <= 2800 && height <= 2800)
				strUsage = "l";
			
			// Turn the usage dict into a string.
			// NOTE: New flags must be added to the end so existing queries aren't disturbed.
			var strReference:String = "EeTdSFPtprACcXf12345678";
			var astrFeatures:Array = strReference.split("");
			for each (var strFeature:String in astrFeatures)
			strUsage += (strFeature in dctUsage) ? strFeature : "0";
			
			return strUsage;
		}
		
		//
		// Undo/redo related functions and tracking state
		//
	
		private var _cUndoTransactionNests:Number = 0;
		private var _imgut:ImageUndoTransaction;

		// For DebugConsoleBase and TestImageDocument's use ONLY		
		public function GetHistoryInfo(): Object {
			return {
				_autHistory: _autHistory,
				_iutHistoryTop: _iutHistoryTop,
				_cUndoTransactionNests: _cUndoTransactionNests,
				_ut: _imgut	
			}
		}
		
		public function get condensedEdits(): String {
			var astrEdits:Array = [];
			for (var iut:Number = 0; iut < _iutHistoryTop - 1; iut++) {
				var imgut:ImageUndoTransaction = _autHistory[iut];
				astrEdits.push(imgut.strName);
			}
			return astrEdits.join(", ");
		}
		
		// If fCacheInUse is true
		// - the current background is presumed to be in a cache and must not be disposed by
		//   RollbackUndoTransaction
		// - CommitUndoTransaction must remove the background from the cache so it isn't freed
		//   when the cache is cleared
		// Otherwise
		// - RollbackUndoTransaction will dispose of the background it replaces with the undo background
		// - CommitUndoTransaction leaves the background alone
		// fRetainBackground is set to true by callers that plan to perform a background-
		// changing Operation(s).
		//
		// Memory usage:
		// BeginUndoTransaction does not create any new BitmapDatas but if fCopyBackground is
		// true it will assign a reference to the current background to the UndoTransaction's
		// bmd member. If so, EndUndoTransaction will dispose of it.
		public function BeginUndoTransaction(strName:String, fCacheInUse:Boolean=false,
				fRetainBackground:Boolean=true, fLog:Boolean=true): void {
//			trace("BeginUndoTransaction(\"" + strName + "\", fCacheInUse=" + fCacheInUse + ", fRetainBackground=" + fRetainBackground + ", fLog=" + fLog + "), cUndoTransactionNests=" + _cUndoTransactionNests);
			if (_cUndoTransactionNests == 0) {
				if (fRetainBackground)
					FreeUndoBitmaps();
				
				_imgut = new ImageUndoTransaction(fRetainBackground ? _bmdBackground: null, _fDirty,
						strName, null, fLog, fCacheInUse);
			}
			_cUndoTransactionNests++;
		}
		
		// Free the undo bitmaps retained by all UndoTransactions except the first and last ones.
		private function FreeUndoBitmaps( fAll:Boolean = false ): void {
			var bmdFirst:BitmapData = null;
			for (var iut:Number = 0; iut < _iutHistoryTop - 1 && !fAll; iut++) {
				if (_autHistory[iut].bmdBackground != null) {
					bmdFirst = _autHistory[iut].bmdBackground;
					break;
				}
			}
			
			var bmdLast:BitmapData = null;
			for (iut = _iutHistoryTop - 1; iut >= 0 && !fAll; iut--) {
				if (_autHistory[iut].bmdBackground != null) {
					bmdLast = _autHistory[iut].bmdBackground;
					break;
				}
			}
			
			for (iut = 0; iut < _iutHistoryTop; iut++) {
				var bmd:BitmapData = _autHistory[iut].bmdBackground;
				if (bmd != null && bmd != bmdFirst && bmd != bmdLast) {
					var bmdDispose:BitmapData = _autHistory[iut].bmdBackground;
					_autHistory[iut].bmdBackground = null;
					VBitmapData.SafeDispose(bmdDispose);
				}
			}
		}
		
		public function EndUndoTransaction(fCommit:Boolean=true, fClearCache:Boolean=false): void {
//			trace("EndUndoTransaction(" + (_imgut ? '"' + _imgut.strName + '"' : "null") + ", fCommit=" + fCommit + ", fClearCache=" + fClearCache + "), cUndoTransactionNests=" + _cUndoTransactionNests);
			
			// It's OK to try to end when no transaction is in progress, makes things simpler for callers
			if (_imgut == null)
				return;
				
			_cUndoTransactionNests--;
			Debug.Assert(_cUndoTransactionNests >= 0, "EndUndoTransaction _cUndoTransactionNests underflow");
			if (_cUndoTransactionNests == 0) {
				if (fCommit)
					CommitUndoTransaction(); // Always clears cache
				else
					RollbackUndoTransaction(fClearCache);
			}
		}

		// Commit the change to the undo history (clears out redo history)
		private function CommitUndoTransaction(): void {
			if (_imgut.fLog) {
				var strNiceName:String = _imgut.strName.replace(/[0-9]*/g, "");
				PicnikService.Log("Client doing " + strNiceName);
			}
			
			// Uncache the background BitmapData so it won't be lost when the cache is cleared
			if (_imgut.fCacheInUse) {
				BitmapCache.Remove(_bmdBackground);
				BitmapCache.Clear();
			}
			
			Debug.Assert(_cUndoTransactionNests == 0, "Can only commit top-level UndoTransactions");
			TakeReferences();
			AddToHistory(_imgut);
			isDirty = true;
			
			_imgut = null;
		}
			
		public function AbortUndoTransaction(): void {
			// It's OK to try to end when no transaction is in progress, makes things simpler for callers
			if (_imgut == null)
				return;
				
			_cUndoTransactionNests--;
			_imgut = null;
			
			// AbortUndoTransaction is called in response to imgd.Do failures that are most likely
			// caused by out of memory exceptions. Clear the cache to improve the situation but
			// don't accidentally dispose the background or composite.
			BitmapCache.Remove(_bmdBackground);
			BitmapCache.Remove(_bmdComposite);
			BitmapCache.Clear();
		}
		
		private var _fSuspendValidation:Boolean = false;
		
		// Rollback the change without affecting the undo/redo history
		private function RollbackUndoTransaction(fClearCache:Boolean): void {
			Debug.Assert(_cUndoTransactionNests == 0, "Can only rollback top-level UndoTransactions");
			
			// If the cache is in use (i.e. we're in the middle of an interactive do/undo/do
			// loop) don't Validate at undo time because we don't want to regenerate the
			// composite and update the view when the subsequent Do will do so.
			_fSuspendValidation = !fClearCache;
			_Undo(_imgut);
			_fSuspendValidation = false;
			
			_imgut = null;
			if (fClearCache)
				BitmapCache.Clear();
		}
		
		public function RecordImageOperation(op:ImageOperation): void {
			// Implicitly, any image operation invalidates the composite
			InvalidateComposite();
			
			if (_imgut) {
				_imgut.aop.push(SerializationUtil.DeepCopy(op));
			}
			isDirty = true;
		}
		
		public function IsInCache(bmd:BitmapData): Boolean {
			if (BitmapCache.Contains(bmd))
				return true;
			if (_bmdrInteractiveBackground != null && _bmdrInteractiveBackground._bmd == bmd)
				return true;
			if (_bmdrComposite != null && _bmdrComposite._bmd == bmd)
				return true;
			return false;
		}
	
		// Undo a standalone transaction (no impact on the undo/redo history)
		protected override function _Undo(ut:UndoTransaction): void {
			// Undo the operations in the reverse order from how they were Do'ed.
			// This phase of Undo is for ObjectOperations, no changes are made to the
			// background bitmap which will be restored below.
			var imgut:ImageUndoTransaction = ut as ImageUndoTransaction;
			for (var iop:Number = imgut.aop.length - 1; iop >= 0; iop--) {
				var op:ImageOperation = imgut.aop[iop];
				op.Undo(this);
			}
			
			// If there are any ImageOperations we have to produce a new background bitmap
			if (!imgut.objectOperationsOnly) {
				var imgutKeyframe:ImageUndoTransaction = null;
			
				// If we find a bitmap at the top of the undo stack (not counting ObjectOperations)
				// we can replace the background with it without making a clone.
				var fClone:Boolean = false;
				
				// Maybe this UndoTransaction has saved the old background bitmap
				if (imgut.bmdBackground) {
					// Yay!
					imgutKeyframe = imgut;
				} else {
					// Nope, scan backwards from the top of the undo history for an UndoTransaction
					// that has a BitmapData we can restore
					for (var iut:Number = _iutHistoryTop - 1; iut >= 0; --iut) {
						var imgutT:ImageUndoTransaction = _autHistory[iut];
						if (imgutT.bmdBackground != null) {
							// Found one, cool
							imgutKeyframe = imgutT;
							break;
						}
						
						// We're going to have to build up the restored background bitmap
						// by playing back ImageOperations. That'll mean cloning the one we
						// find so it can be reused for future undos
						if (!imgutT.objectOperationsOnly)
							fClone = true;
					}
				}

				if (imgutKeyframe) {
					// Restore the BitmapData and then scan forward playing back every transaction
					// between it and where we want to be.
					var bmdBackgroundOld:BitmapData = _bmdBackground;
					var fRefCounted:Boolean = _bmdrInteractiveBackground != null;
					if (fClone) {
						background = imgutKeyframe.bmdBackground.clone();
					} else {
						background = imgutKeyframe.bmdBackground;
						imgutKeyframe.bmdBackground = null;
					}
					
					// Leave it to whoever is caching to dispose of the old background
					if ((!imgut.fCacheInUse || !IsInCache(bmdBackgroundOld)) && !fRefCounted)
					{
						if (_fCompositeInvalid)
							_abmdOldBackgrounds.push(bmdBackgroundOld);
						else if (bmdBackgroundOld != _bmdComposite)
							VBitmapData.SafeDispose(bmdBackgroundOld);
					}
					
					for (; iut < _iutHistoryTop - 1; iut++) {
						var imgutDelta:ImageUndoTransaction = _autHistory[iut];
						FilteredDoOperations(imgutDelta, true, false); // ImageOperations yes, ObjectOperations no
					}
				} else {
					// Whoa. None of the UndoTransactions has a background image attached. This can only
					// mean that the document started 'blank' with a solid background created automatically.
					try {
						background = VBitmapData.Construct(_cxOriginal, _cyOriginal, true, _coBackground, "undo solid bkgnd");
					} catch (e:InvalidBitmapError) {	
						OnMemoryError(e);
					}
				}
			}
			isDirty = true;

			// Dispose of bitmaps hanging off the transaction
			if (imgut.bmdBackground && imgut.bmdBackground != background && imgut.bmdBackground != _bmdComposite) {
				var bmdDispose:BitmapData = imgut.bmdBackground;
				imgut.bmdBackground = null;
				VBitmapData.SafeDispose(bmdDispose);
			}
		}
		
		private function FilteredDoOperations(imgut:ImageUndoTransaction, fImage:Boolean, fObject:Boolean): void {
			for (var iop:Number = 0; iop < imgut.aop.length; iop++) {
				var op:ImageOperation = imgut.aop[iop];
				if (op is ObjectOperation) {
					if (fObject)
						op.Do(this, true, false);
				} else if (fImage) {
					// Callers of Operation.Do() are responsible for disposing the old background
					var bmdDispose:BitmapData = _bmdBackground;
					op.Do(this, fObject, false);
					if (_bmdBackground != bmdDispose) {
						BitmapCache.Remove(_bmdBackground);
						VBitmapData.SafeDispose(bmdDispose);
					}
					BitmapCache.Clear();
				}
			}
		}
		
		protected override function _Redo(ut:UndoTransaction): void {
			var imgut:ImageUndoTransaction = ut as ImageUndoTransaction;
			// Don't mess with the background bitmap if this is an object-only transaction
			var fImageOp:Boolean = !imgut.objectOperationsOnly;
			if (fImageOp) {
				imgut.bmdBackground = _bmdBackground;
				imgut.fCacheInUse = false; // Make sure Undo will free the background after replacing it
			}
			
			for (var iop:Number = 0; iop < imgut.aop.length; iop++) {
				var op:ImageOperation = imgut.aop[iop];
				var bmdDispose:BitmapData = _bmdBackground;
				
				// Do the operation with fUseCache == true so all intermediary bitmaps can be
				// disposed with a ClearCache() call.
				// Pass false for fDoObjects if this is an ImageOperation. Any ObjectOperations
				// it produced will already be in the UndoTransaction and played back (albeit in
				// a slightly different order (ObjectOp then the ImageOp that produced it)).
				var fDoObjects:Boolean = op is ObjectOperation ||
						(op is NestedImageOperation && ImageUndoTransaction.ArrayContainsObjectOp((op as NestedImageOperation).children));
				op.Do(this, fDoObjects, false);
				
				if (bmdDispose != _bmdBackground && bmdDispose != imgut.bmdBackground)
					VBitmapData.SafeDispose(bmdDispose);
				BitmapCache.Remove(_bmdBackground);
				BitmapCache.Clear();
				background = _bmdBackground;
			}

			// Don't mess with the undo bitmaps if this is an object-only transaction
			if (fImageOp)
				FreeUndoBitmaps();
		}		
		
		public function get topUndoTransaction(): ImageUndoTransaction {
			if (_iutHistoryTop == 0)
				return null;
			return _autHistory[_iutHistoryTop - 1];
		}

		public function get undoTransactionPending(): Boolean {
			return _imgut != null;
		}

		public function get pendingUndoTransaction(): ImageUndoTransaction {
			return _imgut;
		}
		
		private function _ValidateBitmapdataUnused(bmd:BitmapData): void {
			if (bmd == null) return;
			if (bmd == _bmdBackground)
				throw new InvalidBitmapError( InvalidBitmapError.ERROR_IS_BACKGROUND );			
			if (bmd == _bmdComposite)
				throw new InvalidBitmapError( InvalidBitmapError.ERROR_IS_COMPOSITE );			
			
			// History
			for each (var imgutT:ImageUndoTransaction in _autHistory) {
				if (bmd == imgutT.bmdBackground)
					throw new InvalidBitmapError( InvalidBitmapError.ERROR_IS_KEYFRAME );			
			}
		}
		
		// to avoid dependencies on PicnikBase, we do this weird object workaround
		public static function get activeDocument(): ImageDocument {
			var obApp:Object = Object(Application.application);
			
			// When unit tests are run there is no Application.application.activeDocument
			if (!("activeDocument" in obApp))
				return null;
			
			return obApp.activeDocument as ImageDocument;
		}
		
		public static function ValidateBitmapdataUnused(bmd:BitmapData): void {
			var imgd:ImageDocument = activeDocument;
			if (imgd)
				imgd._ValidateBitmapdataUnused(bmd);
		}
		
		private function _IsComposite(bmd:BitmapData): Boolean {
			if (bmd == _bmdComposite)
				return true;			
			return false;			
		}
		
		public static function IsComposite(bmd:BitmapData): Boolean {
			var imgd:ImageDocument = activeDocument;
			if (imgd)
				return imgd._IsComposite(bmd);
			return false;
		}
				
		private function _IsBackground(bmd:BitmapData): Boolean {
			if (bmd == _bmdBackground)
				return true;			
			return false;			
		}
		
		public static function IsBackground(bmd:BitmapData): Boolean {
			var imgd:ImageDocument = activeDocument;
			if (imgd)
				return imgd._IsBackground(bmd);
			return false;
		}
		
		private function ValidateBitmaps(): void {
			if (_bmdBackground) _bmdBackground.width;
			if (_bmdComposite) _bmdComposite.width;
		}

		public function OnMemoryError( e:Error = null ):void {
			// to avoid dependencies on PicnikBase, we do this weird object workaround
			var obApp:Object = Object(Application.application);
			if ("OnMemoryError" in obApp) {
				obApp.OnMemoryError(e);
			} else if (e) {
				PicnikService.Log("Exception: MemoryError " + e + ", " + e.getStackTrace(), PicnikService.knLogSeverityError);				
			}
		}
		
		public function set lastSaveInfo( imgp:ImageProperties ): void {
			_imgpLastSaveInfo = new ImageProperties();	
			imgp.CopyTo(_imgpLastSaveInfo);			
		}
		
		public function get lastSaveInfo(): ImageProperties {
			return _imgpLastSaveInfo;
		}

		public override function GetDocumentThumbnail(): UIComponent {
			var imgv:ImageView = new ImageView();
			imgv.imageDocument = this;
			//			imgv.percentWidth = 100;
			//			imgv.percentHeight = 100;
			return imgv;
		}
	}
}
