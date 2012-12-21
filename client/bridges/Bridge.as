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
package bridges
{
	import com.adobe.utils.StringUtil;
	
	import controls.Gears;
	import controls.PicnikMenu;
	import controls.PicnikMenuItem;
	import controls.list.PicnikTileList;
	
	import dialogs.DialogContent.IDialogContent;
	import dialogs.DialogContent.IDialogContentContainer;
	import dialogs.DialogManager;
	import dialogs.EasyDialog;
	import dialogs.EasyDialogBase;
	
	import events.ActiveDocumentEvent;
	
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	
	import imagine.ImageDocument;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.ItemClickEvent;
	import mx.events.StateChangeEvent;
	import mx.resources.ResourceBundle;
	
	import pages.Page;
	
	import util.GalleryItem;
	import util.IAssetSource;
	import util.ImagePropertiesUtil;
	import util.LocUtil;
	import util.PhotoBasketVisibility;
	import util.UserBucketManager;

/**
 *  Dispatched when the this component becomse "active" as defined by IBridge
 *
 *  <p>The event is dispatched when the the component is selected/becomes visible
 *
 *  <p>This is different than the activate event which is triggered when
 *  the window is selected, whether or not the component is visible..</p>
 *
 *  @eventType mx.events.Event "activate2"
 */
	[Event(name="activate2", type="flash.events.Event")]

	public class Bridge extends Page implements IBridge, IDialogContent {

		// Bridge item actions - these must correspond to the id fields
		// in the link buttons in bridge menu item mxml
		public static const EDIT_ITEM:String = "edit";
		public static const EDIT_GALLERY:String = "edit_gallery";
		public static const DELETE_ITEM:String = "delete";
		public static const DELETE_GALLERY:String = "delete_gallery";
		public static const ADD_GALLERY_ITEM:String = "add_gallery_item";
		public static const RENAME_ITEM:String = "rename"; // Edit the name
		public static const COMMIT_RENAME_ITEM:String = "commitRename"; // Save the name change
		public static const EMAIL_ITEM:String = "email";
		public static const EMAIL_GALLERY:String = "email_gallery";
		public static const SHARE_GALLERY:String = "share_gallery";
		public static const LAUNCH_GALLERY:String = "launch_gallery";
		public static const DOWNLOAD_ITEM:String = "download";
		public static const OPEN_ITEMS_WEBPAGE:String = "openWebPage";
		public static const OPEN_ITEMS_FLICKRPAGE:String = "openFlickrPage";
		public static const POST_TO_PROFILE:String = "postToProfile";
		public static const SEND_TO_FRIEND:String = "sendToFriend";
		public static const PUBLISH_TEMPLATE:String = "publishTemplate";
		
		private var _strServiceID:String; // identifies the service associated with this bridge
		
		// Callback function pointers for the overwrite/cancel dialog.
		protected var _fnContinueOverwrite:Function = null;
		protected var _fnOverwriteCanceled:Function = null;
		
		protected var _mnuOptions:PicnikMenu = new PicnikMenu();
		
		// prevents this bridge from appearing in the navbar, even if it's selected
		[Bindable] public var NoNavBar:Boolean = false;
		
		[Bindable] protected var _doc:GenericDocument;

		// identifies the service associated with this bridge
		[Bindable]
		public function set serviceid(str:String): void {
			_strServiceID = str;
		}
		public function get serviceid(): String {
			return _strServiceID;
		}

		[Bindable]
		protected function set doc( doc:GenericDocument ):void {
			var imgdOld:ImageDocument = _imgd;
			var galdOld:GalleryDocument = _gald;
			_doc = doc;
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, '_imgd', imgdOld, _imgd));
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, '_gald', galdOld, _gald));
		}
		
		protected function get doc(): GenericDocument {
			return _doc;
		}

		// UNDONE: remove accessors/mutators that work specifically with ImageDocument/GalleryDocument
		// create set/get version of _imgd for backwards compatibility with
		// code that only wants to know about image documents
		[Bindable]
		protected function set _imgd( imgd:ImageDocument ):void {
			_doc = imgd;
		}
		
		protected function get _imgd(): ImageDocument {
			return _doc as ImageDocument;
		}

		[Bindable]
		protected function set _gald( gald:GalleryDocument ):void {
			_doc = gald;
		}
		
		protected function get _gald(): GalleryDocument {
			return _doc as GalleryDocument;
		}

  		[ResourceBundle("Bridge")] static protected var _rb:ResourceBundle;
		
		public function Bridge() {
			//trace("Bridge constructor: " + className);
			super();
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
			addEventListener(StateChangeEvent.CURRENT_STATE_CHANGE, OnStateChange );
			_mnuOptions._acobMenuItems = new ArrayCollection([new PicnikMenuItem( Resource.getString("Bridge", "Disconnect"),
					{ id: "disconnect" })]);
			_mnuOptions.addEventListener(ItemClickEvent.ITEM_CLICK, OnMenuItemClick);
		}
		
		protected function GetPhotosAndAlbums(nPhotos:Number, nAlbums:Number, strKeySuffix:String="albums"): String {
			// Avoid reporting the scary "No photos" message while the bridge is initializing
			if (nPhotos == -1 || nAlbums == -1)
				return "";
				
			return LocUtil.zeroOneOrMany2('Bridge', nPhotos, nAlbums, "number_of_photos_and_" + strKeySuffix);
		}
		
		protected function GetPhotosAndSets(nPhotos:Number, nAlbums:Number): String {
			return GetPhotosAndAlbums(nPhotos, nAlbums, "sets");
		}
		
		// Override this in Out bridge classes which do not extend OutBridge and do not have 'outbridge' in their class name
		protected function get isOutBridge(): Boolean {
			if (this is OutBridge) return true;
			// Do a case insensitve search for 'outbridge' in the class name
			return className.toLowerCase().indexOf('outbridge') > -1;
		}
		
		protected function chomp(strIn:String, strRemoveFromTail:String): String {
			if (StringUtil.endsWith(strIn, strRemoveFromTail))
				return strIn.substr(0, strIn.length - strRemoveFromTail.length);
			return strIn;
		}
		
		protected function get simpleBridgeName(): String {
			// Remove "Base" and "In/OutBridge" from the class name, convert to all lower case.
			var strName:String = className.toLowerCase();
			strName = chomp(strName, 'base');
			strName = chomp(strName, 'inbridge');
			strName = chomp(strName, 'outbridge');
			return strName;
		}
		
		// in transfer types: upload, import, local, sample
		// out transfer types: download, export, local
		protected var transferType:String;
		
		// strEvent has a preceeding slash, e.g. '/withperfectmemory'
		protected function ReportSuccess(strEvent:String=null, strTransferType:String="undefined"): void {
			if (isOutBridge) {
				PhotoBasketVisibility.ReportSave(_imgd);
			}
			DoReportSuccess(isOutBridge, simpleBridgeName, strEvent, strTransferType, isOutBridge && _imgd ? _imgd.GetFeatureUsageString() : null);
		}

		public static function DoReportSuccess(fIsOutBridge:Boolean, strSimpleBridgeName:String, strEvent:String=null,
				strTransferType:String="undefined", strFeatureUsage:String=null): void {
			if (strEvent == null)
				strEvent = "/-";
			var strPath:String = "";
			strPath += '/bridges';
			strPath += fIsOutBridge ? '/out' : '/in';
			strPath += '/' + strSimpleBridgeName;
			if (strEvent == null)
				strEvent = "";
			if (strEvent.length > 0 && strEvent.charAt(0) != '/')
				strPath += '/';
			strPath += strEvent;
			Util.UrchinLogReport(strPath);
			
			if (fIsOutBridge)
				UserBucketManager.GetInst().OnSave(strSimpleBridgeName);
			else
				UserBucketManager.GetInst().OnOpen(strSimpleBridgeName);

			// Log image in/out stats to GA.
			// Final path looks like: /images/{in|out}/{transfer type}/{guest|reg|paid}			
			strPath = "/images/";
			var strUserType:String = AccountMgr.GetInstance().isPaid ? "paid" : AccountMgr.GetInstance().isGuest ? "guest" : "reg";
			strPath += (fIsOutBridge ? "out" : "in") + "/" + strTransferType + "/" + strUserType;
			Util.UrchinLogReport(strPath);

			// Log which features have been used on this image.
			if (fIsOutBridge && strFeatureUsage)
				Util.UrchinLogReport("/feature_usage/" + strUserType.charAt(0) + "/" + strFeatureUsage);
		}
		
		protected function OnInitialize(evt:FlexEvent): void {
			//trace("Bridge.OnInitialize: " + id);
		}

		private function OnCreationComplete(evt:FlexEvent): void {
			//trace("Bridge.OnCreationComplete: " + id);
		}

		protected function OnOptionsClick(evt:Event): void {
			_mnuOptions.Show(evt.currentTarget as UIComponent);
		}
		
		protected function OnMenuItemClick(evt:ItemClickEvent): void {
			// Override in sub-classes
		}

		protected function OnStateChange(evt:StateChangeEvent):void {
			PicnikBase.app.UpdateBridges();
		}

		//
		// IBridge implementation
		//
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			
			// this call is necessary so that we'll properly re-order
			// the in/out bridges when a new user signs in (or signs out).
			PicnikBase.app.UpdateBridges();

			PicnikBase.app.addEventListener(ActiveDocumentEvent.CHANGE, OnActiveDocumentChange);
			OnActiveDocumentChange(new ActiveDocumentEvent(ActiveDocumentEvent.CHANGE, null, PicnikBase.app.activeDocument))
		}
		
		override public function OnDeactivate(): void {
			super.OnDeactivate();

			HideBusy();
			PicnikBase.app.removeEventListener(ActiveDocumentEvent.CHANGE, OnActiveDocumentChange);
			OnActiveDocumentChange(new ActiveDocumentEvent(ActiveDocumentEvent.CHANGE, PicnikBase.app.activeDocument, null ))
		}

		protected function OnActiveDocumentChange(evt:ActiveDocumentEvent): void {
			doc = evt.docNew;
		}
		
		private function get busyGears(): Gears {
			var grs:Gears = null
			var p:DisplayObjectContainer = this;
			while (!grs && p) {
				grs = Gears(p.getChildByName("_grsBusy"));
				p = p.parent;
			}
			return grs;
		}
		
		public function set busyShowing(fShowing:Boolean): void {
			if (fShowing)
				ShowBusy();
			else
				HideBusy();
		}
		
		[Bindable] protected var busyCount:int = 0;
		
		protected function ShowBusy(): void {
			// Multiple busy actions may be happening at once
			if (busyGears) {
				busyCount++;
				if (busyCount == 1)
					busyGears.visible = true;
			}
		}
		
		protected function HideBusy(): void {
			if (busyGears) {
				busyCount--;
				if (busyCount < 0)
					busyCount = 0;
				if (busyCount == 0)
 					busyGears.visible = false;
 			}
		}
		
		// This is just here to be overridden
		protected function OverwriteCanceled(): void {
			// Take care of any cleanup necessary when a user cancels out of an upload due to
			// an image edit which has not been saved.
		}
		
		// Make sure it is OK to load an image.
		// If there are unsaved changes, pops up a dialog and asks to save changes
		// Dialog options are: Yes (save), No (overwrite) and Cancel (do nothing)
		// If there are no changes or the user selects "no" (overwrite), fnContinueOverwrite is called
		// If the user selects "yes" (save changes), take them to the save changes tab and call (OverwriteCanceled or fnOverwriteCanceled)
		// CONSIDER: If save were simple, we could save changes first and then upload.
		// If the user selects "cancel" do nothing (calls OverwriteCanceled or fnOverwriteCanceled)
		protected function ValidateOverwrite(fnContinueOverwrite:Function, fnOverwriteCanceled:Function = null): void {
			if (PicnikBase.app.activeDocument && PicnikBase.app.activeDocument.isDirty) {
				_fnContinueOverwrite = fnContinueOverwrite;
				_fnOverwriteCanceled = fnOverwriteCanceled;
				DialogManager.Show('ConfirmLoadOverEditDialog', PicnikBase.app, ValidateOverwriteCallback);
			} else {
				fnContinueOverwrite();
			}
		}
		
		// Callback for ValidateOverwrite dialog. Will react to user input (Yes (save), No (overwrite) and Cancel)
		protected function ValidateOverwriteCallback(res:Object): void {
			if (res.success)
				_fnContinueOverwrite();
			else if (_fnOverwriteCanceled != null)
				_fnOverwriteCanceled();
			else
				OverwriteCanceled();
		}
		
		public static function DisplayCouldNotProcessChildrenError(): void {
			var dlg1:EasyDialog =
				EasyDialogBase.Show(
					PicnikBase.app,
					[Resource.getString('Bridge', 'ok')],
					Resource.getString("Bridge", "blargh"),
					Resource.getString("Bridge", "couldNotProcessSomePhotos"),
					function( obResult:Object ):void {
						// When done, Navigate to the edit tab
						PicnikBase.app.NavigateTo(PicnikBase.EDIT_CREATE_TAB);
					}
				);							
		}
		
		private function NearbyIndexOf(aob:Array, strLabel:String, strThumbnailURL:String, nStartPos:Number, nLookAhead:Number): Number {
			for (var i:Number = nStartPos; i < nStartPos + nLookAhead && i < aob.length; i++) {
				var obj:Object = aob[i];
				if (obj.title == strLabel && obj.thumbnailurl == strThumbnailURL)
					return i;
			}
			return -1;
		}
		
		protected function SmartUpdateDataProvider(aobIn:Array, tlst:PicnikTileList, fReset:Boolean=false): void {
			const knLargeChangeSize:Number = 20;
			
			var acOut:ArrayCollection = null;
			
			if (tlst.dataProvider == null) {
				fReset = true;
			} else {
				acOut = (ArrayCollection)(tlst.dataProvider);
				var nChangeSize:Number = GetChangeSize(aobIn, acOut, knLargeChangeSize);
				if (nChangeSize >= knLargeChangeSize || nChangeSize >= aobIn.length || nChangeSize >= acOut.length) {
					fReset = true;
				}
			}
			
			if (fReset) {
				tlst.dataProvider = aobIn;
			} else {
				SmartUpdateArray(aobIn, acOut);
			}
		}

		private function GetChangeSize(aobIn:Array, aobOut:ArrayCollection, nMaxChange:Number): Number {
			// Update the contents of our out array based on in array
			// Try to minimize changes
			// As implemented, this function is pretty slow - O(N*N) worst case
			const knLookAhead:Number = 5; // Look this many rows ahead
			var nInPos:Number;
			var nOutPos:Number = 0;
			var nChangeSize:Number = 0;
			for (nInPos = 0; nInPos < aobIn.length && nChangeSize < nMaxChange; nInPos++) {
				// Assume the arrays are up to date for all previous positions
				
				if (nOutPos >= aobOut.length) { // If we are at the end of our output list
					nChangeSize++; // At the end, skip the out pos
				} else {
					// Look ahead to figure out where to insert aob[nInPos]
					var nMatchPos:Number = NearbyIndexOf(aobOut.source, aobIn[nInPos].title, aobIn[nInPos].thumbnailurl, nOutPos, knLookAhead);
					if (nMatchPos == -1) {
						// Not found, skip the in pos
						nChangeSize += 1;
					} else {
						// Found a match. Delete other elements before the match
						var nToDelete:Number = nMatchPos - nOutPos;
						nChangeSize += nToDelete;
						nOutPos += nToDelete;
						nOutPos++;
					}
				}
			}
			// Remove remainder of out list
			nChangeSize += Math.max(0,aobOut.length - nOutPos);
			
			return nChangeSize;
		}
		
		private function SmartUpdateArray(aobIn:Array, aobOut:ArrayCollection): void {
			// Update the contents of our out array based on in array
			// Try to minimize changes
			// As implemented, this function is pretty slow - O(N*N) worst case
			const knLookAhead:Number = 5; // Look this many rows ahead
			var nInPos:Number;
			var nOutPos:Number = 0;
			for (nInPos = 0; nInPos < aobIn.length; nInPos++) {
				// Assume the arrays are up to date for all previous positions
				
				if (nOutPos >= aobOut.length) { // If we are at the end of our output list
					aobOut.addItem(aobIn[nInPos]);
					nOutPos++;
				} else {
					// Look ahead to figure out where to insert aob[nInPos]
					var nMatchPos:Number = NearbyIndexOf(aobOut.source, aobIn[nInPos].title, aobIn[nInPos].thumbnailurl, nOutPos, knLookAhead);
					if (nMatchPos == -1) {
						// Found a new element, insert it
						// First, check to see if the opposite element is in this list.
						// If not, replace, otherwise insert.
						var nReverseMatchPos:Number = NearbyIndexOf(aobIn, aobOut[nOutPos].title, aobOut[nOutPos].thumbnailurl, nInPos, knLookAhead);
						if (nReverseMatchPos == -1)
							aobOut.setItemAt(aobIn[nInPos], nOutPos); // Opposite member is not (nearby) in the in list, so overwrite it.
						else
							aobOut.addItemAt(aobIn[nInPos], nOutPos); // Opposite member is in the list, so keep it around
						nOutPos++;
					} else {
						// Found a match. Delete other elements before the match
						var nToDelete:Number = nMatchPos - nOutPos;
						for (var i:Number = 0; i < nToDelete; i++) {
							aobOut.removeItemAt(nOutPos);
						}
						// Now update the next element.
					 	var imgpOut:ImageProperties, imgpIn:ImageProperties;
						imgpOut = (aobOut[nOutPos] is ImageProperties) ?
									(aobOut[nOutPos] as ImageProperties) :
									((aobOut[nOutPos] as ItemInfo).asImageProperties());

						imgpIn = (aobIn[nInPos] is ImageProperties) ?
									(aobIn[nInPos] as ImageProperties) :
									((aobIn[nInPos] as ItemInfo).asImageProperties());
						
						// Copy the updated properties one at a time to avoid unnecessary
						// updating due to a change event being fired
						imgpIn.CopyTo(imgpOut);
						nOutPos++;
					}
				}
			}
			// Remove remainder of out list
			while (nOutPos < aobOut.length) aobOut.removeItemAt(aobOut.length - 1);
		}
		
		// Create a base image name that the server will be happy with.
		// Remove prefix characters before and including \, /
		// Remove suffix characters after and including ?, .
		// URL-encode the whole filename
		// Remove % and @ characters anywhere in the filename
		// Prepend a timestamp and underscore.
		// "/whatever/my%_strange file@name.jpg?whatever=something" -> "db44b5de_my_strange%20filename"
		public static function GetBaseImageName(strFilePath:String): String {
			var cms:Number = (new Date()).getTime();
			var strTimestamp:String = "";
			for (var i:Number = 0; i < 8; i++, cms >>= 4)
				strTimestamp = (cms & 0xf).toString(16) + strTimestamp;
			var rx:RegExp = /[%@]/g;
			var strImageName:String = escape(ImageProperties.TitleFromPathOrURL(strFilePath)).replace(rx, "");
			return (strTimestamp + "_" + strImageName).substr(0, ImageDocument.kcchFileNameMax);
		}
		
		//
		// In bridge renderer support implementation
		//
		
		public function GetMenuItems(): Array {
			return [Bridge.EDIT_ITEM, Bridge.DELETE_ITEM, Bridge.RENAME_ITEM,
					Bridge.EMAIL_ITEM, Bridge.DOWNLOAD_ITEM];
		}

		// Returns true if the file name is editable (based on menu items)
		public function NameIsEditable(): Boolean {
			return GetMenuItems().indexOf(Bridge.RENAME_ITEM) >= 0;
		}
		
		// Once a download is complete, we need to go somewhere based on the
		// action. This function figures out where to go.
		protected function NavigateToAction(strAction:String): void {
			if (strAction == null) strAction = Bridge.EDIT_ITEM; // Default to edit
			switch(strAction) {
				case Bridge.EDIT_ITEM:
					PicnikBase.app.NavigateTo(PicnikBase.EDIT_CREATE_TAB);
					break;
				case Bridge.EDIT_GALLERY:
					PicnikBase.app.NavigateTo(PicnikBase.GALLERY_STYLE_TAB);
					break;
				case Bridge.DOWNLOAD_ITEM:
					PicnikBase.app.NavigateTo(PicnikBase.OUT_BRIDGES_TAB);
					break;
				case Bridge.EMAIL_ITEM:
					PicnikBase.app.NavigateTo(PicnikBase.OUT_BRIDGES_TAB, OutBridge.EMAIL_SUB_TAB);
					break;

				case Bridge.SHARE_GALLERY:
				case Bridge.EMAIL_GALLERY:
					DialogManager.Show("ShareContentDialog", null, null, {item:_gald.info});
					break;
			}
		}
		
		static public function GetServiceName(strServiceId:String): String {
			// "null" ends up in the database for unknown services
			if (!strServiceId || strServiceId == "null")
				return "";
			
			// try looking up a localized version of the name
			var strServiceName:String = null;
			try {
				strServiceName = Resource.getString( "Bridge", strServiceId );
			} catch (e:Error) {
				// let it pass through
			}
			
			if (!strServiceName) {
				// The ServiceManager knows about a lot of services
				strServiceName = ServiceManager.GetFriendlyName(strServiceId);
			}
			
			if (!strServiceName) {
				// The GenericEmailOutBridge annotates history entries with GenericEmail/destination.
				// Return the destination part.
				var ichSlash:int = strServiceId.indexOf("/");
				if (ichSlash != -1)
					strServiceName = strServiceId.slice(ichSlash + 1);				
			}
			return strServiceName;
		}		
		
		static public function GetServiceFavIconUrl(strServiceId:String): String {
			// Lower case the service id and truncate entries at the dividing '/', if any
			// (e.g. GenericEmail/Walmart -> genericemail)
			var strIcon:String = strServiceId.toLowerCase();
			var ichSlash:int = strIcon.indexOf("/");
			if (ichSlash != -1)
				strIcon = strIcon.slice(0, ichSlash);
			return "/graphics/thirdpartylogos/serviceicons/" + strIcon + ".png";
		}
		
		//
		// IDialogContent implementation
		//
		
		private var _dcc:IDialogContentContainer;
		[Bindable]
		public function get container(): IDialogContentContainer {
			return _dcc;			
		}
		
		public function set container(dcc:IDialogContentContainer): void {
			_dcc = dcc;
		}
		
		protected function addGalleryItem(evt:BridgeItemEvent): void {
			var imageProps:ImageProperties;
			if (evt.bridgeItemData is ItemInfo)
				imageProps = (evt.bridgeItemData as ItemInfo).asImageProperties();
			else
				imageProps = (evt.bridgeItemData as ImageProperties);
				
			var asrc:IAssetSource = ImagePropertiesUtil.GetAssetSource(imageProps);
			var gi:GalleryItem = GalleryItem.Create( doc as GalleryDocument, asrc );		
			gi.title = imageProps.title;
			gi.caption = imageProps.description;
			gi.thumbUrl = asrc.thumbUrl;
			var gdoc:GalleryDocument = doc as GalleryDocument;
			if (gdoc.items.length >= GalleryDocument.maxAllowedImageCount)
				gdoc.MaxPhotosDialog();	// UNDONE: should be inside InsertImage()?
			else
				gdoc.InsertImage(gi);
		}
	}
}
