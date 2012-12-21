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
package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.FontStyle;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextLineMetrics;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.clearInterval;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	
	import mx.events.RSLEvent;
	import mx.preloaders.IPreloaderDisplay;
	import mx.utils.URLUtil;
	
	import util.GooglePlusUtil;
	import util.VersionStamp;

	public class PicnikPreloaderDisplay extends Sprite implements IPreloaderDisplay
	{
		public static var appRoot:String = null;

		// Constants
		private static const kclrBackground:Number = 0xffffff; // CONFIG
		private static const kaclrTopAndBottomGradientColors:Array = [0xcbdce5, kclrBackground]; // CONFIG
		private static const knHeaderFooterPercentage:Number = 20; // CONFIG: Header and footer gradients take up this much percentage of the screen
		private static const knTrackWidth:Number = 188; // The width of the middle of the progress bar

		// Variables
		private var _fProgBarLoaded:Boolean = false;
		private var _obParams:Object = null;
		private var _soClientState:SharedObject = null;
		private var _fInitComplete:Boolean = false;
		private var _fDontShow:Boolean = false;

		private var _dctImagesByName:Dictionary = null;
		private var _dctImagesByLoaderInfo:Dictionary = null;
		private var _obPostLoadImage:Object = null;
		
		private var _fRealSize:Boolean = false;
		private var _fSizeInvalid:Boolean = false;
		
		// This is our array of images which are loaded and added displayed
		// images with fProgBar == false are automatically displayed when they load
		// images with fProgBar == true are displayed only when all are loaded
		// xOff and yOff are offsets from the stage center.
		// strName is used to find image objects (in _dctImagesByName) and also
		// as the name of the display object (for getChildByName())
		private var _aobImages:Array =
				[{strName:"picnikLogo",xOff:-200,yOff:-50,fProgBar:false,strUrl:"../graphics/picnik_brand.swf", fNonDialogModeOnly:true, fHideForGooglePlus:true},
				{strName:"loadingPhrases",xOff:-13,yOff:12,fProgBar:false, fNonDialogModeOnly:true,
					strUrl:"../graphics/" + GetLocale() + "/loadingPhrases.swf",
					strGooglePlusUrl:"../graphics/" + GetLocale() + "/gp_loadingPhrases.swf"},
				{strName:"greenDot",xOff:183,yOff:25,fProgBar:false,strUrl:"../graphics/progressbar/grn_dot.png",fPostLoad:true,fNonDialogModeOnly:true},
				{strName:"slowLoadMessage",xOff:-187,yOff:96,fProgBar:false,strUrl:"../graphics/" + GetLocale() + "/slowLoadMessage.swf",fPreWaitOnly:true,fNonDialogModeOnly:true},

				// dialog mode bits
				{strName:"bluegrad_short", halign:"left", valign:"top", explicitWidth:"stretch", explicitHeight:702,
							fProgBar:false, fDialogModeOnly:true,
							strUrl:"../graphics/bluegrad_short.gif", layer:0},
				{strName:"clouds", halign:"center", valign:"top", explicitWidth:983, explicitHeight:177,
							fProgBar:false, fDialogModeOnly:true,
							strUrl:"../graphics/clouds.jpg", layer:1},				
				{strName:"picnikLogo2", halign:"left", valign:"top", xOff:40, yOff:40,
							fProgBar:false, fDialogModeOnly:true,
							strUrl:"../graphics/picnik_com.png", layer:2},				
				{strName:"gears",halign:"center", valign:"center",
							fProgBar:false,fDialogModeOnly:true,
							strUrl:"../graphics/gears.swf", layer:3},
				]

		private var _aobBundles:Array =
				[{ strUrl:"../graphics/progressbar/pbar_assets.swf", strGooglePlusUrl:"../graphics/gp_progressbar/pbar_assets.swf",
					fNonDialogModeOnly:true,
					aAssets: [	
						{strName:"pbTrackLeft",xOff:-13,yOff:-12,fProgBar:true,strId:'clstrackLeftCap_png'},
						{strName:"pbTrackMid",xOff:-7,yOff:-12,fProgBar:true,strId:'clstrackMiddle_png'},
						{strName:"pbTrackRight",xOff:knTrackWidth-8,yOff:-12,fProgBar:true,strId:'clstrackRightCap_png'},
						{strName:"pbBarLeft",xOff:-13,yOff:-12,fProgBar:true,strId:'clsbarLeftCap_png'},
						{strName:"pbBarMid",xOff:-7,yOff:-12,fProgBar:true,strId:'clsbarMiddle_png'},
						{strName:"pbBarRight",xOff:-6,yOff:-12,fProgBar:true,strId:'clsbarRightCap_png'}]
				}];
		
		
		private function GetLocale(): String {
			return CONFIG::locale;		
		}
		
		public function PicnikPreloaderDisplay()
		{
			super();
		}
		
		private function CheckStageSize(): void {
			if (stage) {
				stageWidth = stage.stageWidth;
				stageHeight = stage.stageHeight;
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  Code copied from DownloadProgressBar.as, with some modifications
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  The percentage of the progress bar that the downloading phase
		 *  fills when the SWF file is fully downloaded.
		 *  The rest of the progress bar is filled during the initializing phase.
		 *  This should be a value from 0 to 100.
		 */
		protected var DOWNLOAD_PERCENTAGE:uint = 60;
		private var	_maximum:Number = 0;
		private var	_value:Number = 0;
		private var _startTime:int;
		private var _startedLoading:Boolean = false;
		private var _startedInit:Boolean = false;
		private var _showingDisplay:Boolean = false;
		private var _displayStartCount:uint = 0;
		private var _initProgressCount:uint = 0;
		private var _initProgressTotal:uint = 12;
		private var _fRslLoaded:Boolean = false;
		private var _noProgressTimer:Timer = null;
		private var _obNoProgressContainer:Object;
		
		//----------------------------------
		//  visible
		//----------------------------------
		
		private var _visible:Boolean = false;

		/**
		 *  Specifies whether the download progress bar is visible.
		 *
		 *  <p>When the Preloader control determines that the progress bar should be displayed,
		 *  it sets this value to <code>true</code>. When the Preloader control determines that
		 *  the progress bar should be hidden, it sets the value to <code>false</code>.</p>
		 *
		 *  <p>A subclass of the DownloadProgressBar class should never modify this property.
		 *  Instead, you can override the setter method to recognize when
		 *  the Preloader control modifies it, and perform any necessary actions. </p>
		 *
		 *  @default false
		 */
		override public function get visible():Boolean
		{
			return _visible;
		}
		override public function set visible(value:Boolean):void
		{
			if (!_visible && value)
				show();
			
			else if (_visible && !value )
				hide();
			
			_visible = value;
		}
		
		//--------------------------------------------------------------------------
		//
		//  Properties: IPreloaderDisplay
		//
		//--------------------------------------------------------------------------
		
		//----------------------------------
		//  backgroundAlpha
		//----------------------------------
	
		// These are functions defined in IPreloaderDisplay that we ignore	
		public function get backgroundAlpha(): Number {
			return 1;
		}

		public function set backgroundAlpha(value:Number): void {
		}
		
		public function get backgroundColor(): uint {
			return 0xffffff;
		}
	
		public function set backgroundColor(value:uint): void {
		}

		public function get backgroundImage(): Object {
			return null;
		}
		
		public function set backgroundImage(value:Object): void {
		}

		public function get backgroundSize(): String {
			return "";
		}
		
		public function set backgroundSize(value:String): void {
		}
		
		//----------------------------------
		//  preloader
		//----------------------------------
	
		/**
		 *  @private
		 *  Storage for the preloader property.
		 */
		private var _preloader:Sprite;
		
		/**
		 *  The Preloader class passes in a reference to itself to the display class
		 *  so that it can listen for events from the preloader.
		 */
		public function set preloader(value:Sprite):void
		{
			_preloader = value;
			
			try {			
				_soClientState = SharedObject.getLocal("ClientState", "/");
			} catch (e:Error) {
				if (e.errorID == 2134) {
					DisplayError(root.loaderInfo.parameters["nonCdnServerRoot"] + "/info/storage");
				}
			}			
					
			value.addEventListener(ProgressEvent.PROGRESS, progressHandler);	
			
			value.addEventListener(RSLEvent.RSL_ERROR, rslErrorHandler);
			value.addEventListener(RSLEvent.RSL_COMPLETE, rslEventHandler);	
			value.addEventListener(RSLEvent.RSL_PROGRESS, rslEventHandler);
		}
	
		//----------------------------------
		//  stageHeight
		//----------------------------------
	
		/**
		 *  Storage for the stageHeight property.
		 */
		private var _stageHeight:Number = 375;
	
		/**
		 *  The height of the stage,
		 *  which is passed in by the Preloader class.
		 */
		public function get stageHeight(): Number {
			return _stageHeight;
		}
	
		public function set stageHeight(value:Number): void {
			if (value != 0 && (value != _stageHeight || !_fRealSize)) {
				_stageHeight = value;
				_fRealSize = true;
				_fSizeInvalid = true;
			}
		}
			
		//----------------------------------
		//  stageWidth
		//----------------------------------
	
		/**
		 *  Storage for the stageWidth property.
		 */
		private var _stageWidth:Number = 500;
	
		/**
		 *  The width of the stage,
		 *  which is passed in by the Preloader class.
		 */
		public function get stageWidth(): Number {
			return _stageWidth;
		}
		
		
		public function set stageWidth(value:Number): void {
			if (value != 0 && (value != _stageWidth || !_fRealSize)) {
				_stageWidth = value;
				_fRealSize = true;
				_fSizeInvalid = true;
			}
		}

		/**
		 *  Read-only; Time the preloader was started in number of milliseconds since Epoch.
		 *  Only used for preloader performance logging.
		 */
		private var _preloaderStartTime:Number = 0;
		
		public function get preloaderStartTime(): Number {
		  return _preloaderStartTime;
		}

		//--------------------------------------------------------------------------
		//
		//  Methods:IPreloaderDisplay
		//
		//--------------------------------------------------------------------------
	
		/**
		 *  Called by the Preloader after the download progress bar
		 *  has been added as a child of the Preloader.
		 *  This should be the starting point for configuring your download progress bar.
		 */
		public function initialize(): void {
			_startTime = getTimer();
			_preloaderStartTime = new Date().getTime();
			
			// If we haven't made any real progress for 15 seconds, there is very likely
			// something wrong. The user will be presented with a little error dialog
			// rerouting them to a "troubleshooting" page, or they can just wait a little bit.
			_noProgressTimer = new Timer(15000);
			_noProgressTimer.addEventListener(TimerEvent.TIMER, OnNoProgressBeingMade);
			_noProgressTimer.start();
		}
		
		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------
		
		private function UpdateSize(): void {
			for each (var obImage:Object in _dctImagesByName) {
				PositionImage(obImage);
			}
			drawBackground();
			_fSizeInvalid = false;
		}
		
		/**
		 *  @private
		 *  Updates the display.
		 */
		private function draw(): void {
			if (_fSizeInvalid)
				UpdateSize();
			
			var percentage:Number;
	
			if (_startedLoading) {
				if (!_startedInit) {
					// 0 to MaxDL Percentage
					percentage = Math.round(getPercentLoaded(_value, _maximum) *
											DOWNLOAD_PERCENTAGE / 100);
				} else {
					// MaxDL percentage to 100
					percentage = Math.round((getPercentLoaded(_value, _maximum) *
											(100 - DOWNLOAD_PERCENTAGE) / 100) +
											DOWNLOAD_PERCENTAGE);
				}
			} else {
				percentage = getPercentLoaded(_value, _maximum);
			}
			setActualProgress(percentage);		
		}
		
		private var _fFirstProgress:Boolean = true;
		private var _nIntervalId:uint = 0;
		private var _nActualProgress:Number = 0;
		private var _nDisplayProgress:Number = 0;
		private var _nFirstProgress:Number = 0;
		private var _nProgressIntervals:Number = 0;
		private var _aRunningAvg:Array = [];

		private function  setActualProgress(nPercent:Number): void {
			if (_fFirstProgress && nPercent > 0) {
				_fFirstProgress = false;
				
				// Set up an interval to animate the progress bar smoothly every 100 ms
				_nIntervalId = setInterval( OnProgressInterval, 100 );
				_nDisplayProgress = 0;
				_nProgressIntervals = 0;
				_nFirstProgress = nPercent;
				_aRunningAvg = [];
			}			
			if (nPercent == 100) {
				// we're done!  Jump to 100% right away.
				clearInterval(_nIntervalId);
				if (_fProgBarLoaded) updateProgressBar(_nDisplayProgress);	
			} else {
				// store this value for later animation in OnProgressInterval
				// scale it to map 0..(100-first) to 0..100
				_nActualProgress = (nPercent - _nFirstProgress) * 100 / (100-_nFirstProgress);
				OnProgressInterval();
			}
		}
		
		private function OnProgressInterval():void {
			// This function smoothly animates the progress bar.
			// It assumes it'll get called about 10 times/second			
			_nProgressIntervals++;
			
			if (_aRunningAvg.push( _nActualProgress ) > 30)
				_aRunningAvg.shift(); // remove first element
				
			var nRecentRate:Number = (_aRunningAvg[_aRunningAvg.length-1] - _aRunningAvg[0]) / 30;
			
			// if we're falling behind (or getting ahead) make some
			// adjustments to the required rate.  We divide by some constant tp
			// smear this number adjustment across several frames
			nRecentRate += (_nActualProgress - _nDisplayProgress) / 10;

			// Make sure the slider always goes forwards!
			if (nRecentRate < 0 ) nRecentRate = 0;
			
			// update the display!
			_nDisplayProgress += nRecentRate;		
			if (_nDisplayProgress >= 100) {
				clearInterval(_nIntervalId);
				_nDisplayProgress = 100;
			}	

			if (_fProgBarLoaded) updateProgressBar(_nDisplayProgress);	
		}
		
		/**
		 *  Updates the display of the download progress bar
		 *  with the current download information.
		 *  A typical implementation divides the loaded value by the total value
		 *  and displays a percentage.
		 *  If you do not implement this method, you should create
		 *  a progress bar that displays an animation to indicate to the user
		 *  that a download is occurring.
		 *
		 *  <p>The <code>setProgress()</code> method is only called
	     *  if the application is being downloaded from a remote server
	     *  and the application is not in the browser cache.</p>
	     *
		 *  @param completed Number of bytes of the application SWF file
		 *  that have been downloaded.
		 *
		 *  @param total Size of the application SWF file in bytes.
		 */
		protected function setProgress(completed:Number, total:Number): void {
			if (!isNaN(completed) &&
			   !isNaN(total) &&
			   completed >= 0 &&
			   total > 0)
			{
				if (completed != _value || total != _maximum) {
					_noProgressTimer.reset();
					_noProgressTimer.start();
				}
				_value = Number(completed);
				_maximum = Number(total);
				draw();
			}	
		}	
		
		/**
		 *  Returns the percentage value of the application loaded.
	     *
		 *  @param loaded Number of bytes of the application SWF file
		 *  that have been downloaded.
		 *
		 *  @param total Size of the application SWF file in bytes.
		 *
		 *  @return The percentage value of the loaded application.
		 */
		protected function getPercentLoaded(loaded:Number, total:Number): Number {
			var perc:Number;
			
			if (loaded == 0 || total == 0 || isNaN(total) || isNaN(loaded))
				return 0;
			else
			 	perc = 100 * loaded/total;
	
			if (isNaN(perc) || perc <= 0)
				return 0;
			else if (perc > 99)
				return 99;
			else
				return Math.round(perc);
		}
		
		/**
		 *  @private
		 *  Make the display class visible.
		 */
		private function show(): void {
			if (_fDontShow || _showingDisplay)
				return;
			_showingDisplay = true;
			calcScale();
			draw();
		}
		
		/**
		 *  @private
		 */
		private function hide(): void {
		}
		
		/**
		 *  @private
		 *  Figure out the scale for the display class based on the stage size.
		 *  Then creates the children subcomponents.
		 */
		private function calcScale(): void {
			drawBackground();
		}
		
		/**
		 *  Defines the algorithm for determining whether to show
		 *  the download progress bar while in the download phase.
		 *
		 *  @param elapsedTime number of milliseconds that have elapsed
		 *  since the start of the download phase.
		 *
		 *  @param event The ProgressEvent object that contains
		 *  the <code>bytesLoaded</code> and <code>bytesTotal</code> properties.
		 *
		 *  @return If the return value is <code>true</code>, then show the
		 *  download progress bar.
		 *  The default behavior is to show the download progress bar
		 *  if more than 700 milliseconds have elapsed
		 *  and if Flex has downloaded less than half of the bytes of the SWF file.
		 */
		protected function showDisplayForDownloading(elapsedTime:int,
												  event:ProgressEvent):Boolean
		{
			return true;
//			return elapsedTime > 500 &&
//				event.bytesLoaded < event.bytesTotal / 2;
		}
		
		/**
		 *  Defines the algorithm for determining whether to show the download progress bar
		 *  while in the initialization phase, assuming that the display
		 *  is not currently visible.
		 *
		 *  @param elapsedTime number of milliseconds that have elapsed
		 *  since the start of the download phase.
		 *
		 *  @param count number of times that the <code>initProgress</code> event
		 *  has been received from the application.
		 *
		 *  @return If <code>true</code>, then show the download progress bar.
		 */
		protected function showDisplayForInit(elapsedTime:int, count:int): Boolean {
			return true;
//			return elapsedTime > 300 && count == 2;
		}

		//--------------------------------------------------------------------------
		//
		//  Event handlers
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  Event listener for the <code>ProgressEvent.PROGRESS</code> event.
		 *  This implementation updates the progress bar
		 *  with the percentage of bytes downloaded.
		 *
		 *  @param event The event object.
		 */
		
		protected function progressHandler(event:ProgressEvent): void {
			var loaded:uint = event.bytesLoaded;
			var total:uint = event.bytesTotal;
			
			var elapsedTime:int = getTimer() - _startTime;
			
			// Only show the Loading phase if it will appear for awhile.
//			if (loaded == total)
//				_fDontShow = true;

			CheckStageSize();
				
			if (_showingDisplay || showDisplayForDownloading(elapsedTime, event))
			{
				if (!_startedLoading)
				{
					show();
					_startedLoading = true;
				}
	
				setProgress(event.bytesLoaded, event.bytesTotal);
			}
		}
		
		/**
		 *  Event listener for the <code>RSLEvent.RSL_ERROR</code> event.
		 *  This event listner handles any errors detected when downloading an RSL.
		 *
		 *  @param event The event object.
		 */
		protected function rslErrorHandler(event:RSLEvent): void {
			DisplayError(root.loaderInfo.parameters["nonCdnServerRoot"] + "/error?log=true&err=RSLLoadFailure");
		}

		protected function rslEventHandler(event:RSLEvent): void {
			if (event.type == RSLEvent.RSL_COMPLETE) {
				_fRslLoaded = true;
				_noProgressTimer.reset();
				_noProgressTimer.start();
			}
			// Wait for RSLs sto start loading before loading graphics
			// If we load before RSLs start, RSL loading unloads our images (?!?)
			LoadGraphics();
		}
		
		public function DisplayError( strMoreInfoUrl:String, strImage:String = "../graphics/picnik_load_error.png" ): void {
			if (root.loaderInfo.parameters["ymail"] == "true") {
				// display an image asking users to click through to the error page
				var fnOnClick:Function = function(evt:MouseEvent):void {
					flash.net.navigateToURL(new URLRequest(strMoreInfoUrl), "_blank");			
				}
				var ob:Object = {
					strName:"errorImage",
					xOff:-286,
					yOff:-63,
					fProgBar:false,
					strUrl:strImage,
					dob:null,
					onclick:fnOnClick};
				_dctImagesByName[ob.strName] = ob;
				_dctImagesByLoaderInfo[LoadImage(ob)] = ob;
			} else {
				flash.net.navigateToURL(new URLRequest(strMoreInfoUrl), "_self");			
				if (!_showingDisplay) {
					show();
				}				
			}
		}
		
		public function InitProgress(nCompleted:Number, nTotal:Number): void {
			LoadGraphics(); // Just in case we didn't hit this already.
			CheckStageSize();
			_startedInit = true;
			if (!_showingDisplay) show();
			if (_obPostLoadImage) {
				AddImage(_obPostLoadImage);
				_obPostLoadImage = null;
			}
			if (nCompleted >= nTotal) {
				_fInitComplete = true;
				RemoveImages();
				_noProgressTimer.stop();
				dispatchEvent(new Event(Event.COMPLETE));
			} else {
				setProgress(nCompleted, nTotal-1);
			}
		}
		
		private function loader_ioErrorHandler(event:IOErrorEvent): void {
			// Swallow the error
		}

		//--------------------------------------------------------------------------
		//
		//  Code below here is new, NOT copied from DownloadProgressBar.as
		//
		//--------------------------------------------------------------------------

		protected function drawGradientRect(rc:Rectangle, aclrColors:Array, radDirection:Number = Math.PI/2): void {
			var mat:Matrix = new Matrix();
			var anRatios:Array = [ 0, 0xFF ];
			var anAlphas:Array = [ 1.0, 1.0 ];
			mat.createGradientBox(rc.width, rc.height, radDirection, rc.x, rc.y);
			graphics.beginGradientFill(GradientType.LINEAR, aclrColors, anAlphas,
					anRatios, mat);
			graphics.drawRect(rc.x, rc.y, rc.right, rc.bottom);
			graphics.endFill();
		}
		
		private function ShowGradientBackground(): Boolean {
			if (root.loaderInfo.parameters["lite"] == "true")
				return false;
			
			if (root.loaderInfo.parameters["mdlg"])
				return false;

			if (root.loaderInfo.parameters["plain_preloader"] == "true")
				return false;

			if (GooglePlusUtil.UsingGooglePlusAPIKey(root.loaderInfo.parameters))
				return false;

			return true;
		}
				
		/**
		 *  Creates the subcomponents of the display.
		 */
		protected function drawBackground(): void {
			if (!_fRealSize) return;
			try {
				var g:Graphics = graphics;
				g.clear();
				
				// Draw the background first
				g.beginFill(kclrBackground, 1);
				g.drawRect(0, 0, stageWidth, stageHeight);
				
				var cyBgBlueHeight:Number = stageHeight * knHeaderFooterPercentage * 0.01;
				
				// Don't show the gradient for Picnik lite or dialogmode
				if (ShowGradientBackground()) {
					// Top and bottom background gradients
					drawGradientRect(new Rectangle(0, 0, stageWidth, cyBgBlueHeight),
							kaclrTopAndBottomGradientColors); // Blue to white
					drawGradientRect(new Rectangle(0, stageHeight-cyBgBlueHeight, stageWidth, cyBgBlueHeight),
							kaclrTopAndBottomGradientColors, Math.PI / -2); // PI/-2 => reverse the direction
				}
			} catch (e:Error) {
				// Ignore preloader errors
			}
		}
		
		private function IsShowable(ob:Object):Boolean {
			var fShowable:Boolean = true;
			
			if ("fPreWaitOnly" in ob) {
				// check to see if the prewait flag is set.
				// otherwise, skip this item.
				if (!_soClientState ||
					_soClientState.data["socookie"] == undefined ||						
					_soClientState.data["socookie"]["prewait"] == undefined ||
					_soClientState.data["socookie"]["prewait"] == "false") {

					// also check in the swf params						
					if (root.loaderInfo.parameters['prewait'] == undefined ||
						root.loaderInfo.parameters['prewait'] == "false") {
						fShowable = false;
					}
				}
			}
			if ("fDialogModeOnly" in ob) {
				// check to see if the dialog_mode flag is set.
				// otherwise, skip this item.
				if (!root.loaderInfo.parameters['mdlg']) {
					fShowable = false;
				}
			}
			if ("fNonDialogModeOnly" in ob) {
				// check to see if the dialog_mode flag is set.
				// if it is, skip this item.
				if (root.loaderInfo.parameters['mdlg']) {
					fShowable = false;
				}
			}
			if (("fHideForGooglePlus" in ob) &&
				(GooglePlusUtil.UsingGooglePlusAPIKey(root.loaderInfo.parameters))) {
				fShowable = false;
			}
			
			return fShowable;
		}

		// Start loading all of our images
		// Set up our dictionaries so we can find them by loaderInfo or name
		private function LoadGraphics(): void {
			if (_dctImagesByName == null) {
				_dctImagesByName = new Dictionary();
				_dctImagesByLoaderInfo = new Dictionary(true);
				var ob:Object;
				for each (ob in _aobImages) {
					if (!IsShowable(ob)) continue;
					ob.dob = null; // Not loaded yet
					_dctImagesByName[ob.strName] = ob;
					_dctImagesByLoaderInfo[LoadImage(ob)] = ob;
				}
				for each (var bundle:Object in _aobBundles) {
					if (!IsShowable(bundle)) continue;
					for each (ob in bundle['aAssets']) {
						if (!IsShowable(ob)) continue;
						_aobImages.push(ob);
						ob.dob = null; // Not loaded yet
						_dctImagesByName[ob.strName] = ob;
					}
					bundle.dob = null; // Not loaded yet
					_dctImagesByLoaderInfo[LoadImage(bundle)] = bundle;
				}							
			}
		}
		
		private function GetUrl(obImage:Object): String {
			if (GooglePlusUtil.UsingGooglePlusAPIKey(root.loaderInfo.parameters) && ('strGooglePlusUrl' in obImage))
				return obImage.strGooglePlusUrl;
			else
				return obImage.strUrl;
		}

		// Start to load an image object.
		// Returns the loaderInfo for this load.
		private function LoadImage(obImage:Object): LoaderInfo {		
			// Load background image from external URL
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, OnLoadComplete);
			loader.contentLoaderInfo.addEventListener(
					IOErrorEvent.IO_ERROR, loader_ioErrorHandler);	
			var loaderContext:LoaderContext = new LoaderContext();
			loaderContext.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
			loader.load(new URLRequest(GetStaticUrl(GetUrl(obImage))), loaderContext);		

			return loader.contentLoaderInfo;
		}
		
		private function GetStaticUrl(strRelPath:String): String {
			var strVS:String = VersionStamp.getVersionStamp();
			if (strRelPath.indexOf("?") == -1) {
				strRelPath += "?"
			} else {
				strRelPath += "&"
			}
			strRelPath += "rel=" + strVS;
			if (!appRoot) {
				appRoot = root.loaderInfo.loaderURL.substr(
					0, root.loaderInfo.loaderURL.lastIndexOf("/") + 1);
			}
			return appRoot + strRelPath;
		}
				
		// Called when an image loads
		// Look up the image object by loaderInfo and update the image object dob (dispaly object)
		private function OnLoadComplete(event:Event): void {
			CheckStageSize();
			var ldrinf:LoaderInfo = LoaderInfo(event.target);
			
			// Images may continue to complete loading even after the Preloader
			// is finished. Somehow loadingPhrases.swf chews up inifinite memory
			// and eventually pegs CPU usage at 100% if we don't stop() it.
			if (_fInitComplete) {
				if (ldrinf.content is MovieClip)
					MovieClip(LoaderInfo(event.target).content).stop();
				ldrinf.loader.unload();
				return;
			}
			
			var obImage:Object = _dctImagesByLoaderInfo[ldrinf];
			if (obImage) {
				if ('aAssets' in obImage) {
					obImage.dob = DisplayObject(ldrinf.loader);
		        	for each (var ob:Object in obImage['aAssets']) {
						var clsImage:Class;
						var bmd:BitmapData = null;
						try {
							// Old bundle format
			        		clsImage = ldrinf.applicationDomain.getDefinition(ob.strId) as Class;
							bmd = new clsImage(10,10);
						} catch (e:Error) {
							// New bundle format (generated by picnik/imagebundle/build_pbar_bundles.py)
							var oBundle:Object = ldrinf.applicationDomain.getDefinition("Bundle") as Object;
							clsImage = oBundle[ob.strId] as Class;
							var obBitmap:Object = new clsImage();
							bmd = obBitmap.bitmapData;
						}
			        	if (bmd) {
			        		var bmpImage:Bitmap = new Bitmap;
			        		bmpImage.bitmapData = bmd;
			        		if (bmpImage) {
			        			ShowImage( ob, bmpImage, bmpImage.width, bmpImage.height );
			        		}
			        	}
		        	}
				} else {
					ShowImage( obImage, DisplayObject(ldrinf.loader), ldrinf.width, ldrinf.height );
				}
			}
		}
		
		private function ShowImage( obImage:Object, dob:DisplayObject, width:Number, height:Number ): void {
			obImage.dob = dob;
			obImage.width = width;
			obImage.height = height;
			if ("fPostLoad" in obImage && obImage.fPostLoad) {
				if (_startedInit)
					AddImage(obImage);
				else
					_obPostLoadImage = obImage;			
			} else if (!obImage.fProgBar) {
				AddImage(obImage);
			} else {
				if (AllProgBarImagesLoaded()) {
					OnAllProgBarImagesLoaded();
				}
			}			
		}

		// Called when the last progress bar image has loaded
		// Use this to initialize the progress bar
		private function OnAllProgBarImagesLoaded(): void {
			// Go ahead and add them.
			for each (var ob:Object in _aobImages) {
				if (ob.fProgBar) AddImage(ob);
			}
			var dobTrackMid:DisplayObject = getChildByName("pbTrackMid");
			if (dobTrackMid) {
				dobTrackMid.width = knTrackWidth;
				var dobTrackRight:DisplayObject = getChildByName("pbTrackRight");
				if (dobTrackRight) dobTrackRight.x = dobTrackMid.x + dobTrackMid.width - 1;
			}
			_fProgBarLoaded = true;
			show();
		}
		
		private function AddImage(obImage:Object): void {
			var dob:DisplayObject = DisplayObject(obImage.dob);
			if (dob != null) {
				PositionImage(obImage);
				dob.name = obImage.strName;
				if ('layer' in obImage) {
					for (var i:int = 0; i < numChildren; i++) {
						var dobkid:DisplayObject = getChildAt(i);
						var obimgKid:Object = _dctImagesByName[dobkid.name];
						if (obimgKid && ['layer'] in obimgKid && obimgKid.layer >= obImage.layer)
							break;
					}
					addChildAt(dob,i);
				} else {
					addChild(dob);
				}
				if ("onclick" in obImage && obImage["onclick"]) {
					dob.addEventListener(MouseEvent.CLICK, obImage["onclick"]);
				}
			}
		}
		
		private function PositionImage(obImage:Object): void {
			var dob:DisplayObject = DisplayObject(obImage.dob);
			if (dob != null) {
				if (obImage.explicitWidth) {
					if (obImage.explicitWidth == "stretch") {
						dob.scaleX = stageWidth / obImage.width;						
					} else {
						dob.scaleX = obImage.explicitWidth / obImage.width;
					}
				}
				if (obImage.explicitHeight) {
					if (obImage.explicitHeight == "stretch") {
						dob.scaleY = stageHeight / obImage.height;						
					} else {
						dob.scaleY = obImage.explicitHeight / obImage.height;
					}
				}
				
				if (obImage.halign == "left") {
					dob.x = 0;
				} else if (obImage.halign == "right") {
					dob.x = Math.round(stageWidth-obImage.width * dob.scaleX);
				} else if (obImage.halign == "center") {
					dob.x = Math.round((stageWidth - obImage.width * dob.scaleX)/2);
				} else {
					dob.x = Math.round(stageWidth / 2);
				}

				if (obImage.valign == "top") {
					dob.y = 0;
				} else if (obImage.valign == "bottom") {
					dob.y = Math.round(stageHeight-obImage.height * dob.scaleY);
				} else if (obImage.valign == "center") {
					dob.y = Math.round((stageHeight - obImage.height * dob.scaleY)/2);
				} else {
					dob.y = Math.round(stageHeight / 2);
				}
				
				if (obImage.xOff) {
					dob.x += obImage.xOff;
					if (GooglePlusUtil.UsingGooglePlusAPIKey(root.loaderInfo.parameters))
						dob.x -= 100;
				}
				if (obImage.yOff) {
					dob.y += obImage.yOff;
				}

			}
		}
		
		// This is very ham-fisted. Why aren't these automagically garbage collected?
		private function RemoveImages(): void {
			var ob:Object;
			for each (ob in _aobImages) {
				if (ob.dob) {
					if (ob.dob.parent)
						removeChild(ob.dob);
					if (ob.dob is Loader)
						Loader(ob.dob).unload();
					if (ob.dob is MovieClip)
						MovieClip(ob.dob).stop();
					ob.dob = null;
				}
			}
			for each (ob in _aobBundles) {
				if (ob.dob) {
					if (ob.dob.parent)
						removeChild(ob.dob);
					if (ob.dob is Loader)
						Loader(ob.dob).unload();
					if (ob.dob is MovieClip)
						MovieClip(ob.dob).stop();
					ob.dob = null;
				}
			}
		}
		
		private function AllProgBarImagesLoaded(): Boolean {
			var ob:Object;
			for each (ob in _aobImages) {
				if (ob.fProgBar && !ob.dob) {
					return false;
				}
			}
			return true;
		}
		
		/**
		 *  Update the progress bar to reflect progress
		 */
		private function updateProgressBar(percentage:Number): void {
			if (isNaN(percentage)) percentage = 0;

			// exponentify the progress to give it a curve.
			// mix it with an even slope to give more consistent
			// early movement and reduce the late acceleration
			percentage =  percentage*percentage/100 * 0.25 + percentage * 0.75;

			// Update the position of the bar middle and right
			var cxBarMiddleWidth:Number = knTrackWidth * percentage * 0.01;
			var dobBarMid:DisplayObject = getChildByName("pbBarMid");
			if (!dobBarMid) return;
			dobBarMid.width = cxBarMiddleWidth;
			var dobBarRight:DisplayObject = getChildByName("pbBarRight");
			if (dobBarRight) dobBarRight.x = dobBarMid.x + dobBarMid.width - 1;
		}
		
		/**
		 * We seem to be stalled in loading. Report it to both the user and
		 * our analytics engine.
		 */
		private function OnNoProgressBeingMade(evt:TimerEvent): void {
			if (_obNoProgressContainer == null) {
				var localContainer:Sprite = new Sprite();
				var localBackdrop:Shape = new Shape();				
				localContainer.addChild(localBackdrop);
	
				var localTextfield:TextField = new TextField();
				localTextfield.autoSize = TextFieldAutoSize.LEFT;
				localTextfield.antiAliasType = flash.text.AntiAliasType.ADVANCED;
				localTextfield.sharpness = -200;
				localTextfield.multiline = true;
				localContainer.addChild(localTextfield);
	
				_obNoProgressContainer = /* new object */ {
					strName:"NoProgressContainer",
					dob:localContainer,
					width:1,
					height:1,
					halign:"center",
					valign:"center",
					yOff:-100,
					backdrop: localBackdrop,
					textfield: localTextfield
				};
				// make sure it gets repositions when screen size changes.
				_dctImagesByName[_obNoProgressContainer.strName] = _obNoProgressContainer;
				AddImage(_obNoProgressContainer);
			}
	
			// Note that from here the code may be called more than once, basically only to update the little
			// debugging status message. Given the layout of the text this is very unlikely to actually change
			// the shape of anything, but it might. Seemed worth noting.
			var container:Sprite = Sprite(_obNoProgressContainer.dob);
			var backdrop:Shape = Shape(_obNoProgressContainer.backdrop);
			var textfield:TextField = TextField(_obNoProgressContainer.textfield);
			
			var moreInfoURL:String;
			if (root != null) {
				moreInfoURL = root.loaderInfo.parameters["nonCdnServerRoot"] + "/error?log=true&err=PreloaderError";
			} else {
				// this is wierd, and only seen once, but basically the app is so hosed we haven't even initialized
				// the display hierarchy yet. We just jam in a hard-wired URL and get on with it. C'est la vie.
				moreInfoURL = "http://www.mywebsite.com/error?log=true&err=PreloaderError";
			}
			
			textfield.htmlText =
				"<P align='left'>" +
					"<FONT face='trebuchetMS' size='15pt' color='#618430'>" +
						"We noticed Picnik is loading slowly. It’s possible waiting<BR>" +
						"may solve this issue. If you’re still having trouble:" +
					"</FONT>" +
				"</P>" +
				"<P align='right'>" +
					"<FONT face='trebuchetMS' size='10pt' color='#618430'>" +
						"<I>" +
							"[" + (_fRslLoaded ? "t" : "f") + _value + "]" +
						"</I>" +
					"</FONT>" +
					"<FONT face='trebuchetMS' size='14pt' color='#2D4006'>" +
						"<A target='_self' href='" + moreInfoURL + "'>" +
							"<B>" +
								"   Click for Assistance\u00BB" +
							"</B>" +
						"</A>" +
					"</FONT>" +
				"</P>";
			
			// Figure out position of the TextField.
			var hpad:int = 20;
			var vpad:int = 10;
			textfield.x = hpad;
			textfield.y = vpad;
			
			// Now get the text field size, expand and draw the backdrop
			var bounds:Rectangle = textfield.getBounds(container);
			bounds.inflate(hpad, vpad);
			backdrop.graphics.clear();
			backdrop.graphics.beginFill(0xD6EFB2);
			backdrop.graphics.drawRoundRect(bounds.left, bounds.top, bounds.width, bounds.height, 8, 8);
			backdrop.graphics.endFill();
			
			// set the container's size to match the backdrop, and redraw it.
			container.width = bounds.width;
			container.height = bounds.height;
			_obNoProgressContainer.width = bounds.width;
			_obNoProgressContainer.height = bounds.height;
			PositionImage(_obNoProgressContainer);
			
			// Notify Google Analytics.
			try {
				ExternalInterface.call("urchinTracker", "/r/preloaderError/" + (_fRslLoaded ? "t" : "f") + "/" + _value);
			} catch (err:Error) {
				// Ignore
			}
		}
	}
}
