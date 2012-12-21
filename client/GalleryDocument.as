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
	
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceError;
	
	import com.adobe.serialization.json.JSONDecoder;
	import com.adobe.serialization.json.JSONEncoder;
	
	import dialogs.DialogManager;
	import dialogs.EasyDialogBase;
	
	import imagine.documentObjects.*;
	
	import errors.*;
	
	import events.*;
	
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import imagine.imageOperations.*;
	
	import interfaces.slide.*;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Image;
	import mx.controls.SWFLoader;
	import mx.core.UIComponent;
	import mx.resources.ResourceBundle;
	
	import imagine.objectOperations.*;
	
	import util.GalleryItem;
	import util.StateSaveManager;
	import util.collection.ArrayCollectionPlus;
	
	public class GalleryDocument extends GenericDocument implements IDocumentStatus {
		
		// common errors shared across imagedocument and gallery document
		public static const errNone:Number = 0;
		public static const errPikDownloadFailed:Number = 1;
		public static const errPikUploadFailed:Number = 2;
		public static const errBaseImageDownloadFailed:Number = 3;
		public static const errBaseImageUploadFailed:Number = 4;
		public static const errOutOfMemory:Number = 5;
		public static const errChildObjectFailedToLoad:Number = 6;
		public static const errInitFailed:Number = 7;
		public static const errDocumentError:Number = 8;
		
		// gallery-specific errors
		public static const errDisabled:Number = 9000;
		public static const kcchFileNameMax:Number = 128;
		
  		[Bindable] [ResourceBundle("GalleryDocument")] protected var _rb:ResourceBundle;
  		
  		[Bindable] public var _acItems:ArrayCollection;
  		[Bindable] public var _acDeadItems:ArrayCollection; // including deleted ones
  		[Bindable] public var _dProps:Object = new ItemInfo({});

  		// Serialized document state
		private var _info:Object = null;
		
		private var _fPublished:Boolean = false;
		private var _fOwner:Boolean = false;
		private var _fPremiumStyle:Boolean = false;
		
		private var _fnProgress:Function;
		private var _fnDone:Function;
		private var _fOverwrite:Boolean;
		private var _fnRestoreProgress:Function;
		private var _fnRestoreDone:Function;		

		private var _ldrSlideshow:SWFLoader;
		private var _nSlideshowSWFRetries:Number = 0;
		private var _slideshowSWF:ISlideShowLoader = null;
		private var _afnOnSlideshowLoaded:Array = null;
		private var _autChangeLog:Array = null;
		private var _strCurrentUserId:String = null;
		private var _nStatus:Number = DocumentStatus.Loaded;
		private var _nNumChildrenLoading:Number = 0; // True when all descendants have loaded or error states
		private var _afnOnChildLoaded:Array = [];
		private var _aobMultiMoves:Array = null;

		private static var s_fShownNewVersionDialog:Boolean = false;

		override public function get type(): String {
			return "gallery";
		}

		public function GalleryDocument() {
			info = new ItemInfo({
				owner: AccountMgr.GetInstance().GetUserId(),				
				access: GenericDocument.kAccessFull
			});

			// bypass undo/changelog logic
			SetProperty( "name", Resource.getString("GalleryDocument", "NewShowDefaultName"), false, false );
			// UNDONE: for most controls, initial values are not set, which will make the undo logic
			// fall down for the first change -- the initial value is not set, just implied, so when
			// you undo the first property change, the value will be null.  Added the transition delay
			// here to quicly fix a pressing bug, but it needs to be solved For Real.  We could set all
			// initial values here, but consider that GalleryDocument can't know about all properties
			// for all possible presentation types. 
			SetProperty( "nDelay", "3.5", false, false );
			SetProperty( "strTransType", "all", false, false );
			
			_strCurrentUserId = AccountMgr.GetInstance().GetUserId();
			
			CreateEmptyItemList();
			CreateEmptyChangeLog();
			
			// populate with basic fields
			SetProperties( {
					fShowCaptions: "false",
					ownerid: AccountMgr.GetInstance().GetUserId(),
					ownername: AccountMgr.GetInstance().displayName },
				{}, false, true );
			isInitialized = false;							
			isDirty = false;
			isOwner = true;
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
			

		private function CreateEmptyItemList(): void {
			items = new ArrayCollectionPlus();
		}
		
		private function CreateEmptyChangeLog(): void {
			_autChangeLog = new Array();
			deadItems = new ArrayCollection();
		}
		
		override public function OnUserChange(): void {
			var strOldUserId:String = _strCurrentUserId;
			_strCurrentUserId = AccountMgr.GetInstance().GetUserId();
			
			if (null != strOldUserId && _strCurrentUserId != strOldUserId) {
				ReloadGalleryInfo( function( err:Number ): void {				
						// move items that belonged to the old user over to the new user.
						MigrateItems(strOldUserId,AccountMgr.GetInstance().GetUserId(),AccountMgr.GetInstance().displayName);
	
						// Reset UI mode so that tabs get displayed properly
						PicnikBase.app.uimode = PicnikBase.kuimGallery; 		
					} );
			} else {
				// user might have upgraded from guest to registered, in which case their name changed
				SetProperties( {
						ownername: AccountMgr.GetInstance().displayName },
					{}, false, true );
				
			}	
		}
		
		//
		// Public properties
		//
		[Bindable]
		public function get info():Object{
			return _info;
		}
		
		public function set info(obInfo:Object): void {
			if (obInfo as ItemInfo == null)
				trace("GalleryDocument.info is not ItemInfo!");
			_info = obInfo;
		}
	
		[Bindable]
		public function get isPublished():Boolean {
			return _fPublished;
		}
		
		public function set isPublished(fPub:Boolean): void {
			_fPublished = fPub;
		}	
		
		[Bindable]
		public function get isOwner():Boolean {
			return _fOwner;
		}
		
		public function set isOwner(fOwner:Boolean): void {
			_fOwner = fOwner;
		}
		
		[Bindable]
		public function get isPremiumStyle():Boolean {
			return GetProperty("premiumStyle") == "1";
		}
		
		public function set isPremiumStyle(fPremium:Boolean): void {
			SetProperty("premiumStyle", fPremium ? "1" : "0");
		}
		
		[Bindable]
		public function get id():String {
			return _info.id;
		}
		
		public function set id(strId:String): void {
			_info.id = strId;
		}
		
		[Bindable]
		public function get name():String {
			return GetProperty("name") as String;
		}
		
		public function set name(strName:String): void {
			SetProperty( "name", strName, false );
		}
								
		[Bindable]
		public override function get isPublic():Boolean {
			return (GetProperty("public") != "0");
		}
		
		public override function set isPublic(fPublic:Boolean): void {
			SetProperty("public", fPublic ? "1" : "0", false);
		}		
		
		public function get props():Object {
			return _dProps;
		}
		
		[Bindable]
		public function get items():ArrayCollection {
			return _acItems;
		}
		
		public function set items( ac:ArrayCollection ): void {
			var item:GalleryItem;
			for each (item in _acItems) {
				item.removeEventListener( Event.CHANGE, OnItemLoaded );
			}
			_acItems = ac;
			for each (item in _acItems) {
				item.addEventListener( Event.CHANGE, OnItemLoaded );
			}
		}		

		[Bindable]
		public function get deadItems():ArrayCollection {
			return _acDeadItems;
		}
		
		public function set deadItems( ac:ArrayCollection ): void {
			_acDeadItems = ac;
		}
		
		// this looks at all items, including those in the dead pool.  Useful to undo transactions and stuff
		public function GetItemById( strId:String ):GalleryItem {
			var item:GalleryItem;
			for each (item in items) {
				if (item.id == strId)
					return item;
			}
			for each (item in deadItems) {
				if (item.id == strId)
					return item;
			}
			return null;
		}
		
		override public function GetState(): Object {
			var obState:Object = super.GetState();
			var obAMF:Object = SerializeAMF();
			if (obAMF != null)
				obState.obAMF = obAMF;
				
			obState.strName = name;
			obState.strId = id;
			obState.strItemInfo = infosave(_info);
			obState.fPublished = isPublished;
			obState.iutHistoryTop = _iutHistoryTop;
			obState.fOwner = isOwner;
			obState.props = _dProps;

			return obState;
		}
		
		// fnProgress(nPercentDone:Number, strStatus:String)
		override public function RestoreStateAsync(sto:Object, fnProgress:Function, fnDone:Function): void {
			var fnMyInit:Function = function( err:Number, strErr:String ): void {
					var nErr:Number = GalleryDocument.errNone;
					if (sto.obAMF) {
						nErr = DeserializeAMF(sto.obAMF);
					} else if (sto.strXml) {
						var xml:XML = new XML(sto.strXml);
						nErr = Deserialize(xml);
					}
					if (nErr == GalleryDocument.errNone) {
						isDirty = _autChangeLog.length > 0;
						if (sto.strId)
							id = sto.strId;
						if (sto.strName)
							name = sto.strName;
						if (sto.fPublished)
							isPublished = sto.fPublished;
						if (sto.fOwner)
							isOwner = sto.fOwner;
						if (sto.strItemInfo)
							info = new ItemInfo(infoload(sto.strItemInfo));

						GetSlideshowSWF( function( ldrSlideshow:SWFLoader, issl:ISlideShowLoader ):void {
							if (null == issl) return;	//handle failure from GetSlideshowSWF
							if ('id' in info && info.id && 'secret' in info && info.secret) {
								var fid:String = info.id + "_" + info.secret;
								issl.SetSlideShowId(fid);
							}
						
							if (sto.props) {
								for (var o:Object in sto.props)
									SetProperty(o as String, sto.props[o], false, false);
							}
							if (sto.iutHistoryTop)
								_iutHistoryTop = sto.iutHistoryTop;
								
							RestoreState_OnDone( nErr, "" );
						} );
					} else {
						RestoreState_OnDone( nErr, "" );
					}
				}
				
			_fnRestoreProgress = fnProgress;
			_fnRestoreDone = fnDone;
				
			super.RestoreStateAsync( sto, fnProgress, fnMyInit );
				
		}
			
		protected function RestoreState_OnProgress(nPercentDone:Number, strStatus:String): void {
			_fnRestoreProgress(nPercentDone, strStatus);
		}
		
		protected function RestoreState_OnDone(err:Number, strError:String): void {
			_fnRestoreDone(err, strError);
		}

		override public function Dispose(): void {
			super.Dispose();
			if (_ldrSlideshow != null) {
				_ldrSlideshow.unloadAndStop();
				_ldrSlideshow = null;
			}
			if (_slideshowSWF != null) {
				_slideshowSWF.UnloadSlideShow();
				_slideshowSWF = null;
			}
			_nSlideshowSWFRetries = 0;
			
			var item:GalleryItem;
			for each (item in _acItems) {
				item.removeEventListener( Event.CHANGE, OnItemLoaded );
			}
			_acItems.removeAll();
			_acDeadItems.removeAll();
			
		}
		
		/**
		* @method 		InitFromPicnikFile
		* @description 	xxx
		* @usage		InitFromPicnikFile is an async operation so the caller passes in functions to
		* be notified of progress and completion.
		* @param		itemInfo		Describes the object to load
		* @param		fnProgress		Callback parameters are nPercentDone:Number, strStatus:String
		* @param		fnDone			Callback parameters are err:Number, strError:String
		* @return		false if anything goes wrong
		**/
		public function InitFromPicnikFile(itemInfo:ItemInfo, fnProgress:Function=null, fnDone:Function=null): Boolean {
			
			if (!PicnikConfig.galleryUpdate) {
				fnDone(GalleryDocument.errDisabled, "PicnikConfig.galleryUpdate says galleries are disabled");				
				return false;									
			}
			
			_fnProgress = fnProgress;
			_fnDone = fnDone;
			
			var fid:String = itemInfo.id + "_" + itemInfo.secret;
			
			if (_fnProgress != null)
				_fnProgress(0, Resource.getString("GalleryDocument", "Loading_Picnik_file"));
				
			var urlr:URLRequest = new URLRequest(PicnikService.GetFileURL(fid, null, null, null, false, true));
			var urll:URLLoader = new URLLoader();
			var docThis:GalleryDocument = this;
			
			var fnRemoveListeners:Function = function(): void {
				urll.removeEventListener(IOErrorEvent.IO_ERROR, fnOnLoadIOError);
				urll.removeEventListener(Event.COMPLETE, fnOnLoadComplete);
				urll.removeEventListener(ProgressEvent.PROGRESS, fnOnLoadProgress);				
			}
			
			var fnOnLoadIOError:Function = function (evt:IOErrorEvent): void {
					// UNDONE: retrying
					fnRemoveListeners();
					if (fnDone != null)
						fnDone(GalleryDocument.errPikDownloadFailed, "Failed to load");
				}
			
			var fnOnLoadProgress:Function = function (evt:ProgressEvent): void {
					if (_fnProgress != null)
						_fnProgress((evt.bytesLoaded / evt.bytesTotal) * 5, Resource.getString("GalleryDocument", "Loading_Picnik_file"));
				}
			
			var fnOnLoadComplete:Function = function (evt:Event): void {
					fnRemoveListeners();
					if (_fnProgress != null)
						_fnProgress(5, Resource.getString("GalleryDocument", "Picnik_file_loaded"));
						
					GetSlideshowSWF( function( ldrSlideshow:SWFLoader, issl:ISlideShowLoader ):void {
							if (issl) {
								issl.SetSlideShowId( fid );
								issl.LoadSlideShowFromData(urll.data);

								// generate a list of all the gallery items
								var imglist:IImageList = issl.imagelist;
								var items:Array = [];
								for (var i:int = 0; i < imglist.ImageCount; i++) {
									var iimg:IImage = imglist.GetImageInfo(i);
									items.push(GalleryItem.CreateFromImage(docThis, iimg));
								}
								
								// also grab all the slideshow's properties and set them on ourselves
								var oProps:Object = issl.GetProperties();
								for (var k2:String in oProps) {
									SetProperty(k2, oProps[k2], false);
								}
								
								// inserting the items into the gallery doc will cause them to be inserted
								// back into the slideshow swf, so delete them all from the SWF then insert into the doc.
								// UNDONE: do we need to check for maximum # of images allowed?
								issl.imagelist.DeleteAllImages();
								for each ( var item2:GalleryItem in items ) {
									InsertImage(item2, -1, false);
								}
								
								isPublished = true;
								isOwner = ( itemInfo.ownerid == AccountMgr.GetInstance().GetUserId() );
								isDirty = false;
								id = itemInfo.id;
								isPublic = GetProperty("public") == "1";
								
								// init the info	
								info = itemInfo;

								OnInitFromPicnikFile(itemInfo);
								
								if (fnDone != null)
									fnDone(GalleryDocument.errNone);
							} else {
								if (fnDone != null)
									fnDone(GalleryDocument.errInitFailed, "Failed to load");
							}
						} );		
				}
			
			urll.addEventListener(IOErrorEvent.IO_ERROR, fnOnLoadIOError);
			urll.addEventListener(Event.COMPLETE, fnOnLoadComplete);
			urll.addEventListener(ProgressEvent.PROGRESS, fnOnLoadProgress);
			
			urll.load(urlr);
			return true;
		}
		
		private function ReloadGalleryInfo(fnDone:Function=null): void {
//			if (info.serviceid != "Show") {
//				fnDone(GalleryDocument.errNone);
//				return;
//			}
			if (!isPublished) {
				SetProperties( {
						ownerid: AccountMgr.GetInstance().GetUserId(),
						ownername: AccountMgr.GetInstance().displayName },
					{}, false, true );
				fnDone(GalleryDocument.errNone);
				return;			
			}
						
			var fnOnGetInfo:Function = function( err:Number, strErr:String, dctInfo:Object ): void {
				if (err != StorageServiceError.None) {
					fnDone(GalleryDocument.errInitFailed);
					return;
				}
				
				isOwner = ( dctInfo.ownerid == AccountMgr.GetInstance().GetUserId() );
				info = dctInfo;
				
				fnDone(GalleryDocument.errNone);
				
			}
			
			var ss:IStorageService = AccountMgr.GetStorageService("Show");
			ss.GetSetInfo( info.id, fnOnGetInfo, null );
		}		
				
		private function MigrateItems(strFromUserId:String, strToUserId:String, strToUserName:String): void {
			// if a user was working on a gallery as a guest, and then signs in, we need to migrate
			// the items they've added over to the new ownerid/ownername
			var item:GalleryItem;
			for each ( item in items ) {
				if (item.ownerid == strFromUserId) {
					SetImageProperties( item.id, {ownerid:strToUserId, ownername:strToUserName}, false );
				}
			}
			for each ( item in deadItems ) {
				if (item.ownerid == strFromUserId) {
					SetImageProperties( item.id, {ownerid:strToUserId, ownername:strToUserName}, false );
				}
			}
		}
		
		public function OnInitFromPicnikFile( itemInfo:ItemInfo ): void {
			CreateEmptyChangeLog();
		}		
				
		public function Deserialize(xml:XML):Number {
			return _InitFromXml(xml);
		}
		
		public function DeserializeAMF(ob:Object):Number {
			return _InitFromAMF(ob);
		}
		
		// 2 cases we _InitFromXml:
		// - restoring an ImageDocument from the local SharedObject
		// - loading a History document
		private function _InitFromXml(xml:XML): Number {
			try {
				CreateEmptyItemList();
				CreateEmptyChangeLog();

				var gut:GalleryUndoTransaction = null;
				var xmlItem:XML;
				var item:GalleryItem;
				for each (xmlItem in xml.Items.item) {
					item = GalleryItem.fromXml( this, xmlItem );
					InsertImage( item, -1, false, false );
				}
				for each (xmlItem in xml.DeadItems.item) {
					item = GalleryItem.fromXml( this, xmlItem );
					_acDeadItems.addItem(item);
				}
				
				for each (var xmlUndo:XML in xml.Undo.gut) {
					gut = GalleryUndoTransaction.fromXml( this, xmlUndo );
					_autHistory.push(gut);
				}
								
				for each (var xmlLog:XML in xml.ChangeLog.gut) {
					gut = GalleryUndoTransaction.fromXml( this, xmlLog );
					_autChangeLog.push(gut);
				}

				for each (xmlItem in xml.Items.item) {
					if (!item.valid) {
						DeleteImage( item.id, false, true );
					}
				}

			} catch (e:Error) {
				trace("_InitFromXml exception: " + e.message);
				return GalleryDocument.errInitFailed;
			}
			return GalleryDocument.errNone;
		}

		private function _InitFromAMF(obDoc:Object): Number {
			try {
				CreateEmptyItemList();
				CreateEmptyChangeLog();

				var gut:GalleryUndoTransaction = null;
				var obItem:Object;
				var item:GalleryItem;
				for each (obItem in obDoc.aobItems) {
					item = GalleryItem.fromAMF( this, obItem );
					InsertImage( item, -1, false, false );
				}
				for each (obItem in obDoc.aobDeadItems) {
					item = GalleryItem.fromAMF( this, obItem );
					_acDeadItems.addItem(item);
				}
				
				for each (var obUndo:Object in obDoc.aobUndo) {
					gut = GalleryUndoTransaction.fromAMF( this, obUndo );
					_autHistory.push(gut);
				}
								
				for each (var obLog:Object in obDoc.aobLog) {
					gut = GalleryUndoTransaction.fromAMF( this, obLog );
					_autChangeLog.push(gut);
				}

				for each (obItem in obDoc.aobItems) {
					if (!item.valid) {
						DeleteImage( item.id, false, true );
					}
				}

			} catch (e:Error) {
				trace("_InitFromXml exception: " + e.message);
				return GalleryDocument.errInitFailed;
			}
			return GalleryDocument.errNone;
		}

		public function Serialize(): XML {
			var gut:GalleryUndoTransaction;
			var item:GalleryItem;
			var xmlItems:XML = <Items/>;
			for each ( item in items ) {
				xmlItems.appendChild(item.toXml());
			}
			var xmlDeadItems:XML = <DeadItems/>;
			for each ( item in deadItems ) {
				xmlDeadItems.appendChild(item.toXml());
			}
			var xmlLog:XML = <ChangeLog/>
			for each ( gut in _autChangeLog ) {
				xmlLog.appendChild( gut.toXml() );
			}			
			var xmlUndo:XML = <Undo/>
			for each ( gut in _autHistory ) {
				xmlUndo.appendChild( gut.toXml() );
			}			
			var xml:XML = <GalleryDocument/>
			xml.appendChild(xmlItems);
			xml.appendChild(xmlDeadItems);
			xml.appendChild(xmlLog);
			xml.appendChild(xmlUndo);
			return xml;
		}		
		
		public function SerializeAMF(): Object {
			var gut:GalleryUndoTransaction;
			var item:GalleryItem;
			var aobItems:Array = [];
			for each ( item in items ) {
				aobItems.push(item.toAMF());
			}
			var aobDeadItems:Array = [];
			for each ( item in deadItems ) {
				aobDeadItems.push(item.toAMF());
			}
			var aobLog:Array = [];
			for each ( gut in _autChangeLog ) {
				aobLog.push( gut.toAMF() );
			}
			var aobUndo:Array = [];
			for each ( gut in _autHistory ) {
				aobUndo.push( gut.toAMF() );
			}			
			var obDoc:Object = {};
			obDoc.aobItems = aobItems;
			obDoc.aobDeadItems = aobDeadItems
			obDoc.aobLog = aobLog;
			obDoc.aobUndo = aobUndo;
			return obDoc;
		}
		
		private function OnItemLoaded( evt:Event ):void {
			var item:GalleryItem = evt.target as GalleryItem;
			if (item) {
				var pos:int = items.getItemIndex(item);
				if (pos >= 0) {
					var gut:GalleryUndoTransaction = new GalleryUndoTransaction( GalleryUndoTransaction.SET_IMAGE_PROPERTIES,
						isDirty, item, item.id, -1, -1, null, item.GetProperties(), null );
					dispatchEvent( new GalleryDocumentEvent( GalleryDocumentEvent.CHANGE, gut) );
					
					var issl:ISlideShowLoader = GetSlideshowSWF();
        			if (issl) {
        				var obProps:Object = item.GetProperties();
        				for ( var k:String in obProps ) {
        					issl.imagelist.SetProperty( item.id, k, obProps[k] );
        				}
		        	}
		  		}
		  		UpdateStatus();
			}			
		}	
			
		private function UpdateStatus(): void {
			var nStatus:Number = DocumentStatus.Loaded;
			var nLoading:Number = 0;
			if (items != null) {
				for (var i:Number = 0; i < items.length; i++) {
					var itm:GalleryItem = items.getItemAt(i) as GalleryItem;
					if (itm) {
						if (itm.status != DocumentStatus.Error && itm.status <= DocumentStatus.Preview) {
							nLoading++;
						}
						nStatus = DocumentStatus.Aggregate(nStatus, itm.status);	
					}
				}
			}
			status = nStatus;			
			numChildrenLoading = nLoading;
		}
		
		[Bindable]
		public function set numChildrenLoading(nNumChildrenLoading:Number): void {
			if (_nNumChildrenLoading == nNumChildrenLoading) return;
			_nNumChildrenLoading = nNumChildrenLoading;
			PicnikBase.app.callLater( DoChildLoadedCallbacks );
		}
		
		public function get numChildrenLoading(): Number {
			return _nNumChildrenLoading;
		}
				
		// Returns the number of descendants not errored or loaded (preview or loading)
		// calls fnLoaded(nChildrenLoading:Number): void {} whenever a child loads
		public function WaitForChildrenToLoad(fnOnChildLoaded:Function): Number {
			_afnOnChildLoaded.push(fnOnChildLoaded);
			UpdateStatus();
			PicnikBase.app.callLater( DoChildLoadedCallbacks );
			return items.length;
		}
						
		// Returns the number of descendants not errored or loaded (preview or loading)
		// stop calls to fnLoaded(nChildrenLoading:Number): void {} whenever a child loads
		public function StopWaitForChildrenToLoad(fnOnChildLoaded:Function): Number {
			if (_afnOnChildLoaded.indexOf(fnOnChildLoaded) >= 0) {
				_afnOnChildLoaded.splice( _afnOnChildLoaded.indexOf(fnOnChildLoaded), 1 );
			}
			return items.length;
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
					
		public function IndexToId( pos:int ):String {
			if (pos < 0 || pos >= items.length)
				return null;
			return (items[pos] as GalleryItem).id;
		}		
		
		public function IdToIndex( id:String ):int {
			for (var i:int = 0; i < items.length; i++) {
				if ((items.getItemAt(i) as GalleryItem).id == id)
					return i;
			}
			return -1;
		}		
		
		/////////////////////////////////////////////
		// Gallery document manipulation functions
		//
		public function InsertImage(item:GalleryItem, pos:int=-1, fUndo:Boolean=true, fChangeLog:Boolean=true): int {
			Debug.Assert(!inMultiMoveMode);
			var gut:GalleryUndoTransaction = new GalleryUndoTransaction(GalleryUndoTransaction.INSERT_IMAGE, isDirty, item, item.id, pos);			
			Apply(gut, fUndo, fChangeLog);
			return pos;
		}
		
		// If the top two undo transactions are an insert at the bottom followed
		// by an immediate move, merge them into a single operation 
		public function MergeInsertAndMove(): void {
			if (_autHistory.length != _iutHistoryTop) {
				trace("MergeInsertAndMove: conflicting redo history");
			} else if (_autHistory.length < 2) {
				trace("MergeInsertAndMove: not enough items");
			} else {
				var gutInsert:GalleryUndoTransaction = _autHistory[_iutHistoryTop-2] as GalleryUndoTransaction;
				var gutMove:GalleryUndoTransaction = _autHistory[_iutHistoryTop-1] as GalleryUndoTransaction;
				
				if (gutInsert != null && gutInsert.strName == "InsertImage" && gutMove != null && gutMove.strName == "MoveImage" && gutInsert.pos == -1) {
					_autHistory.pop();
					_iutHistoryTop--;
					gutInsert.pos = gutMove.pos;
				} else {
					trace("MergeInsertAndMove: incorrect item types");
				}
			}
		}

		public function InsertImages(items:ArrayCollection, pos:int=-1, fUndo:Boolean=true, fChangeLog:Boolean=true): int {
			Debug.Assert(!inMultiMoveMode);
			var gut:GalleryUndoTransaction = new GalleryUndoTransaction(GalleryUndoTransaction.INSERT_IMAGES, isDirty, null, null, pos, -1, null, null, null, items);			
			Apply(gut, fUndo, fChangeLog);
			return pos;
		}

		public function DeleteImage(id:String, fUndo:Boolean=true, fChangeLog:Boolean=true): Boolean {
			Debug.Assert(!inMultiMoveMode);
			var pos:int = IdToIndex(id);
			if (pos < 0 || pos >= items.length)
				return false;
			var item:GalleryItem = items.getItemAt(pos) as GalleryItem;
			var gut:GalleryUndoTransaction = new GalleryUndoTransaction(GalleryUndoTransaction.DELETE_IMAGE, isDirty, item, id, -1, pos);
			Apply(gut, fUndo, fChangeLog);						
			return true;
		}

		public function DeleteAllImages(fUndo:Boolean=true, fChangeLog:Boolean=true): void {
			Debug.Assert(!inMultiMoveMode);
			var gut:GalleryUndoTransaction = new GalleryUndoTransaction(GalleryUndoTransaction.DELETE_ALL_IMAGES, isDirty, null, null, -1, -1, null, null, null, items);
			Apply(gut, fUndo, fChangeLog);						
		}
		
		public function SetImageProperty(id:String, key:String, val:Object, fUndo:Boolean=true, fChangeLog:Boolean=true):Object {
			var pos:int = IdToIndex(id);
			if (pos < 0 || pos >= items.length)
				return null;
			if (key == null || val == null)
				return null;
			var item:GalleryItem = items.getItemAt(pos) as GalleryItem;
			var old:Object = item[key];			
			var gut:GalleryUndoTransaction = new GalleryUndoTransaction(GalleryUndoTransaction.SET_IMAGE_PROPERTY, isDirty, null, id, -1, -1, key, val, old);
			Apply(gut, fUndo, fChangeLog);							
			return old;
		}

		public function SetImageProperties(id:String, vals:Object, fUndo:Boolean=true, fChangeLog:Boolean=true):Object {
			var pos:int = IdToIndex(id);
			if (pos < 0 || pos >= items.length)
				return null;
			if (vals == null)
				return null;
			var item:GalleryItem = items.getItemAt(pos) as GalleryItem;
			var old:Object = item.GetProperties();			
			var gut:GalleryUndoTransaction = new GalleryUndoTransaction(GalleryUndoTransaction.SET_IMAGE_PROPERTIES, isDirty, item, id, -1, -1, null, vals, old);
			Apply(gut, fUndo, fChangeLog);							
			return old;
		}		
		
		public function GetImageProperty(id:String, key:String):Object {
			var pos:int = IdToIndex(id);
			if (pos < 0 || pos >= items.length)
				return null;
			if (key == null)
				return null;
			var item:GalleryItem = items.getItemAt(pos) as GalleryItem;
			return item[key];
		}

		public function SetProperty(key:String, val:Object, fUndo:Boolean=true, fChangeLog:Boolean=true): Object {
			if (key == null || val == null)
				return null;
			var old:Object = props[key];
			var gut:GalleryUndoTransaction = new GalleryUndoTransaction(GalleryUndoTransaction.SET_PROPERTY, isDirty, null, null, -1, -1, key, val, old);						
			Apply(gut, fUndo, fChangeLog);							
			return old;
		}		

		public function Refresh(): void
		{
			var issl:ISlideShowLoader = GetSlideshowSWF();
			if (issl)
				issl.imagelist.dispatchEvent(new SlideShowEvent(SlideShowEvent.REFRESH));
		}


		// set multiple properties at once.  If we've been fiddling with controls, we've likely already
		// changed the state of the live preview before hitting the apply button, so we have the option of
		// letting the gallery style control pass in it's previously collected set of old values.
		public function SetProperties(values:Object, oldValues:Object=null, fUndo:Boolean=true, fChangeLog:Boolean=true): Object {
			// should also check for non-dictionary types
			if (values == null)		
				return null;

			if (oldValues == null) {				
				oldValues = {};
				for (var k:String in values) {
					if (props[k] != undefined)
						oldValues[k] = props[k];
				}
			}
			var gut:GalleryUndoTransaction = new GalleryUndoTransaction(
						GalleryUndoTransaction.SET_PROPERTIES, isDirty, null, null, -1, -1, null, values, oldValues);
			Apply(gut, fUndo, fChangeLog);
			return oldValues;
		}

		public function GetProperty(key:String):Object {
			if (key == null)
				return null;
			return props[key];
		}
		
		public function BeginMultiMove(): void {
			Debug.Assert(!inMultiMoveMode);
			_aobMultiMoves = [];
		}
		
		private function InternalMoveImage(posFrom:int, posTo:int): void {
			if (items is ArrayCollectionPlus) {
				(items as ArrayCollectionPlus).moveItem(posFrom, posTo);
			} else {
				var obItem:Object = items.removeItemAt(posFrom);
				items.addItemAt(obItem, posTo);
			}
		}
		
		public function MultiMoveImage(posFrom:int, posTo:int): void {
			Debug.Assert(inMultiMoveMode);
			InternalMoveImage(posFrom, posTo);
			// Combine multiple sequential moves of the same object.
			// Undone: Handle more complicated but combineable moves (e.g. move-multiple objects at once)
			if ((_aobMultiMoves.length > 0) && (_aobMultiMoves[_aobMultiMoves.length-1].posTo == posFrom)) {
				_aobMultiMoves[_aobMultiMoves.length-1].posTo = posTo;
			} else {
				_aobMultiMoves.push({posFrom:posFrom, posTo:posTo});
			}
		}
		
		private function get inMultiMoveMode(): Boolean {
			return _aobMultiMoves != null;
		}
		
		public function CommitMultiMove(fUndo:Boolean=true, fChangeLog:Boolean=true): Boolean {
			Debug.Assert(inMultiMoveMode);
			// First, undo our moves
			var i:Number;
			for (i = _aobMultiMoves.length-1; i >= 0; i--)
				InternalMoveImage(_aobMultiMoves[i].posTo, _aobMultiMoves[i].posFrom);
			
			// Next, commit each move
			var fChanged:Boolean = false;
			for (i = 0; i < _aobMultiMoves.length; i++)
				if (_MoveImage(_aobMultiMoves[i].posFrom, _aobMultiMoves[i].posTo, fUndo, fChangeLog))
					fChanged = true;
			
			_aobMultiMoves = null; // We are out of multi-move mode.  
			return fChanged;
		}
	
		public function MoveImage(id:String, posTo:int, fUndo:Boolean=true, fChangeLog:Boolean=true):Boolean {
			Debug.Assert(!inMultiMoveMode);
			return _MoveImage(IdToIndex(id), posTo, fUndo, fChangeLog);
		}

		private function _MoveImage(posFrom:int, posTo:int, fUndo:Boolean, fChangeLog:Boolean):Boolean {
			var id:String = IndexToId(posFrom);
			if (posFrom < 0 || posTo < 0 || posFrom >= items.length || posTo >= items.length)
				return false;
				
			if (posFrom == posTo)
				return true;

			var gut:GalleryUndoTransaction = new GalleryUndoTransaction(GalleryUndoTransaction.MOVE_IMAGE, isDirty, null, id, posTo, posFrom );
			Apply(gut, fUndo, fChangeLog);
			return true;
		}

		public function get imageCount():Number {
			return items.length;
		}

		static public function get maxAllowedImageCount(): Number {
			return AccountMgr.GetInstance().isPaid ? 100 : 10;
		}

		protected override function _Undo(ut:UndoTransaction): void {
			var gut:GalleryUndoTransaction = ut as GalleryUndoTransaction;
			Apply( gut.Invert(), false, false );
			ChangeLogUndo( gut );
		}

		protected override function _Redo(ut:UndoTransaction): void {
			var gut:GalleryUndoTransaction = ut as GalleryUndoTransaction;
			Apply(gut, false, false);
			ChangeLogRedo( gut );
		}
		
		public function Apply( gut:GalleryUndoTransaction, fUndo:Boolean=true, fChangeLog:Boolean=true ): void {
			StateSaveManager.SomethingChanged();
			var issl:ISlideShowLoader = GetSlideshowSWF();
			var item:GalleryItem = null;
			var pos:int = -1;
			var k:String = null;

			//trace( new Date().toString() + " GalleryDocument.Apply:" + gut.strName + " " + gut.id + " " + gut.pos);
		
			switch (gut.strName) {
				
				case GalleryUndoTransaction.INSERT_IMAGE:
					if (gut.pos < 0 || gut.pos > items.length) {
						items.addItem(gut.item);
					} else {
						items.addItemAt(gut.item, gut.pos);
					}
					gut.item.addEventListener( Event.CHANGE, OnItemLoaded );
					gut.item.active = true;
					if (issl) issl.imagelist.InsertImage(gut.item.GetProperties(), gut.pos);
					break;

				case GalleryUndoTransaction.SET_IMAGES:
					items.removeAll();
					if (issl) issl.imagelist.DeleteAllImages();
					// fall through
										
				case GalleryUndoTransaction.INSERT_IMAGES:
					for (pos=0; pos<gut.items.length; pos++) {
						item = gut.items[pos];
						items.addItem(item);
						item.addEventListener( Event.CHANGE, OnItemLoaded );
						item.active = true;
						if (issl) issl.imagelist.InsertImage( item.GetProperties(), gut.pos );
					}
					break;
					
				case GalleryUndoTransaction.DELETE_IMAGE:
					pos = IdToIndex(gut.id);
					if (pos < 0)
						break;
					//pos = (gut.pos >= 0) ? gut.pos : items.length-1;
					item = items.removeItemAt(pos) as GalleryItem;
					deadItems.addItem(item);
					item.active = false;
					item.removeEventListener( Event.CHANGE, OnItemLoaded );
					if (issl) issl.imagelist.DeleteImage(gut.id);
					break;

				case GalleryUndoTransaction.DELETE_IMAGES:
					for (pos=0; pos<gut.items.length; pos++) {
						item = gut.items[pos];
						items.removeItemAt(IdToIndex(item.id));
						deadItems.addItem(item);
						item.active = false;
						item.removeEventListener( Event.CHANGE, OnItemLoaded );
						if (issl) issl.imagelist.DeleteImage(item.id);
					}
					break;
					
				case GalleryUndoTransaction.DELETE_ALL_IMAGES:
					for (pos=0; pos<items.length; pos++) {
						item = items[pos];
						deadItems.addItem(item);
						item.active = false;
						item.removeEventListener( Event.CHANGE, OnItemLoaded );
					}
					CreateEmptyItemList();
					if (issl) issl.imagelist.DeleteAllImages();
					break;

				case GalleryUndoTransaction.SET_PROPERTY:
					props[gut.key] = gut.val;
					if (issl) issl.SetProperty(gut.key, (gut.val != null) ? gut.val.toString() : null);
					break;
					
				case GalleryUndoTransaction.SET_PROPERTIES:
					for (k in gut.val) {
						props[k] = gut.val[k];
						if (issl) issl.SetProperty(k, (gut.val[k] != null) ? gut.val[k].toString() : null);
					}
					break;
					
				case GalleryUndoTransaction.SET_IMAGE_PROPERTY:
					pos = IdToIndex(gut.id);
					if (pos < 0 || pos >= items.length)
						break;
					item = items.getItemAt(pos) as GalleryItem;
					item[gut.key] = gut.val;
					items.setItemAt(item, pos);
					if (issl) issl.imagelist.SetProperty(gut.id, gut.key, (gut.val != null) ? gut.val.toString() : null);				
					break;
										
				case GalleryUndoTransaction.SET_IMAGE_PROPERTIES:
					pos = IdToIndex(gut.id);
					if (pos < 0 || pos >= items.length)
						break;
					item = items.getItemAt(pos) as GalleryItem;
					for (k in gut.val) {
						item[k] = gut.val[k];
						if (issl) issl.imagelist.SetProperty(gut.id, k, (gut.val[k] != null) ? gut.val[k].toString() : null);
					} 					
					items.setItemAt(item, pos);
					break;
										
				case GalleryUndoTransaction.MOVE_IMAGE:
					var posFrom:int = IdToIndex(gut.id);					
					if (posFrom == gut.pos)
						break;
					InternalMoveImage(posFrom, gut.pos);
					if (issl) issl.imagelist.MoveImage(gut.id, gut.pos);
					break;

				default:
					trace("unknown transaction type in GalleryDocument.Apply()!");
			}
			UpdateStatus();			
			if (fUndo && isInitialized) AddToHistory(gut);
			if (fChangeLog) _autChangeLog.push( gut );
			dispatchEvent( new GalleryDocumentEvent( GalleryDocumentEvent.CHANGE, gut) );
			if (isInitialized) isDirty = true;
		}
		
		public override function GetDocumentThumbnail(): UIComponent {
			var img:Image = new Image;
			var gtv:GalleryThumbView = new GalleryThumbView();
			gtv.image1 = GetImageProperty(IndexToId(0), 'thumbUrl') as String;
			gtv.image2 = GetImageProperty(IndexToId(1), 'thumbUrl') as String;
			gtv.image3 = GetImageProperty(IndexToId(2), 'thumbUrl') as String;
			
			gtv.LoadImages( function():void {
					img.invalidateProperties();
				} );
			
			img.source = gtv;
							
			return img;
		}		
		
		public  function GetSlideshowSWF( fnOnLoaded:Function = null ): ISlideShowLoader {
			if (_slideshowSWF) {
				if (fnOnLoaded != null)
					fnOnLoaded( _ldrSlideshow, _slideshowSWF );
			} else {
				if (!_afnOnSlideshowLoaded) {
					_afnOnSlideshowLoaded = [fnOnLoaded];
					_loadSlideshowSWF();	
				} else {
					if (fnOnLoaded != null) _afnOnSlideshowLoaded.push( fnOnLoaded );
				}
			}			
			return _slideshowSWF;
		}
		
		private function _loadSlideshowSWF(): void {
			var strUrl:String = "/slide/slide.swf?refer=client.GalleryDocument";
			if (_nSlideshowSWFRetries > 0) {
				strUrl += "&cb=" + new Date().time;
			}
			_ldrSlideshow = new SWFLoader();
			_ldrSlideshow.percentWidth = 100;
			_ldrSlideshow.percentHeight = 100;
			_ldrSlideshow.load(PicnikBase.StaticUrl(strUrl));
			_ldrSlideshow.addEventListener(flash.events.Event.COMPLETE, OnSlideshowLoaded);			
		}
        	
        private function _initSlideshowSWF( issl:ISlideShowLoader ): void {
        	if (!issl) return;
        	
			issl.imagelist.DeleteAllImages();

			for each (var item:GalleryItem in items) {
				var index:int = issl.imagelist.InsertImage( item.GetProperties(), -1 );
			}
			
			for (var o:Object in props) {
				issl.SetProperty(String(o), String(props[o]));
			}
        }	       
       
        private function OnSlideshowLoaded(evt:Event): void {        	
        	try {
        		var b:Boolean = ("getVersionStamp" in evt.target.content && evt.target.content['getVersionStamp']() != PicnikBase.getVersionStamp());
        		b = false;
        		if (b) {
        			_nSlideshowSWFRetries++;
        			if (_nSlideshowSWFRetries == 3) {
        				if (!s_fShownNewVersionDialog) {
							s_fShownNewVersionDialog = true;			
							EasyDialogBase.Show(
								PicnikBase.app,
								[Resource.getString('GalleryDocument', 'sureThing')],
								Resource.getString("GalleryDocument", "newVersionTitle"),						
								Resource.getString("GalleryDocument", "newVersionText"),						
								function( obResult:Object ):void {}
							);		
        				}
        				return;

        			}
        			_loadSlideshowSWF();
        			return;
        		}
	        	_slideshowSWF = evt.target.content as ISlideShowLoader;
	        	_slideshowSWF.SetServerRoot(PicnikService.serverURL);
	        	_slideshowSWF.SetProperty("presentation", "EasySlideShow");
	        	_slideshowSWF.SetImageUrlOverride( OnBuildImageUrl );
	        	_slideshowSWF.SetUserActionOverride( OnSlideShowUserAction );
	        	_slideshowSWF.SetControlVisible("share", false);
	        	_slideshowSWF.SetControlVisible("Button_Captions", false);
	        } catch (e:Error) {
	        	// trap security errors here, in case we're loading cross-domainly
				trace("Unable to init slideshowSWF");
	        	_slideshowSWF = null;
	        }
	       
       		_initSlideshowSWF( _slideshowSWF );
        	
			// call all the callbacks that want to get a pointer to the slideshow
        	if (_afnOnSlideshowLoaded) {
        		for each (var fnOnLoaded:Function in _afnOnSlideshowLoaded) {
        			if (fnOnLoaded != null)
        				fnOnLoaded( _ldrSlideshow, _slideshowSWF );
        		}
        		_afnOnSlideshowLoaded = null;
        	}
        }   
       
        public function GetChangeLog(): Array {
        	return _autChangeLog;
        }
       
        private function OnBuildImageUrl( strUrl:String, iimg:IImage, nMaxWidth:int, nMaxHeight:int ):String {
			var oProps:Object = iimg.oProps;
			if ('ssid' in oProps && oProps['ssid'] != null && oProps['ssid'].length > 0 &&
					(!('ss' in oProps) || oProps['ss'] == 'Picnik')) {
				strUrl = PicnikService.GetResizedFileURL(oProps['ssid'], Math.max(nMaxWidth,nMaxHeight) );
			}
			return strUrl;        	
        }

		// UI somewhere might want to influence if/how these actions are handled. Event
		// handlers can prevent the slideshow's default behavior by calling evt.preventDefault().       
		private function OnSlideShowUserAction(action:SlideShowAction): Boolean {
			// UNDONE: change Slideshow to dispatch this event itself so GalleryDocument doesn't have to get involved
			var evt:Event = new SlideShowUserActionEvent(SlideShowUserActionEvent.USER_ACTION, false, true, action.type);
			dispatchEvent(evt);
			return !evt.isDefaultPrevented();
		}       
       
       	private function ChangeLogUndo( gut:GalleryUndoTransaction ): void {
       		// on undo, we remove the last item from our ChangeLog.
       		// However, if our ChangeLog is empty then convert the undo into a redo
       		// and add it onto our ChangeLog.
       		var nChanges:Number = _autChangeLog.length;
       		if (nChanges > 0 && gut.Matches(_autChangeLog[nChanges-1])) {
   				// we've been asked to undo an operation that is right at the end of our list,
   				// so we can just remove it from our list.
   				_autChangeLog.pop();
       		} else {
       			// we can't just remove the last operation from the list, so invert the operation
       			// and add it onto our list of changes
       			var gutInvert:GalleryUndoTransaction = gut.Invert();
       			_autChangeLog.push( gutInvert );
       		}
       	}
       	
       	private function ChangeLogRedo( gut:GalleryUndoTransaction ): void {
       		// on undo, we should add this item onto our ChangeLog.       		
       		// However, if the opposite of this item is already on the ChangeLog
       		// as our last item, then just remove that item and we're happy.
       		var nChanges:Number = _autChangeLog.length;
       		if (nChanges > 0 && gut.Invert().Matches(_autChangeLog[nChanges-1])) {
   				// we've been asked to redo an operation that was being undone by the most
   				// recent change on our list, so just remove that change.
   				_autChangeLog.pop();
       		} else {
       			// add this op to our list
       			_autChangeLog.push( gut );
       		}
       	}
       	
       	override public function Revert(): void {
       		// go through the changelog and undo everything in it
       		while (_autChangeLog.length > 0) {
       			var gut:GalleryUndoTransaction = _autChangeLog.pop();
       			Apply( gut.Invert(), false, false );
       		}
       		CreateEmptyChangeLog();
       		super.Revert();
       	}

		public function OnSaved( iiResult:ItemInfo ): void {
			if (iiResult) {
				id = iiResult.id;
				info = iiResult;
			}
			isDirty = false;
			isPublished = true;			
       		CreateEmptyChangeLog();
       		CreateEmptyUndoHistory();
		}
		
		////////////////////////////////////////////
		
		// this is a temporary function that we'll use until some updated
		// ItemInfo code gets checked in
		private function infoget( strField:String, obDefault:*) : * {
			if (null == _info || !(strField in _info))
				return obDefault;
			return _info[strField];
		}
		
		// this is a temporary function that we'll use until some updated
		// ItemInfo code gets checked in
		private function infosave( info:Object ) : String {
			var jsonenc:JSONEncoder = new JSONEncoder(info);
			return jsonenc.getString();
		} 		
       	
		// this is a temporary function that we'll use until some updated
		// ItemInfo code gets checked in
		private function infoload( strInfo:String ) : Object {
			var jsondec:JSONDecoder = new JSONDecoder(strInfo, false);
			return jsondec.getValue();
		} 		

		// Bring up a dialog saying the current Show is full.  If we've spilled
		// over the max # of photos, it'll trim it back to size.  If the user
		// isn't premium, it'll give them a chance to upgrade.
		public function MaxPhotosDialog(): void {
			var isPaid:Boolean = AccountMgr.GetInstance().isPaid;
			EasyDialogBase.Show(PicnikBase.app,
					[Resource.getString("GalleryStyle", isPaid ? null : "maxPhotosUpgrade"),
						Resource.getString("GalleryStyle", isPaid ? "maxPhotosOk" : "maxPhotosCancel")],
					Resource.getString("GalleryStyle",          "maxPhotosHeader"),
					Resource.getString("GalleryStyle", isPaid ? "maxPhotosTextPremium" : "maxPhotosText"),
					function (obResult:Object): void {
						while (imageCount > maxAllowedImageCount)
							Undo();
						ClearRedo();
						if (!isPaid && obResult.success) {
							DialogManager.ShowUpgrade("/showItemLimit_" + maxAllowedImageCount);
						} else {
							// do nothing
						}
					}
			);				
		}
		
       	
	}
}