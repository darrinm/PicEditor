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
package bridges.storageservice {
	import bridges.Bridge;
	
	import dialogs.IBusyDialog;
	
	import events.*;
	
	import flash.events.*;
	
	import mx.containers.HBox;
	import mx.controls.ComboBox;
	import mx.events.FlexEvent;
	import mx.events.ItemClickEvent;
	import mx.events.StateChangeEvent;
	import mx.resources.ResourceBundle;
	
	import util.LocUtil;
	
	public class StorageServiceBridgeBase extends Bridge {
		// MXML-specified variables
		[Bindable] public var _cboxSets:ComboBox;
		[Bindable] public var _cboxFriends:ComboBox;
		[Bindable] public var _tpa:ThirdPartyAccount;
		[Bindable] public var _ss:IStorageService;
		[Bindable] public var _ssa:StorageServiceAccountBase;
		[Bindable] public var _cItems:Number;
		[Bindable] public var _cSets:Number;
		[Bindable] public var _adctSetInfos:Array;
		[Bindable] public var _adctFriendInfos:Array;
		[Bindable] public var _hbxOptions:HBox;
		[Bindable] public var _fIsPro:Boolean;
		
		// This is set to true when we're done refreshing our data
		[Bindable] public var _fRefreshed:Boolean = false;

		protected var _bsy:IBusyDialog;
		protected var _dctUserInfo:Object;
		protected var _dctStoreInfo:Object;
		protected var _strSelectedSetID:String = null;
		protected var _strSelectedFriendID:String = null;
		protected var _fNoSets:Boolean = false;
		protected var _fNoFriends:Boolean = false;
		protected var _nRefreshUserInfoOutstanding:Number = 0;
		protected var _nRefreshFriendsOutstanding:Number = 0;
		protected var _nRefreshSetsOutstanding:Number = 0;
		protected var _nRefreshStoreInfoOutstanding:Number = 0;
		protected var _nFailCount:Number = 0;

		private var _usri:UserInfo;
		
   		[ResourceBundle("StorageServiceInBridgeBase")] private var _rb:ResourceBundle;

		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			if (_tpa) _ss = _tpa.storageService;
			addEventListener(StateChangeEvent.CURRENT_STATE_CHANGE, OnCurrentStateChange);
			addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown); // To capture Enter
			if (_hbxOptions) _hbxOptions.addEventListener(MouseEvent.CLICK, OnOptionsClick);
			if (_hbxOptions) _hbxOptions.addEventListener(MouseEvent.DOUBLE_CLICK, OnOptionsClick);
			if (_cboxSets) _cboxSets.addEventListener(Event.CHANGE, OnSetsComboChange);
			AccountMgr.GetInstance().addEventListener(AccountEvent.USER_CHANGE, OnUserChange);						
		}
		
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);

			// If not already logged in make sure the Connect state is being shown
			// and call it's OnActivate so it will attempt to log in if it has enough
			// information to do so.
			if (!_ss.IsLoggedIn()) {
				if (currentState != GetSignedOutState())
					currentState = GetSignedOutState();
				else if (_ssa)
					_ssa.OnActivate();
			} else {
				RefreshEverything();
			}
		}		
		
		protected function GetSignedOutState(): String {
			return "NeedAuthorization";
		}
		
		protected function OnCurrentStateChange(evt:StateChangeEvent): void {
			if (evt.newState == GetSignedOutState()) {
				if (_ssa) {
					_ssa.addEventListener(LoginEvent.LOGIN_COMPLETE, OnLoginComplete);
					_ssa.OnActivate();
				}
			}
		}

		protected function OutstandingRefreshes(): Number {
			return _nRefreshUserInfoOutstanding +
					_nRefreshSetsOutstanding +
					_nRefreshFriendsOutstanding +
					_nRefreshStoreInfoOutstanding;
		}		
		
		protected function RefreshEverything(): void {
			if (storeIsOff) return;
			if (OutstandingRefreshes() == 0) {
				RefreshUserInfo();	// Will call RefreshFriends after loading user info
				RefreshStoreInfo();
				RefreshSets();	// Will call RefreshImageList after loading the sets // CHIP: it does *not*, which is the cause of bug #3413059
			}
		}
		
		protected function OnLoginComplete(evt:LoginEvent): void {
			if (_ssa)
				_ssa.removeEventListener(LoginEvent.LOGIN_COMPLETE, OnLoginComplete);
			if (!_ss.IsLoggedIn()) {
				if (currentState != GetSignedOutState())
					currentState = GetSignedOutState();
			} else {
				RefreshEverything();
				currentState = GetState();
			}
		}
		
		// This is meant to be overridden by subclasses
		// It should return whatever state we want after we are authorized
		protected function GetState(): String {
			return "";
		}

		protected override function OnMenuItemClick(evt:ItemClickEvent): void {
			Disconnect();
		}
		
		protected function Disconnect(): void {
			_tpa.SetUserId("");
			_tpa.SetToken("", true);
			_tpa.storageService.LogOut();
			if (_ssa) _ssa.Logout();
			_nFailCount = 0;
			currentState = GetSignedOutState();
		}
		
		public function RequireAuthorization(): void {
			if (currentState != GetSignedOutState())
				currentState = GetSignedOutState();
		}
		
		protected function CheckFailCount( err:Number, strError:String ): void {
			// Sometimes a random call to a service will fail.  In that
			// situation, we want to try to re-authorize in case our
			// credentials are stale.  But if that works and then we fail again,
			// (ie., _nFailCount > 1), then we should clear the credentials
			// so that we don't get into an infinite loop.
			if (err != StorageServiceError.None) {
				_nFailCount++;
				if (_nFailCount > 1) {
					if (_ssa)		
						_ssa.OnAccountError( err, strError );		
					_tpa.storageService.LogOut();
					_nFailCount = 0;
				}
			}
		}

		protected function UpdateState(): void {
			if ((_ss && _ss.IsLoggedIn()) || currentState != GetSignedOutState()) {
				currentState = GetState();
			}
		}

		protected function GetItemInfo(strSetId:String, strItemId:String,
				fnCallback:Function, obCallbackData:Object = null): void {
			_ss.GetItemInfo(strSetId, strItemId,
				function (err:Number, strError:String, itemInfo:ItemInfo=null): void {
					if (err != StorageServiceError.None) {
						fnCallback(null, obCallbackData);
						return;
					}
					
					// UNDONE: this should just return itemInfo directly
					var imgp:ImageProperties = itemInfo.asImageProperties();
					fnCallback(imgp, obCallbackData);
				});
		}

		protected function RefreshSets(): void {
			if (storeIsOff) return;
			// UNDONE: keep in and outbridge selected set synchronized and persisted
			ShowBusy();
			_nRefreshSetsOutstanding++;
			_ss.GetSets( _strSelectedFriendID, OnGetSets);
		}
		
		protected function OnGetSets(err:Number, strError:String, adctSetInfos:Array=null): void {
			CheckFailCount( err, strError );
			Debug.Assert(_nRefreshSetsOutstanding > 0);
			HideBusy();
			
			if (err != StorageServiceError.None) {
				_nRefreshSetsOutstanding--;								
				currentState = GetSignedOutState();	// attempt to reconnect
				return;
			}

			_adctSetInfos = adctSetInfos;
			
			// Let subclasses know we've refreshed the sets
			OnSetsRefreshed();
			_nRefreshSetsOutstanding--;
			_fRefreshed = OutstandingRefreshes() == 0 ? true : false;
			
		}
		
		private function FindItemIndex(strSetID:String): Number {
			var aitm:Array = _cboxSets.dataProvider.source;
			if (aitm) {
				for (var i:Number = 0; i < aitm.length; i++) {
					var itm:StorageServiceSetComboItem = aitm[i] as StorageServiceSetComboItem;
					if (itm.setinfo && itm.setinfo.id == strSetID)
						return i;
				}
			}			
			return -1;
		}
		
		private function FindFriendItemIndex(strFriendID:String): Number {
			var aitm:Array = _cboxFriends.dataProvider.source;
			for (var i:Number = 0; i < aitm.length; i++)
			{
				var itm:StorageServiceFriendComboItem = aitm[i] as StorageServiceFriendComboItem;
				if (itm.friendInfo.uid == strFriendID)
					return i;
			}
			
			return -1;
		}
		
		protected function OnSetsRefreshed(): void {
			var aitmSets:Array = SetInfosToComboItems(_adctSetInfos);
			if (_cboxSets) {
				_cboxSets.dataProvider = aitmSets;
				var iSelected:Number = FindItemIndex(_strSelectedSetID);
				_cboxSets.selectedIndex = iSelected >= 0 ? iSelected : 0;
				
				if (_cboxSets.selectedItem && ((_cboxSets.selectedItem as StorageServiceSetComboItem).cmd == "CreateSet")) {								
					// don't have "create a new album" be the default selection
					_cboxSets.selectedIndex++;
				}
			}
			_fNoSets = aitmSets.length == 0;
		}
		
		protected function SetInfosToComboItems( adctSetInfos:Array ): Array {
			var aitmSets:Array = [];
			for each (var dctSetInfo:Object in _adctSetInfos) {
				if (null != dctSetInfo) {
					aitmSets.push(new StorageServiceSetComboItem(dctSetInfo.title,
							dctSetInfo.thumbnailurl, dctSetInfo));
				}
			}		
			StorageServiceSetComboItem.UpdateHasIcons(aitmSets);
			return aitmSets;	
		}
		
		// Override this to turn the store off
		protected function get storeIsOff():Boolean {
			return false;
		}
		
		protected function RefreshStoreInfo(): void {
			if (storeIsOff) return;
			_nRefreshStoreInfoOutstanding++;
			ShowBusy();
			_ss.GetStoreInfo(OnGetStoreInfo);
		}
		
		private function OnGetStoreInfo(err:Number, strError:String, dctStoreInfo:Object=null): void {
			CheckFailCount( err, strError );
			Debug.Assert(_nRefreshStoreInfoOutstanding > 0);
			HideBusy();
			
			if (err != StorageServiceError.None) {
				_nRefreshStoreInfoOutstanding--;
				currentState = GetSignedOutState();	// attempt to reconnect
				return;
			}

			if (dctStoreInfo.itemcount != null)
				_cItems = dctStoreInfo.itemcount;
			if (dctStoreInfo.setcount != null)
				_cSets = dctStoreInfo.setcount;
				
			_dctStoreInfo = dctStoreInfo;
			OnStoreInfoRefreshed();
			_nRefreshStoreInfoOutstanding--;
			_fRefreshed = OutstandingRefreshes() == 0 ? true : false;
		}

		// This is meant to be overridden by subclasses		
		protected function OnStoreInfoRefreshed(): void {
		}

		protected function RefreshUserInfo(): void {
			if (storeIsOff) return;
			_nRefreshUserInfoOutstanding++;
			ShowBusy();
			_ss.GetUserInfo(OnGetUserInfo);
		}
		
		private function OnGetUserInfo(err:Number, strError:String, dctUserInfo:Object=null): void {
			CheckFailCount( err, strError );
			HideBusy();
			
			if (err != StorageServiceError.None) {
				_nRefreshUserInfoOutstanding--;
				currentState = GetSignedOutState();	// attempt to reconnect
				return;
			}
			_dctUserInfo = dctUserInfo;
			if ("is_pro" in _dctUserInfo)
				_fIsPro = _dctUserInfo.is_pro;
			else
				_fIsPro = false;
			RefreshFriends();
			OnUserInfoRefreshed();
			_nRefreshUserInfoOutstanding--;
			_fRefreshed = OutstandingRefreshes() == 0 ? true : false;
		}
		
		protected function RefreshFriends(): void {
			if (storeIsOff) return;
			_nRefreshFriendsOutstanding++;
			ShowBusy();
			_ss.GetFriends(OnGetFriends);
		}
		
		private function OnGetFriends(err:Number, strError:String, adctFriends:Array=null): void {
			HideBusy();
			if (err != StorageServiceError.None) {
				// UNDONE: what to do? Try again later?
				// we'll just clear out the friend info so that no friends are displayed
			}
			_adctFriendInfos = adctFriends;
			OnFriendsRefreshed();
			_nRefreshFriendsOutstanding--;
			_fRefreshed = OutstandingRefreshes() == 0 ? true : false;
		}
		
		// This is meant to be overridden by subclasses		
		protected function OnUserInfoRefreshed(): void {
		}
		
		// This is meant to be overridden by subclasses		
		protected function OnFriendsRefreshed(): void {
			var aitmFriends:Array = [];
			
			// always add the current user as the first friend
			var strName:String = _dctUserInfo.fullname;
			if (!strName) strName =  _dctUserInfo.username;
			var strYou:String;
			if (strName) {
				strYou = LocUtil.rbSubst('StorageServiceInBridgeBase', 'you_name', strName);
			} else {
				strYou = Resource.getString('StorageServiceInBridgeBase', 'you');
				strName = "";
			}
			var meAsFriendInfo:Object = {
						uid: null, // use null to indicate "default"
						name: strName,
						picurl: _dctUserInfo.thumbnailurl };
			aitmFriends.push(new StorageServiceFriendComboItem(strYou,
						_dctUserInfo.thumbnailurl, meAsFriendInfo));
			
			// add each of the user's friends
			for each (var dctFriendInfo:Object in _adctFriendInfos) {
				aitmFriends.push(new StorageServiceFriendComboItem(dctFriendInfo.name,
						dctFriendInfo.picurl, dctFriendInfo));
			}
			
			// update the combo box if we've got one
			if (_cboxFriends) {
				_cboxFriends.dataProvider = aitmFriends;
				var iSelected:Number = FindFriendItemIndex(_strSelectedFriendID);
				_cboxFriends.selectedIndex = iSelected >= 0 ? iSelected : 0;
			}
			_fNoFriends = aitmFriends.length == 1;
		}
			

		// This is meant to be overridden by subclasses		
		protected function OnKeyDown(evt:KeyboardEvent): void {
		}		
		
		protected function OnSetsComboChange(evt:Event): void {
			if ((_cboxSets.selectedItem as StorageServiceSetComboItem).setinfo)
				_strSelectedSetID = (_cboxSets.selectedItem as StorageServiceSetComboItem).setinfo.id;
		}
		
		protected function OnUserChange(evt:AccountEvent): void {
		}				
		
	}
}
