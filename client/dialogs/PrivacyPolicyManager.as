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
package dialogs {
	
	import api.PicnikRpc;
	import api.RpcResponse;
		
	public class PrivacyPolicyManager {
		
		// fnDetourDone looks like this: function DetourDone( fAccepted:Boolean) :void {}
		// fAccepted indicates whether the privacy policy was accepted or not.
		// fAccepted will also be true if we are not enforcing the privacy policy right now
		public static function ShowDetourIfRequired(fnDetourDone:Function): void {
			PicnikService.GetUserProperties("privacypolicy",
				function (err:Number, obResult:Object): void {
						if ("privacypolicy" in obResult &&
								"accepted" in obResult.privacypolicy &&
								"1" == obResult.privacypolicy.accepted.value) {
							fnDetourDone(true);
						} else {
							ShowDetour(null, fnDetourDone);
						}
					});
		}

		// fnDone(rpcresp:RpcResponse): void
		private static function SetUserPropertiesHelper( oCredentials:Object, oParams:Object, fnDone:Function=null): void {
			PicnikRpc.SetUserProperties(oParams, "privacypolicy", oCredentials, fnDone);
		}
		
		public static function ShowDetour(oCredentials:Object, fnDetourDone:Function): void {
			PrivacyPolicyManager.SetUserPropertiesHelper( oCredentials, { "shown": "1" } );
			
			
			Util.UrchinLogReport("/privacypolicy/detour/shown");
			
			var fnOnShowDetour:Function = function(oResult:Object) : void {
					if (oResult.strResult == "accepted") {
						Util.UrchinLogReport("/privacypolicy/detour/accepted");
						PrivacyPolicyManager.SetUserPropertiesHelper( oCredentials, { "accepted": "1" },
							function( rpcresp:RpcResponse ):void {
									fnDetourDone(true);
								} );
						
					}
					if (oResult.strResult == "cancelled") {
						Util.UrchinLogReport("/privacypolicy/detour/cancelled");
						fnDetourDone(false);
					}
					if (oResult.strResult == "rejected") {
						Util.UrchinLogReport("/privacypolicy/detour/rejected");
						ShowDetourConfirmReject(oCredentials, fnDetourDone);
					}
				}
				
			var strUsername:String = null;
			if (oCredentials && 'strUserId' in oCredentials) {
				strUsername = oCredentials.strUserId;
			} else if (AccountMgr.GetInstance().hasCredentials) {
				strUsername = AccountMgr.GetInstance().displayName;
			}
			
			// if this user account is being asked to accept the privacy policy AND
			// their account was created after Oct 2010 then we want to show them
			// slightly modified verbage.  Also, since there's no way for us to have
			// been storing their data without them having accept the privacy policy,
			// then we don't have to show them the "delete" option.  Facebook and other
			// headless Third Party Accounts fall into this category.
			var fFreshUser:Boolean = false;
			var dtCreated:Date = AccountMgr.GetInstance().dateCreated;
			var dtOct2010:Date = new Date(2010, 9, 1);
			fFreshUser = (dtCreated == null) || (dtCreated.getTime() > dtOct2010.getTime());

			DialogManager.Show("PrivacyDetourDialog", null, fnOnShowDetour, { freshUser:fFreshUser, username: strUsername });
		}		

		public static function ShowDetourConfirmReject(oCredentials:Object, fnDetourDone:Function): void {
			
			Util.UrchinLogReport("/privacypolicy/confirmreject/shown");
			
			var fnOnShowDetourConfirmReject:Function = function(oResult:Object) : void {
					if (oResult.strResult == "accepted") {
						// back to the first dialog
						Util.UrchinLogReport("/privacypolicy/confirmreject/goback");
						ShowDetour(oCredentials, fnDetourDone);
					}
					if (oResult.strResult == "cancelled") {
						// back to the first dialog
						Util.UrchinLogReport("/privacypolicy/confirmreject/cancelled");
						ShowDetour(oCredentials, fnDetourDone);
					}
					if (oResult.strResult == "rejected") {
						Util.UrchinLogReport("/privacypolicy/confirmreject/rejected");
						ShowDetourFinalReject(oCredentials, fnDetourDone);
					}
				}

			var strUsername:String = null;
			if (oCredentials && 'strUserId' in oCredentials) {
				strUsername = oCredentials.strUserId;
			} else if (AccountMgr.GetInstance().hasCredentials) {
				strUsername = AccountMgr.GetInstance().displayName;
			}

			DialogManager.Show("PrivacyDetourConfirmRejectDialog", null, fnOnShowDetourConfirmReject, { username: strUsername });
		}	
		
		public static function ShowDetourFinalReject(oCredentials:Object, fnDetourDone:Function): void {
			
			Util.UrchinLogReport("/privacypolicy/finalreject/shown");
			
			var fnOnShowDetourFinalReject:Function = function(oResult:Object) : void {
					if (oResult.strResult == "accepted") {
						// back to the first dialog
						Util.UrchinLogReport("/privacypolicy/finalreject/goback");
						ShowDetour(oCredentials, fnDetourDone);
					}
					if (oResult.strResult == "cancelled") {
						// back to the first dialog
						Util.UrchinLogReport("/privacypolicy/finalreject/cancelled");
						ShowDetour(oCredentials, fnDetourDone);
					}
					if (oResult.strResult == "rejected") {
						Util.UrchinLogReport("/privacypolicy/finalreject/rejected");
						var bsy:IBusyDialog = BusyDialogBase.Show(	PicnikBase.app,
										Resource.getString("PrivacyDetourDialog", "Processing"),
										BusyDialogBase.DELETE,
										"IndeterminateNoCancel");

						PicnikService.RejectPrivacyPolicy(oCredentials, oResult.strEmail, oResult.fSendArchive,
							function( err:Number, strErr:String ):void {
									bsy.Hide();
									ShowDetourCompleteReject(oCredentials, fnDetourDone);
								} );
					}
				}

			var strUsername:String = null;
			if (oCredentials && 'strUserId' in oCredentials) {
				strUsername = oCredentials.strUserId;
			} else if (AccountMgr.GetInstance().hasCredentials) {
				strUsername = AccountMgr.GetInstance().displayName;
			}
			DialogManager.Show("PrivacyDetourFinalRejectDialog", null, fnOnShowDetourFinalReject, { username: strUsername });
		}		
		
		public static function ShowDetourCompleteReject(oCredentials:Object, fnDetourDone:Function): void {
			
			Util.UrchinLogReport("/privacypolicy/completereject/shown");
			
			var fnOnShowDetourCompleteReject:Function = function(oResult:Object) : void {
					fnDetourDone(false);
				}
			
			var strUsername:String = null;
			if (oCredentials && 'strUserId' in oCredentials) {
				strUsername = oCredentials.strUserId;
			} else if (AccountMgr.GetInstance().hasCredentials) {
				strUsername = AccountMgr.GetInstance().displayName;
			}
			DialogManager.Show("PrivacyDetourCompleteRejectDialog", null, fnOnShowDetourCompleteReject, { username: strUsername });
		}	

	}
}
