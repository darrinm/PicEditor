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
	import api.PicnikRpc;
	import api.RpcResponse;
	
	import bridges.*;
	import bridges.basket.Basket;
	
	import com.adobe.utils.StringUtil;
	// import com.earthbrowser.ebutils.MacMouseWheelHandler;
	
	import commands.Command;
	import commands.CommandMgr;
	
	import containers.ActivatableModuleLoader;
	import containers.InfoWindow;
	import containers.PageContainer;
	import containers.ResizingDialog;
	import containers.TabNavigatorPlus;
	
	import controls.Notifier;
	import controls.Tip;
	import controls.ToolTipPlus;
	
	import debug.DebugConsole;
	
	import dialogs.*;
	import dialogs.DialogContent.UserWelcome;
	import dialogs.Purchase.Balloons;
	
	import errors.InvalidBitmapError;
	
	import events.*;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.StageDisplayState;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.LocalConnection;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.system.System;
	import flash.text.Font;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import imagine.ImageDocument;
	
	import inspiration.InspirationManager;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.Canvas;
	import mx.containers.HBox;
	import mx.containers.ViewStack;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.controls.Text;
	import mx.core.Application;
	import mx.core.Container;
	import mx.core.ContainerCreationPolicy;
	import mx.core.IChildList;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	import mx.events.IndexChangedEvent;
	import mx.managers.DragManager;
	import mx.managers.ISystemManager;
	import mx.preloaders.Preloader;
	import mx.resources.ResourceBundle;
	import mx.utils.URLUtil;
	
	import overlays.helpers.Cursor;
	
	import picnik.core.Env;
	
	import urlkit.rules.UrlBrowserManager;
	import urlkit.rules.UrlRuleSet;
	
	import util.ABTest;
	import util.AdManager;
	import util.ClientEnvironment;
	import util.DynamicLocalConnection;
	import util.ExternalService;
	import util.GlobalEventManager;
	import util.GooglePlusUtil;
	import util.HelpManager;
	import util.ITabContainer;
	import util.KeyVault;
	import util.LocUtil;
	import util.ModulePreloader;
	import util.NextNavigationTracker;
	import util.PerfLogger;
	import util.TipManager;
	import util.UniversalTime;
	import util.UserBucketManager;
	import util.VersionStamp;
	import util.WelcomeTipManager;
	
	[Event(name=ActiveDocumentEvent.CHANGE, type="events.ActiveDocumentEvent")]
	
	public class PicnikBase extends mx.core.Application {
		[Embed(source="/theme/trebuchet.swf", fontName="trebuchetMS", fontStyle="normal")]
		private var _clsTrebuchet:Class;
		
		[Embed(source="/theme/trebuchetBold.swf", fontName="trebuchetMS", fontWeight="bold")]
		private var _clsTrebuchetBold:Class;

		// MXML-defined variables
		[Bindable] public var _tabn:TabNavigatorPlus;
		[Bindable] public var _vstkTabHolder:ViewStack;
		[Bindable] public var _brgcIn:PageContainer;
		[Bindable] public var _brgcOut:PageContainer;
		[Bindable] public var _btnSignOut:Button;
		[Bindable] public var _btnSignIn:Button;
		[Bindable] public var _btnMyAccount:Button;
		[Bindable] public var _btnHelp:Button;
		[Bindable] public var _btnPicnikMenu:Button;
		[Bindable] public var _btnLanguage:Button;
		[Bindable] public var _imgGlobe:Image;
		[Bindable] public var _btnSettings:Button;
		[Bindable] public var _btnUpgrade:Button;
		[Bindable] public var _btnTopUpgrade:Button;
		[Bindable] public var _btnRegister:Button;
		[Bindable] public var _dbgc:DebugConsole;
		[Bindable] public var _imgLogo:Image;
		[Bindable] public var _imgCobrand:Image;
		[Bindable] public var _ubm:UrlBrowserManager;
		[Bindable] public var _urs:UrlRuleSet;
		[Bindable] public var _canvas1:Canvas;
		[Bindable] public var _hboxButtonBar:HBox;
		[Bindable] public var _wndc:WindowControls;
		[Bindable] public var _strLongRegisterPrompt:String;
		[Bindable] public var _strShortRegisterPrompt:String;
		[Bindable] public var basket:Basket;
		[Bindable] public var _lbConnecting:Label;
		[Bindable] public var _btnSave:Button;
		[Bindable] public var _btnCancel:Button;
		[Bindable] public var _txtCancel:Text;
		[Bindable] public var _cnvFullscreen:Canvas;
		[Bindable] public var _blns:Balloons;
		[Bindable] public var _cvsEditCreate:CreativeToolsTab;
	
		[Bindable] public var showSignOutButton:Boolean = false;
		[Bindable] public var showSignInButton:Boolean = false;
		[Bindable] public var showTopUpgradeButton:Boolean = false;
		[Bindable] public var showRegisterButton:Boolean = false;
		[Bindable] public var flickrlite:Boolean = false;
		[Bindable] public var liteUI:Boolean = false;
		[Bindable] public var thirdPartyEmbedded:Boolean = false;
		[Bindable] public var instanceId:String = "";

		[Bindable] public var thirdPartyHosted:Boolean = false;
		[Bindable] public var canNavParentFrame:Boolean = true;
		[Bindable] public var singleDocMode:Boolean = false;
		[Bindable] public var multi:MultiManager;
		[Bindable] public var dialogMode:Boolean = false;
		[Bindable] public var closing:Boolean = false;
		
		[Bindable] public var _pwndPopupInfo:InfoWindow;
		[Bindable] public var freemiumModel:Boolean = false;
		[Bindable] public var allFree:Boolean = false;
		[Bindable] public var hasInBridge:Boolean = true;
		[Bindable] public var hasHomeTab:Boolean = true;
		public var inManualSerializationMode:Boolean = false; // When true, the client must call SaveApplicationState() manually.
		
		public var delaySessionSaveUntilMS:Number = 0; // Don't update the sesion until new Date().time > this number

		// Bridge IDs for use with NavigateTo()		
		public static const IN_BRIDGES_TAB:String = "_brgcIn";
		public static const EDIT_CREATE_TAB:String = "_cvsEditCreate";
		public static const OUT_BRIDGES_TAB:String = "_brgcOut";
		public static const HOME_TAB:String = "_pgcHome";
		public static const COLLAGE_TAB:String = "_cvsCollage";
		public static const GALLERY_STYLE_TAB:String = "_cvsGalleryStyle";
		public static const ADVANCED_COLLAGE_TAB:String = "_cvsAdvancedCollage";

		// UI modes. These determine which tabs are shown
		public static const kuimLite:String = "lite";		
		public static const kuimWelcome:String = "welcome";
		
		public static const kuimCollage:String = "collage";
		public static const kuimAdvancedCollage:String = "advancedcollage";
		
		public static const kuimGallery:String = "gallery";
		public static const kuimPhotoEdit:String = "edit photo";
		
		private var _fModalPopup:Boolean = false;

		// It would be nice to use the consts defined above (which ARE used to
		// index the dictionary throughout our code) but the compiler doesn't
		// seem to have access to them at this point in compilation. It doesn't
		// give any error but it doesn't initialize the object properly either.
		private static const s_dctModeTabs:Object = {
			"lite": [ "edit" ],
			"welcome": [ "home", "in" ],
			"collage": [ "home", "in", "collage" ],
			"gallery": PicnikBase.calcGalleryTabs,
			"advancedcollage": [ "home", "in", "advancedcollage" ],
			"edit photo": [ "home", "in", "edit", "out" ]
		}
		
		private static var s_obProjectTabMap:Object = null;
		
		private static function get projectTabMap(): Object {
			if (s_obProjectTabMap == null) {
				s_obProjectTabMap = {};
				s_obProjectTabMap[PicnikBase.COLLAGE_TAB] = true;
				s_obProjectTabMap[PicnikBase.GALLERY_STYLE_TAB] = true;
				s_obProjectTabMap[PicnikBase.ADVANCED_COLLAGE_TAB] = true;
			}
			return s_obProjectTabMap;
		}
		
		private static var s_obEditImageTabMap:Object = null;
		
		public static function IsGooglePlus(): Boolean {
			return GooglePlusUtil.UsingGooglePlusAPIKey(PicnikBase.app.parameters);
		}
		
		private static function get editImageTabMap(): Object {
			if (s_obEditImageTabMap == null) {
				s_obEditImageTabMap = {};
				s_obEditImageTabMap[PicnikBase.EDIT_CREATE_TAB] = true;
			}
			return s_obEditImageTabMap;
		}
		
		private static function calcGalleryTabs( gdoc:GalleryDocument ):Array {
			var aTabs:Array = [ "home", "in", "show" ];
			if (gdoc && !gdoc.isOwner)
				aTabs.splice( aTabs.indexOf("show"), 1 );
			return aTabs;			
		}
		
		public static function get DeepLink() : String {
			return PicnikBase._gstrDeepLink;
		}
		
		public static function set DeepLink(deepLink:String) : void {
			if (deepLink) {
				deepLink = deepLink.replace("/create/", "/edit/");
			}
			_gstrDeepLink = deepLink;
		}
		
		private static const knDefaultNotifyDelay:Number = 100; // Delay before starting notify transition to hidden in ms
		private var _tmrNotifyHide:Timer = null;

		public static const knAppVersion:Number = 1.0;

		private static var _app:Picnik;
		public static var isDesktop:Boolean = false;
		public static var gstrRelease:String = 'NOTSET';
		private static var _gstrDeepLink:String = null;
		public static var gfRestoreDocument:Boolean = true;
		public static var gstrSoMgrServer:String = null;  // Talk to shared objects through this URL. Useful for serving from a different url

		private var _doc:GenericDocument;
		private var _zmv:ZoomView;
		private static var s_fFirstOpenPictureSelection:Boolean = true;
		private var _ntfNotifier:Notifier = new Notifier();
		private var _bsy:IBusyDialog;
		private var _iidPollStagePresence:Number;
		private var _strUIMode:String = kuimWelcome;
		private var _fRestoringState:Boolean = false;
		
		private var _skin:PicnikSkin;
		private var _fMultiMode:Boolean = false;
		private var _external:ExternalService;
		
		private var _iidSaveState:Number;
		[Bindable] public var _pas:PicnikAsService;
  		[Bindable] [ResourceBundle("Picnik")] protected var rb:ResourceBundle;

		private var _chw:ChangeWatcher = null;
		private var _chw2:ChangeWatcher = null;
		private var _chw3:ChangeWatcher = null;

		private var _fPostUserInitFinished:Boolean = false;		
		private var _fReportedMemoryError:Boolean = false;

		private var _fCreationComplete:Boolean = false;
		private var _fSOModuleLoaded:Boolean = false;
		private var _lcs:LocalConnectionServer;
		
		private static var _dctMenuItems:Dictionary = null;

		// Speed up persistent state reads using a cache. Writes are slow and update both the cache and the shared object.
		private static var _obPersistentStateCache:Object = new Object();

		private var _ppdPreloader:PicnikPreloaderDisplay = null;
		private const knInitStates:Number = 13;

		private var _tip:Tip = null;
		
		private var env:picnik.core.Env;

		// vars for reliable popup-block detection for NavigateToURLInPopup()
		private var _tmrCheckPopupSuccess:Timer = null;
		private var _fnPopupComplete:Function = null;
		private var _lconPopupSuccess:DynamicLocalConnection = null;
		private var _fLconPopupSuccessConnected:Boolean = false;
		private var _fPopupSuccessful:Boolean = false;
		
		private var _strUrchinProxyCampaign:String = null; // Set to non-null to enable proxy urchin logging

		//
		// Initialization (not including state restoration)
		//
		
		public function PicnikBase() {
			super();
			
			Env.inst = new ClientEnvironment();
			
			try { // AIR will throw SecurityError: Error #3207: Application-sandbox content cannot access this feature.
				Security.allowDomain("www.mywebsite.com");	
				Security.allowDomain("cdn.mywebsite.com");
				Security.allowDomain("test.mywebsite.com");	
				Security.allowDomain("testcdn.mywebsite.com");	
				Security.allowDomain("local.mywebsite.com");	
				Security.allowDomain("localcdn.mywebsite.com");

				Security.allowDomain("www.gstatic.com");	
				Security.allowDomain("ssl.gstatic.com");	

				Security.allowDomain("flickr.com");
				Security.allowDomain("www.flickr.com");
				Security.allowDomain("staging.flickr.com");
				Security.allowDomain("extbeta1.flickr.com");
				Security.allowDomain("beta1.flickr.com");
				Security.allowDomain("beta2.flickr.com");
				Security.allowDomain("beta3.flickr.com");
				Security.allowDomain("l.yimg.com");
				Security.allowDomain("backstage.flickr.com");
				
				// allowDomains for Yahoo!mail.  This lets us set up callbacks from JS -> AS.
				Security.allowDomain("34p1m64sm8cr1.om.mail.yahoo.net");
				Security.allowDomain("3idpg6gsj4pb2.om.mail.yahoo.net");
				Security.allowDomain("3id9j6srjepj1.om.mail.yahoo.net");
				Security.allowDomain("3gcr1clj3acpl.om.mail.yahoo.net");

				
			} catch (err:Error) {
				// Ignore
			}
			_app = Picnik(this);
			_skin = new PicnikSkin;

			ToolTipPlus.InstallToolTipPlus();
			addEventListener(FlexEvent.PREINITIALIZE, OnPreInitialize);
			addEventListener(FlexEvent.INITIALIZE, OnInitialize);
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
//			addEventListener(StateChangeEvent.CURRENT_STATE_CHANGE, OnCurrentStateChange);

			// We don't know what kind of user this is yet
			Util.UrchinSetVar("Visitor", "indeterminate");
		}
		
		// Returns null if we are not proxying urchin requests
		// otherwise, returns the campaign name (usually an embeded site url)
		public function get urchinProxyCampaign(): String {
			var strProxyCampaign:String = _strUrchinProxyCampaign;
			if (strProxyCampaign == null && _pas != null)
				strProxyCampaign = _pas.GetServiceParameter("urchinProxyCampaign", null);

			return strProxyCampaign;
		}		

		private function UpdatePreloader(nCompleted:Number, nTotal:Number): Boolean {
			try {
				var ppldr:PicnikPreloaderDisplay = GetPreloader();
				if (ppldr && systemManager && systemManager.stage) {
					// we need to force the stageWidth because if we're
					// managing the preloader ourselves. Otherwise, IE shows a skinny window.
			 		ppldr.stageWidth = systemManager.stage.stageWidth;
					ppldr.stageHeight = systemManager.stage.stageHeight;
				}
	
				if (ppldr) ppldr.InitProgress(nCompleted, nTotal);
				if (ppldr) return true;  // Found the preloader.
			} catch (e:Error) {
				LogException("UpdatePreloader", e, true);
			}
			return false; // Couldn't find the preloader
		}
		
		private function HidePreloader(): void {
			// jump the preloader to the end so that we show the main UI			
			if (!UpdatePreloader(knInitStates, knInitStates)) {
				// Oops - couldn't find the preloader. Bail
				HandleError(PicnikService.errFail, "HidePreloader failed");
			}
		}
		
		private function GetPreloader(): PicnikPreloaderDisplay {
			if (_ppdPreloader) return _ppdPreloader;
			
			if (systemManager == null) return null;
			var chlst:IChildList = systemManager.popUpChildren;
			for (var i:Number = 0; i < chlst.numChildren; i++) {
				var pldr:Preloader = chlst.getChildAt(i) as Preloader;
				if (pldr) {
					for (var j:Number = 0; j < pldr.numChildren; j++) {
						var ppldr:PicnikPreloaderDisplay = pldr.getChildAt(j) as PicnikPreloaderDisplay;
						if (ppldr) {
							_ppdPreloader = ppldr;
							return ppldr;
						}
					}
				}
			}
			
			return null;
		}

		// "Data binding will not be able to detect assignments to "app"" when it is a public
		// static var so make it a getter function instead.
		public static function get app(): PicnikBase {
			return _app;
		}
		
		// "warning: unable to bind to property 'app' on class 'PicnikBase' (class is not an IEventDispatcher)"
		// Happens in some cases when we use the app getter above. So here is another way to do it that
		// doesn't result in runtime warnings.
		public static function GetApp(): PicnikBase {
			return _app;
		}

		public static function getVersionStamp():String {
			return VersionStamp.getVersionStamp();
		}

		public static function StaticSource(oSource:Object): Object {
			var strPath:String = oSource as String;
			if (null == strPath || 0 == strPath.length) {
				return oSource;
			}
			return StaticUrl(strPath);
		}

		public static function TextureThumbUrl(strUrl:String): String {
			var oExtRegex:Object = /(\.\w+)$/;

			if (oExtRegex.test(strUrl)) {
				return StaticUrl('../clipart/textures/' +
					strUrl.replace(oExtRegex, "_thumb$1"));
			}

			// there was no obvious extension, just tack it on in the back
			return StaticUrl('../clipart/textures/' + strUrl + "_thumb");
		}
		
		/// Given a relative path, construct a CDN URL
		private static var cdnRoot:String = null;
		
		public static function MakeCDNUrl(strPath:String):String {
			if (strPath.indexOf("../") == 0) {
				strPath = strPath.slice(2);
			}
			return CDNRoot + strPath;
		}
		
		public static function get CDNRoot() : String {
			// This method gets called before PicnikBase has been fully initialized,
			// and so its loaderInfo isn't set. But the preloader has already figured out
			// our appRoot (www.gstatic.com/picnik/app, for example). We just need to strip
			// off the "app" part.
			if (!cdnRoot) {
				cdnRoot = PicnikPreloaderDisplay.appRoot.substr(0, PicnikPreloaderDisplay.appRoot.length - 5);
			}
			return cdnRoot;
		}
		
		public static function StaticUrl(strPath:String): String {
			if (null == strPath || 0 == strPath.length) {
				return strPath;
			}
			
			// check if we've been given a Picnik URL.  If so, then add a REL param
			var strPathLC:String = strPath.toLowerCase();
			var fRelify:Boolean = false;
			var strPathRoot:String = "";
			if (strPathLC.indexOf('://') == -1) {
				var strPathToCheck:String = strPathLC;
				if (strPathToCheck.charAt(0) == "/") {
					strPathToCheck = strPathLC.substr(1);
				} else if (strPathToCheck.substr(0,3) == "../") {
					strPathToCheck = strPathLC.substr(3);
				}
				
				var nSlash:int = strPathToCheck.indexOf("/",1);
				var nQuest:int = strPathToCheck.indexOf("?",1);
				var nEnd:int = strPathToCheck.length;
				
				if (nSlash != -1) nEnd = nSlash;
				if (nQuest != -1 && nQuest < nSlash) nEnd = nQuest;
				strPathRoot = "/" + strPathToCheck.substring(0,nEnd);
				fRelify = true;
			} else {
				var aMatches:Array = strPathLC.match(/^.*?:\/\/(.*?)mywebsite.com(\/[^\/]*).*$/);
				if (aMatches != null && aMatches.length >= 3) {
					strPathRoot = aMatches[2];
					fRelify = true;
				}
			}
			if (fRelify) {
				// we're referencing a picnik asset, but don't relify anything in our blacklisted paths
				var aBlackList:Array = ['/file', '/proxy', '/thumbproxy'];
				if (aBlackList.indexOf(strPathRoot) != -1) {
					fRelify = false;
				}
			}
			
			if (strPathLC.indexOf("rel=") != -1) {
				fRelify = false;
			}
			
			if (fRelify) {
				// add a rel param since there isn't one already
				// note: this would probably break if a hash # is in the URL, but that's unlikely for an img url
				strPath += (strPath.indexOf("?") == -1 ) ? "?" : "&";
				strPath += "rel=" + PicnikBase.gstrRelease;
			}
			if((strPath.indexOf('://') == -1) && !IsStandaloneFlashPlayer()) {
				strPath = MakeCDNUrl(strPath);
			}
			return strPath;
		}		
		
		public static function IsStandaloneFlashPlayer(): Boolean {
			return ("http" != Application.application.url.substr(0,4).toLowerCase());
		}
		
		private function OnPreInitialize(evt:Event): void {
			UpdatePreloader(1, knInitStates);
			if (parameters["log_to_json"]) {
				PerfLogger.LogToJson(true);
			}
			var ppldr:PicnikPreloaderDisplay = GetPreloader();
			if (ppldr) {
				PerfLogger.AttemptLogPerfTimeStart("PicnikPreloader", ppldr.preloaderStartTime);
				PerfLogger.AttemptLogPerfTimeEnd("PicnikPreloader");
			}
			PerfLogger.AttemptLogPerfTimeStart("PicnikInit");
		}
		
		private function OnInitialize(evt:Event): void {
			try {
				PerfLogger.AttemptLogPerfTimeStart("OnInitialize");
				UpdatePreloader(2, knInitStates);
				//trace( (new Date()).getTime() + ": " + "PicnikBase.OnInitialize");
				
				// HACK: Work around the Flex bug that makes text disappear from modules when RSLs are used.
				// See http://stackoverflow.com/questions/1709318/why-do-flex-charts-axis-values-labels-not-show-up-when-using-runtime-share-librar
				Font.registerFont(_clsTrebuchet);
				Font.registerFont(_clsTrebuchetBold);
				
				// Pull the release number if specified.  Otherwise, use the compiled-in version stamp
				if (parameters["rel"])
					gstrRelease = parameters["rel"];
				else
					gstrRelease = PicnikBase.getVersionStamp();			
				
				if (parameters["inst"])
					instanceId = parameters["inst"];
				
				// init our launch parameters from the cmd line and from the /service call
				if (parameters["lite"] == "true") {
					// this is the signifier that we're running in flickr mode
					liteUI = true;
					thirdPartyEmbedded = true;
					thirdPartyHosted = true;
					flickrlite = true;
					_strUrchinProxyCampaign = "flickr.com";
				}

				if (parameters["embed"] == "true") {
					thirdPartyEmbedded = true;
					canNavParentFrame = false;
				}
				
				if (parameters["stateCb"]) {
					ExternalService.GetInstance().SetStateCallback(parameters["stateCb"]);
				}
				
				if (yahoomail) {
					DialogManager.PopupSecureDialogs();
					thirdPartyEmbedded = true;
					_strUrchinProxyCampaign = "mail.yahoo.com";
					canNavParentFrame = false;					
				}

				// set the userAgent via the passed in parameters
				if ("userAgent" in parameters) {
					Util.userAgent = parameters["userAgent"];
				}

				// UNDONE: fullscreen mode while in IE *and* Yahoo Mail does not work.
				// until a fix can be found, it's disabled.
				if (yahoomail && Util.IsInternetExplorer())
					_cnvFullscreen.visible = _cnvFullscreen.includeInLayout = false;
				
				// create the some managers.
				multi = new MultiManager;
				_external = new ExternalService;
	
				// Create the master ZoomView to be shared across the Adjustment
				// and Creative tools. Add it as a child to get it initialized
				// then remove it.
				_zmv = new ZoomView();
				_zmv.id = "_zmv";	// So it can be found via Util.GetChildById
				_zmv.visible = false;
				addChild(_zmv);
				removeChild(_zmv);
				
				_btnSignOut.addEventListener(MouseEvent.CLICK, OnSignOutClick);
				_btnMyAccount.addEventListener(MouseEvent.CLICK, OnMyAccountClick);
				_btnHelp.addEventListener(MouseEvent.CLICK, OnHelpClick);
				_btnPicnikMenu.addEventListener(MouseEvent.CLICK, OnPicnikMenuClick);
				_btnLanguage.addEventListener(MouseEvent.CLICK, OnLanguageClick);
				//TODO: turn on when SettingsTab is turned on:
				//_btnSettings.addEventListener(MouseEvent.CLICK, OnSettingsClick);
				_btnTopUpgrade.addEventListener(MouseEvent.CLICK, OnUpgradeClick);
				_btnSave.addEventListener(MouseEvent.CLICK, OnSaveClick);
				_txtCancel.addEventListener(TextEvent.LINK, OnCancelClick);
				_btnCancel.addEventListener(MouseEvent.CLICK, OnCancelButtonClick);		
					
				// Listen to the TabNavigator index changed events and activate/
				// deactivate its children
				_tabn.addEventListener(IndexChangedEvent.CHANGE, OnTabNavIndexChange);
				
				addEventListener(MouseEvent.ROLL_OUT, OnRollOut);
				addEventListener(MouseEvent.ROLL_OVER, OnRollOver);
				
				// The SWF can be loaded in 4 different contexts:
				// 1. within Flex (url will be "file:///<whatever>")
				// 2. a local HTML file (url is the same as above)
				// 3. a local web server (url is "http://localhost/<whatever>")
				// 4. a remote web server (url is "http://domain/<whatever>")
				// We can also pass in an explicit serverurl in the swf's parameters
	
				// We do this here because url isn't initialized until after the
				// PicnikBase constructor is called
				
				var strUrl:String = url;
				if (parameters["serverurl"])
					strUrl = parameters["serverurl"];
				
				var strProtocol:String = URLUtil.getProtocol(strUrl).toLowerCase();
				var nPort:int = URLUtil.getPort(strUrl);
				var isSecure:Boolean = URLUtil.isHttpsURL(strUrl);
				var fileServerUrl:String;
				if (strProtocol == "file")
					fileServerUrl = "http://localhost";
				else
					fileServerUrl = strProtocol + "://" + URLUtil.getServerNameWithPort(strUrl).toLowerCase();
	
				var originatingHost:String = URLUtil.getServerName(fileServerUrl);
				if (originatingHost != 'localhost' &&
					originatingHost != 'local.mywebsite.com' &&
					originatingHost != 'test.mywebsite.com' &&
					originatingHost != 'www.mywebsite.com') {
					fileServerUrl = strProtocol + '://www.mywebsite.com';
				}

				PicnikService.serverURL = fileServerUrl;
	
				// if we're loaded from an external (partner) server, we use our server for secure transactions
				var strSURL:String = URLUtil.getServerName(strUrl);
				// gstrSoMgrServer = strProtocol + "://www.mywebsite.com";
				PicnikService.sserverURL = "https://www.mywebsite.com";
	
				// if we're the desktop app, we talk to www.mywebsite.com's API when necessary
				if (strProtocol == "app") {
					PicnikService.sserverURL = "http://www.mywebsite.com"; // TODO(bsharon): why not https?
					PicnikService.serverURL = "http://www.mywebsite.com";
					// gstrSoMgrServer = null;
					
				// if we're local, we don't force secure transactions and we use our local somgr
				} else if (strProtocol == "file" || strSURL == "localhost" || (strSURL.indexOf("local.mywebsite.com") >= 0) ||
						strSURL.match(new RegExp("^10\.|^127\.","i"))) {
					PicnikService.secureUrlLoaderForceHttps = isSecure;
					PicnikService.serverURL = strProtocol + "://local.mywebsite.com";
					PicnikService.sserverURL = "https://local.mywebsite.com";
					// TODO(bsharon): alternate ports, are they used in practice, or is this dead code?
					// gstrSoMgrServer = strProtocol + "://local.mywebsite.com" + (nPort > 0 ? (":" + nPort.toString()) : "");
	
				// if we're local, we don't force secure transactions and we use our local somgr
				} else if (strSURL.indexOf("localcdn.mywebsite.com") >= 0) {
					PicnikService.secureUrlLoaderForceHttps = isSecure;
					PicnikService.serverURL = strProtocol + "://local.mywebsite.com";
					PicnikService.sserverURL = "https://local.mywebsite.com";
					// TODO(bsharon): alternate ports, are they used in practice, or is this dead code?
					// gstrSoMgrServer = strProtocol + "://local.mywebsite.com" + (nPort > 0 ? (":" + nPort.toString()) : "");
				
				// if we're loaded off the testcdn, handle it				
				} else if (strSURL.indexOf("testcdn.mywebsite.com") >= 0) {
					PicnikService.serverURL = strProtocol + "://test.mywebsite.com";
					PicnikService.sserverURL = "https://test.mywebsite.com";
					// TODO(bsharon): alternate ports, are they used in practice, or is this dead code?
					// gstrSoMgrServer = strProtocol + "://test.mywebsite.com" + (nPort > 0 ? (":" + nPort.toString()) : "");
				
				// if we're loaded off the of cdn, treat it differently from test servers (next if)
				// use www.mywebsite.com for ssl and somgr
				} else if (strSURL.match(new RegExp("cdn\\d?.mywebsite.com", "i"))) {
					PicnikService.serverURL = strProtocol + "://www.mywebsite.com";
					PicnikService.sserverURL = "https://www.mywebsite.com";
					
				// if we're loaded from one of our test, staging or release servers, we
				// use that server for secure transactions.
				} else if (strSURL.match(new RegExp("\.mywebsite.com$", "i"))) {
					PicnikService.sserverURL = "https://" + strSURL;
					// gstrSoMgrServer = strProtocol + "://" + strSURL;
				}
				
	 			// Don't log anything until after PicnikService knows where to talk to
	 			PicnikService.Log("Client started");
	
	 			// debug flag to force use of production shared object
	 			if (parameters["uselivesomgr"] == "true") {
					// gstrSoMgrServer = strProtocol + "://www.mywebsite.com";
	 			}
	 			
	 			if (thirdPartyHosted)
	 				Session.LoadSWF(FinishOnInit, null);
	 			else
	 				Session.LoadSWF(FinishOnInit, gstrSoMgrServer);
	 		} catch (e:Error) {
	 			LogException("OnInitialize", e, true);
	 		}
			PerfLogger.AttemptLogPerfTimeEnd("OnInitialize");
		}
			
		// If
		private function FinishOnInit(strError:String=null, e:Error=null):void {
			PerfLogger.AttemptLogPerfTimeStart("FinishOnInit");
			if (strError != null || e != null) {
				// Failure loading somgr. Bail
				HandleError(PicnikService.errFail, "Failed to load SOMg: " + strError, e);
				return;
			}
			
			_pas = new PicnikAsService(thirdPartyEmbedded ? parameters : null);
			_ubm = new UrlBrowserManager();
						
			// dd the OnCreate method fire before we're down with our so module load, if so fire it off		
			_fSOModuleLoaded = true;
			if (_fCreationComplete == true) {
				OnCreationComplete(null);
			}
			
			try {
				// Start a timer to keep going off until PicnikBase's stage var is initialized
				_iidPollStagePresence = setInterval(function (): void {
					if (stage) {
						clearInterval(_iidPollStagePresence);
						KeyboardShortcuts.mode = KeyboardShortcuts.EDIT;
						KeyboardShortcuts.enable = true;
						GlobalEventManager.enable = true;
						stage.stageFocusRect = false;
						/*
						try {
							if (ExternalInterface.available)
								MacMouseWheelHandler.init(stage);
						} catch (e:SecurityError) {
							// nothing -- probably not allowed to talk to the container
						}
						*/
					}
				}, 50);
				
				// Register Command handlers
				CommandMgr.Register(new Command("ToggleConsoleVisibility", ToggleConsoleVisibility));
				CommandMgr.Register(new Command("GenericDocument.Undo", DocumentUndo));
				CommandMgr.Register(new Command("GenericDocument.Redo", DocumentRedo));
				CommandMgr.Register(new Command("ImageDocument.Undo", DocumentUndo));	//backwards compatibility
				CommandMgr.Register(new Command("ImageDocument.Redo", DocumentRedo));	//backwards compatibility
				
				// Flickr will take care of loading the right localized SWF based on its
				// locale understanding so we don't want to second guess it here.
				if (canNavParentFrame) {
					// see if we've been launched with the right locale.
					// if not, we should bail and re-launch
					var strLaunchLocale:String = Session.GetPersistentClientState( "locale", CONFIG::locale );
					var fLocaleRelaunch:Boolean = Session.GetPersistentClientState( "locale.relaunch", false );
					if ('locale' in parameters && parameters['locale'].length > 0) {
						strLaunchLocale = parameters['locale'];
					}					
					if (strLaunchLocale != CONFIG::locale && !fLocaleRelaunch) {
						// redirect to soint for re-launch with the correct locale
						// also set a relaunch param so that we don't loop-de-loop	
						Session.SetPersistentClientState( "locale.relaunch", true );
						NavigateToURL(new URLRequest(gstrSoMgrServer + "/soint2?dest=/app&re=localemismatch&locale=" +strLaunchLocale));
						return;
					}
					// clear any relaunch flags that are lying around			
					Session.SetPersistentClientState( "locale.relaunch", false );
					Session.SetPersistentClientState( "locale.cookie_timestamp", false );
				}
						
				if (parameters["loglevel"])
					PicnikService.logLevel = int(parameters["loglevel"]);
				
				// Don't show the gift popup now that we have tip popups
				// _pwndPopupInfo.visible = !flickrlite && GetPersistentClientState("PicnikBase.nLastClosedPopupInfo", 0) < _pwndPopupInfo.serial;
				
				// Show Expand and Close buttons if requested
				var strWindowControlsState:String = "Fullscreen";
				if (_pas.GetServiceParameter( "lite_ui" ) == "true")			
					liteUI = true;
				if (_pas.GetServiceParameter( "_expand_button" ) == "true")			
					strWindowControlsState += "Expand";
				if (_pas.GetServiceParameter( "_close_target" ).length > 0) {			
					strWindowControlsState += "Close";
					_wndc.closeTarget = _pas.GetServiceParameter( "_close_target" ) as String;
					if (_pas.GetServiceParameter( "_host_name" ).length > 0) {	
						_wndc.closeTargetLabel = LocUtil.rbSubst('Picnik', "back_to", (_pas.GetServiceParameter( "_host_name" ) ) );
					}
				}
	
				// rename the save and cancel buttons as appropriate
				var strSaveButton:String = _pas.GetServiceParameter( "_save_button" );
				if (strSaveButton.length > 0 && _btnSave) {
					_btnSave.label = strSaveButton;
				}
				
				var strCancelButton:String = _pas.GetServiceParameter( "_cancel_button" );
				if (strCancelButton.length > 0 && _btnCancel) {
					_btnCancel.label = strCancelButton;
				}
				
				// Note that skin loading is asynchronous.
				// If "external_skin" doesn't have a value then nothing will happen.	
				skin.LoadSkin(_pas.GetServiceParameter("external_skin"));
							
				freemiumModel = _pas.freemiumModel;
				allFree = _pas.GetServiceParameter('all_free', "false") == "true";
				
				_wndc.currentState = strWindowControlsState;
				if (_pas.hideFullscreenAds) BusyDialogBase.DisableFullscreenAds();
				
				WelcomeTipManager.GetInstance().tipsDisabled = _pas.hideWelcomeTips;
				
				PicnikBase.DeepLink = _ubm.browserUrl;
				if (PicnikBase.DeepLink == "")
					PicnikBase.DeepLink = null;
				
				_chw = ChangeWatcher.watch(AccountMgr.GetInstance(), "isGuest", OnUserStateChange);
				_chw2 = ChangeWatcher.watch(AccountMgr.GetInstance(), "hasCredentials", OnUserStateChange);
				_chw3 = ChangeWatcher.watch(AccountMgr.GetInstance(), "isPremium", OnUserStateChange);
				AccountMgr.GetInstance().addEventListener(AccountEvent.USER_ID_CHANGE, OnUserChange);
				
				SetupRightClickMenu();
				InitExternalListeners();
			} catch (e:Error) {
				HandleError(0, "FininshOnInit", e);
			}
			PerfLogger.AttemptLogPerfTimeEnd("FinishOnInit");
		}
		
		protected function OnLanguageHBoxEvent(evt:MouseEvent): void {
			_btnLanguage.dispatchEvent(evt);
		}

		//
		// Right click menu code: BEGIN
		//

		// Set up a right click listener
		protected function SetupRightClickMenu(): void {
			var mnu:ContextMenu = new ContextMenu();
			mnu.hideBuiltInItems();
			contextMenu = mnu;
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, OnMenuSelect);
		}
		
		// Prepare a right click menu right before displaying it (the right mouse button was clicked)
		protected function OnMenuSelect(evt:ContextMenuEvent): void {
			var mnu:ContextMenu = evt.target as ContextMenu;

			var dob:DisplayObject = evt.mouseTarget;
			var aobRightClickMenuItems:Array = null;
			while (dob) {
				if ("rightClickMenuItems" in dob) {
					aobRightClickMenuItems = dob["rightClickMenuItems"];
					dob = null;
				} else {
					dob = dob.parent as DisplayObject;
				}
			}
			
			// Undone: Do we need to do clear the old menu? ClearCustomItems(mnu);
			if (aobRightClickMenuItems) {
				mnu.customItems = CreateCustomItems(aobRightClickMenuItems);
			} else {
				mnu.customItems = null;
			}
		}
		
		// Given an array of right click menu options, create a menu
		protected function CreateCustomItems(aobRightClickMenuItems:Array): Array {
			var amnuiMenuItems:Array = new Array();
			_dctMenuItems = new Dictionary();
			for each (var ob:Object in aobRightClickMenuItems) {
				var mnui:ContextMenuItem = new ContextMenuItem(ob.label);
				if ('separatorBefore' in ob) mnui.separatorBefore = ob.separatorBefore;
				_dctMenuItems[mnui] = ob.click;
				mnui.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function (evt:ContextMenuEvent): void {_dctMenuItems[evt.target as ContextMenuItem]();});
				amnuiMenuItems.push(mnui);
			}
			return amnuiMenuItems;
		}
		
		// Sample right click menu item getter. Add this to any display object to display a right click menu.
		/*
		public function get rightClickMenuItems(): Array {
			return [
				{label:'Test1', click:function(): void {trace("Test1");}},
				{label:'Test2', click:function(): void {trace("Test2");}}];
		}
		*/

		//
		// Right click menu code: END
		//

		protected function GetGreeting(strName:String): String {
			if (strName && strName.length > 0 && strName.toLowerCase() != "guest") {
				return mx.utils.StringUtil.substitute(Resource.getString('Picnik', '_lbGreeting_user'),strName);
			} else {
				return Resource.getString('Picnik', '_lbGreeting_guest');
			}
		}
		
		protected function GetGreetingName(strName:String):String {
			if (strName && strName.length > 0 && strName.toLowerCase() != "guest") {
				return strName;
			} else {
				return "";
			}
		}
		
//		// UNDONE: this will bite us when we localize
//		protected function OnRegisterPromptResize(evt:ResizeEvent): void {
//			var btn:Button = evt.target as Button;
//			btn.label = btn.width < 240 ? _strShortRegisterPrompt : _strLongRegisterPrompt;
//		}
		
		// Global keyboard handler for toggling the debug console on/off
		public function ToggleConsoleVisibility(): void {
			if (parameters["debug"] == "true")
				_dbgc.visible = !_dbgc.visible;
		}
		
		// UNDONE: command enablng/disabling, command queuing
		public function DocumentUndo(): void {
			var gend:GenericDocument = activeDocument as GenericDocument;
			if (gend) {
				if (gend.undoDepth > 0)
					gend.Undo();
			}
		}
		
		public function DocumentRedo(): void {
			var gend:GenericDocument = activeDocument as GenericDocument;
			if (gend) {
				if (gend.redoDepth > 0)
					gend.Redo();
			}
		}
		
		/*
		private function OnCurrentStateChange(evt:StateChangeEvent): void {
			//trace( (new Date()).getTime() + ": " + "PicnikBase.OnCurrentStateChange: " + evt.newState);
			//if (StringUtil.beginsWith(evt.newState, "Guest"))
			//	_btnRegister.addEventListener(MouseEvent.CLICK, OnRegisterClick);
		}
		*/
		
		// When the mouse leaves the flash app, make sure we remove the cursor
		private function OnRollOut(evt:MouseEvent): void {
			// ROLL_OUTs caused by leaving the app have a null relatedObject. Only clear
			// the cursor for them so as to not mess up drag-drop cursors.
			if (evt.relatedObject == null)
				Cursor.RemoveAll();
		}
		
		// When we restore a session, we want to come back to the last activated session
		private function OnActivate(evt:Event): void {
			Session.GetCurrent().OnActivate();
		}
		
		// Bring back whatever cursor we have when the mouse comes back into our app
		private function OnRollOver(evt:MouseEvent): void {
			if (Cursor.Current) Cursor.Current.Apply();
		}
		
		static private var s_fBadCredentialsLogged:Boolean = false;
		static private var s_strGoogleCookie:String = null;
		
		
		public function get thirdPartyCredentials(): Boolean {
			// Do some credential sanity checks. Of course, this is a poor substitute for
			// actually asking the third party if the credentials are good.
			if (parameters["authservice"] && parameters["token"] && parameters["userid"]) {
				var strUserIdCheck:String = String(parameters["userid"]).toLowerCase();
				
				// MySpace has been seen to pass -1 and null as a userids
				// Yahoo Mail has been seen to pass false
				if (strUserIdCheck == "null" || strUserIdCheck == "-1" || strUserIdCheck == "false" ||
					strUserIdCheck == "0" || strUserIdCheck == "none") {
					if (!s_fBadCredentialsLogged) {
						s_fBadCredentialsLogged = true;
						PicnikService.Log("bad third-party credentials, service: " + parameters["authservice"] +
							", userid: " + parameters["userid"] + ", token: " + parameters["token"],
							PicnikService.knLogSeverityWarning);
					}
					return false;
				}
				
				return true;
			}
			
			// No standard third party creds. Check the google cookie.
			try {
				var strGoogleCookie:String = ExternalInterface.call("readCookie", "gpc");
				if (strGoogleCookie != null && strGoogleCookie.length > 0) {
					s_strGoogleCookie = strGoogleCookie;
					return true;
				}
			} catch (e:Error) {
				trace("Ignoring exception reading google cookie: " + e.toString());
			}
			return false;
			
		}

		private function OnCreationComplete(evt:FlexEvent): void {
			PerfLogger.AttemptLogPerfTimeStart("OnCreationComplete");
			try {
				//Don't run before we're initialized. We'll get called again after we SO
				_fCreationComplete = true;
				if (_fSOModuleLoaded == false)
				{
					return;
				}
				
				//_lcs = new LocalConnectionServer();
				
				UpdatePreloader(3, knInitStates);
				//trace( (new Date()).getTime() + ": " + "PicnikBase.OnCreationComplete");
	
				try {
					// see if any auth is passed in via socookie, and use it and clear it
					parameters['authservice'] = Session.GetCurrent().GetSOCookie("authservice", parameters['authservice']);
					parameters['token'] = Session.GetCurrent().GetSOCookie("token", parameters['token']);
					parameters['userid'] = Session.GetCurrent().GetSOCookie("userid", parameters['userid']);
					
					// clear the auth params out when we've used them so that when users
					// sign out, we don't use them to sign back in again
					Session.GetCurrent().SetSOCookie("authservice", null, false);
					Session.GetCurrent().SetSOCookie("token", null, false);
					Session.GetCurrent().SetSOCookie("userid", null, true);
				} catch (e:Error) {
				}
				
				
					
				// Find a session to connect to
				// UNDONE: when should passed-in parameters override an existing session?
				
				var strToken:String = Session.FindTokenToReconnectTo();
				
				var aobCredentials:Array = [];
				var obCredentials:Object;
				
				if (thirdPartyCredentials) {
					aobCredentials.push(GetThirdPartyCredentials());
				}
				if (strToken) {
					aobCredentials.push(AccountMgr.GetTokenLogInCredentials(strToken));
				}
				aobCredentials.push(AccountMgr.GetGuestLogInCredentials()); // Fall back to a guest login
				var strApiKey:String = null;
				if (_pas) {
					if (_pas.apikey)
						strApiKey = _pas.apikey;
					if (_pas.GetServiceParameter("force_new_guest", "false") == "true") {
						aobCredentials = [AccountMgr.GetGuestLogInCredentials()]; // Always log in as a new guest
					}
				}
				
				AccountMgr.GetInstance().InitialLogIn(aobCredentials, GetCapabilities(), strApiKey, OnLoginComplete);
				
				// set up initial user state
				OnUserStateChange( null );
			} catch (e:Error) {
				HandleError(0, "Exception in OnCreationComplete", e);
			}
			PerfLogger.AttemptLogPerfTimeEnd("OnCreationComplete");
		}
		
		public function GetThirdPartyCredentials(): Object {
			if (s_strGoogleCookie) {
				return AccountMgr.GetGoogleLogInCredentials(s_strGoogleCookie);
			} else if (parameters["authservice"] && parameters["userid"] && parameters["token"]) {
				return AccountMgr.GetThirdPartyLogInCredentials(parameters["authservice"], parameters["userid"], parameters["token"]);
			}
			return null;
		}
		
		private function LoadExtraParams(): void {
			//trace( (new Date()).getTime() + ": " + "PicnikBase.LoadExtraParams" );			
			// OK, now we have a user who has not expired
			var strMethod:String = Session.GetCurrent().GetSOCookie("svc_method", null);
			// Import goes away when finished, so it overrules service
			if (_pas.HasImport()) {
				// If an 'import={url}' query parameter has been passed we want to head
				// straight to the WebInBridge w/o restoring any previous document the
				// user might have messing with.
				// UNDONE: WebInBridge should do this in its HandleQueryParameters
				PicnikBase.DeepLink = "/in/url";
				PicnikBase.gfRestoreDocument = false;
			} else if (strMethod == "service") {
				PicnikBase.gfRestoreDocument = PicnikBase.gfRestoreDocument && !_pas.willLoadServiceDocument;
				
				// UNDONE: This reference to "svc_page" appears to be obsolete.  We're using
				// PicnikAsService._obSvcParameters._page  to handle deep linking instead.
				var strDeepLink:String = Session.GetCurrent().GetSOCookie("svc_page", null);
				if (!strDeepLink) {
					strDeepLink = "/edit";
					Session.GetCurrent().SetSOCookie("svc_page", null);
				}
				PicnikBase.DeepLink = strDeepLink;
			}
		}

		private function LogException(strLoc:String, e:Error, fIgnored:Boolean): void {
			var strError:String = fIgnored ? "Ignored " : "";
			var strStack:String = e.getStackTrace();
			strError = "PicnikBase." + strLoc + ": " + strError + " Client Exception: " + e + ", " + ( strStack ? strStack.substr(6) : "no stack" );
			trace(strError);
			PicnikService.Log(strError, PicnikService.knLogSeverityWarning);
		}

		private function GetCapabilities(): String {
			var strCapabilities:String = "";
			try {
				// Log the client's capabilities
				strCapabilities = Capabilities.serverString;
				strCapabilities += "&build=" + escape(getVersionStamp());
				strCapabilities += "&locale=" + escape(CONFIG::locale);
				if (PicnikBase.app.stage != null) {
					strCapabilities += "&stagewidth=" + PicnikBase.app.stage.width;
					strCapabilities += "&stageheight=" + PicnikBase.app.stage.height;
				}
				strCapabilities = strCapabilities;
			} catch (e:Error) {
			}
			return strCapabilities;
		}
		
		// Strip everything from the URL this SWF was loaded from up through "Picnik"
		// and replace it with the module name. This way the module will exactly match
		// the Picnik.SWF's locale, debug/release, and release #.
		public function GetLocModuleName(strModuleName:String): String {
			// Get the Picnik.swf's URL from the systemManager because PicnikBase's url property
			// hasn't been initialized by the time this function is called.
			var strUrl:String = systemManager.loaderInfo.url;
			var ichPicnik:int = strUrl.lastIndexOf("icnik") - 1;
			var strPrefix:String = strUrl.slice(0, ichPicnik);
			var strSuffix:String = strUrl.slice(ichPicnik + 6);
			var strModuleUrl:String = strPrefix + strModuleName + strSuffix;
			return strModuleUrl;
		}
		
		// If user has successfully logged in we restore their personal state.
		private function OnLoginComplete(resp:RpcResponse): void {
			PerfLogger.AttemptLogPerfTimeStart("OnLoginComplete");
			try {
				UpdatePreloader(4, knInitStates);
				if (resp.isError) {
					// Failed to log in
					HandleError( resp.errorCode, "Unable to log in: " + resp);
					return;
				}
	
				// register an API key hit with Google Analytics
				if (_pas.apikey && _pas.apikey.length > 0)
					Util.UrchinLogReport("/api/" + _pas.apikey + "/connect" );
				LogCampaign();
				UpdatePreloader(6, knInitStates);

				// we'll get back a whole big list of keys from this call
				if (resp.data && ('clientKeys' in resp.data) && resp.data.clientKeys != null) {
					for (var k:String in resp.data.clientKeys) {
						KeyVault.GetInstance().AddKey( k, resp.data.clientKeys[k] );
					}
					
					// The server returns its idea of the current universal time in seconds.
					UniversalTime.Init(Number(resp.data.clientKeys.UTCSeconds));
				}
				
				PicnikConfig.Init();
				UpdatePreloader(9, knInitStates);
				
				LoadExtraParams();
				PostUserInit();
			
			} catch (e:Error) {
				LogException("OnLoginComplete", e, true);
				HidePreloader();
			}
			PerfLogger.AttemptLogPerfTimeEnd("OnLoginComplete");
		}
		
		private function LogCampaign(): void {
			var strUrchinInitParams:String = Session.GetCurrent().GetSOCookie("urchin_init_params", null);
			if (strUrchinInitParams == null || strUrchinInitParams.length == 0) {
				// Try reading from the host
				if (PicnikBase.app.parameters["host"]) {
					var strPartnerSite:String = PicnikBase.app.parameters["host"];
					if ((strPartnerSite.toLowerCase() != "flickr") && (strPartnerSite.toLowerCase() != "facebook")) {
						strPartnerSite = escape(strPartnerSite + ".com");
						strUrchinInitParams = "utm_source=" + escape(strPartnerSite) + "&utm_medium=api&utm_campaign=" + escape(strPartnerSite);
					}
				}
			}
			if (strUrchinInitParams != null && strUrchinInitParams.length > 0) {
				// Clear the params
				Session.GetCurrent().SetSOCookie("urchin_init_params", null);
				// And call Urchin
				try {
					ExternalInterface.call("loadHiddenPage", '/urchcamp.html?' + unescape(strUrchinInitParams));
				} catch (e:Error) {
					trace("Ignoring error in LogCampaign: " + e);
				}
			}
		}
		
		public function HandleError(err:Number, strError:String, e:Error=null): void {
			try {
				if (e != null) strError += ": " + e + ", " + e.getStackTrace();
				trace("HandleError: " + err + ", " + strError);
				PicnikService.Log("ClientInitFail: " + strError + " (" + err.toString() + ")", PicnikService.knLogSeverityError);
			} finally {
				// We stay with parameters["nonCdnServerRoot"] instead of PicnikService.serverURL just in
				// case the error occurred really early and the service was not yet fully configured.
				var strUrl:String = parameters["nonCdnServerRoot"] + "/error?err=" + strError;
				if (!NavigateToURL(new URLRequest(strUrl))) {
					
					if (flickrlite) {
						// navigation is disabled -- we should pop up a dialog
						// and then, if we can, redirect outta here
						HidePreloader();
						var strMessage:String = Resource.getString('Picnik', 'download_error');
						var dlg:EasyDialog =
							EasyDialogBase.Show(
								this,
								[Resource.getString('Picnik', 'cancel')],
								Resource.getString('Picnik', 'download_error_title'),						
								strMessage,
								function( obResult:Object ):void {
									LiteUICancel();
								}	
							);
					} else {		
						GetPreloader().DisplayError(strUrl);
					}
				}	
			}							
		}

		public function HandleSSLError(err:Error = null): void {
			// log ssl error
			var strMsg:String = "PicnikService:ReportSSLError " + "[" + err.toString() + ", " + err.getStackTrace() + "]"

			//Redirect to the SSL Help Page
			// We stay with parameters["nonCdnServerRoot"] instead of PicnikService.serverURL just in
			// case the error occurred really early and the service was not yet fully configured.
 			var strUrl:String = parameters["nonCdnServerRoot"] + "/sslerror?msg=" + encodeURIComponent(strMsg);
			if (!PicnikBase.app.NavigateToURL(new URLRequest(strUrl))) {
				// Nav is disabled. Popup a dialog so that we can open a new browser window on user click.
				GetPreloader().DisplayError(strUrl, PicnikBase.StaticUrl("../graphics/picnik_load_error2.png"));
			}
		}		

		// A guest user has just signed on as a registered user or a registered user has
		// just signed out to be a guest.
		// Handle changes to the session object (load the previous image if none is open)
		public function FinishLogOn(): void {
			//trace( (new Date()).getTime() + ": " + "PicnikBase.FinishLogOn" );			
			PerfLogger.AttemptLogPerfTimeStart("FinishLogOn");
			try {
				if (!AccountMgr.GetInstance().isGuest && !closing) {
					// Restore the previous doc if there are no docs open
					if (activeDocument == null) RestoreApplicationState();
				
					ShowWelcomeBackDialog();
					ShowMessageTips();		
					AdManager.GetInstance().LogAdCampaignEvent(AdManager.kAdCampaignEvent_Register);	
				}
				// Deactivate and reactivate the current bridge to force its OnActivate logic to execute.
				var pgc:PageContainer = _tabn.selectedChild as PageContainer;
				if (pgc && pgc.active) {
					var vstk:ViewStack = pgc._vstk;
					if (vstk) {
						var brg:Bridge = vstk.selectedChild as Bridge;
						if (brg && brg.active) {
							try {
								brg.OnDeactivate();
								brg.OnActivate();
							} catch (e:Error) {
								LogException("FinishLogOn.1", e, true);
							}
						}
					}
				}
				
				if (AccountMgr.GetInstance().isGuest) {
					// Logging in as a new guest. Go home.
					PicnikBase.DeepLink = GetDefaultLink();
					_urs.containerUrl = PicnikBase.DeepLink;
				}
			} catch (e:Error) {
				LogException("FinishLogOn.2", e, true);
			}
			PerfLogger.AttemptLogPerfTimeEnd("FinishLogOn");
		}
		
		public function GetSaveButtonTitle(fFlickrLite:Boolean, strExportTitle:String): String {
			if (fFlickrLite)
				return Resource.getString('Picnik', '_btnSaveFlickr');
			
			if (strExportTitle)
				return strExportTitle;
			
			return Resource.getString('Picnik', '_btnSave'); // Default
		}
		
		private function PostUserInit(): void {			
			PerfLogger.AttemptLogPerfTimeStart("PostUserInit");
			UpdatePreloader(10, knInitStates);
			//trace( (new Date()).getTime() + ": " + "PicnikBase.PostUserInit" );			
			// Act on any service request passed via cookies.
			// Processing is divided into two pieces: pre-UI and post-UI.  This lets us
			// control how some of the UI looks before we display it.						
			try {
				
				// we may have been asked to display a dialog immediately upon launching
				var strDialog:String = Session.GetCurrent().GetSOCookie("show_dialog", "");
				var obDialogParams:Object = Util.ObFromQueryString( Session.GetCurrent().GetSOCookie("show_dialog_params", "") );
				if (strDialog.length == 0 && 'mdlg' in parameters && parameters['mdlg'].length > 0) {
					strDialog = parameters['mdlg'];
					if (parameters['_apikey'] && parameters['_apikey'].length > 0) {
						this.AsService().apikey = parameters['_apikey'];
					}
					DialogManager.SetModalDialogMode(true);		
					for (var k:String in parameters) {
						if (parameters[k] && parameters[k].length > 0) {
							obDialogParams[k] = parameters[k];								
						}
					}	
				}
	
				if (strDialog.length > 0) {
					var fDlgShown:Boolean = DialogManager.HandleShowDialogParam(strDialog, obDialogParams);
					if (fDlgShown && DialogManager.IsModalDialogMode()) {
						currentState = "DialogMode";
						
						// give it a tiny bit of time to settle down
						var tmrHidePreloader:Timer = new Timer(300, 1);
						tmrHidePreloader.addEventListener(TimerEvent.TIMER, function(evt:Event): void {
									HidePreloader();
								});
						tmrHidePreloader.start();
						return;
					}
				}
				
				if (_pas.ProcessServiceParametersPreUI(OnProcessServiceParametersPreUIComplete)) {
					// we should hide the preloader ASAP so we can display some busy/loading UI
					HidePreloader();
				}
				
				// We don't want to act on deep links until now so we don't initialize
				// UrlKit in the usual way. Instead we initialize it here which requires
				// a bit of voodoo since it wasn't designed to be used this way.
				_ubm.applicationState = _urs;
				_ubm.initialized(document, "_ubm");
				_urs.containerUrl = PicnikBase.DeepLink;
				_urs.invalidateState();
				_ubm.creationComplete(null);
				LogNav();
				
				// report that we're ready back out to the world
				ExternalService.GetInstance().ReportState("app_loaded");

			} catch (e:Error) {
				LogException("PostUserInit", e, true);
				HidePreloader();
			}
			UpdatePreloader(11, knInitStates);
			PerfLogger.AttemptLogPerfTimeEnd("PostUserInit");
		}

		private function OnProcessServiceParametersPreUIComplete(): void {			
			//trace( (new Date()).getTime() + ": " + "PicnikBase.OnProcessServiceParametersPreUIComplete" );
			PerfLogger.AttemptLogPerfTimeStart("OnProcessServiceParametersPreUIComplete");
			var strMode:String = PicnikBase.kuimWelcome;
			
			try {
				// We update session state when we are activated.
				// Make sure we wait to do this until after we've loaded the correct sesion state.
				addEventListener(Event.ACTIVATE, OnActivate);
				
				_fPostUserInitFinished = true;
	
				// Figure out where in the user interface the user should be taken to.
				// In order of precedence (from greater to lesser):
				// 1. an import parameter (e.g. 'import={url}') was passed in the URL
				// 2. a deep link (e.g. '#/in/flickrsearch') was passed in the URL
				// 3. Picnik is being used as a service and _import or _ss parameter has been passed
				// 4. the user's last location as stored in the app SharedObject
				// 5. the default location which depends on whether the user is logged in
				//   and whether we're displaying the FlickrSubset UI.
				//
				// The first two initialize DeepLink before reaching this point so
				// we only have to handle the others if DeepLink is still uninitialized.
				if (!PicnikBase.DeepLink) {
					PicnikBase.DeepLink = Session.GetCurrent().GetDeepLink();
					if (!PicnikBase.DeepLink) {
						PicnikBase.DeepLink = GetDefaultLink();
					}
				}
				_pas.UpdateDeepLink();
				
				// Don't restore the user's previous document if Picnik is being
				// used as a service. The calling site will either pass an image
				// or will be specifying one of the in bridges as a landing page.
				gfRestoreDocument = gfRestoreDocument && !_pas.willLoadServiceDocument;
			} catch (e:Error) {
				LogException("OnProcessServiceParametersPreUIComplete.1", e, true);
			}
			
			try {
				// Sometimes, the _tabn controls get initialized early, before we even
				// get here or tell it to start creating.  Check for this and make sure
				// we do the callback properly even if init'd is true.  Note that we still
				// need to set the creationPolicy to make sure the init completes properly.
				if (!_tabn.initialized) {
					_tabn.addEventListener(FlexEvent.CREATION_COMPLETE, OnTabNavCreationComplete);
				} else {
					PicnikBase.app.callLater( OnTabNavCreationComplete, [null] );
				}				
					
				// When we are finished restoring/setting up, make sure we dispatch
				// an index changed event so that the selected tab becomes active.
				// The TabNav's creationPolicy is 'none' so the UI isn't fully initialized
				// at this point. This is a good thing because we want to hold off on that
				// initialization until we know more about the user (some components want to
				// bind to user attributes). Now that we do, we can complete UI initialization.
				_tabn.creationPolicy = ContainerCreationPolicy.AUTO;
				_tabn.createComponentsFromDescriptors();
				
			} catch (e:Error) {
				LogException("OnProcessServiceParametersPreUIComplete.2", e, true);
			}
			
			try {
				// Select the tab and subtab the deep link references. We must do this here because
				// the createComponetsFromDescriptors call above initializes the ViewStack of _tabn
				// which will force it to select tab 0, fire an IndexChangedEvent, and perform
				// unnecessary initialization if a different tab is the one deep linked to. Here we
				// set the selectedIndex to the correct tab so it will be the one initialized.
				var obDeepLink:Object = ParseDeepLink();
				if (obDeepLink.strTab) {
					for (var i:Number = 0; i < _tabn.numChildren; i++) {
						var obT:Object = _tabn.getChildAt(i);
						if (obT.urlkit == obDeepLink.strTab) {
							_tabn.selectedIndex = i;
							
							// Select the appropriate subtab index for the same reason as above
							if (obDeepLink.strSubTab) {
								var ctnr:Container = _tabn.selectedChild as Container;
								ctnr.creationPolicy = ContainerCreationPolicy.AUTO;
								ctnr.createComponentsFromDescriptors();
								
								var vstk:ViewStack = null;
								if ("_vstk" in ctnr) vstk = ctnr["_vstk"];
								if (vstk) {
									for (i = 0; i < vstk.numChildren; i++) {
										obT = vstk.getChildAt(i);
										if ("urlkit" in obT && obT.urlkit == obDeepLink.strSubTab) {
											vstk.selectedIndex = i;
											break;
										}
									}
								}
							}
							break;
						}
					}
					
					switch (obDeepLink.strTab) {
					case "collage":
						strMode = PicnikBase.kuimCollage;
						break;
						
					case "advancedcollage":
						strMode = PicnikBase.kuimAdvancedCollage;
						break;
						
					case "show":
						strMode = PicnikBase.kuimGallery;
						break;
						
					case "edit":
					case "create":
					case "edit-new":
					case "out":
						strMode = PicnikBase.kuimPhotoEdit;
						break;
					}
				}
			} catch (e:Error) {
				LogException("OnProcessServiceParametersPreUIComplete.3", e, true);
			}

			uimode = strMode;			

			_pas.ProcessServiceParametersPostUI();
			PerfLogger.AttemptLogPerfTimeEnd("OnProcessServiceParametersPreUIComplete");
		}				
		
		public function hasGoogleCreds(): Boolean {
			return s_strGoogleCookie != null;
		}

		
		// If this is a registered user and something important has happened since
		// they last logged in show them the UserWelcome dialog. The UserWelcome
		// dialog differentiates between free/premium if appropriate.
		public function ShowWelcomeBackDialog(): void {
			
			// Show the freeForAll message to all users one time
			if (PicnikConfig.freeForAll) {				
				var fnOnGetUserProperties1Billion:Function = function (err:Number, obResult:Object): void {
					if (!("misc" in obResult) || !("shown_1billion" in obResult.misc) || (obResult.misc.shown_1billion == "0")) {
						// Prevent ourselves from showing the 1 billion message more than once.
						PicnikRpc.SetUserProperties({ shown_1billion: "1" }, "misc");
						
						// Show it
						DialogManager.ShowFreeForAllSignIn("/welcome", PicnikBase.app);
					}
				}
				PicnikService.GetUserProperties("misc", fnOnGetUserProperties1Billion);
				FloatBalloons(20);				
			}
			
			// Guests don't get welcomed back. We don't even know who they are!
			if (AccountMgr.GetInstance().isGuest)
				return;
				
			// Show the privacy policy dialog as appropriate
			PrivacyPolicyManager.ShowDetourIfRequired( function( fAccepted:Boolean ): void {
					if (!fAccepted) {
						if (flickrlite) {
							ExternalInterface.call("F.picnik.its_raining", null);
						} else {
							// handle API users who might not have a welcome page
							var strCloseTarget:String = _pas.GetServiceParameter( "_close_target" ) as String;
							if (singleDocMode && strCloseTarget.length) {
								if (!PicnikBase.app.activeDocument || !PicnikBase.app.activeDocument.isDirty) {
									Session.GetCurrent().LogOut( strCloseTarget );
								} else {
									PicnikBase.app.ConfirmCancelWithChanges( function (obResult:Object): void {	
										if (obResult.success)
											Session.GetCurrent().LogOut( strCloseTarget );
									});	
								}			
							} else {
								AccountMgr.GetInstance().LogOut(null, true);
							}
						}
					} else {
						// steveler 2010-08-17: this welcome back dialog content is 18+ months old and
						// no longer relevant.  Commenting out so that PrettyDialog gets excluded from
						// the build.
						
						// Flickr lite users don't get welcomed either because they aren't getting
						// the free/premium changes yet.
						//if (flickrlite)
						//	return;
							
						/* The current UserWelcome dialog has been localized.
						// We don't have the welcome dialog translated yet. Don't show it to non-
						// English users.
						if (!IsEnglish())
							return;
						*/
							 			
						// Show the welcome message to all users the server tells us we should be
						// showing it to.
						//
						//var fnOnGetUserProperties:Function = function (err:Number, obResult:Object): void {
						//	if ("misc" in obResult) {
						//		if (obResult.misc.show_welcome_back == "1") {
						//			// Prevent ourselves from showing the welcome message more than once.
						//			PicnikRpc.SetUserProperties({ show_welcome_back: "0" }, "misc");
						//			
						//			// Show it
						//			var dlg:PrettyDialog = new PrettyDialog();
						//			ResizingDialog.Show(dlg, PicnikBase.app, dialogs.DialogContent.UserWelcome);
						//		}
						//	}												
						//}
						//PicnikService.GetUserProperties("misc", fnOnGetUserProperties);
					}
				});						
				
		}

		private function _showExpiredTip(strDate:String=null):Boolean {
			var strExpires:String = (AccountMgr.GetInstance()).GetUserAttribute('strSubscription', 'null');
			// have we already shown this dialog?
			if (strDate != null && strDate == strExpires)
				return false;
				
			// mark it so we don't see it again
			PicnikRpc.SetUserProperties({'subexpired':strExpires}, 'renewal');
			// show the expired tip
			UserMessageDialog.Show(PicnikBase.app, 'renewexpired');
			return true;
		}
		
		public function ShowMessageTips(): void {
			// If we have a message waiting for the user, display just the first one
			// and remove it from the DB
			if ((AccountMgr.GetInstance()).isExpired == false)
				return ShowOtherTips();
				
			var fnOnGetUserProperties:Function = function (err:Number, obResult:Object): void {
				// if user is an expired user then show the expired tip
				var fShow:Boolean = true;
				if ('renewal' in obResult && 'subexpired' in obResult['renewal']) {
					var strT:String = obResult['renewal']['subexpired'];
					if (!_showExpiredTip(strT)) {
						ShowOtherTips();
					}
				} else {
					_showExpiredTip();	
				}
			}
			
			PicnikService.GetUserProperties("renewal", fnOnGetUserProperties);
		}
		
//		public function ShowMessageTips(): void {
		public function ShowOtherTips(): void {
			// If we have a message waiting for the user, display just the first one
			// and remove it from the DB
			var fnOnGetUserProperties:Function = function (rpcresp:RpcResponse): void {
				// if user is an expired user then show the expired tip
				if (rpcresp.data && 'message' in rpcresp.data) {
					for (var k:String in rpcresp.data['message']) {
						var url_vars:Object = Util.ObFromQueryString(rpcresp.data['message'][k]);
						var delete_prop:Object = {}; delete_prop[k] = '';
						if (!('msg' in url_vars)) {
							PicnikRpc.SetUserProperties(delete_prop, 'message');
							continue;
						}
						if ('expires' in url_vars) {
							// if it's a SQL date, change colons to slashes so we can parse it.
							// time specifiers are disallowed
							url_vars.expires = url_vars.expires.replace(new RegExp(':', 'g'), '/');
							var now:Date = new Date();
							var expireDate:Date = new Date(url_vars.expires);
							trace("expiration: " + expireDate.toString());
							if (expireDate < now) {
								PicnikRpc.SetUserProperties(delete_prop, 'message');
								continue;
							}
						}

						UserMessageDialog.Show(PicnikBase.app, url_vars['msg']);
						PicnikRpc.SetUserProperties(delete_prop, 'message');
						break;		// only display one message
					}
				}												
			}
			PicnikRpc.GetUserProperties("message", fnOnGetUserProperties);
		}

		private static const kastrServices:Array = [
			"Photobucket", "Facebook", "PicasaWeb", "Flickr", "MyComputer"
		]
		
		public function ImagePropertyBridgeToService(strBridge:String): String {
			if (strBridge == null)
				return null;
			strBridge = strBridge.toLowerCase();
			for each (var strService:String in kastrServices)
				if (strBridge == strService.toLowerCase())
					return strService;
			return null;
		}
		
		public function GetExternalFAQ(): String {
			return ServiceManager.GetExternalFAQ(_pas.GetServiceParameter("_apikey"), Locale());
		}
		
		public function GetPreferredInBridge(): String {
			return _pas.GetServiceParameter("_default_in", GetPreferredService()) as String;
		}
		
		public function GetPreferredOutBridge(): String {
			return _pas.GetServiceParameter("_default_out", GetPreferredService()) as String;
		}
		
		public function UpdateBridges():void {
			var pgc:PageContainer = _tabn.selectedChild as PageContainer;		
			if (pgc)
				pgc.UpdatePages();
		}
		
		public function GetPreferredService(): String {
			var strService:String = null;
			var imgd:ImageDocument = _doc as ImageDocument;
			if (imgd && imgd.properties && imgd.properties./*bridge*/serviceid)
				strService = ImagePropertyBridgeToService(imgd.properties./*bridge*/serviceid);

			// If Picnik is being hosted have the host be the service
			if (strService == null)
				strService = _pas.GetServiceName();
				
			if (strService == null) {
				if (false) { // UNDONE: remove this condition when the Project sub-tab is turned on
					if (AccountMgr.GetThirdPartyAccount("Flickr").HasCredentials()) {
						strService = "Flickr";
					} else if (AccountMgr.GetThirdPartyAccount("PicasaWeb").HasCredentials()) {
						strService = "PicasaWeb";
					} else if (AccountMgr.GetThirdPartyAccount("Photobucket").HasCredentials()) {
						strService = "Photobucket";
					} else if (AccountMgr.GetThirdPartyAccount("Facebook").HasCredentials()) {
						strService = "Facebook";
					} else if (AccountMgr.GetThirdPartyAccount("Twitter").HasCredentials()) {
						strService = "Twitter";
					} else {
						strService = "MyComputer";
					}
				} else {
					strService = "projects";
				}
			}

			return strService;
		}

		// Take a deep link string (e.g. "/in/flickr") and return an object with
		// two properties, strTab (e.g. "in") and strSubTab (e.g. "flickr")
		private function ParseDeepLink(): Object {
			var ob:Object = {};
			var astr:Array = PicnikBase.DeepLink.split('/');
			if (astr.length >= 2)
				ob.strTab = astr[1];
			if (astr.length >= 3)
				ob.strSubTab = astr[2];
			return ob;
		}
		
		private function GetDefaultLink(): String {
			if (IsServiceActive())
				return ServiceManager.GetAttribute(GetPreferredService(), "_page", "/in/upload");
			else
				return "/home/welcome"; // UNDONE: What if there is no home tab?
		}
		
		public function NavigateToDefaultOutBridge(): void {
			if (_doc as GalleryDocument != null)
				NavigateTo(PicnikBase.GALLERY_STYLE_TAB, null, OutBridge.PUBLISH_ACTION);
			else
				NavigateTo(PicnikBase.OUT_BRIDGES_TAB, _brgcOut.defaultTab);
		}
		
		//
		// Public methods
		//
		
		// will only be true iff current document is a gallery doc AND we're in a mode
		// where gallery documents are disallowed, i.e. API-with-export mode.
		public function get isAGalleryInDisallowedState(): Boolean
		{
			var sto:Object = Session.GetCurrent().GetAppState();
			var isGalleryInDisallowedState:Boolean = (!PicnikConfig.galleryVisible
				&& sto != null && sto.doc != null
				&& sto.doc.strType.indexOf("GalleryDocument") != -1);
//			var isGalleryInDisallowedState:Boolean = false;
			return isGalleryInDisallowedState;
		}
		
		// We need an IndexChangedEvent to fire so we'll call OnActivate on the
		// selected tab. It won't fire naturally because TabNavigator has logic to
		// avoid firing it if the selectedIndex is unchanged or previously -1.
		// Therefore we send our own IndexChangedEvent.
		private function OnTabNavCreationComplete(evt:FlexEvent): void {
			PerfLogger.AttemptLogPerfTimeStart("OnTabNavCreationComplete");
			UpdatePreloader(12, knInitStates);
			try {
				//trace("OnTabNavCreationComplete");
				var nDebug:Number = 0; // To help isolate the cause of a hard to repro exception
				
				// We don't want to act on deep links until now so we don't initialize
				// UrlKit in the usual way. Instead we initialize it here which requires
				// a bit of voodoo since it wasn't designed to be used this way.
				_ubm.applicationState = _urs;
				nDebug = 1;
				_ubm.initialized(document, "_ubm");
				nDebug = 2;
				_urs.containerUrl = PicnikBase.DeepLink;
				nDebug = 3;
				_urs.invalidateState();
				nDebug = 4;
				_ubm.creationComplete(null);
				nDebug = 5;
				
				// Make sure we let the bridge container know that it has been initialized
				// This is because we don't receive an index changed event on the viewstack,
				// even though we just set it to something.
				var pgc:PageContainer = _tabn.selectedChild as PageContainer;
				if (pgc) pgc.selectedStartTab = true;
				nDebug = 6;
				
				// Restore the previous doc if there are no docs open. Do this BEFORE the IndexChangedEvent
				// is dispatched below so the activated tab can take into account that state restoration
				// is (or isn't) in progress.
				if (activeDocument == null && !isAGalleryInDisallowedState) {
					RestoreApplicationState();
				} else {
					// Make sure we start saving the application state (this happens inside RestoreApplicationState)
					clearInterval(_iidSaveState);
					// Save the complete application state every 2 seconds
					_iidSaveState = setInterval(SaveApplicationState, 2000);
				}
				nDebug = 7;
				
				// The event used to only fire if selectedIndex is not equal 0. Now that we
				// force the initial selectedIndex (see OnLoginComplete) it doesn't fire at
				// all. Damn you Flex!
				_tabn.dispatchEvent(new IndexChangedEvent(IndexChangedEvent.CHANGE,
						false, false, null, -1, _tabn.selectedIndex, null));
				nDebug = 8;
				
				// update the user's perfered language
				PicnikRpc.SetUserProperties({'Locale':Locale()}, "Locale");
				ShowWelcomeBackDialog();
				ShowMessageTips();
				nDebug = 9;
				
				// We're done with the FirstRun screen, reveal the main app!
				var strState:String = AccountMgr.GetInstance().isGuest ? "Guest" : "";
				strState += _pas.GetServiceParameter( "_export" ).length > 0 ? "Export" : "";
				currentState = strState;
				
				// Also show ads
				AdManager.GetInstance().Init(_pas.hideBannerAds);

				HidePreloader();
				
				// Start loading the questions so that we know if we can show a question option for a tip				
				//QuestionManager.Init();
				
				// Start loading the tips
				TipManager.Init();
				
				// Load inspiration
				InspirationManager.Load();
				
				// Delayed start help loading
				var tmrLoadHelp:Timer = new Timer(4000, 1);
				tmrLoadHelp.addEventListener(TimerEvent.TIMER, function(evt:Event): void {
							HelpManager.Init();
						});
				tmrLoadHelp.start();

				if (parameters["preload"] == "true") {
					// Higher priority numbers are loaded first
					ModulePreloader.Instance.AddModule(
						GetLocModuleName('ModCreate'), 100);
					ModulePreloader.Instance.AddModule(
						GetLocModuleName('ModDialog'), 20);
					ModulePreloader.Instance.AddModule(
						GetLocModuleName('ModAccount'), 10);
					ModulePreloader.Instance.Start();
				}

				// moved earlier DialogManager.HandleShowDialogParam();
			} catch (e:Error) {
				LogException("OnTabNavCreationComplete." + nDebug, e, false);
				HidePreloader();
				throw e;
			}
			PerfLogger.AttemptLogPerfTimeEnd("OnTabNavCreationComplete");
			PerfLogger.AttemptLogPerfTimeEnd("PicnikInit");
		}
		
		private function OnUserChange(evt:AccountEvent): void {
			if (_doc != null)
				_doc.OnUserChange();	
			DialogManager.ResetDialogs();
		}
		
		private function OnUserStateChange(evt:Event): void {
			UpdateGuestState();
			UpdateSignOutButton();
			UpdateSignInButton();
			UpdateRegisterButton();
			UpdateTopUpgradeButton();	
		}
				
		private function UpdateSignOutButton(): void {
			// don't show signout/exit if we're a third-party account
			showSignOutButton = AccountMgr.GetInstance().hasCredentials;
			if (AccountMgr.GetInstance().isGuest) {
				_btnSignOut.label = Resource.getString('Picnik', 'exit');
			}	
			else {
				_btnSignOut.label = Resource.getString("Picnik", "_btnSignOut");
			}
		}	
		
		private function UpdateSignInButton(): void {
			showSignInButton = !AccountMgr.GetInstance().hasCredentials;
		}		
		
		private function UpdateRegisterButton(): void {
			showRegisterButton = !AccountMgr.GetInstance().hasCredentials;
		}		
		
		private function UpdateTopUpgradeButton(): void {
			showTopUpgradeButton = !AccountMgr.GetInstance().isPaid;
			if (showTopUpgradeButton)
				_btnTopUpgrade.label = LocUtil.iff("Picnik", yahoomail, "GoPremium", "_btnTopUpgrade");
		}
		
		public function UpdateGuestState(): void {
			if (currentState != "FirstRun") {
				if (AccountMgr.GetInstance().isGuest) {
					// Make sure our state begins with "Guest"
					if (!StringUtil.beginsWith(currentState, "Guest")) {
						currentState = "Guest" + currentState;
					}
				} else { // Not guest
					if (StringUtil.beginsWith(currentState, "Guest")) {
						currentState = currentState.substr("Guest".length);
					}
				}
			}
		}
		
		public function NavigateToMyAccount(): void {
			if (hasHomeTab) {
				NavigateTo(PicnikBase.HOME_TAB, "_pagSettings");
			} else {
				DialogManager.Show("SettingsDialog");
			}
		}

		// Navigate to a url. Do any cleanup/state saving necessary.
		// If we are in an iframe, add a header with a link to exit the iframe
		public function NavigateToURLWithIframeHelp(strToUrl:String, strWindow:String = "_self", fForce:Boolean=false): Boolean {
			var strURL:String = gstrSoMgrServer + "/popoutframe?dest=" + encodeURIComponent(strToUrl);
			return NavigateToURL(new URLRequest(strURL), strWindow, fForce);
		}

		// Navigate to a url. Do any cleanup/state saving necessary.
		// If we are in an iframe, add a header with a link to exit the iframe
		public function NavigateToURLWithIframeBreakout(strToUrl:String, strWindow:String = "_self", fForce:Boolean=false): Boolean {
			var strURL:String = gstrSoMgrServer + "/breakoutframe?dest=" + encodeURIComponent(strToUrl);
			return NavigateToURL(new URLRequest(strURL), strWindow, fForce);
		}

		// Navigate to a url. Do any cleanup/state saving necessary
		public function NavigateToURL(url:URLRequest, strWindow:String = "_self", fForce:Boolean=false): Boolean {
			if (!canNavParentFrame && !fForce && (strWindow == "_self" || strWindow == "_top" || strWindow == "_parent")) {
				// Sorry, but navigating while we're directly embedded is not allowed	
				return false;
			}
			Util.UrchinLogNav('/navigateTo?url=' + encodeURIComponent(url.url));
			
			ExitFullscreenMode(); // Browser can hang if we don't do this!
			SaveApplicationState(true);
			Session.GetCurrent().OnNavAway();
			var fWindowOpened:Boolean = false;
			if (strWindow && strWindow.toLowerCase() == "_blank" && !Util.IsSafari()) {
				// For popups, first try an external interface call
				// This works better in Firefox.
				try {
					ExternalInterface.call("window.open", url.url, "_blank");
					fWindowOpened = true;
				} catch (e:Error) {
					// Ignore errors - we'll fall through and call navigateToUrl
				}
			}
			if (!fWindowOpened)
				flash.net.navigateToURL(url, strWindow);
								
			return true;
		}

		// Try to navigate to an URL, but do so in a popup.
		// use esoteric inter-process communication to verify.  We get to our destination via
		// SOInterface, and send some magic variable names which cause it to establish a
		// LocalConnection that sends us a message.  If we get the message, we call our fnComplete
		// method.  We also have a timer, which will call fnComplete with a failure notification
		// if we haven't heard from it in N ms.  Thus, we can be guaranteed to know if the popup
		// failed to display.
		// NOTE: this urlencodes the provided URL, but soint2 has an odd behavior that strips all
		// arguments except the first inside the dest argument, and treats them as separate arguments
		// alongside dest.  urlencoding strUrl before passing it in here will counter this, however.

		// dctOptions can contain a dictionary with options for the call to javascript window.open(),
		// taking these possible values:
		//	status, toolbar, location, menubar, directories, resizable, scrollbars: either 1 or 0
		//	width, height: positive integer
		// function fnComplete(nError, strError, strData): void
		public function NavigateToURLInPopup(strUrl:String, width:int, height:int, fnComplete:Function=null, dctOptions:Object=null, strExtraSOIntParams:String=""): void {
			var strSuccessMethod:String = "successMethod";
			var strConnectionName:String = "ps" + Math.random();
			_fnPopupComplete = fnComplete;
			_fPopupSuccessful = false;
			_lconPopupSuccess = new DynamicLocalConnection();
			_lconPopupSuccess.allowPicnikDomains();
			
			// Once we open a connection, we have to be VERY careful to make sure we close it.
			_lconPopupSuccess[strSuccessMethod] = function(str:String=null): void {
				// the popup succeeded!
				try {
					_lconPopupSuccess.close();
				} catch (e:Error) { /*NOP*/ }
				if (_fnPopupComplete != null) {
					_fnPopupComplete(0, "", str);
					_fnPopupComplete = null;
				}
				_fLconPopupSuccessConnected = false;
				_fPopupSuccessful = true;
				_lconPopupSuccess = null;
			};
			
			if (!_fLconPopupSuccessConnected) {
				try {
					_lconPopupSuccess.connect(strConnectionName);
				} catch (e:Error) { /*NOP*/ }
				_fLconPopupSuccessConnected = true;
			}
			strUrl= PicnikService.serverURL + "/soint2?dest=" + encodeURIComponent(strUrl)
					+ "&alertAppConnection=" + strConnectionName
					+ "&alertAppMethod=" + strSuccessMethod + strExtraSOIntParams;
			NavigateToURLInPopup2(strUrl, width, height, dctOptions);

			if (_tmrCheckPopupSuccess == null) {
				_tmrCheckPopupSuccess = new Timer(10000, 1);
				_tmrCheckPopupSuccess.addEventListener(TimerEvent.TIMER_COMPLETE, function(evt:TimerEvent) : void {
					if (!_fPopupSuccessful) {
						// didn't hear from the popup in 10 secs, assume it failed.
						DialogManager.Show("BlockedPopupDialog");
	
						if (_fnPopupComplete != null) {
							// Make sure we close the connection, if we have one, before we fail.
							try {
								_lconPopupSuccess.close();
							} catch (e:Error) { /*NOP*/ }
							_fnPopupComplete(PicnikService.errFail, "popup navigation failed", null);
							_fnPopupComplete = null;
						}
					}
				});
			}
			_tmrCheckPopupSuccess.reset();
			_tmrCheckPopupSuccess.start();
		}

		private function NavigateToURLInPopup2(strUrl:String, width:int, height:int, dctOptions:Object=null): Boolean {
			var fSuccess:Boolean = false;
			if (ExternalInterface.available) {
				try {
					// some primitive defaults if no options are passed.
					var dctOptions2:Object = { 'status' : 1, 'scrollbars' : 1, 'resizable' : 1, 'width': width, 'height' : height };
					if (dctOptions != null) {
						for (var opt1:Object in dctOptions) {
							dctOptions2[opt1] = dctOptions[opt1];
						}
					}
					var strOptions:String = "";
					for (var opt2:Object in dctOptions2) {
						if (strOptions.length > 0)
							strOptions += ',';
						strOptions += opt2 + "=" + dctOptions2[opt2];
					}
					var strJS:String =  "function openWindow(newWindow) { " +
										"  w = window.open(newWindow, 'win', '"+ strOptions + "'); " +
										"  return w && !w.closed;" +
										"}";
					var o:Object = ExternalInterface.call(strJS, strUrl);
					if (o == true) {
						fSuccess = true;
						Util.UrchinLogNav("/navigateTo?url=" + encodeURIComponent(strUrl))
					}
				} catch (e:Error) {
					// fall through
				}
			}
			if (!fSuccess) {
				try {
					fSuccess = PicnikBase.app.NavigateToURL(new URLRequest(strUrl), "_blank");
				} catch (e:Error) {
					// fall through
				}
			}
			return fSuccess;
		}			

		public function ExitFullscreenMode(): void {
			if (stage && stage.displayState == StageDisplayState.FULL_SCREEN)
				stage.displayState = StageDisplayState.NORMAL;
		}
		
		// Called periodically to save the application's entire state to the local SharedObject
		public function SaveApplicationState(fForce:Boolean=false): void {
			if (!fForce) {
				if (inManualSerializationMode)
					return;
				if (delaySessionSaveUntilMS > 0)
					if (delaySessionSaveUntilMS > new Date().time)
						return;
					else
						delaySessionSaveUntilMS = 0;
			}
				
			// Don't bother trying to save document state while inside a model document change loop
			var imgd:ImageDocument = _doc as ImageDocument;
			if ((imgd && imgd.undoTransactionPending) || DragManager.isDragging)
				return;
			Session.GetCurrent().UpdateAppState(GetState(), fForce);
		}

		public function RestoreApplicationState(): void {
			restoringState = true;
			
			// We don't want the save state timer going off while we're in the
			// the middle of restoring state
			clearInterval(_iidSaveState);
			
			// Restore the application state
			var fRestored:Boolean = false;
			var sto:Object = Session.GetCurrent().GetAppState();
			if (sto != null) {
				RestoreMgr.RestoreState(sto, RestoreDone);
				fRestored = true;
			}

			if (!fRestored)
				RestoreDone(); // Make sure we call this when we are done restoring/setting up
			
			// Save the complete application state every 2 seconds
			_iidSaveState = setInterval(SaveApplicationState, 2000);
		}
		
		// This should ALWAYS be called when we are done restoring/setting up.
		private function RestoreDone(): void {
			restoringState = false;
			dispatchEvent(new LoginEvent(LoginEvent.RESTORE_COMPLETE));
		}
		
		/**
		 * Recursively restore state. If a class can't be restored synchronously
		 * pass it an fnDone callback function that will continue the restore process.
		 */
		public function RestoreStateAsync(sto:Object, fnProgress:Function, fnDone:Function): void {
			try {
				if (gfRestoreDocument && !isDesktop) {
					// restore multiMode state
					// STL: punted until later, when there's a UI way to turn multi off
					//if (sto.multi) {
					//	multiMode = true;
					//	multi.Deserialize( sto.multi );
					//	_zmv.currentState = "MultiMode";
					//}
					
					if (sto.imgd) {
						sto.doc = sto.imgd;
						sto.doc.strType = "ImageDocument";
					}
					
					if (sto.doc && sto.doc.strType.indexOf("ImageDocument") != -1) {					
						if (sto.strUIMode)
							uimode = sto.strUIMode;
							
						// Reset the ZoomView from the NoDocument state
						_zmv.currentState = "";
	
						var imgd:ImageDocument = new ImageDocument();
						imgd.RestoreStateAsync(sto.doc, fnProgress, function (err:Number, strError:String): void {
							if (err == 0) {
								activeDocument = imgd;
								RestoreStateAsync2(sto, fnProgress, fnDone);
							} else {
								uimode = kuimWelcome;
								fnDone(err, strError);
							}
						});	
					} else if (sto.doc && sto.doc.strType.indexOf("GalleryDocument") != -1) {					
						if (sto.strUIMode)
							uimode = sto.strUIMode;
							
	
						var gdoc:GalleryDocument = new GalleryDocument();
						gdoc.RestoreStateAsync(sto.doc, fnProgress, function (err:Number, strError:String): void {
							if (err == 0) {
								activeDocument = gdoc;
								RestoreStateAsync2(sto, fnProgress, fnDone);
							} else {
								uimode = kuimWelcome;
								fnDone(err, strError);
							}
						});	
					} else {
						RestoreStateAsync2(sto, fnProgress, fnDone);					
					}	
				} else {
					RestoreStateAsync2(sto, fnProgress, fnDone);
				}
			} catch (err:Error) {
				trace("Restore state async error: " + err.message + "\n" + err.getStackTrace());
				fnDone(err.errorID, err.message);
			}
		}
		
		private function RestoreStateAsync2(sto:Object, fnProgress:Function, fnDone:Function): void {
			try {
				if (sto.zmv != undefined)
					_zmv.loadState(sto.zmv);
				fnDone(0, null);
			} catch (err:Error) {
				fnDone(err.errorID, err.message);
			}
		}
		
		public function GetState(): Object {
			return {
				timestamp: new Date(),
				doc: _doc ? _doc.GetState() : null,
				//multi: multiMode ? multi.Serialize() : null,
				zmv: _zmv ? _zmv.saveState() : null,
				strDeepLink: _ubm ? _ubm.browserUrl : null,
				strUIMode: uimode
			}
		}
		
		/**
		 * Attach the master ZoomView to a container and give it the positioning parameters
		 * of a passed-in ZoomView template. The ZoomView as added to a container at the
		 * depth position of the template which is hidden.
		 */
		public function AttachZoomView(dobc:DisplayObjectContainer, cvsTemplate:Canvas): ZoomView {		
			var zmv:ZoomView = zoomView;
			dobc.addChildAt(zmv, dobc.getChildIndex(cvsTemplate));
			zmv.setStyle("left", cvsTemplate.getStyle("left"));
			zmv.setStyle("top", cvsTemplate.getStyle("top"));
			zmv.setStyle("right", cvsTemplate.getStyle("right"));
			zmv.setStyle("bottom", cvsTemplate.getStyle("bottom"));
			zmv.horizontalScrollPolicy = ScrollPolicy.OFF;
			zmv.verticalScrollPolicy = ScrollPolicy.OFF;
			
			zmv.visible = true;
			cvsTemplate.visible = false;
			return zmv;
		}
		
		public function DetachZoomView(dobc:DisplayObjectContainer): void {
			dobc.removeChild(zoomView);
		}
		
		/**
		 * The Help menu on the main app screen and the LinkBar at the
		 * bottom of the FirstRun page both want to display various
		 * information dialogs when the user selects items. ShowDialog
		 * takes a dialog and invokes it. A hack handles the forums
		 * and opens a new browser page at www.mywebsite.com/forums rather
		 * than bringing up a dialog.
		 */
		public function ShowDialog(strName:String, strSource:String = null): void {
			NextNavigationTracker.OnClick("/show_dialog/" + strName);
			switch (strName) {
			case "balloons":
				if (AccountMgr.GetInstance().isPaid) {
					FloatBalloons(20);
				} else {
					FloatBalloons(1);
					DialogManager.ShowUpgrade(navUpgradePath + "/balloons");
				}
				Util.UrchinLogReport("/balloons/" + (AccountMgr.GetInstance().isPremium ? "premium" : "free"));
				break;
				
			case "blog":
				NavigateToURL(new URLRequest("http://blog.mywebsite.com/"), null);
				break;
				
			case "tos":
				NavigateToURL(new URLRequest(gstrSoMgrServer + "/info/tos"), null);
				break;
				
			case "tosTab":
				NavigateTo(PicnikBase.HOME_TAB, "_pagTerms");
				break;
				
			case "apitos":
				NavigateToURL(new URLRequest(gstrSoMgrServer + "/info/apitos"), null);
				break;
				
			case "prmtos":
				NavigateToURL(new URLRequest(gstrSoMgrServer + "/info/prmtos"), null);
				break;
				
			case "forums":
				NavigateToURL(new URLRequest("http://www.mywebsite.com/forums"), null);
				break;
				
			case "badges":
				NavigateToURL(new URLRequest(gstrSoMgrServer + "/info/badges"), null);
				break;
				
			case "api":
				NavigateToURL(new URLRequest(gstrSoMgrServer + "/info/api"), null);
				break;
				
			case "settings":
				NavigateToURL(new URLRequest(gstrSoMgrServer + "/auth/settings"), null);
				break;
				
			case "tools":
				NavigateToURL(new URLRequest(gstrSoMgrServer + "/info/tools"), null);
				break;
			
			case "press":
				NavigateToURL(new URLRequest("http://press.mywebsite.com/"), null);
				break;
				
			case "jobs":
				NavigateToURL(new URLRequest("http://www.google.com/intl/ln/jobs/uslocations/seattle-kirkland/index.html"), null);
				break;
			
			case "usersettings":
				NavigateToMyAccount();
				break;
				
			case "help":
				DialogManager.Show("HelpDialog", this);
				break;
				
			case "helphub":
				if (hasHomeTab) {
					NavigateTo(PicnikBase.HOME_TAB, "_pagHelpHub");
				} else {
					DialogManager.Show("HelpDialog");
				}				
				break;
					
			case "privacyTab":
				NavigateTo(PicnikBase.HOME_TAB, "_pagPrivacyPolicyNew");
				break;
								
			case "privacy":
			case "privacypolicy":
				NavigateToURL(new URLRequest("http://www.google.com/privacypolicy.html"), null);
				break;
				
			case "privacypolicy2":
				NavigateToURL(new URLRequest(gstrSoMgrServer + "/info/privacypolicy2"), null);
				break;
				
			case "programpolicy":
				NavigateToURL(new URLRequest(gstrSoMgrServer + "/info/programpolicy/?locale=" + PicnikBase.Locale()), null);
				break;
				
			case "feedback":
				DialogManager.Show("FeedbackDialog");
				break;
				
			case "register":
				DialogManager.ShowRegister(this);
				break;

			case "forgotpw":
				DialogManager.ShowForgotPW(this);
				break;

			case "lostemail":
				DialogManager.ShowLostEmail(this);
				break;

			case "login":
				DialogManager.ShowLogin(this);
				break;

			case "give":
				DialogManager.ShowGiveGift(strSource, this);
				break;
				
			case "askforpremium":
				DialogManager.Show( "AskForPremiumDialog", this);
				break;

			case "googlemerge":
				DialogManager.Show( "GoogleMergeDialog", this);
				break;
				
			case "redeem":
				var obDefaults:Object = { 'fReturnToPaymentSelector': false };
				DialogManager.ShowRedeemGift(strSource, this, null, obDefaults );
				break;				
			}
		}

		// Writes are always slow and update both the persistent state and the cache.
		public static function SetPersistentClientState(strName:String, obState:*, fFlush:Boolean=true): void {
			Session.SetPersistentClientState(strName, obState, fFlush);
		}

		// Reads are fast when the state is in the cache (and possibly inaccurate when some other process is modifying the state)	
		public static function GetPersistentClientState(strName:String, obDefault:*): * {
			return Session.GetPersistentClientState(strName, obDefault);
		}
		
		//
		// Public properties
		//
		[Bindable]
		public function get activeDocument(): GenericDocument {
			return _doc;
		}
		
		public function set activeDocument(doc:GenericDocument): void {
			var docOld:GenericDocument = _doc;
			_doc = doc;
			
			// don't forget to clean up the old document!
			if (docOld) {
				docOld.Dispose();
				//mwhmwh AssetMgr.FlushAssets();
			}
			if (doc) {
				//mwhmwh AssetMgr.TrackAssets(doc.assets);
				AdManager.GetInstance().LogAdCampaignEvent(AdManager.kAdCampaignEvent_OpenPicture);
			}
			
			dispatchEvent(new ActiveDocumentEvent(ActiveDocumentEvent.CHANGE, docOld, _doc));

			if (docOld) {
				ExternalService.GetInstance().ReportState("photo_closed");
			}
			if (doc) {
				ExternalService.GetInstance().ReportState("photo_loaded");
			}
		}
		
		public function get applicationState(): String {
			if (parameters.full == undefined || parameters.full != "true") {
				return "FlickrSubset";
			} else {
				return "";
			}
		}
		
		public static function SetPremiumPreview(f:Boolean): void {
			app.zoomView.premiumPreview = f;
		}
		
		public function get zoomView(): ZoomView {
			return _zmv;
		}
		
		public function get skin(): PicnikSkin {
			return _skin;
		}
		
		[Bindable]
		// I wish I could justify naming this variable multiBall.
		public function set multiMode(f:Boolean): void {
			basket.multi = true;
			_fMultiMode = f;
		}

		public function get multiMode(): Boolean {
			return _fMultiMode;
		}
		
		[Bindable]
		public function get yahoomail(): Boolean {
			if (parameters)
				return parameters["ymail"] == "true";
			return false;
		}
		
		public function set yahoomail(f:Boolean): void {
			Debug.Assert(false, "yahoomail attribute is not settable");			
		}
		
		[Bindable]
		public function get restoringState(): Boolean {
			return _fRestoringState;
		}
		
		public function set restoringState(fRestoringState:Boolean): void {
			_fRestoringState = fRestoringState;
		}
		
		public function get external(): ExternalService{
			return _external;
		}
		
		//
		// Top level user interface
		//
		public function OnGivePicnikClick():void {
			DialogManager.ShowGiveGift( "/popup", this );
		}
		
		public function OnClosePopupInfo():void {
			_pwndPopupInfo.visible=false			
			SetPersistentClientState("PicnikBase.nLastClosedPopupInfo", _pwndPopupInfo.serial);
		}
		
		private function OnSignOutClick(evt:MouseEvent): void {
			// handle API users who might not have a welcome page
			var strCloseTarget:String = _pas.GetServiceParameter( "_close_target" ) as String;
			if (singleDocMode && strCloseTarget.length) {
				if (!PicnikBase.app.activeDocument || !PicnikBase.app.activeDocument.isDirty) {
					Session.GetCurrent().LogOut( strCloseTarget );
				} else {
					PicnikBase.app.ConfirmCancelWithChanges( function (obResult:Object): void {	
						if (obResult.success)
							Session.GetCurrent().LogOut( strCloseTarget );
					});	
				}			
			} else {
				AccountMgr.GetInstance().LogOut(null);
			}
		}
		
		private function OnMyAccountClick(evt:MouseEvent): void {
			NavigateToMyAccount();
		}

		private function OnHelpClick(evt:MouseEvent): void {
			var mnu:HelpMenu = new HelpMenu();
			mnu.currentState = AccountMgr.GetInstance().isGuest ? "Guest" : "";
			mnu.Show(this, _btnHelp);
		}

		private function OnPicnikMenuClick(evt:MouseEvent): void {
			var mnu:PicnikLiteMenu = new PicnikLiteMenu();
			mnu.Show(this, _btnPicnikMenu);
		}
	
		private function OnLanguageClick(evt:MouseEvent): void {
			var mnu:LocaleMenu = new LocaleMenu();
			mnu.Show(this, _imgGlobe);
		}
	
		private function OnSaveClick(evt:MouseEvent): void {
			DoSave();
		}	
		
		public function DoSave(): void {
			if (flickrlite) {
		    	var actl:IActionListener = _tabn.selectedChild as IActionListener;
		    	if (actl) {
		    		actl.PerformActionIfSafe(new Action(FlickrSave));
		    	} else {
		    		FlickrSave();
		    	}
			} else {
				if (!liteUI) {
					// navigate to Save & Share tab
					NavigateToDefaultOutBridge();
				} else {
					_pas.ExportClick();
				}
			}
		}
		
		public function FlickrSave(): void {
			DialogManager.Show("FlickrSaveDialog", this);
		}
		
		private function OnCancelClick(evt:TextEvent): void {
			if (multiMode) {
				CloseActiveDocument();
			} else {
				LiteUICancel();
			}
		}
		
		private function OnCancelButtonClick(evt:MouseEvent): void {
			LiteUICancel();
		}
		
		// Define the following resources:
		// Button 1: <strResourcePrefix>_yes
		// Button 2: <strResourcePrefix>_no
		// Header: <strResourcePrefix>_header
		// text: <strResourcePrefix>_text
		private function ConfirmAction(strResourcePrefix:String, fnComplete:Function, strBundle:String="Picnik"): void {
			var imgd:ImageDocument = activeDocument as ImageDocument;
			if (activeDocument && (activeDocument.isDirty || (imgd && imgd.undoTransactionPending))) {
				var dlg:EasyDialog = EasyDialogBase.Show(this,
						[Resource.getString("Picnik", strResourcePrefix + "_yes"),
								Resource.getString("Picnik", strResourcePrefix + "_no")],
						Resource.getString("Picnik", strResourcePrefix + "_header"),						
						Resource.getString("Picnik", strResourcePrefix + "_text"),
						fnComplete
					);		
			} else {
				fnComplete({success:true});
			}
		}
		
		public function ConfirmCancelWithChanges(fnComplete:Function): void {
			ConfirmAction("cancel_with_changes", fnComplete);
		}
		
		public function ConfirmSignOutWithChanges(fnComplete:Function): void {
			var strPrefix:String = AccountMgr.GetInstance().isGuest ? "exit" : "signout";
			strPrefix +=  "_with_changes"
			ConfirmAction(strPrefix, fnComplete);
		}
		
		// function fnDone(fSuccess:Boolean): void
		public function SafeSignOut(fnDone:Function=null, fClosing:Boolean = false): void {
			PicnikBase.app.ConfirmSignOutWithChanges(function(obResult:Object): void {
				if (obResult.success) {
					PicnikBase.app.closing = fClosing;
					PicnikBase.app.activeDocument = null;
					AccountMgr.GetInstance().LogOut(fnDone);
				} else {
					if (fnDone != null) fnDone(false);
				}
			} );
			
		}
		
		public function LiteUICancel(): void {
			ExitFullscreenMode();
			PicnikBase.app.ConfirmCancelWithChanges( function(obResult:Object): void {
				if (obResult.success) {
					PicnikBase.app.closing = true;
					PicnikBase.app.activeDocument = null;
					
					// register an API key hit with Google Analytics
					if (_pas.apikey && _pas.apikey.length > 0)
						Util.UrchinLogReport("/api/" + _pas.apikey + "/cancel" );
					
					if (flickrlite) {
						try {
							ExternalInterface.call("F.picnik.its_raining", null);
						} catch (err:Error) {
							// do nothing
						}
					} else {
						var strCloseTarget:String = _pas.GetServiceParameter( "_close_target" ) as String;
						if (strCloseTarget.indexOf("javascript:") == 0) {
							ExternalService.GetInstance().ReportState("app_close", null);
						} else {						
							Session.GetCurrent().LogOut( strCloseTarget );
						}
					}
				}
			} );
		}
		
		public function OnDownloadCancel(): void {
			LiteUICancel();
		}		
		
		// fForce flag currently only used when you're deleting a gallery you're already
		// working on; you've already confirmed you're deleting (and closing!) the gallery
		// that's currently open
		// fForce also used for close via API in embed mode .
		public function CloseActiveDocument(fForce:Boolean=false): void {
			NextNavigationTracker.OnClick("close_photo");
			multi.saveSuccess = false;
			if (fForce || !PicnikBase.app.activeDocument || !PicnikBase.app.activeDocument.isDirty) {
				_CloseActiveDocument();
			} else {
				DialogManager.Show('ConfirmLoadOverEditDialog', PicnikBase.app, function (res:Object): void {
						if (res.success)
							_CloseActiveDocument();
					});
			}
		}

		private function _CloseActiveDocument(): void {
			activeDocument = null;
			Notify(Resource.getString("Picnik", "_strClosedNotifyMessage"));
			uimode = PicnikBase.kuimWelcome;
		}

		public function OnDownloadError( err:Number, strError:String, fRetry:Boolean, fnCallback:Function ): void {			
			if (err == GalleryDocument.errDisabled) {
				var dlgDisabled:EasyDialog =
					EasyDialogBase.Show(
						this,
						[Resource.getString('Picnik', 'ok')],
						Resource.getString('Picnik', 'no_gallery_create_title'),						
						Resource.getString('Picnik', 'no_gallery_create_message'),						
						function( obResult:Object ):void {
						}	
					);			
				return;					
			}
			
			// log this error back to the server
			var strDisplay:String = Resource.getString('Picnik', 'download_error'); // + strError;
			var nSeverity:Number = PicnikService.knLogSeverityWarning;
			if (strError && strError.search(/^Error #2035/) != -1) {
				strDisplay = Resource.getString('Picnik', 'url_not_found');
				nSeverity = PicnikService.knLogSeverityInfo;
			}
			PicnikService.Log( "PicnikBase.OnDownloadDoneError:" + strError + " ("+err.toString()+")", nSeverity );
			
			if (_pas.apikey && _pas.apikey.length > 0)
				Util.UrchinLogReport("/api/" + _pas.apikey + "/downloaderror" );

			// jump the preloader to the end so that we show the main UI
			HidePreloader();			
			
			var dlg:EasyDialog =
				EasyDialogBase.Show(
					this,
					fRetry ? [Resource.getString('Picnik', 'retry'), Resource.getString('Picnik', 'cancel')] :
							 [Resource.getString('Picnik', 'cancel')],
					Resource.getString('Picnik', 'download_error_title'),						
					strDisplay,
					function( obResult:Object ):void {
						if (obResult.success && fRetry) {
							//retry
							fnCallback( {retry:true} );
						}
						else {
							ExternalService.GetInstance().ReportState("photo_error");
							if (liteUI || thirdPartyEmbedded)
								LiteUICancel();
							else	
								fnCallback( {retry:false} );
						}
					}
				);			
		}		
		
		private function OnFeedbackClick(evt:MouseEvent): void {
			DialogManager.Show('feedback');
		}
		
		private function CleanTabName(strName:String): String {
			if (strName == null || strName == "" || strName.charAt(0) == '-')
				return "";
			return strName.replace(/ /g, '_');
		}		

		public function get navUpgradePath(): String {
			var strEvent:String = "/" + CleanTabName(selectedTabName);
			var strSubTab:String = CleanTabName(selectedSubTabName);
			if (strSubTab.length > 0) strEvent += "_" + strSubTab;
			strEvent = strEvent.replace("collage_grid", "collage");
			return strEvent;
		}

		private function OnUpgradeClick(evt:MouseEvent): void {
			DialogManager.ShowUpgrade(navUpgradePath + "/upgrade_bar");
		}

		public function SignIn(): void {
			DialogManager.ShowLogin(this);
		}
		
		public function Register(): void {
			DialogManager.ShowRegister(this);
		}
		
		private function OnTabNavIndexChange(evt:IndexChangedEvent): void {
			var actOld:IActivatable = null;
			//trace( (new Date()).getTime() + ": " + "PicnikBase.OnTabNavIndexChange oldIndex: " + evt.oldIndex + ", newIndex: " + evt.newIndex);
			if (evt.oldIndex != -1 && evt.oldIndex < evt.target.numChildren)
				actOld = evt.target.getChildAt(evt.oldIndex) as IActivatable;
			if (actOld != null && actOld.active)
				actOld.OnDeactivate();
			var actNew:IActivatable = evt.target.getChildAt(evt.newIndex) as IActivatable;
			
			var strNew:String = evt.newIndex == -1 ? "<none>" : evt.target.getChildAt(evt.newIndex).id;
			if (actNew != null && !actNew.active) {
				actNew.OnActivate();
				NextNavigationTracker.OnClick("/tab_nav/" + strNew);
			}

			// Hide or show the basket depending on the tab
			if (basket) {
				var show:Boolean = false;
				var strOld:String = evt.oldIndex == -1 || evt.oldIndex >= evt.target.numChildren ? "<none>" : evt.target.getChildAt(evt.oldIndex).id;				
				
				if (multiMode && ((strNew in editImageTabMap) || (strNew in projectTabMap))) {
					show = true;
				} else if ( !singleDocMode &&
					((strNew in editImageTabMap) && AccountMgr.GetInstance().isPremium) ||
					(strNew in projectTabMap)) {
					show = true;
				}

				if (show) {
					basket.Show();
				} else {
					basket.Hide();
				}
			}
			
			// show a new add
			AdManager.GetInstance().LoadNewAd();	
		}
		
		// Extra URL is added to the nav url (with a separating /). E.g. "focalBW"
		// QueryParms should not start with '?' and may include &, e.g. type=jpg&size=1000x2000
		public function LogNav(strExtraUrl:String=null, strQueryParams:String=null): void {
			var strUrl:String = _ubm.browserUrl;
			if (strExtraUrl && strExtraUrl.length > 0) strUrl += "/" + strExtraUrl;
			if (strQueryParams && strQueryParams.length > 0) strUrl += "?" + strQueryParams;
			Util.UrchinLogNav(strUrl);
			ABTest.HandleNav(strUrl);
		}
		
		public function Notify(strMessage:String, nDuration:Number = -1): void {

			var sm:ISystemManager = systemManager;
			var targetLayer:IChildList = sm.toolTipChildren;
			
			// Set up the notifier
			if (_ntfNotifier.parent != null) {
				// Currently playing
				_ntfNotifier._effNotify.removeEventListener(EffectEvent.EFFECT_END, OnTransitionEnd);
				_ntfNotifier._effNotify.end();
				targetLayer.removeChild(_ntfNotifier);
			}
			
			targetLayer.addChild(_ntfNotifier);

			if (nDuration == -1) nDuration = knDefaultNotifyDelay;
			_ntfNotifier._nNotifierDelay = nDuration;
			
			_ntfNotifier._lblNotification.text = strMessage;
			// Center the notify canvas
			_ntfNotifier.x = Math.round((width - _ntfNotifier.width) / 2);
			_ntfNotifier.y = Math.round((height - _ntfNotifier.height) / 3);

			// Start the effect
			_ntfNotifier._effNotify.addEventListener(EffectEvent.EFFECT_END, OnTransitionEnd);
			_ntfNotifier._effNotify.play();
		}
		
		protected function OnTransitionEnd(evt:Event): void {
			// Clean up the notifier after the effect finishes.
			var sm:ISystemManager = systemManager;
			var targetLayer:IChildList = sm.toolTipChildren;
			targetLayer.removeChild(_ntfNotifier);
			_ntfNotifier._effNotify.removeEventListener(EffectEvent.EFFECT_END, OnTransitionEnd);
		}
		
		public function NavigateTo(strTab:String, strSubTab:String = null, strCmd:String = null): void {
			// CONSIDER: this doesn't feel like a great place for this logic
			// Use the requested tab as a mode selector. Hide any tabs not appropriate
			// for the mode, and show the ones needed for the mode.
			switch (strTab) {
			// Collage mode!
			case PicnikBase.COLLAGE_TAB:
				uimode = kuimCollage;
				break;
			
			case PicnikBase.ADVANCED_COLLAGE_TAB:
				uimode = kuimAdvancedCollage;
				break;
			
			case PicnikBase.GALLERY_STYLE_TAB:
				uimode = kuimGallery;
				break;
			
			// Edit Photo mode!
			case PicnikBase.EDIT_CREATE_TAB:
			case PicnikBase.OUT_BRIDGES_TAB:
				uimode = kuimPhotoEdit;
				break;
			}
			
			if (strTab != null)
				activeTabId = strTab;

			// For now, we only need level 2 nav for bridges
			if (strSubTab != null || strCmd != null) {
				var cntSelected:DisplayObject = _tabn.selectedChild;
				
				if (cntSelected is PageContainer) {
					var brg:PageContainer = _tabn.selectedChild as PageContainer;
					brg.NavigateTo(strSubTab);
				} else if (cntSelected is ActivatableModuleLoader) {
					var amldr:ActivatableModuleLoader = _tabn.selectedChild as ActivatableModuleLoader;
					amldr.LoadTab(strSubTab, strCmd);
				} else if (cntSelected is ITabContainer) {
					var itc:ITabContainer = _tabn.selectedChild as ITabContainer;
					itc.LoadTab(strSubTab);
				}  else {
					Debug.Assert(false, "Can not select sub-tab of non-bridge non-ActivatableModuleLoader container");
				}
			}
		}

		public function NavigateToService(strTab:String, strSubTab:String = null): void {
			if (strTab != null)
				_tabn.selectedChild = _tabn.getChildByName(strTab) as Container;

			// For now, we only need level 2 nav for bridges
			if (strSubTab != null) {
				var brg:PageContainer = _tabn.selectedChild as PageContainer;
				Debug.Assert(brg != null, "Can not select sub-tab of non-bridge container");
				brg.NavigateToService(strSubTab);
			}
		}


		public function NavigateToAltPage( strUrl:String ): void {
			PicnikBase.app.external.ShowAlternate( strUrl, null );
		}

		// Use this to select a sub-tab without selecting the parent tab.
		// This is useful for selecting the default out-bridge when an image is opened.
		public function SelectSubTab(strTab:String, strSubTab:String): void {
			if (strTab == null || strSubTab == null) return; // Nothing to select.

			var cntrTab:Container = _tabn.getChildByName(strTab) as Container;
			if (cntrTab != null) {
				var vstk:ViewStack = cntrTab.getChildByName("_vstk") as ViewStack;
				if (vstk != null) {
					vstk.selectedChild = vstk.getChildByName(strSubTab) as Container;
				}
			}
		}
		
		public function SetBrowserTitle(strTitle:String): void {
			// TODO: (STL) I don't think anyone is using this code
			try {
				if (ExternalInterface.available) {
					ExternalInterface.call("setTitle", strTitle);
				}
			} catch (e:Error) {
				// Ignore the error
			}
		}
		
		private static const kstrTabNameSources:Array = ['urlkit', 'label', 'name', 'id'];
		
		public function get selectedTabName(): String {
			if (_tabn == null) return "-No tab navigator";
			if (_tabn.selectedChild == null) return "-No selected tab";
			var ctr:Container = _tabn.selectedChild;
			for each (var strKey:String in kstrTabNameSources) {
				if (strKey in ctr && ctr[strKey] != null && String(ctr[strKey]).length > 0)
					return ctr[strKey];
			}
			return "-No name found";
		}
		
		public function get selectedSubTabName(): String {
			if (_tabn == null) return "-No tab navigator";
			if (_tabn.selectedChild == null) return "-No selected tab";
			var vstk:ViewStack = _tabn.selectedChild.getChildByName("_vstk") as ViewStack;
			if (vstk == null) return "-No sub tab viewstack";
			if (vstk.selectedChild == null) return "-No selected sub tab";
			var ctr:Container = vstk.selectedChild;
			for each (var strKey:String in kstrTabNameSources) {
				if (strKey in ctr && ctr[strKey] != null && String(ctr[strKey]).length > 0)
					return ctr[strKey];
			}
			return "-No name found";
		}

		public function IsServiceActive(): Boolean {
			return _pas.IsServiceActive();
		}
		
		public function AsService(): PicnikAsService{
			return _pas;
		}
		
		public function set uimode(strMode:String): void {
			_strUIMode = strMode;
			// if we're running as Picnik Lite, we should use the lite mode tabs.
			var obTabs:Object = liteUI ? s_dctModeTabs[PicnikBase.kuimLite] : s_dctModeTabs[strMode];
			var astrTabs:Array = [];
			if (obTabs is Array)
				astrTabs = obTabs as Array;
			else if (obTabs is Function)
				astrTabs = obTabs(activeDocument as GalleryDocument);
				
			ChangeTabs.apply(this, astrTabs);
			
			switch (_strUIMode) {
			case kuimCollage:
			case kuimAdvancedCollage:
			case kuimGallery:
				basket.Open();
				break;
				
			case kuimWelcome:
				if (multiMode)
					basket.Open();
				else
					basket.Close();
				break;
				
			default:
				basket.Close();
				break;
			}
			if (zoomView) zoomView.uimode = strMode;
		}
		
		public function get uimode(): String {
			return _strUIMode;
		}
		
		public function set activeTabId(strTab:String): void {
			var ctr:Container = _tabn.getChildByName(strTab) as Container;
			if (ctr == null)
				return;
			_tabn.selectedChild = ctr;
		}
		
		public function get activeTabId(): String {
			if (_tabn.selectedChild == null)
				return null;
			return _tabn.selectedChild.id;
		}
		
		public function get activeSubTabId(): String {
			var vstk:ViewStack = _tabn.selectedChild.getChildByName("_vstk") as ViewStack;
			if (vstk == null) return null;
			if (vstk.selectedChild == null) return null;
			return vstk.selectedChild.id;
		}
		
		// Add and remove tabs so that the result is the requested list
		// of tabs. The API _exclude parameter overrides (filters) the
		// requested tabs.
		private function ChangeTabs(... astrTabs:Array): void {
			// Filter out any API _exclude'ed tabs
			if (_pas.IsServiceActive()) {
				var astrExclude:Array = new Array();
				var strExclude:String = _pas.GetServiceParameter("_exclude");			
				if (strExclude)
					astrExclude = strExclude.split(",");
				for each (strExclude in astrExclude) {
					var i:int = astrTabs.indexOf(strExclude);
					if (i != -1)
						astrTabs.splice(i, 1);
				}
			}
			
			// Make lists of tabs that need to be added and removed
			var astrRemove:Array = [];
			var astrAdd:Array = astrTabs.slice(0);
			for (i = 0; i < _tabn.numChildren; i++) {
				var ob:Object = _tabn.getChildAt(i);
				if (astrTabs.indexOf(ob.urlkit) == -1) {
					astrRemove.push(ob.urlkit);
				} else {
					var j:int = astrAdd.indexOf(ob.urlkit);
					astrAdd.splice(j, 1);
				}
			}
			
			// Remove and add the tabs
			if (astrRemove.length != 0)
				ChangeTabs2(astrRemove, true, null);
			if (astrAdd.length != 0)
				ChangeTabs2(astrAdd, false, astrTabs);

			hasInBridge = astrTabs.indexOf("in") != -1;
			hasHomeTab = astrTabs.indexOf("home") != -1;
			
			// HACK: when we're running inside of Yahoo! Mail we style the Save & Share tab
			// as a button. Don't ask why.
			if (yahoomail) {
				if (_tabn.getChildByName("_brgcOut") != null)
					_tabn.setStyle("lastTabStyleName", "tabButton");
				else
					_tabn.setStyle("lastTabStyleName", _tabn.getStyle("tabStyleName"))
			}
		}

		private function ChangeTabs2(astrTabs:Array, fHide:Boolean, astrTabOrder:Array): void {
			var vstkFrom:ViewStack = fHide ? _tabn : _vstkTabHolder;
			var vstkTo:ViewStack = fHide ? _vstkTabHolder : _tabn;
			
			var i:int;
				
			for each (var str:String in astrTabs) {
				for (i = 0; i < vstkFrom.numChildren; i++) {
					var ob:Object = vstkFrom.getChildAt(i);
					if (ob.urlkit == str) {
						// Deactivate tabs being removed before they're removed
						var dobTab:DisplayObject = vstkFrom.getChildAt(i);
						if (fHide && (dobTab is IActivatable) && IActivatable(dobTab).active)
							IActivatable(dobTab).OnDeactivate();
							
						vstkFrom.removeChildAt(i);
						
						// If we don't do this we will hit: "Error: Multiple sets of visual
						// children have been specified for this component (base component
						// definition and derived component definition)." in Container.as
						// setDocumentDescriptor.	
						var ctnr:Container = dobTab as Container;
						
						if (ctnr && !ctnr.processedDescriptors) {
							ctnr.creationPolicy = ContainerCreationPolicy.AUTO;
							ctnr.createComponentsFromDescriptors();
						}
						if (!fHide && astrTabOrder) {							
							vstkTo.addChildAt(dobTab, astrTabOrder.indexOf(str));
						} else {
							vstkTo.addChild(dobTab);
						}
					}
				}
			}
			
			// Validate after removing tabs or we will encounter crazy errors
			// when defered validation tries to validate tabs that have been removed
			// along with tabs that have been added. 
			if (fHide) {
				_tabn.selectedIndex = 0;
				// BUGBUG: if the active tab has been removed this will fire an IndexChangedEvent with
				// newIndex being the highest tab (e.g. "in" if we're transitioning to "welcome")
				_tabn.validateProperties();
			}
		}

		public function SwitchLocale(strLocale:String): void {
			// change to the new locale
			Session.SetPersistentClientState("locale.relaunch", true);
			NavigateToURL(new URLRequest(gstrSoMgrServer + "/soint2?dest=/app&re=localechange&locale=" + strLocale));
		}

		public static function Locale(): String {
			return CONFIG::locale;
		}
		
		public static function ForceGC():void {
			// from http://www.gskinner.com/blog/archive/2006/08/as3_resource_ma_2.html
		   var nMem:uint = System.totalMemory;
			try {
			   new LocalConnection().connect('foo');
			   new LocalConnection().connect('foo');
			} catch (e:*) {}
			//trace( "memory used after GC (before): " + System.totalMemory + " (" + nMem + ")" );
		}

		public function OnMemoryError(e:Error = null): void {
			if (!_fReportedMemoryError) {
				ForceGC();
				
				var strTitle:String = Resource.getString('Picnik', 'memoryTitle');
				var strMessage:String = Resource.getString('Picnik', 'memoryMessage');
				var eBitmap:InvalidBitmapError = e as InvalidBitmapError;
				
				var strLog:String = null;
				var nSeverity:Number = PicnikService.knLogSeverityMonitor;
				if (eBitmap &&
						(eBitmap.type == InvalidBitmapError.ERROR_ARGUMENTS ||
						 eBitmap.type == InvalidBitmapError.ERROR_IS_BACKGROUND ||
						 eBitmap.type == InvalidBitmapError.ERROR_IS_COMPOSITE ||
						 eBitmap.type == InvalidBitmapError.ERROR_IS_KEYFRAME ||
						 eBitmap.type == InvalidBitmapError.ERROR_DISPOSED )) {
					strTitle = Resource.getString('Picnik', 'bitmapErrorTitle'); 		
					strMessage = Resource.getString('Picnik', 'bitmapErrorMessage');
					strLog = "Client encountered";
					
					// We want to keep an eye on these until we understand them better
					nSeverity = PicnikService.knLogSeverityWarning;
				}
						
				var dlg:EasyDialog =
					EasyDialogBase.Show(
						this,
						[Resource.getString('Picnik', 'ok')],
						strTitle,
						strMessage);
				_fReportedMemoryError = true;
				if (strLog == null)
					strLog = "Client displayed memory error (" + System.totalMemory + " used)";
				if (e) {
					PicnikService.Log(strLog + ": " + e + ", " + e.getStackTrace(), nSeverity);
				} else {
					PicnikService.Log(strLog, nSeverity);
				}
			}		
		}
		
		public function ShowSaveToHistoryFailed(): void {
			// UNDONE: try again a couple times?
			EasyDialogBase.Show(this,
					[Resource.getString('Picnik', 'ok')],
					Resource.getString('Picnik', 'saveToHistoryFailedTitle'),
					Resource.getString('Picnik', 'saveToHistoryFailedMessage'));
		}
		
		protected function InitExternalListeners(): void {
			try {
				ExternalInterface.addCallback( "externalUpgrade", externalUpgrade );	
			} catch (e:Error) {
//				PicnikService.Log("Ignored Client Exception in InitExternalListeners: " + e, PicnikService.knLogSeverityInfo);
			}
		}
		
		protected function externalUpgrade(strSource:String): void {
			// User clicked upgrade button outside of swf (e.g. ad banner)
			DialogManager.ShowUpgrade("/external/" + strSource);
		}
		
		protected function externalMoveTo(x:Number, y:Number):void {
			return;
		}
		public function OnSaveComplete(): void {
			var nSaves:int = Session.GetPersistentClientState( "stats.numSaves", 0 );
			Session.SetPersistentClientState("stats.numSaves", nSaves + 1);

			var imgd:ImageDocument = activeDocument as ImageDocument;

			if (multiMode) {
				// update the multi manager with the new item
				if (imgd) multi.AddItem( ItemInfo.FromImageProperties(imgd.properties) );
				
				// we need to close open document
				activeDocument = null;
	
				// tell the multi that the last item was successfully saved.
				// Note that we'll probably need to set this to false one day,
				// but for now the UI never gets into a state where it matters.			
 				multi.saveSuccess = true;
				uimode = PicnikBase.kuimWelcome;
			} else if (liteUI) {
				ExitFullscreenMode(); // Browser can hang if we don't do this!
				if (flickrlite) {
					var strPhotoId:String = imgd ? imgd.properties.flickr_photo_id : null;
					try {
						ExternalInterface.call("F.picnik.its_raining", strPhotoId);
					} catch (err:Error) {
						// do nothing
					}
				} else {
					var strURL:String = imgd ? imgd.properties.webpageurl : (_pas.GetServiceParameter( "_close_target", "http://www.flickr.com" ) as String);
					Session.GetCurrent().LogOut( strURL );
				}			
			} else {
				// only flash the Saved! message if we're not in multiMode
				PicnikBase.app.Notify(Resource.getString("Picnik", "_strSavedNotifyMessage"));
			}
		}		
		
		// Figure out whether we should continue in Collage or Edit mode
		public function ResumeEditing(): void {
			NextNavigationTracker.OnClick("/continue_editing");
			var strTargetTab:String = PicnikBase.EDIT_CREATE_TAB;
			var imgd:ImageDocument = activeDocument as ImageDocument;
			if (imgd && imgd.isCollage)
				strTargetTab = imgd.isFancyCollage ? PicnikBase.ADVANCED_COLLAGE_TAB : PicnikBase.COLLAGE_TAB;
			var gald:GalleryDocument = activeDocument as GalleryDocument;
			if (gald) {
				strTargetTab = PicnikBase.GALLERY_STYLE_TAB;
			}				
			NavigateTo(strTargetTab);
		}	
		
		public function CreateFreshGallery():void {
			var fnNavigateToGallery:Function = function():void {
					var galleryDoc:GalleryDocument = new GalleryDocument;
					PicnikBase.app.activeDocument = galleryDoc;
					PicnikBase.app.uimode = PicnikBase.kuimGallery;
					PicnikBase.app.activeTabId = PicnikBase.GALLERY_STYLE_TAB;
				}

			if (!PicnikConfig.galleryCreate) {
				var dlg:EasyDialog =
					EasyDialogBase.Show(
						this,
						[Resource.getString('Picnik', 'ok')],
						Resource.getString('Picnik', 'no_gallery_create_title'),						
						Resource.getString('Picnik', 'no_gallery_create_message'));			
				return;					
			}

			var doc:GenericDocument = PicnikBase.app.activeDocument;
			if (doc != null && doc.isDirty) {
				DialogManager.Show('ConfirmLoadOverEditDialog', PicnikBase.app, function (res:Object): void {
						if (res.success)
							fnNavigateToGallery();
					});
			} else {
				fnNavigateToGallery();
			}
		}
		
		[Bindable]
		public function get modalPopup(): Boolean{
			return _fModalPopup;
		}
		
		public function set modalPopup(f:Boolean): void {
			_fModalPopup = f;
		}

//		public function ShareOnTwitter1Billion(): void {
//			ShareOnTwitter( "Picnik is celebrating its one billionth photo edited with FREE PICNIK PREMIUM for the next 24 hours! http://bit.ly/abdYvF" );
//		}		
//		
//		public function ShareOnFacebook1Billion(): void {
//			ShareOnFacebook( "Picnik is celebrating its one billionth photo edited with FREE PICNIK PREMIUM for the next 24 hours!",
//							 "http://www.mywebsite.com/one_billion" ); // Facebook does not bit.ly urls but this one seems to work.
//		}	
		
		public function FloatBalloons( nCount:int = 20 ): void {
			_blns.Float( nCount );
		}	

		public function ShareOnTwitter( strMsg:String, strUrl:String = null ): void {
			// undone: smartly truncate to 140 chars
			if (null == strMsg) {
				strMsg = "";
			}
			if (strUrl) {
				strMsg += " " + strUrl;
			}
			var strTweetUrl:String = "http://twitter.com/home?status=" + encodeURIComponent(strMsg); 
			var urlr:URLRequest = new URLRequest( strTweetUrl );
			navigateToURL( urlr );
		}
					
		public function ShareOnFacebook( strTitle:String, strUrl:String ): void {
			if (null == strTitle) {
				strTitle = "";
			}
			var strFBUrl:String = 'http://www.facebook.com/sharer.php?u=' + encodeURIComponent(strUrl) + '&t=' + encodeURIComponent(strTitle);
			var urlr:URLRequest = new URLRequest( strFBUrl );
			navigateToURL( urlr );
		}
		
		public function ShareOnBuzz( strTitle:String, strUrl:String ): void {
			if (null == strTitle) {
				strTitle = "";
			}
			var strFBUrl:String = 'http://www.google.com/buzz/post?message=' + encodeURIComponent(strTitle) + '&url=' + encodeURIComponent(strUrl);
			var urlr:URLRequest = new URLRequest( strFBUrl );
			navigateToURL( urlr );
		}
	}
}
