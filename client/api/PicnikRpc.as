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
package api
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Security;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import util.CreditCard;
	import util.CreditCardTransaction;

	public class PicnikRpc
	{
		public static const kfRetry:Boolean = true;
		public static const kfNoRetry:Boolean = false;

		public static const kfSecure:Boolean = true;
		public static const kfInsecure:Boolean = false;
		
		public function PicnikRpc()
		{
		}

		/*
		Function: AddAdminMessage
		
		Args:
		message: a string
		
		public fnDone(rpcresp:RpcResponse): void
		
		rpcresp.data: A dictionary with the following fields:
		nErrorCode: the result. likely values include:
		PicnikService.errNone: success
		PicnikService.errInvalidToken: 3rd party token is not valid
		PicnikService.errInvalidUserName: username contains invalid characters
		PicnikService.errUnknownAccount: user does not exist or password is wrong
		*/
		public static function AddAdminMessage(strMessage:String, fnDone:Function=null): void {
			var obParams:Object = { message: strMessage };
			CallMethod("user.addadminmessage", obParams, fnDone, false, false );
		}
		
		/*
		Function: GetUserProperties
		
		On success, rpcresp.response is dictionary of { group: [ { name:, value:, updated: }, ... ] }
		
		public fnDone(rpcresp:RpcResponse): void
		*/
		public static function GetUserProperties(strGroup:String, fnDone:Function, bSecure:Boolean=false): void {
			CallMethod("user.getproperties", {group:strGroup}, fnDone, bSecure, PicnikRpc.kfRetry);
		}
		
		/*
		Function: LogIn
		
		Args:
		obParameters: a dictionary containing:
			{'credentials': [cred1, cred2, ...]}
			where cred is a dictionary of user credentials:
				Guest
				{'authtype':'guest'}
				
				Picnik username/password
				{'authtype':'picnik', 'username':[username], 'password':[md5 password]}
				
				Picnik user token
				{'authtype':'picniktoken', 'userkey':[token]}
				
				Third party credentials
				{'authtype':'thirdparty', 'authservice':[third party service],
				'id':[third party id], 'token':[third party token]}
			
			Optional credential parameters:
			'privacypolicyrequired': [a boolean]
			
			Optional parameters:
			strCapabilities: log these client capabilities
			fClientConnect: if true, return clientKeys dict

		public fnDone(rpcresp:RpcResponse): void
		
		Returns: A dictionary with te following fields:
			'user': {'userkey': strUserKey, 'tokencookie': strTokenCookie, 'username': strUserName, 'userid': strUserId}
			'attributes' : [results of calling get attributes for this user]
			'clientKeys' : dictionary of client keys (returned if fClientConnect is passed in as True)
		*/
		public static function LogIn(obParameters:Object, fRetry:Boolean, fnDone:Function): void {
			// log in version 2 returns an error code rather than an exception for expected errors (not exceptions). For example, bad password.
			obParameters.version = 2;
			
			// All methods currently fail. Instead of failing, return a random dummy user
			// CallMethod("user.login", obParameters, fnDone, true, fRetry);
			
			var rpcresp:RpcResponse = new RpcResponse("user.login", PicnikService.errNone, null, {
				user: {userkey: RandomAlphaNum(), tokencookie: RandomAlphaNum(), username: RandomAlphaNum(), userid: RandomAlphaNum()},
				attributes: {},
				clientKeys: {}
			});
			PicnikBase.app.callLater(fnDone, [rpcresp]);
		}
		
		private static function RandomAlphaNum(nDigits:Number=12): String {
			var str:String = "";
			while (str.length < nDigits) {
				var iRand:Number = Math.min(26+26+10, Math.floor(Math.random() * (26+26+10)));
				if (iRand < 26)
					str += String.fromCharCode('a'.charCodeAt(0) + iRand);
				else if (iRand < (26 + 26))
					str += String.fromCharCode('A'.charCodeAt(0) + iRand-26);
				else 
					str += String.fromCharCode('0'.charCodeAt(0) + iRand-26-26);
			}
			return str;
		}
				
		/*
		Function: TestCredentials
		
		Args:
		obCredentials: a dictionary
			See LogIn doc string for supported credentials.
		
		public fnDone(rpcresp:RpcResponse): void
		
		rpcresp.data: A dictionary with the following fields:
			nErrorCode: the result. likely values include:
				PicnikService.errNone: success
				PicnikService.errInvalidToken: 3rd party token is not valid
				PicnikService.errInvalidUserName: username contains invalid characters
				PicnikService.errUnknownAccount: user does not exist or password is wrong
			dLogInServices [present on success]: dictionary of service credentials this user has:
				{'picnik':True}, {'picnik':True, 'google':True}, {'google':True}, {}
			strUserId: [present on success]
			fPaid: [present on success]
			strDisplayName: [google email address or picnik username]
		*/
		public static function TestCredentials(obCredentials:Object, fnDone:Function): void {
			CallMethod("user.testcredentials", obCredentials, fnDone, true, true);
		}
		
		/*
		Function: GetGoogleCookieForUser
			Get the Google cookie value (gpc) for the current user.
			Use this to set the GPC cookie on the client after a merge.
			A Picnik + Google merge is the one time that the Google
			cookie might be out of sync with the client (e.g. merge fails).
		
		Args:
			{}: Current user is passed in automatically
		
		public fnDone(rpcresp:RpcResponse): void
		
		rpcresp.data: A dictionary with:
			strGoogleCookie: the google cookie corresponding to the current user
		*/
		public static function GetGoogleCookieForUser(fnDone:Function): void {
			CallMethod("user.getgooglecookie", {}, fnDone, true, true);
		}
		
		/*
		Function: FindByNameOrEmail
		
		Args:
		obNameOrEmail: a dictionary which contains either 'name' or 'email'
		
		Looks up a user by picnik username or email (whichever is specified).
		
		If found, returns: {'fExists':True, 'fGoogleCredentials':True/False}
		If not found, returns: {'fExists':False, 'fGoogleCredentials':False}
		
		Correctly handles 'Guest' username and email

		public fnDone(rpcresp:RpcResponse): void
		*/
		public static function FindByNameOrEmail(obNameOrEmail:Object, fnDone:Function): void {
			CallMethod("user.findbynameoremail", obNameOrEmail, fnDone, true, true);
		}
		
		/*
		Function SetUserProperties
		
		Accepts a dictionary of name: value pairs, the group they belong to and adds
		them as properties for the current user or for a user with the oOtherUserCreds login data.
		
		fnDone(rpcresp:RpcResponse): void
		*/
		public static function SetUserProperties(oProps:Object, strGroup:String, oOtherUserCreds:Object=null, fnDone:Function=null): void {
			var oOtherUser:Object = null;
			if (oOtherUserCreds != null)
				oOtherUser = {
					authservice:oOtherUserCreds['strAuthService'],
					id: oOtherUserCreds['strUserId'],
					token: escape(oOtherUserCreds['strToken'])
				};
			CallMethod("user.setproperties", {group:strGroup, props:oProps, otheruser:oOtherUser}, fnDone, PicnikRpc.kfInsecure, PicnikRpc.kfRetry);
		}

		// fnDone(rpcresp:RpcResponse): void
		public static function EchoTest(obParams:Object, fnDone:Function, fSecure:Boolean, fUseGet:Boolean): void {
			CallMethod("apidemo.echo", obParams, fnDone, fSecure, false, fUseGet);
		}
		
		// fnDone(rpcresp:RpcResponse): void
		public static function GetInspiration(fNoCache:Boolean, fnDone:Function): void {
			CallMethod("inspiration.get", {fNoCache:fNoCache}, fnDone, false, true);
		}
		
		/*
		Function AddCreditCard
		
		Adds a credit card to the user's account.
		
		fnDone(rpcresp:RpcResponse): void
		*/		
		public static function AddCreditCard(cc:CreditCard, fnDone:Function=null): void {
			
			// Called in error cases
			var fnOnError:Function = function (evt:Event): void {
				if ( fnDone != null )
					fnDone(new RpcResponse("braintree.signdata",PicnikService.errServerError, "ServerError", null));
			}
			
			// Called as a result of the signcustomerupdate REST call
			var fnOnSignCustomerResult:Function = function (rpcresp:RpcResponse): void {
				// Load the policy file
				if (rpcresp.errorCode != PicnikService.errNone) {
					fnDone( rpcresp );
					return;
				}
				
				try {	
					var strTRUrl:String = rpcresp.data.tr_url;
					var strPolicyFileUrl:String = strTRUrl.substr(0, strTRUrl.lastIndexOf('/')) + "/crossdomain.xml";
					flash.system.Security.loadPolicyFile(strPolicyFileUrl);
					
					// Setup POST vars
					var urlv:URLVariables = cc.getBrainTreeVars();
					urlv["tr_data"] = rpcresp.data.tr_data;
	
					// Launch the request to BrainTree
					var urlr:URLRequest = new URLRequest( strTRUrl );
					urlr.method = URLRequestMethod.POST;
					urlr.data = urlv
					
					var urll:URLLoader = new URLLoader();
					
					// Called once we have data from BrainTree			
					var fnOnBrainTreeResult:Function = function (evt:Event): void {
						//Server returns the auth token in the request body
						cc.strBrainTreeConfToken = evt.target.data;
						CallMethod("payment.confirmcard", {strBrainTreeConfToken: evt.target.data}, fnDone, true, false);
					}
					
					urll.addEventListener(Event.COMPLETE, fnOnBrainTreeResult);
					urll.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fnOnError);
					urll.addEventListener(IOErrorEvent.IO_ERROR, fnOnError);
					
					urll.load(urlr);
				} catch (e:Error) {
					fnDone( new RpcResponse("payment.signcustomerupdate", PicnikService.errFail, "Exception", null) );
				}
			}
			
			var obParams:Object = { country: cc.strCountry };
			if (cc.strCCId != null) {
				obParams.strCCId = cc.strCCId;
				obParams.fDefault = 'false';
			}
				
			CallMethod("payment.signcustomerupdate", obParams, fnOnSignCustomerResult, true, false );
		}
		
		
		
		/*
		Function SubscribeUser
		fnDone(rpcresp:RpcResponse): void
		*/		
		public static function SubscribeUser(cct:CreditCardTransaction, fnDone:Function=null): void {		
			// Called as a result of the signcustomerupdate REST call
			var obParams:Object = {
				    strSkuId: cct.strSkuId,
					strSource: cct.strSource,
					nAmount: cct.nAmount,
					strCountry: cct.cc.strCountry,
					strZip: cct.cc.strZip,
					strState: cct.cc.strState,
					strEmail: cct.cc.strEmail };
			
			CallMethod("payment.subscribeuser", obParams, fnDone, true, false );
		}	
		
		
		/*
		Function PurchaseGift
		fnDone(rpcresp:RpcResponse): void
		*/		
		public static function PurchaseGift(cct:CreditCardTransaction, fnDone:Function=null): void {		
			// Called as a result of the signcustomerupdate REST call
			var obParams:Object = {
	 				strSkuId: cct.strSkuId,
					strSource: cct.strSource,
					nAmount: cct.nAmount,
					strCCId: 'gift',
					strCountry: cct.cc.strCountry,
					strZip: cct.cc.strZip,
					strState: cct.cc.strState,
					strEmail: cct.cc.strEmail };
			
			CallMethod("payment.purchasegift", obParams, fnDone, true, false );
		}	

			
		/*
		Function CancelSubscription
		
		Cancels a user's subscription (via transaction id).
		
		fnDone(rpcresp:RpcResponse): void
		*/		
		public static function CancelSubscription(fnDone:Function=null): void {
			CallMethod("payment.cancelsubscription", {}, fnDone, true, false );
		}		
		
		public static function GetSubscriptionStatus(fnDone:Function=null): void {
			CallMethod("user.subscriptionstatus", {}, fnDone, true, false );
		}		
		
		public static function GetCreditCard(fnDone:Function=null): void {
			CallMethod("payment.getcard", {}, fnDone, true, false );
		}		
		
		public static function RemoveCreditCard(fnDone:Function=null): void {
			CallMethod("payment.removecards", {}, fnDone, true, false );
		}
		
		public static function CalculateTaxRate(cct:CreditCardTransaction, fnDone:Function=null): void {
			var obParams:Object = { nAmount: cct.nAmount,
				strCountry: cct.cc.strCountry,
				strZip: cct.cc.strZip,
				strState: cct.cc.strState };
			CallMethod("payment.calctax", obParams, fnDone, false, false);
		}		
		
		/*
		// fnDone(rpcresp:RpcResponse): void
		public static function FailTest(nCode:Number, strError:String, fnDone:Function): void {
			CallMethod("apidemo.fail", {nCode:nCode, strError:strError}, fnDone, false);
		}
		
		// fnDone(rpcresp:RpcResponse): void
		public static function DivideByZeroTest(fnDone:Function): void {
			CallMethod("apidemo.dividebyzero", {}, fnDone, false);
		}
		*/
		
		private static function CallMethod(strMethod:String, obParams:Object, fnDone:Function, fSecure:Boolean, fRetry:Boolean, fUseGet:Boolean=false): void {
			// NOTE: Because CookInExtraParams adds the current userkey to the parameter list, any method
			// call that invokes it should then talk to the server via https. Currently that setting is
			// controlled by a flag.
			if (PicnikConfig.secureApi)
				fSecure = true;
			PicnikService.CookInExtraParams({obParams:obParams}, true);
			
			// Choose a connection method
			// var connector:IRpcConnector = new AmfRpcConnector();
			var connector:IRpcConnector = new PicnikAmfConnector(fUseGet);
			
			var fReturned:Boolean = false;
			var nRetriesLeft:Number = fRetry ? 3 : 0;
			var msSleepBeforeRetry:Number = 300; // Grows by 3x after each pause to a total of 2700ms
						
			// Retry logic
			var fnError:Function = function(strError:String, err:Number=1 /*PicnikService.errFail*/): void {
				var strErrorLog:String = "rpc failure[" + connector.GetType() + "]: " + strMethod + ": " + strError;
				if (nRetriesLeft >= 1 && err != PicnikService.errNotYetImplemented) {
					nRetriesLeft--;
					trace(strErrorLog + ": Retrying in " + msSleepBeforeRetry + "ms");
					var tmr:Timer = new Timer(msSleepBeforeRetry, 1);
					tmr.addEventListener(TimerEvent.TIMER, function(evt:Event): void {
						connector.CallMethod(strMethod, obParams, fnSuccess, fnError, fSecure);
						tmr.stop();
					});
					tmr.start();
					msSleepBeforeRetry *= 3;
				} else {
					// Failed
					trace(strErrorLog);
					// PicnikService.Log(strErrorLog, PicnikService.knLogSeverityError);
					if (fnDone != null && !fReturned)
						fnDone(new RpcResponse(strMethod, err, strError, null));
					fReturned = true;
				}
			};
			
			var fnSuccess:Function = function(obResult:Object): void {
				try {
					if (fnDone != null && !fReturned)
						fnDone(new RpcResponse(strMethod, PicnikService.errNone, null, obResult));
					fReturned = true;
				} catch (e:Error) {
					trace("callback exception: " + strMethod + ", " + e.toString());
				}
			}
				
			connector.CallMethod(strMethod, obParams, fnSuccess, fnError, fSecure);
		}

	}
}