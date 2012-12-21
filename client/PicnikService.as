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
﻿package {
	import api.PicnikRpc;
	import api.RpcResponse;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.rpc.http.HTTPService;
	import mx.rpc.xml.SimpleXMLDecoder;
	import mx.utils.Base64Encoder;
	import mx.utils.ObjectProxy;
	import mx.utils.ObjectUtil;
	import mx.utils.URLUtil;
	
	import util.ABTest;
	import util.SecureURLLoader;
	import util.URLLogger;
	import util.UniversalTime;
	import util.UserBucketManager;
	
	public class PicnikService {
		public static const errNone:Number = 0;
		public static const errFail:Number = 1;
		public static const errFileDoesNotExist:Number = 2;
		public static const errFileExists:Number = 3;
		public static const errServerError:Number = 4;
		public static const errBadParams:Number = 5;
		public static const errPermissionViolation:Number = 6;
		public static const errInvalidXML:Number = 7;
		public static const errAuthFailed:Number = 8;
		public static const errUnknownAccount:Number = 9;
		public static const errUsernameAlreadyExists:Number = 10;
		public static const errEmailAlreadyExists:Number = 11;
		public static const errInvalidUserName:Number = 12;
		public static const errInvalidEmail:Number = 13;
		public static const errInvalidPassword:Number = 14;
		public static const errUnknownMethod:Number = 15;
		public static const errDownloadFailed:Number = 16;
		public static const errFlickrFailed:Number = 17;
		public static const errInvalidFlickrAuthToken:Number = 18;
		public static const errInvalidFlickrNSID:Number = 19;
		public static const errInvalidFlickrUsername:Number = 20;
		public static const errInvalidFlickrFullname:Number = 21;
		public static const errInvalidAuthService:Number = 22;
		public static const errFileIOError:Number = 23;
		public static const errInvalidUserNameTooShort:Number = 24;
		public static const errInvalidUserNameTooLong:Number = 25;
		public static const errInvalidUserNameBadChars:Number = 26;
		public static const errInvalidPasswordTooShort:Number = 27;
		public static const errInvalidPasswordTooLong:Number = 28;
		public static const errInvalidPasswordBadChars:Number = 29;
		public static const errInvalidToken:Number = 30;
		public static const errMissingUserName:Number = 31;
		public static const errMissingPassword:Number = 32;
		public static const errMissingEmail:Number = 33;
		public static const errMissingConfirmEmail:Number = 34;
		public static const errConfirmEmailMismatch:Number = 35;
		public static const errMissingConfirmPassword:Number = 36;
		public static const errConfirmPasswordMismatch:Number = 37;
		public static const errPostImageFailed:Number = 38;
		public static const errInvalidPermissions:Number = 39;
		public static const errPicasaWebFailed:Number = 40;
		public static const errFacebookFailed:Number = 41;
		public static const errMissingContactName:Number = 42;
		public static const errMissingSiteUrl:Number = 43;
		public static const errMissingIntendedUse:Number = 44;
		public static const errMustAgree:Number = 45;
		public static const errTransactionDeclined:Number = 46;
		public static const errTransactionError:Number = 47;
		public static const errNoPendingTransaction:Number = 48;
		public static const errUserAlreadyPaid:Number = 49;
		public static const errUserNotRegistered:Number = 50;
		public static const errMethodRequiresHTTPS:Number = 51;
		public static const errInvalidGiftCode:Number = 52;
		public static const errGiftCodeAlreadyUsed:Number = 53;
		public static const errUserNotPremium:Number = 54;
		public static const errTooManyRecipients:Number = 55;
		public static const errPhotobucketFailed:Number = 56;
		public static const errSSLLoadFailure:Number = 57;
		public static const errPayPalFailed:Number = 58;
		public static const errTinyPicFailed:Number = 59;
		public static const errBridgeOffline:Number = 60;
		public static const errPrivacyPolicy:Number = 61;
		public static const errCancelled:Number = 62;
		public static const errGoogleAccount:Number = 63; // Can't sign in to a google account using Picnik creds.
		public static const errNotYetImplemented:Number = 64;
				
		public static const errHTTPOK:Number = 200;
		
		public static const errHTTPBadRequest:Number = 400;
		public static const errHTTPUnauthorized:Number = 401;
		public static const errHTTPPaymentRequired:Number = 402;
		public static const errHTTPForbidden:Number = 403;
		public static const errHTTPNotFound:Number = 404;
		public static const errHTTPMethodNotAllowed:Number = 405;
		public static const errHTTPNotAcceptable:Number = 406;
		public static const errHTTPProxyAuthenticationRequired:Number = 407;
		public static const errHTTPRequestTimeout:Number = 408;
		public static const errHTTPConflict:Number = 409;
		public static const errHTTPGone:Number = 410;
		public static const errHTTPLengthRequired:Number = 411;
		public static const errHTTPPreconditionFailed:Number = 412;
		public static const errHTTPRequestEntityTooLarge:Number = 413;
		public static const errHTTPRequestURITooLong:Number = 414;
		public static const errHTTPUnsupportedMediaType:Number = 415;
		public static const errHTTPRequestRangeNotSatisfiable:Number = 416;
		public static const errHTTPExpectationFailed:Number = 417;
		
		public static const errHTTPInternalServerError:Number = 500;
		public static const errHTTPNotImplemented:Number = 501;
		public static const errHTTPBadGateway:Number = 502;
		public static const errHTTPServiceUnavailable:Number = 503;
		public static const errHTTPGatewayTimeout:Number = 504;
		public static const errHTTPHTTPVersionNotSupported:Number = 505;
		
		public static const errHTTPNotHTML:Number = 510;
		public static const errHTTPFormatNotSupported:Number = 511;
	
		private static const kstrNoError:String = "No Error";	
		private static const kstrRESTEndPoint:String = "/api/rest";
		private static const kstrUploadDir:String = "/upload";
		private static const kstrFileDir:String = "/file";
		
		// NOTE: don't change these values without updating the corresponding
		// constants in the server's PicnikLog class.
		public static const knLogSeverityCritical:Number = 50;
		public static const knLogSeverityError:Number = 40;
		public static const knLogSeverityWarning:Number = 30;
		public static const knLogSeverityMonitor:Number = 25;
		public static const knLogSeverityUserSegment:Number = 27;
		public static const knLogSeverityInfo:Number = 20;
		public static const knLogSeverityDebug:Number = 10;
		public static const knLogSeverityIgnore:Number = 0;
		
		// We default to logging everything
		private static var s_nLogLevel:Number = 0;
		
		private static var s_fLoggedIn:Boolean = false;
		private static var s_strLoginId:String;
		private static var s_strLoginToken:String;
		private static var s_strLoginAuthService:String;
		private static var s_fLoginPrivacyPolicyRequired:Boolean;
		private static var s_strUserId:String;
		
		private static var s_apiKey:String;
		private static var s_userKey:String;
		private static var s_userTokenCookie:String;
		private static var s_strServerURL:String = "http://localhost"; //http
		private static var s_strSServerURL:String = null; //https
		private static var s_strFileServerURL:String = null;
		private static var s_fSecureUrlLoaderForceHttps:Boolean = true;
		private static var s_secureUrlLoader:SecureURLLoader = null;

		public static function GetUserState(): Object {
			return {
				strUserKey: s_userKey, strUserId: s_strUserId,
				fLoggedIn: s_fLoggedIn, strUserTokenCookie: s_userTokenCookie,
				strAuthService: s_strLoginAuthService, strLoginId: s_strLoginId
			};
		}
		
		public static function RestoreUserState(obState:Object): void {
			if (obState == null) return;
			s_userKey = obState.strUserKey;
			s_strUserId = obState.strUserId;
			s_fLoggedIn = obState.fLoggedIn;
			s_userTokenCookie = obState.strUserTokenCookie;
		}
		
		public static function set serverURL(strServerURL:String): void {
			var strServer:String = URLUtil.getServerNameWithPort(strServerURL);
			if (strServer == "localhost")
				s_strServerURL = strServerURL;
			else
				s_strServerURL = strServerURL;
		}
		
		public static function get serverURL(): String	{
			return s_strServerURL;
		}

		public static function set sserverURL(strServerURL:String): void {
			if (strServerURL == null || !s_fSecureUrlLoaderForceHttps) {
				s_strSServerURL = strServerURL;
			} else {
				var strServer:String = URLUtil.getServerNameWithPort(strServerURL);
				s_strSServerURL = "https://" + strServer;
			}
		}		

		public static function get sserverURL(): String	{
			return s_strSServerURL;
		}
	
		public static function get secureUrlLoaderForceHttps(): Boolean {
			return s_fSecureUrlLoaderForceHttps;
		}

		public static function set secureUrlLoaderForceHttps(f:Boolean): void {
			s_fSecureUrlLoaderForceHttps = f;
		}
		
		public static function set logLevel(nLevel:Number): void {
			s_nLogLevel = nLevel;
		}
		
		public static function set fileServerURL(strFileServerURL:String): void {
			s_strFileServerURL = strFileServerURL;
		}
		
		public static function get fileServerURL(): String {
			return s_strFileServerURL;
		}

		public static function EmailGift(strSubject:String, strToName:String, strToAddr:String, strFromName:String, strFromAddr:String,
				strMessage:String, strGiftCode:String, fnDone:Function=null, fnProgress:Function=null): Boolean {
		
			var params:Object = {
				subject: strSubject, fromaddr: strFromAddr, toaddr: strToAddr, giftcode: strGiftCode
			};
			
			// These parameters are all optional
			if (strFromName)
				params.fromname = strFromName;
			if (strToName)
				params.toname = strToName;
			if (strMessage)
				params.message = strMessage;
				
			return callMethod("emailgift", null, params, true, null, fnDone, fnProgress, true);
		}
		
		public static function EmailPartyInvite(strToAddr:String, strFromName:String, strFromAddr:String, strSubject:String,
				strLocation:String, strDate:String, strTime:String, strRsvpDate:String, fnDone:Function=null, fnProgress:Function=null): Boolean {
		
			var params:Object = {
				toaddr: strToAddr,
				fromname: strFromName,
				fromaddr: strFromAddr,
				subject: strSubject,
				location: strLocation,
				date: strDate,
				time: strTime,
				rsvpdate: strRsvpDate
			};
				
			return callMethod("emailpartyinvite", null, params, true, null, fnDone, fnProgress, true);
		}
		
		public static function EmailAskForPicnik(strSubject:String, strToName:String, strToAddr:String,
				strFromName:String, strFromAddr:String, strBccAddr:String,
				strMessage:String, fnDone:Function=null, fnProgress:Function=null): Boolean {
		
			var params:Object = {
				subject: strSubject, fromaddr: strFromAddr, toaddr: strToAddr
			};
			
			// These parameters are all optional
			if (strBccAddr)
				params.bccaddr = strBccAddr;
			if (strFromName)
				params.fromname = strFromName;
			if (strToName)
				params.toname = strToName;
			if (strMessage)
				params.message = strMessage;
				
			return callMethod("emailaskforpicnik", null, params, true, null, fnDone, fnProgress, true);
		}

		public static function ValidateGiftCode(strGiftCode:String, fAddTime:Boolean=false, fnDone:Function=null): Boolean {
			return PicnikService.callMethod("user.validategiftcode", null, { strCode:strGiftCode, fAddTime:fAddTime },
					true, _ValidateGiftCode, fnDone, null, true);
		}
		
		private static function _ValidateGiftCode(fnDone:Function, obResult:Object): void {
			if (fnDone == null)
				return;
				
			var obUser:Object = new Object();
			for (var strField:String in obResult)
				if (obResult[strField] is ObjectProxy)
					obUser[strField] = obResult[strField].value;
				
			if (obUser.fApproved) {
				try {
					var strSite:String = SafeGetProperty(obUser, "strSite", "mywebsite.com");
					Util.UrchinLogReport("/gift/accepted");
				} catch (err:Error) {
					LogException("Failed call to UrchinLogTransaction", err);
				}
			}
			
			fnDone(0, (obUser.fApproved == true) ? kstrNoError : "Error", obUser);
		}

		
		private static function SafeGetProperty(ob:Object, strProp:String, obDefault:*=undefined): * {
			if (strProp in ob) {
				if (ob[strProp] is String)
					return String(ob[strProp]).toLowerCase();
				else
					return ob[strProp];				
			} else {
				return obDefault;
			}
		}

		/*
		Function: CreateUser
		
		public fnDone(err:Number strError:String): void
		*/
		
		/*
		Not called by anyone. Don't expose for security reasons.
		
		public static function CreateUser(strId:String, strToken:String, strAuthService:String="Picnik",
				obServiceSpecificFields:Object=null, fnDone:Function=null): Boolean {
			var params:Object = { id: strId, token: strToken, authservice: strAuthService };
			
			// Incorporate any auth service-specific fields into the CreateUser parameters
			if (obServiceSpecificFields)
				for (var strKey:String in obServiceSpecificFields)
					if (obServiceSpecificFields[strKey] != null)
						params[strKey] = obServiceSpecificFields[strKey];

			return callMethod("user.create", null, params, true, null, fnDone, null, true);
		}
		*/
		
		/*
		Function: DeleteMyAccount
		Deletes the user that is currently logged in.
		public fnDone(err:Number strError:String): void
		*/

		public static function DeleteMyAccount(fnDone:Function=null): Boolean {
			return callMethod("user.markfordeletion", null, null, true, null, fnDone, null);
		}
		
		
		/*
		Function: RejectPrivacyPolicy
		Marks the given user as up for deletion, and sends an email to customer support as appropriate
		public fnDone(err:Number strError:String): void
		*/

		public static function RejectPrivacyPolicy(oCredentials:Object, strEmail:String, fSendArchive:Boolean, fnDone:Function=null): Boolean {	
			var params:Object = {
					email:strEmail,
					sendarchive: fSendArchive
				}
			if (oCredentials) {
				params['authservice'] = oCredentials['strAuthService'];
				params['id'] = oCredentials['strUserId'];
				params['token'] = escape(oCredentials['strToken']);
			}
			return callMethod("user.rejectprivacypolicy", null, params, true, null, fnDone, null, true /*bSecure*/);
		}
		
				
		// Saves strSessionState and returns a session ID (via the callback)
		// public fnDone(err:Number, strError:String, strSessionID:String = null): void
		public static function SaveSessionState(strSessionState:String, fnDone:Function): Boolean {
			var xml:XML = <Param name="strSessionState" value={strSessionState}/>

			return callMethod("user.savesessionstate", xml, {retriesleft:2}, true,
				_SaveSessionState, fnDone, null, true);
		}
		
		public static function _SaveSessionState(fnDone:Function, obResult:Object): void {
			if (fnDone == null) return;
			var strSessionId:String = null;
			if ('strSessionId' in obResult) {
				if (obResult['strSessionId'] is ObjectProxy)
					strSessionId = obResult['strSessionId'].value;
				else
					strSessionId = obResult.strSessionId;
			}
			if (!strSessionId || strSessionId.length == 0)
				fnDone(PicnikService.errFail, 'error');
			else
				fnDone(PicnikService.errNone, kstrNoError, strSessionId);
		}

		/*
		DEPRECATED: Please use PicnikRpc.GetUserProperties() instead.
		This function should be removed as soon as we have time to clean up call references.
		
		Function: GetUserProperties
		
		Returns a dictionary of { group: [ { name:, value:, updated: }, ... ] }
		
		public fnDone(err:Number, strError:String, obResults:Object=null): void
		*/
		public static function GetUserProperties(strGroup:String, fnDone:Function, bSecure:Boolean=false): Boolean {
			return callMethod("user.getproperties", null, {group:strGroup, retriesleft:2}, true, fnDone,
					fnDone, null, bSecure);
		}
		
/* 		private static function UnProxy(ob:Object): Object {
			var obRet:Object = {};
			var fIsProxy:Boolean = false;
			for (var strField:String in ob) {
				if (ob[strField] is ObjectProxy) {
					fIsProxy = true;
					obRet[strField] = UnProxy(ob[strField].value);
				}
			}
			if (!fIsProxy)
				obRet = ob;
			return obRet;
		}
 */		
		private static function _GetUserProperties(fnDone:Function, obResult:Object): void {
			if (fnDone == null)
				return;
			fnDone(0, kstrNoError, obResult);
		}
				
		/*
		Function SetUserAttributes
		
		Looks for 'name', 'email', 'password', 'flickrauthtoken', 'flickr_nsid',
		'flickr_username', 'flickr_fullname'
		*/
		public static function SetUserAttributes(oUser:Object, fnDone:Function=null): Boolean {
			// HACK: xmlAttrs is overflowing the URL length limit when it is expressed as a
			// query parameter. Pass a dummy xmlPayload so the whole request (including the
			// oUser properties) will be POSTed.
			return callMethod("user.setattributes", <dummy/>, oUser, true, _SetUserAttributes, fnDone, null, true);
		}

		private static function _SetUserAttributes(fnDone:Function, obResult:Object): void {
			if (fnDone == null)
				return;
				
			var obUser:Object = new Object();
			for (var strField:String in obResult)
				if (obResult[strField] is ObjectProxy)
					obUser[strField] = obResult[strField].value;
					
			fnDone(0, kstrNoError, obUser);
		}
				
		/*
		Function: GetUserAttributes
		
		Returns all attributes for the logged in user including:
		"id", "name", "email", "password", "lastlogin", "validated", "flickrauthtoken",
		"userid", "flickr_nsid", "flickr_username", "flickr_fullname", "testkey", "perms",
		and the adhoc "xml_attrs" field
		
		public fnDone(err:Number, strError:String, strName:String, strEmail:String): void
		*/
		public static function GetUserAttributes(fnDone:Function=null): Boolean {
			return callMethod("user.getattributes", null, {retriesleft:2}, true, _GetUserAttributes,
					fnDone, null, true);
		}
		
		private static function _GetUserAttributes(fnDone:Function, obResult:Object): void {
			if (fnDone == null)
				return;
				
			var obUser:Object = new Object();
			for (var strField:String in obResult)
				if (obResult[strField] is ObjectProxy)
					obUser[strField] = obResult[strField].value;
			s_strUserId = obUser["userid"];
				
			fnDone(0, kstrNoError, obUser);
		}
		
		// BEGIN: Template Functions
		
		//'template.create'
		// If nPng2SwfQuality is not -1, it is jpeg quality (e.g. 80) to use when compression PNGs as SWFs
		public static function AddTemplate(fid:String, strTitle:String, nPng2SwfQuality:Number=-1, nSubSampling:Number=-1, fnDone:Function=null): Boolean {
			var oProps2:Object = {};
			oProps2['fid'] = fid;
			oProps2['title'] = strTitle;
			if (nPng2SwfQuality != -1) oProps2['quality'] = nPng2SwfQuality;
			if (nSubSampling != -1) oProps2['subsampling'] = nSubSampling;
			return callMethod("template.create", null, oProps2, true, null, fnDone);
		}
		
		//'template.delete'
		public static function DeleteTemplate(fid:String, fnDone:Function=null): Boolean {
			var oProps2:Object = {};
			oProps2['fid'] = fid;
			return callMethod("template.delete", null, oProps2, true, null, fnDone);
		}
		
		//'template.list'
		/*
		Function: GetTemplateList
		
		Gets the list of templates for specified cms modes (default is 'live')
		
		public function fnDone(err:Number, strError:String, adctProps:Array=null): void
		*/
		public static function GetTemplateList(astrCMSStages:Array=null, fnDone:Function=null): Boolean {
			var obParams:Object = { };
			if (astrCMSStages == null) astrCMSStages = ['live'];
			obParams['stage'] = astrCMSStages.join(',');
		
			return callMethod("template.list", null, obParams, true, _GetTemplateList, fnDone);
		}

		/*
		 Parses the returned xml into an array of prop/value dictionaries. The xml should be in the form of:
		 	<rsp stat="ok">
				<templates>
					<template nFileId="id" strMD5="md5">
						<prop name="propname">propvalue</prop>
						...
					</template>
					...
				</templates>		
	    	</rsp>
	    */
		private static function _GetTemplateList(fnDone:Function, obResult:Object): void {
			var adctProps:Array = null;
			if (obResult.templates && obResult.templates.template) {
				adctProps = new Array();
				var aobTemplates:Array = obResult.templates.template is ArrayCollection ? obResult.templates.template.toArray() : [ obResult.templates.template ];
				for each (var obTemplate:Object in aobTemplates) {
					var dctProps:Object = {};
					// TEST: 0 props, 1 props, 2 props
					var aobProps:Array = obTemplate.prop is ArrayCollection ? obTemplate.prop.toArray() : [ obTemplate.prop ];
					for each (var obProp:Object in aobProps)
						dctProps[obProp.name] = obProp.value;
					adctProps.push(dctProps);
				}
			}
			
			if (fnDone != null)
				fnDone(0, kstrNoError, adctProps);
		}
	
		//'template.setpreview'
		public static function SetTemplatePreview(fid:String, fidPreview:String, fnDone:Function=null): Boolean {
			var oProps2:Object = {};
			oProps2['fid'] = fid;
			oProps2['fidPreview'] = fidPreview;
			return callMethod("template.setpreview", null, oProps2, true, null, fnDone);
		}
		
		//'template.setstage'
		public static function SetTemplateStage(fid:String, strCMSStage:String, fnDone:Function=null): Boolean {
			var oProps2:Object = {};
			oProps2['fid'] = fid;
			oProps2['stage'] = strCMSStage;
			return callMethod("template.setstage", null, oProps2, true, null, fnDone);
		}

		//'template.setproperties'
		public static function SetTemplateProperties(oProps:Object, fid:String, fnDone:Function=null): Boolean {
			var oProps2:Object = {};
			for (var strKey:String in oProps) {
				oProps2["prop_" + strKey] = oProps[strKey];
			}
			oProps2['fid'] = fid;
			return callMethod("template.setproperties", null, oProps2, true, null, fnDone, null);
		}
		
		// END: Template Functions

/* DWM: Nobody seems to be using this
		public static function UpdateServiceAccount(strService:String, strServiceId:String, fDefault:Boolean=true, fMerge:Boolean=true, fnDone:Function=null): Boolean {
			return callMethod("user.updatesvcacct", null, {strservice:strService, strserviceid:strServiceId, fdefault:fDefault, fmerge:fMerge}, true, null, fnDone, null, true);
		}
*/

		public static function ForgotPassword(strUsernameOrEmail:String, fnDone:Function=null): Boolean {
			return callMethod("user.forgotpassword", null, {email:strUsernameOrEmail}, true, null, fnDone, null, true);
		}
		
		public static function ForgotPassword2(strUsernameOrEmail:String, fnDone:Function=null): Boolean {
			return callMethod("user.forgotpassword2", null, {email:strUsernameOrEmail}, true, null, fnDone, null, true);
		}
		
		public static function LostEmail(strOldUsernameOrEmail:String, strNewEmail:String, strLast4:String, fnDone:Function=null): Boolean {
			return callMethod("user.lostemail", null, {oldUsernameOrEmail:strOldUsernameOrEmail, newEmail:strNewEmail, last4:strLast4}, true, null, fnDone, null, true);
		}

		public static function CheckPasswordToken(strEmail:String, strToken:String, fnDone:Function=null): Boolean {				
			var params:Object = {email: strEmail, token: strToken, retriesleft:2};			
			return callMethod("user.checkpasswordtoken", null, params, false, _CheckPasswordToken, fnDone, null, true);
		}
		
		private static function _CheckPasswordToken(fnDone:Function, obResult:Object): void {
			if (fnDone != null)
				fnDone( PicnikService.errNone, kstrNoError);
		}
		
		public static function ResetPassword(strEmail:String, strToken:String, strMD5Pass:String, fnDone:Function=null): Boolean {				
			var params:Object = {email: strEmail, token: strToken, md5pass:strMD5Pass, retriesleft:2};			
			return callMethod("user.resetpassword", null, params, false, _ResetPassword, fnDone, null, true);
		}
		
		public static function _ResetPassword(fnDone:Function, obResult:Object): void {				
			if (fnDone == null)
				return;
			
			var obReturn:Object = new Object();
			for (var strField:String in obResult)
				if (obResult[strField] is ObjectProxy)
					obReturn[strField] = obResult[strField].value;

			fnDone(0, kstrNoError, obReturn);
		}
		
		public static function UserExists(oUser:Object, fnDone:Function=null): Boolean {
			return callMethod("user.userexists", null, oUser, true, _UserExists,
					fnDone, null, false);
		}
		
		private static function _UserExists(fnDone:Function, obResult:Object): void {
			if (fnDone == null)
				return;
				
			var obUser:Object = new Object();
			for (var strField:String in obResult)
				if (obResult[strField] is ObjectProxy)
					obUser[strField] = obResult[strField].value;
				
			fnDone(0, kstrNoError, obUser);
		}
		
		public static function PasswordCorrect(strMD5Password:String, fnDone:Function=null): Boolean {
			return callMethod("user.passwordcorrect", null, {password:strMD5Password}, true, _PasswordCorrect,
					fnDone, null, true);
		}
		
		private static function _PasswordCorrect(fnDone:Function, obResult:Object): void {
			if (fnDone == null)
				return;
			
			var obReturn:Object = new Object();
			for (var strField:String in obResult)
				if (obResult[strField] is ObjectProxy)
					obReturn[strField] = obResult[strField].value;

			fnDone(0, kstrNoError, obReturn);
		}

		/*
		Function: LoginGuest
		
		public fnDone(err:Number, strError:String, strUserId:String, strUserName:String, strEmail:String, md5Password:String): void
		public static function LoginGuest(strAuthService:String="Picnik", fnDone:Function=null): Boolean {
			var params:Object = { authservice: strAuthService, retriesleft:2 };

			// save for auto-relogon
			s_strLoginAuthService = strAuthService;
			
			return callMethod("user.loginguest", null, params, false, _Login, fnDone, null, true);
		}
		*/
		
		/*
		Function: UpgradeGuestUser
		
		Pass in oAccountInfo with username, md5pass, and email

		public fnDone(err:Number, strError:String, strUserName): void
		*/
		public static function UpgradeGuestUser(oAccountInfo:Object, fnDone:Function=null): Boolean {
			return callMethod("user.upgradeguest", null, oAccountInfo, true, _UpgradeGuestUser, fnDone, null, true);
		}

		// Called on the successful completion of the UpgradeGuestUser call
		private static function _UpgradeGuestUser(fnDone:Function, obResult:Object): void {
			// NOTE: This method used to be _Login() - which has been moved to PicnikRpc.
			// When we move UpgradeGuestUser to PicnikRpc, most of what happens here will go away.
			var strUserName:String = obResult.username.value;
			s_userKey = obResult.userkey.value;
			s_strUserId = obResult.userid.value;
			
			var errRet:Number = 1;
			if (s_userKey != null) {
				errRet = 0;
				s_fLoggedIn = true;
				s_userTokenCookie = obResult.tokencookie.value;
			}
					
			var fCreated:Boolean = false;
			var fOtherAccts:Boolean = false;
			if (fnDone != null)
				fnDone(errRet, kstrNoError, strUserName, fCreated, fOtherAccts);
		}

		/*
		Function: Login
		
		public fnDone(err:Number, strError:String, strUserName): void
		*/
		
		public static function InstallUser(strUserKey:String, strUserId:String, strToken:String): void {
			s_userKey = strUserKey;
			s_strUserId = strUserId;
			if (s_userKey != null) {
				s_userTokenCookie = strToken;
				s_fLoggedIn = true;
			}
		}

		public static function SetUserToken(strUserToken:String):void {
			s_userKey = strUserToken;
			s_fLoggedIn = s_userKey != null;
		}
		
		public static function GetUserToken():String {
			return s_userKey;
		}
		
		public static function GetUserId(): String {
			return s_strUserId;
		}
		
		// Used by FlashRenderer
		public static function SetUserId(strUserId:String): void {
			s_strUserId = strUserId;
		}
		
		public static function SetUserTokenCookie(strUserTokenCookie:String):void {
			s_userTokenCookie = strUserTokenCookie;
		}

		public static function GetUserTokenCookie():String {
			return s_userTokenCookie;
		}
		
		/*
		Function: Logout
		
		public fnDone(err:Number, strError:String): void
		*/
		public static function Logout2(fnDone:Function=null): Boolean {
			if (s_fLoggedIn != true)
				return false;
			s_fLoggedIn = false;
		
			var bRet:Boolean = callMethod("user.logout", null, {}, false, null, fnDone);
			s_userKey = "";
			s_userTokenCookie = null;
			return bRet;
		}
		
		/*
		Function: GetFileList
		
		Gets the list of files available to the logged on user. An array of property dictionaries
		is returned with the properties of each file, filtered by strPropFilter (if given).
		
		strQuery is of the form:
		<field><operator><value>,<field><operator><value>, etc (note this is an AND operation)
		Allowed Fields: strName, strType, dtCreated, dtModified:
		Allowed Operators: =, >, <, >=, <=, !=, LIKE
		Valued can be quoted.  Escape quotes with a backslash.
		
		strPropFilter is a comma-separated list of the desired property names
		
		public function fnDone(err:Number, strError:String, adctProps:Array=null): void
		public fnProgress(nBytesLoaded:Number, nBytesTotal:Number): void
		*/
		public static function GetFileList(strQuery:String=null, strOrderBy:String=null, strOrderDir:String=null,
				iStart:Number=0, cCount:Number=1000, strPropFilter:String=null, fIncludePending:Boolean=false,
				fnDone:Function=null, fnProgress:Function=null): Boolean {
			var obParams:Object = { start: iStart, count: cCount};
			if (strQuery)
				obParams.query = strQuery;
			if (strOrderBy)
				obParams.order_by = strOrderBy;
			if (strOrderDir)
				obParams.order_dir = strOrderDir;
			if (strPropFilter)
				obParams.prop_filter = strPropFilter;
			if (fIncludePending)
				obParams.include_pending = true;
		
			return callMethod("file.list", null, obParams, true, _GetFileList, fnDone, fnProgress);
		}
	
		/*
		 Parses the returned xml into an array of prop/value dictionaries. The xml should be in the form of:
		 	<rsp stat="ok">
				<files>
					<file nFileId="id" strMD5="md5">
						<prop name="propname">propvalue</prop>
						...
					</file>
					...
				</files>		
	    	</rsp>
	    */
		private static function _GetFileList(fnDone:Function, obResult:Object): void {
			var adctProps:Array = null;
			if (obResult.files && obResult.files.file) {
				adctProps = new Array();
				var aobFiles:Array = obResult.files.file is ArrayCollection ? obResult.files.file.toArray() : [ obResult.files.file ];
				for each (var obFile:Object in aobFiles) {
					var dctProps:Object = {};
					// TEST: 0 props, 1 props, 2 props
					var aobProps:Array = obFile.prop is ArrayCollection ? obFile.prop.toArray() : [ obFile.prop ];
					for each (var obProp:Object in aobProps)
						dctProps[obProp.name] = obProp.value;
					adctProps.push(dctProps);
				}
			}
			
			if (fnDone != null)
				fnDone(0, kstrNoError, adctProps);
		}
		
		/*
		Functions SetFileProperties, SetManyFileProperties
		Sets the properties of one or more files
		*/
		public static function SetFileProperties(dctProps:Object, fid:String, fnDone:Function=null): Boolean {
			return SetManyFileProperties(dctProps, [fid], fnDone);
		}
		
		public static function SetManyFileProperties(dctProps:Object, afid:Array, fnDone:Function=null): Boolean {
			var dctProps2:Object = {};
			for (var strKey:String in dctProps) {
				dctProps2["prop_" + strKey] = dctProps[strKey];
			}
			dctProps2.fid = afid.join(',');
			return callMethod("file.setproperties", null, dctProps2, true, null, fnDone, null);
		}
		

		/*
		Function: GetFileProperties
		
		Returns a dictionary of properties attached to the file, optionally filtered by strPropFilter.
		
		strPropFilter is a comma-separated list of the desired property names. All properties are
		returned if strPropFilter is null.
		
		public function fnDone(err:Number, strError:String, dctProps:Object=null): void
		public fnProgress(nBytesLoaded:Number, nBytesTotal:Number): void
		*/
		public static function GetFileProperties(strFid:String, strSecret:String=null, strPropFilter:String=null, fnDone:Function=null, fnProgress:Function=null): Boolean {
			var obParams:Object = { fid: strFid };
			obParams.retriesleft = 2;
			if (strPropFilter)
				obParams.prop_filter = strPropFilter;
			if (strSecret)
				obParams.secret = strSecret;
				
			return callMethod("file.getproperties", null, obParams, true, _GetFileProperties, fnDone, fnProgress);
		}
	
		/*
		 Parses the returned xml into a prop/value dictionary.
	    */
		private static function _GetFileProperties(fnDone:Function, obResult:Object): void {
			if (fnDone == null)
				return;
							
			var dctProps:Object = {};
			for (var strField:String in obResult) {
				if (obResult[strField] is ObjectProxy) {
					// The server replaces ":" with "%3B" so the SimpleXMLDecoder used by the API transport won't
					// discard file property prefixes. Here we restore the colons.
					var strValue:String = obResult[strField].value;
					strField = strField.replace(/%3B/g, ":");
					dctProps[strField] = strValue
				}
			}
			fnDone(0, kstrNoError, dctProps);
		}

		/*
		Function: CreateFile
		
		NOTE: although CreateFile appears to accept arbitrary properties only strType and fTemporary are
		currently accepted. See PicnikFileREST.py if you want to add support for additional properties.
		
		public function fnDone(err:Number, strError:String, fidCreated:String=null, strAsyncImportUrl:String=null, strSyncImportUrl:String=null, strFallbackImportUrl:String=null): void
		public fnProgress(nBytesLoaded:Number, nBytesTotal:Number): void
		*/
		public static function CreateFile(dctProperties:Object=null, fnDone:Function=null, fnProgress:Function=null): Boolean {
			var obParams:Object = dctProperties ? dctProperties : {};
			for (var strProp:String in obParams) {
				if (strProp != "strType" && strProp != "fTemporary")
					Debug.Assert(false, "CreateFile only accepts strType and fTemporary properties");
			}
			// Get really agressive about making these work.
			obParams.retriesleft = 4;
			obParams.retrydelayfactor = 333; // ms for first delay. delay doubles after each retry
			return callMethod("file.create", null, obParams, true, _CreateFile, fnDone, fnProgress);
		}
		
		private static function _CreateFile(fnDone:Function, obResult:Object): void {
			if (fnDone != null) {
				var strAsyncImportUrl:String = obResult.importurl.value;
				var strSyncImportUrl:String = obResult.importurl.value;
				var strFallbackImportUrl:String = obResult.importurl.value;
				
				try {
					strAsyncImportUrl = obResult.importurl_async.value;
				} catch (e:Error) {
					trace("Ignoring error: " + e + ", " + e.getStackTrace());
				}
				
				try {
					strSyncImportUrl = obResult.importurl_sync.value;
				} catch (e:Error) {
					trace("Ignoring error: " + e + ", " + e.getStackTrace());
				}
				
				try {
					strFallbackImportUrl = obResult.importurl_fallback.value;
				} catch (e:Error) {
					trace("Ignoring error: " + e + ", " + e.getStackTrace());
				}
				
				fnDone(0, kstrNoError, String(obResult.fid.value), strAsyncImportUrl, strSyncImportUrl, strFallbackImportUrl);
			}
		}

		/*
		Function: CreateManyFiles
		
		// aobCreated
		public function fnDone(err:Number, strError:String, aobCreated:Array=null): void
 			aobCreated is an array of nFiles objects with .fid and .importurl
 		public fnProgress(nBytesLoaded:Number, nBytesTotal:Number): void
		*/
		public static function CreateManyFiles(nFiles:int, dctProperties:Object=null, fnDone:Function=null, fnProgress:Function=null): Boolean {
			var obParams:Object = dctProperties ? dctProperties : {};
			obParams.nFiles = nFiles;
			return callMethod("file.createmany", null, obParams, true, _CreateManyFiles, fnDone, fnProgress);
		}
		
		private static function _CreateManyFiles(fnDone:Function, obResult:Object): void {
			if (fnDone != null) {
				var err:Number = 0;
				var strError:String = kstrNoError;
				var aobCreated:Array = null;
				
				try {
					// Parse the result
					aobCreated = [];
					var nFiles:Number = Number(obResult.nFiles.value);
					for (var i:Number = 0; i < nFiles; i++) {
						var obCreated:Object = {};
						obCreated.fid = obResult['fid_' + i].value;
						obCreated.importurl = obResult['importurl_' + i].value;
						aobCreated.push(obCreated);
					}
				} catch (e:Error) {
					err = PicnikService.errFail;
					strError = "Exception in _CreateManyFiles: " + e + ", " + e.getStackTrace();
					aobCreated = null;
				}
				fnDone(err, strError, aobCreated);
			}
		}
		
		/*
		Function: CloneFile
		
		public function fnDone(err:Number, strError:String, fidCreated:String=null): void
		*/
		public static function CloneFile(strFidToClone:String, dctProperties:Object=null, fnDone:Function=null): Boolean {
			var obParams:Object = dctProperties ? dctProperties : {};
			obParams['fidtoclone'] = strFidToClone;
			return callMethod("file.clone", null, obParams, true, _CloneFile, fnDone, null);
		}
		
		private static function _CloneFile(fnDone:Function, obResult:Object): void {
			if (fnDone != null) {
				fnDone(0, kstrNoError, String(obResult.fid.value));
			}
		}
		
		/*
		Function: ReadPik
		
		downloads the XML doc for this pik from the server
	
		public fnProgress(nBytesLoaded:Number, nBytesTotal:Number): void
		public fnDone(err:Number, strError:String, xml:XML): void
		*/
		public static function ReadPik(strName:String, fnDone:Function=null, fnProgress:Function=null): Boolean {
			Debug.Assert(strName != null);

			var params:Object = { name: strName };
			return callMethod("doc.get", null, params, true, _ReadPik, fnDone, fnProgress);
		}
	
		private static function _ReadPik(fnDone:Function, obResult:Object): void {
			import mx.utils.Base64Decoder;
			var strBase64CompressedPik:String = obResult.pik;
			var b64d:Base64Decoder = new Base64Decoder();
			b64d.decode(strBase64CompressedPik);
			var baCompressedPik:ByteArray = b64d.drain();
			baCompressedPik.uncompress();
			var strPik:String = baCompressedPik.toString();
			var xmlPik:XML = new XML(strPik);
			
			// also extract any metadata that's lying around.  If we find
			// some, then set it as an attribute of the xml.
			if ("updated" in obResult && "value" in obResult.updated) {
				xmlPik.@updated = obResult.updated.value;
			}
			
			if (fnDone != null)
				fnDone(0, kstrNoError, xmlPik);
		}
		
		/*
		Function: DeleteFile
		
		deletes this pik from the server
		
		public function fnDone(err:Number, strError:String)
		*/
		public static function DeleteFile(fid:String, fnDone:Function): Boolean {
			return DeleteFiles([fid], fnDone);
		}
		
		public static function DeleteFiles(afid:Array, fnDone:Function): Boolean {
			Debug.Assert(afid && fnDone != null);
			
			var params:Object = { fid: afid.join(',') };
			return callMethod("file.delete", null, params, true, null, fnDone, null);
		}	
		
		public static function DeleteFileType(strType:String, fnDone:Function): Boolean {
			return DeleteMany( "strType='" + strType + "'", fnDone);
		}
		
		public static function DeleteMany(strQuery:String, fnDone:Function): Boolean {
			Debug.Assert(strQuery && fnDone != null);
			
			var params:Object = { query: strQuery };
			return callMethod("file.deletemany", null, params, true, null, fnDone, null);
		}
	
		/*
		Function: CreateHistoryEntry
		
		public function fnDone(err:Number, strError:String)
		*/
		public static function CreateHistoryEntry(xmlPik:XML, strAssetMap:String,
				dctRenderOptions:Object, dctItemInfo:Object, strServiceId:String, baThumbnail:ByteArray,
				fnDone:Function=null, fnProgress:Function=null): Boolean {
			var obParams:Object = {
				assetmap: strAssetMap, serviceid: strServiceId, thumbnail: baThumbnail,
				retriesleft: 2
			}
			
			for (var strProp:String in dctRenderOptions)
				obParams[strProp] = dctRenderOptions[strProp];
				
			for (strProp in dctItemInfo)
				obParams["iteminfo:" + strProp] = dctItemInfo[strProp];
			obParams["iteminfo:history_serviceid"] = strServiceId;
			
			// Stamp this request with a unique id so the server can reject redundant retries
			obParams["requestid"] = Util.GetUniqueId();

			return callMethod("createhistoryentry", xmlPik, obParams, true, null, fnDone, fnProgress);
		}
	
		/*
		Function: CommitRenderHistory
		
		public function fnDone(err:Number, strError:String)
		*/
		public static function CommitRenderHistory(strPikId:String, itemInfo:ItemInfo, strServiceId:String,
				fnDone:Function=null, fnProgress:Function=null): Boolean {
			var obParams:Object = { pikid: strPikId, serviceid: strServiceId, retriesleft: 2 };
			for (var strProp:String in itemInfo)
				obParams["iteminfo:" + strProp] = itemInfo[strProp];
			obParams["iteminfo:history_serviceid"] = strServiceId;
			
			// HACK: obParams might overflow the URL length limit when it is expressed as
			// query parameters. Pass a dummy xmlPayload so the whole request (including the
			// oUser properties) will be POSTed.
			return callMethod("commitrenderhistory", <dummy/>, obParams, true, null, fnDone, fnProgress);
		}
	
		/*
		Function: SaveRenderExport
		
		public function fnDone(err:Number, strError:String, dctFileProps:Object=null)
		*/
		public static function SaveRenderExport(strFlags:String, strFid:String, strResponseFormat:String,
				dctSaveParams:Object, dctRenderParams:Object, dctExportParams:Object, dctTemplateParams:Object,
				fnDone:Function=null, fnProgress:Function=null): Boolean {

			var obParams:Object = {
				flags: strFlags,
				fid: strFid,
				saveParams: dctSaveParams,
				renderParams: dctRenderParams,
				exportParams: dctExportParams,
				templateParams: dctTemplateParams,
				retriesleft: 2
			}
			var baAMF:ByteArray = new ByteArray();
			baAMF.writeObject(obParams);
			// CONSIDER: despite rumors to the contrary, AMF strings are not compressed
			// baAMF.compress();
			var enc:Base64Encoder = new Base64Encoder();
			enc.encodeBytes(baAMF);
			var strB64:String = enc.drain();
			return callMethod("saverenderexport", <dummy/>, { amfargs: strB64 }, true, _GetFileProperties, fnDone, fnProgress);
		}
		
		/*
		Function: SendFeedback
		Send user feedback the server. Caller bundles up things like app version,
		client state, etc in the feedback message.
		public function fnDone(err:Number, strError:String)
		*/
		public static function SendFeedback(xmlMessage:XML,
				fnDone:Function=null, fnProgress:Function=null): Boolean {
			return callMethod("feedback", xmlMessage, {}, true, null, fnDone, fnProgress, true);
		}
	
		/*
		Function: GetGalleryList
		
		Gets the list of files available to the logged on user. An array of property dictionaries
		is returned with the properties of each file, filtered by strPropFilter (if given).
		
		strQuery is of the form:
		<field><operator><value>,<field><operator><value>, etc (note this is an AND operation)
		Allowed Fields: strName, strType, dtCreated, dtModified:
		Allowed Operators: =, >, <, >=, <=, !=, LIKE
		Valued can be quoted.  Escape quotes with a backslash.
		
		strPropFilter is a comma-separated list of the desired property names
		
		public function fnDone(err:Number, strError:String, adctProps:Array=null): void
		public fnProgress(nBytesLoaded:Number, nBytesTotal:Number): void
		*/
		public static function GetGalleryList(strOrderBy:String=null, strOrderDir:String=null,
				iStart:Number=0, cCount:Number=1000, strPropFilter:String=null, fIncludePending:Boolean=false,
				fnDone:Function=null, fnProgress:Function=null): Boolean {
					
			var obParams:Object = { query:"strType=s_gallery", start: iStart, count: cCount};
			if (strOrderBy)
				obParams.order_by = strOrderBy;
			if (strOrderDir)
				obParams.order_dir = strOrderDir;
			if (strPropFilter)
				obParams.prop_filter = strPropFilter;
			if (fIncludePending)
				obParams.include_pending = true;
		
			// gallery.list looks just file.list, so we can use the _GetFileList callback
			return callMethod("gallery.list", null, obParams, true, _GetFileList, fnDone, fnProgress);
		}		
		
		/*
		Functions SetGalleryProperties, SetManyGalleryProperties
		Sets the properties of one or more files
		*/
		public static function SetGalleryProperties(oProps:Object, fid:String, fnDone:Function=null): Boolean {
			return SetManyGalleryProperties(oProps, [fid], fnDone);
		}
		
		public static function SetManyGalleryProperties(oProps:Object, afid:Array, fnDone:Function=null): Boolean {
			var oProps2:Object = {};
			for (var strKey:String in oProps) {
				oProps2["prop_" + strKey] = oProps[strKey];
			}
			oProps2['fid'] = afid.join(',');
			return callMethod("gallery.setproperties", null, oProps2, true, null, fnDone, null);
		}
		

		/*
		Function: GetGalleryProperties
		
		Returns a dictionary of properties attached to the file, optionally filtered by strPropFilter.
		
		strPropFilter is a comma-separated list of the desired property names. All properties are
		returned if strPropFilter is null.
		
		public function fnDone(err:Number, strError:String, dctProps:Object=null): void
		public fnProgress(nBytesLoaded:Number, nBytesTotal:Number): void
		*/
		public static function GetGalleryProperties(strFid:String, strSecret:String=null, strPropFilter:String=null, fnDone:Function=null, fnProgress:Function=null): Boolean {
			var obParams:Object = { fid: strFid };
			obParams.retriesleft = 2;
			if (strPropFilter)
				obParams.prop_filter = strPropFilter;
			if (strSecret)
				obParams.secret = strSecret;
				
			// gallery.getproperties is the same as file.getproperties, so use _GetFileProperties callback
			return callMethod("gallery.getproperties", null, obParams, true, _GetFileProperties, fnDone, fnProgress);
		}
	
		/*
		Function: UpdateGallery
		Sends a gallery changelog to the server
		
		public function fnDone(err:Number, strErr:String, obInfo:Object): void
		*/
		public static function UpdateGallery(strId:String, strSecret:String, xml:XML, fnDone:Function=null, fnProgress:Function=null): Boolean {
			var obParams:Object = { id: strId };
			if (strSecret) obParams.secret = strSecret;
			return callMethod("gallery.update", xml, obParams, true, _UpdateGallery, fnDone, fnProgress, false);
		}
	
		private static function _UpdateGallery(fnDone:Function, obResult:Object): void {
			if (null == fnDone) return;
			
			var obInfo:Object = new Object();
			for (var strField:String in obResult)
				if (obResult[strField] is ObjectProxy)
					obInfo[strField] = obResult[strField].value;
			fnDone(0, kstrNoError, obInfo);
		}
				
		/*
		Function: DeleteGallery
		Sends a gallery delete to the server
		
		public function fnDone(err:Number, strErr:String, obInfo:Object): void
		*/
		public static function DeleteGallery(strId:String, fnDone:Function=null, fnProgress:Function=null): Boolean {
			var obParams:Object = { id: strId };
			var xml:XML = null;		// dummy payload
			return callMethod("gallery.delete", xml, obParams, true, _DeleteGallery, fnDone, fnProgress, false);
		}
	
		private static function _DeleteGallery(fnDone:Function, obResult:Object): void {
			if (null == fnDone) return;
			
			var obInfo:Object = new Object();
			for (var strField:String in obResult)
				if (obResult[strField] is ObjectProxy)
					obInfo[strField] = obResult[strField].value;
			fnDone(0, kstrNoError, obInfo);
		}
				
		/*
		Function: EmailGallery
		email the given gallery (identified by fid) to recipient(s)
		public function fnDone(err:Number, strError:String)
		*/
		public static function EmailGallery(strFid:String, strSecret:String, strToName:String, strToAddr:String, strFromName:String, strFromAddr:String,
				strBccAddr:String, strSubject:String, strMessage:String, fnDone:Function=null, fnProgress:Function=null): void {
			
			var params:Object = {
				fid: strFid,
				secret: strSecret,
				fromaddr: strFromAddr,
				toaddr: strToAddr
			};
			
			// These parameters are all optional
			if (strFromName)
				params.fromname = strFromName;
			if (strToName)
				params.toname = strToName;
			if (strMessage)
				params.message = strMessage;
			if (strSubject)
				params.subject = strSubject;
			if (strBccAddr)
				params.bccaddr = strBccAddr;
	
			callMethod("gallery.email", null, params, false, _EmailGallery, fnDone, fnProgress, false);
		}		
		
		private static function _EmailGallery(fnDone:Function, obResult:Object): void {
			fnDone(PicnikService.errNone, PicnikService.kstrNoError);
		}

		/*
		Function: RenameGallery
		Sends a gallery rename to the server
		
		public function fnDone(err:Number, strErr:String, obInfo:Object): void
		*/
		public static function RenameGallery(strId:String, strName:String, fnDone:Function=null, fnProgress:Function=null): Boolean {
			var obParams:Object = { id: strId, name: strName };
			var xml:XML = null;		// dummy payload
			return callMethod("gallery.rename", xml, obParams, true, _RenameGallery, fnDone, fnProgress, false);
		}
	
		private static function _RenameGallery(fnDone:Function, obResult:Object): void {
			if (fnDone != null)
				fnDone(0, kstrNoError);
		}
			
		/*
		Function: EmailGreeting
		email the given greeting (identified by fid) to recipient(s)
		public function fnDone(err:Number, strError:String)
		*/
		public static function EmailGreeting(strFid:String, strSecret:String, strToName:String, strToAddr:String, strFromName:String, strFromAddr:String,
											strBccAddr:String, strSubject:String, strMessage:String, fnDone:Function=null, fnProgress:Function=null): void {
			
			var params:Object = {
				fid: strFid,
				secret: strSecret,
				fromaddr: strFromAddr,
				toaddr: strToAddr
			};
			
			// These parameters are all optional
			if (strFromName)
				params.fromname = strFromName;
			if (strToName)
				params.toname = strToName;
			if (strMessage)
				params.message = strMessage;
			if (strSubject)
				params.subject = strSubject;
			if (strBccAddr)
				params.bccaddr = strBccAddr;
			
			callMethod("greeting.email", null, params, false, _EmailGreeting, fnDone, fnProgress, false);
		}		
		
		private static function _EmailGreeting(fnDone:Function, obResult:Object): void {
			fnDone(PicnikService.errNone, PicnikService.kstrNoError);
		}		
		
		/*
		* Examine a web page and return fully qualified links all the images in its IMG tags.
		* In addition, return the final, possibly redirected, fully qualified URL of the page.
		*
		* UNDONE: errXXX is returned if the URL is invalid
		* errHTTPNotHTML is returned if the URL points to something other than an HTML page
		* HTTP error codes are relayed for any HTTP errors that occur while loading the page
		*
		* public function fnDone(err:Number, strError:String, strUrl:String, astrImageUrls:Array): void
		* public fnProgress(nBytesLoaded:Number, nBytesTotal:Number): void
		*/
		public static function GetImagesFromUrl(strUrl:String, fnDone:Function=null, fnProgress:Function=null): Boolean {
			var params:Object = { url: strUrl };
			return callMethod("getimagesfromurl", null, params, true, _GetImagesFromUrl, fnDone, fnProgress);
		}
	
		/*
		 Parses the returned xml. The xml should be in the form of:
		 	<rsp stat="ok">
			<page url="http://www.mywebsite.com/" />
			<urllist count="3">
				<url url="http://www.mywebsite.com/graphics/picnik_logo.gif" />
				<url url="http://www.wherever.com/test/filename2.png" />
				...
			</urllist>		
	    	</rsp>
	    */
		private static function _GetImagesFromUrl(fnDone:Function, obResult:Object): void {
			var strPageUrl:String = obResult.page.value;
			var astrUrls:Array = new Array();
			if (obResult.urllist.count > 0)
				var aobUrls:Array;
				if (obResult.urllist.url is Array) aobUrls = obResult.urllist.url as Array;
				else if (obResult.urllist.url is ArrayCollection) aobUrls = (obResult.urllist.url as ArrayCollection).toArray();
				else if (obResult.urllist.count == 1) aobUrls = [ obResult.urllist.url ];
				for each (var obUrl:Object in aobUrls)
					astrUrls.push(obUrl.url);
			
			if (fnDone != null)
				fnDone(0, kstrNoError, strPageUrl, astrUrls);
		}

		
		/*
		Function: EchoTest
		Pass a string to the server, the server sends it back. Used for testing connections.
		
		public function fnDone(err:Number, strErr:String, obInfo:Object): void
		*/
		public static function EchoTest(strEcho:String, fnDone:Function, fSecure:Boolean, fUseGet:Boolean): Boolean {
			var obParams:Object = { strEcho: strEcho };
			var xml:XML = fUseGet ? null : <dummy/>;		// dummy payload
			var strMethod:String = fSecure ? 'echotestssl' : 'echotest';
			return callMethod(strMethod, xml, obParams, true, function(fnDone2:Function, obResult:Object): void {
				fnDone(0, kstrNoError, obResult);
			}, fnDone, null, fSecure);
		}
		
		// fnDone(): void
		public static function LogWithExtendedInfo(strMessage:String, fnDone:Function, nSeverity:Number=knLogSeverityInfo): void {
			// Try a few different test requests and add the results to the post.
			// Call this with true/true, true/false, false/true, false/false
			// fnDone(fSuccess:Boolean): void
			var fnDoEchoAmf:Function = function(fSecure:Boolean, fUseGet:Boolean, fnDone:Function): void {
				// var strEcho:String = "Echo:" + Math.random();
				var strEcho:String = "Echo:" + Math.random();
				while (strEcho.length < 500 && (!fSecure || !fUseGet))
					strEcho += Math.random();
				var dParams:Object = {'strEcho': strEcho};
				PicnikRpc.EchoTest(dParams, function(resp:RpcResponse): void {
					fnDone(!resp.isError && resp.data != null && 'strEcho' in resp.data && resp.data.strEcho == strEcho);
				}, fSecure, fUseGet);
			};
			
			var fnDoEchoRestfn:Function = function(fSecure:Boolean, fUseGet:Boolean, fnDone:Function): void {
				// fnResult(err:Number, strErr:String, obInfo:Object): void
				var strEcho:String = "Echo:" + Math.random();
				PicnikService.EchoTest(strEcho, function(err:Number, strErr:String, obInfo:Object=null): void {
					var fSuccess:Boolean = false;
					if (err == PicnikService.errNone && obInfo != null && 'strEcho' in obInfo) {
						var obEcho:Object = obInfo.strEcho;
						fSuccess = (obEcho == strEcho) || ('value' in obEcho && obEcho.value == strEcho);
					}
					fnDone(fSuccess);
				}, fSecure, fUseGet);
			};
			
			var astrType:Array = ['A', 'R'];
			var ab:Array = [true, false];
			var afnSer:Array = [];
			for each (var strType:String in astrType) {
				for each (var fSec:Boolean in ab) {
					for each (var fGet:Boolean in ab) {
						var strInfo:String = strType + (fSec?'S':'I') + (fGet?'G':'P');
						afnSer.push({info:strInfo, fn:(strType == 'A' ? fnDoEchoAmf : fnDoEchoRestfn), secure:fSec, useGet:fGet});
					}
				}
			}
			
			var astrFailed:Array = [];
			var astrWorked:Array = [];
						
			var fnGo:Function = function(): void {
				if (afnSer.length > 0) {
					var aobParams:Object = afnSer.pop();
					aobParams.fn(aobParams.secure, aobParams.useGet, function(fSuccess:Boolean): void {
						if (fSuccess)
							astrWorked.push(aobParams.info);
						else
							astrFailed.push(aobParams.info);
						fnGo();
					})
				} else {
					// All done. Log the results.
					var strExtraLog:String = " OK[" + astrWorked.join(",") + "],ER[" + astrFailed.join(",") + "]";
					strExtraLog += " " + Capabilities.version + "," + Capabilities.os;
					PicnikService.Log(strMessage + strExtraLog, nSeverity, null, function(err:Number, strError:String): void {
						fnDone();
					});
				}
			};
			
			fnGo();
		}

		// Client messages may be logged by the server out of order due to its multi-threaded
		// handling of HTTP requests. We toss in a sequence number so anyone looking at
		// client-logged messages can be certain of the order the client sent them in.
		static private var s_nSeq:Number = 0;
		
		public static function Log(strMessage:String, nSeverity:Number=knLogSeverityInfo, dctParams:Object=null,
				fnDone:Function=null, fForceLog:Boolean=false): Boolean {
			try {
				// Limit logging to the severities that are equal to or greater than the logLevel
				if (!fForceLog && nSeverity < s_nLogLevel) {
					if (fnDone != null)
						fnDone(0, kstrNoError);
					return true;
				}
				
				var dct:Object = new Object();
				for (var strKey:String in dctParams)
					dct[strKey] = dctParams[strKey];
				dct.message = strMessage + " (" + s_nSeq++ + ")";
				dct.severity = nSeverity;
				trace("Log:" + nSeverity + ": " + strMessage);
	
				return callMethod("log", null, dct, true, null, fnDone, null);
			} catch (e:Error) {
				if (fnDone != null)
					fnDone(errFail, "Client Exception: " + e);
			}
			return false;
		}
		
		public static function LogException(strMessage:String, e:Error=null, fnDone:Function=null, strExtra:String=""): Boolean {
			strMessage += "[" + e.toString() + ", " + e.getStackTrace() + "] " + strExtra;
			trace("LogException: " + strMessage);
			return PicnikService.Log( strMessage, PicnikService.knLogSeverityWarning, null, fnDone );
		}		
	
		//
		//
		//

		public static function GetTempURL(strFilename:String, obParams:Object=null, fUserKey:Boolean=true, fUserId:Boolean=false): String {
			Debug.Assert(strFilename != null);

			// is this already a url? then return it
			if (strFilename.slice(0,4).toLowerCase() == "http")
				return strFilename;
			
			var strURL:String = s_strServerURL + kstrUploadDir + "/" + strFilename;
			var obParamsCopy:Object = ObjectUtil.copy(obParams);
			if (s_apiKey)
				obParamsCopy.api_key = s_apiKey;
			if (s_strUserId && fUserId)
				obParamsCopy.uid = s_strUserId;
			
			return AppendParams(strURL, obParamsCopy, fUserKey);
		}
		
		public static function GetResizedFileURL(fid:String, nMaxSize:Number): String {
			const kanSizes:Array = [75,100,160,320,640,1280,2800];
			var strThumbExt:String = null;
			if (nMaxSize > 0) {
				for (var i:int = 0; i < kanSizes.length; i++) {
					if (kanSizes[i] >= nMaxSize) {
						strThumbExt = "thumb" + kanSizes[i];
						break;
					}
				}
			}
			return GetFileURL( fid, null, strThumbExt );
		}
		
		public static function GetFileURL(fid:String, obParams:Object=null, strRef:String=null, strSecret:String=null, fNeedsScriptAccess:Boolean=false, fCacheBuster:Boolean=false): String {
			// The FlashRenderer receives fully qualified URLs instead of fids in the passed-in asset map.
			// Instead of having all our code paths understand that we handle it here where the rubber
			// meets the road.
			if (Application.application.name == "FlashRenderer" || Application.application.name == "ClientTestRunner")
				return fid;
				
			var strServerURL:String = s_strFileServerURL ? s_strFileServerURL : s_strServerURL;
			if (fNeedsScriptAccess) strServerURL = "";
			var strURL:String = strServerURL + kstrFileDir + "/" + fid;
			
			if (strSecret != null)
				strURL += '_' + strSecret;
			if (strRef != null)
				strURL += "/" + strRef;

			if (fCacheBuster) {
				if (!obParams) {
					obParams = {};
				}
				obParams.nocache = Math.random();
			}

			if (strSecret == null)	
				strURL = AppendParams(strURL, obParams);
			
			return strURL;
		}
		
		public static function GetAssetURL(strFilePath:String, obParams:Object=null, fCacheBuster:Boolean=false): String {				
			var strServerURL:String = s_strFileServerURL ? s_strFileServerURL : s_strServerURL;
			var strURL:String = strServerURL + "/" + strFilePath;
			
			if (fCacheBuster)
				if (obParams)
					obParams.nocache = Math.random();
				else
					obParams = {nocache:Math.random()};
					
			strURL = AppendParams(strURL, obParams, false);			
			return strURL;
		}
				
		public static function AppendParams(strUrl:String, obParams:Object=null, fUserKey:Boolean=true): String {
			var paramList:Array = [];

			strUrl += strUrl.indexOf("?") == -1 ? "?" : "&";


			if (s_userKey && fUserKey) {
				paramList.push("userkey=" + s_userKey);
			}
				
			if (obParams) {
				for (var strParam:String in obParams) {
					paramList.push(escape(strParam) + "=" + encodeURIComponent(obParams[strParam]));
				}
			}

			strUrl += paramList.join("&");

			return strUrl;
		}
		
		/*
		Function: BuildBaseImageURL
		
		returns the url to the base image for this pik
		
		*/
		public static function BuildBaseImageURL(strName:String): String {
			Debug.Assert(strName != null);
			Debug.Assert(s_strUserId != null, "BuildBaseImageURL requires user to be logged in");

			// is this already a url? then return it
			if (strName.slice(0,4).toLowerCase() == "http")
				return strName;
				
			var strURL:String = s_strServerURL + '/users/' + s_strUserId + '/' + strName + ".base";
			if (s_userKey)
				strURL += '?userkey=' + s_userKey;
			
			return strURL;
		}

		/*
		Function: GetMREPhotoInfo
		
		Gets a information about the location of the last photo the user saved
		
		MREInfo {
			strId:string
			strThumbUrl:string
			strMediumUrl:string
			strOrigUrl:string
		}
		
		public function fnDone(err:Number, strError:String, dMREInfo:Object):
		*/
		
		public static function GetMREPhotoInfo( strImageId:String, strUserId:String, strSessionKey:String, fnDone:Function=null): Boolean {
			var params:Object = { 'strImageId':strImageId, 'fb_user_id': strUserId, 'fb_session_key': strSessionKey };
			return callMethod("user.getmrephotoinfo", null, params, true, _GetMREPhotoInfo, fnDone);
		}
	
		private static function _GetMREPhotoInfo(fnDone:Function, obResult:Object): void {			
			if (fnDone == null)
				return;
				
			var obInfo:Object = new Object();
			for (var strField:String in obResult)
				if (obResult[strField] is ObjectProxy)
					obInfo[strField] = obResult[strField].value;
				
			fnDone(0, kstrNoError, obInfo);
		}
		
		public static function CookInExtraParams(obCookedParams:Object, fIgnoreXMLPayload:Boolean=false): void {
			var obParams:Object = obCookedParams.obParams;
			obParams.locale = CONFIG::locale;
		}

		//--------------------------
		public static function callMethod(strMethod:String, xmlPayload:XML,
				obAdditionalArguments:Object, fRequiresSigning:Boolean, fnComplete:Function,
				fnDone:Function=null, fnProgress:Function=null, bSecure:Boolean=false): Boolean {
			
			if (fnDone != null)
				PicnikBase.app.callLater(fnDone, [PicnikService.errFail, "not implemented"]);
			return true;
		}
	}
}
