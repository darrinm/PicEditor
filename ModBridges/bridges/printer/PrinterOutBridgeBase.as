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
package bridges.printer {
	import bridges.OutBridge;
	
	import containers.ProportionalScaleCanvas;
	
	import controls.PrintPreview;
	import controls.PrintPreviewBase;
	
	import dialogs.PrintChangeDialogBase;
	
	import events.ActiveDocumentEvent;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	import flash.printing.PrintJob;
	import flash.printing.PrintJobOptions;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Image;
	import mx.controls.RadioButton;
	import mx.core.UIComponentGlobals;
	import mx.core.mx_internal;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
	
	import util.PicnikAlert;
	import util.PrintLayout;
	import util.PrintPhotoLayout;
	
	use namespace mx_internal;
	
	public class PrinterOutBridgeBase extends OutBridge {
		[Bindable] public var _btnPrint:Button;
		[Bindable] public var _cmboLayout:ComboBox;
		[Bindable] public var _imgThumb1:Image;
		[Bindable] public var _imgThumb2:Image;
		[Bindable] public var _imgPrint:Image;
		[Bindable] public var calibrated:Boolean = false;
		[Bindable] public var _prpv:PrintPreview;
		[Bindable] public var _pscnv:ProportionalScaleCanvas;
		
		[Bindable] public var _rbtnCrop:RadioButton;
		[Bindable] public var _rbtnScale:RadioButton;
		[Bindable] public var _obPrintMetrics:Object = null;
		
   		[ResourceBundle("PrinterOutBridge")] private var _rb:ResourceBundle;
   				
		private var _bm:Bitmap = null;
		
		public var _strSentToPrinterNotifyMessage:String;

		public var _strCalibratePageSetupCancelTitle:String;
		public var _strCalibratePageSetupCancelText:String;
		
		private const knPointsPerIn:Number = 72;
		private const knPointsPerCm:Number = 567/20;

		private var _prtj:PrintJob;
		
		private static const knPrintFailed:Number = 0;
		private static const knPrinted:Number = 1;
		
		public function PrinterOutBridgeBase() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}

		private function OnCreationComplete(evt:FlexEvent):void {
			_btnPrint.addEventListener(MouseEvent.CLICK, OnPrintClick);
		}
		
		private function ResetPrintImage(): void {
			if (_imgPrint) {
				_imgPrint.scaleX = 1;
				_imgPrint.scaleY = 1;
				_imgPrint.rotation = 0;
				if (_bm) {
					_bm.x = 0;
					_bm.y = 0;
				}
				if (_imgd && _imgd.composite) {
					_imgPrint.width = _imgd.composite.width;
					_imgPrint.height = _imgd.composite.height;
				}
			}
		}
		
		public override function OnActivate(strCmd:String=null):void {
			super.OnActivate(strCmd);
			UpdatePrintSize();
		}
		
		protected override function OnActiveDocumentChange(evt:ActiveDocumentEvent):void {
			super.OnActiveDocumentChange(evt);
			UpdatePrintSize();
		}
		
		protected function OnSizeChange(): void {
			// Override in sub-classes
		}
		
		private function UpdatePrintSize(): void {
			if (_cmboLayout != null && _imgd != null && _imgd.height > 0) {
				_cmboLayout.selectedIndex = 0;
				/*
				var nAspectRatio:Number = _imgd.width / _imgd.height;
				var ac:ArrayCollection = _cmboLayout.dataProvider as ArrayCollection;
				
				if (ac != null) {
					var nMinDiff:Number = Number.MAX_VALUE;
					var iMinDiff:Number = -1;
				
					for (var i:Number = 1; i < ac.length; i++) {
						var strFormat:String = String(ac.getItemAt(i).data);
						if (IsNumericFormat(strFormat)) {
							var ptFormatDims:Point = ParseNumericFormat(strFormat);
							var nFormatAspectRatio:Number = ptFormatDims.x / ptFormatDims.y;
							var nDiff:Number = Math.abs(nAspectRatio - nFormatAspectRatio) / nFormatAspectRatio;
							if (nDiff < nMinDiff) {
								nMinDiff = nDiff;
								iMinDiff = i;
							}
							// Try rotating 90 degrees
							nFormatAspectRatio = 1/nFormatAspectRatio;
							nDiff = Math.abs(nAspectRatio - nFormatAspectRatio) / nFormatAspectRatio;
							if (nDiff < nMinDiff) {
								nMinDiff = nDiff;
								iMinDiff = i;
							}
						}
					}
					if (nMinDiff < 0.02) { // 2% tollerance
						_cmboLayout.selectedIndex = iMinDiff;
						OnSizeChange();
					}
				}
				*/
			}
		}
		
		// Returns true on success, false on failure (probably shows an alert, too)
		public function UpdatePrintImage(): Boolean {
			// Update image rotation, position, and scale
			// Does nothing for full sized.
			// Half sized is not supported.
			if (!_imgd || !_imgd.composite) return false;
			
			while (_imgPrint.numChildren) _imgPrint.removeChildAt(0);
			var prlo:PrintLayout = new PrintLayout(_obPrintMetrics, GetSelectedPrintArea(), _rbtnCrop.selected, _imgd.composite);
			if (prlo.outOfBounds) return false;

			var nWidth:Number = _obPrintMetrics.ptPrintSize.x;
			var nHeight:Number = _obPrintMetrics.ptPrintSize.y;

			var aloFirstPageItems:Array = prlo.firstPageItems;
			// UNDONE: Handle multiple pages

			// We don't get margins, only page size and print size.
			// Estimate margins assuming top/bottom and left/right are equal.
			var spr:Sprite = new Sprite();
			spr.graphics.beginFill(0xffffff);
			spr.graphics.drawRect(0,0, nWidth, nHeight);
			_imgPrint.addChildAt(spr, 0);
			for each (var plo:PrintPhotoLayout in aloFirstPageItems) {
				var cnv:Canvas = plo.CreateImage(_imgd.composite);
				// Rotate to fit
				_imgPrint.addChild(cnv);
			}
			_imgPrint.width = nWidth;
			_imgPrint.height = nHeight;
			return true; // Success
		}
		
		private function IsNumericFormat(strFormat:String): Boolean {
			return (strFormat.length > 6 && strFormat.substr(0, 6) == "single");
		}
		
		private function ParseNumericFormat(strFormat:String): Point {
			var astrMatch:Array = strFormat.match(/single (\d+)x(\d+)(.*)/i);
			if (astrMatch == null)
				throw new Error("Failed to parse format: " + strFormat);
			var nPointsPer:Number = (astrMatch[3] == 'cm') ? knPointsPerCm : knPointsPerIn;
			var cxDesired:Number = Number(astrMatch[1]) * nPointsPer;
			var cyDesired:Number = Number(astrMatch[2]) * nPointsPer;
			
			return new Point(cxDesired, cyDesired);
		}

		public function SelectedPrintAreaToObject(str:String): Object {
			var cxDesired:Number = 0;
			var cyDesired:Number = 0;
			var fFullPage:Boolean = true;
			
			if (str && str.length > 0) {
				var strFormat:String = _cmboLayout.selectedItem.data;
				fFullPage = false;
				if (strFormat == "full page") {
					fFullPage = true;
					cxDesired = 0;
					cyDesired = 0;
				} else if (IsNumericFormat(strFormat)) {
					var ptDesired:Point = ParseNumericFormat(strFormat);
					cxDesired = ptDesired.x;
					cyDesired = ptDesired.y;
				}
			}
			return {ptDesired:new Point(cxDesired, cyDesired), fFullPage:fFullPage};
		}
		
		// Returns {ptDesired}
		// {0,0} means full page
		private function GetSelectedPrintArea(): Object {
			var strSelected:String = null;
			if (_cmboLayout && _cmboLayout.selectedItem && _cmboLayout.selectedItem.data) {
				strSelected = _cmboLayout.selectedItem.data;
			}
			return SelectedPrintAreaToObject(strSelected);
		}
		
		private var _strPreviousMetricsLogEntry:String = "";
		
		private function OnPrintClick(evt:MouseEvent): void {
			_prtj = null;
			var prtj:PrintJob = new PrintJob();
			if (!prtj.start())
				return;
			
			try {
				_obPrintMetrics = {ptPageSize: new Point(prtj.paperWidth, prtj.paperHeight),
								   ptPrintSize: new Point(prtj.pageWidth, prtj.pageHeight)}
					
				_strPreviousMetricsLogEntry = "/previously_" + GetMetricsLogName(_prpv.PrintMetrics);

				var nChange:Number = _prpv.UpdatePrintMetrics(_obPrintMetrics);
				calibrated = true;
				if (!UpdatePrintImage()) nChange = PrintPreviewBase.knOutOfBoundsChange;
				_pscnv.ForceRelayout();
				validateNow();
				_prtj = prtj;
				if (nChange == PrintPreviewBase.knNoChange || nChange == PrintPreviewBase.knSmallChange) {
					_strPreviousMetricsLogEntry = ""; // No change
					FinishPrinting();
				} else if (nChange == PrintPreviewBase.knMediumChange) {
					// Warn of pending change, then print.
					PrintChangeDialogBase.Show(this, OnPrintChangeAlert, PrintChangeDialogBase.kstrPageChange);
				} else if (nChange == PrintPreviewBase.knOutOfBoundsChange) {
					// Alert
					PrintChangeDialogBase.Show(this, OnPrintChangeAlert, PrintChangeDialogBase.kstrOutOfBounds);
				}
			} catch (err:Error) {
				PicnikService.Log("Error printing: " + err + ", " + err.getStackTrace(), PicnikService.knLogSeverityInfo);
				trace("print error: " + err);
			}
		}
		
		public function Calibrate(): void {
			PrintChangeDialogBase.Show(this, OnCalibrate, PrintChangeDialogBase.kstrCalibrate);
		}
		
		public function OnCalibrate(fCalibrate:Boolean): void {
			if (fCalibrate) {
				try {
					var prtj:PrintJob = new PrintJob();
					if (!prtj.start()) {
						// User canceled print
						PicnikAlert.show(_strCalibratePageSetupCancelText, _strCalibratePageSetupCancelTitle);
					} else {
						// Calibrated.
						_obPrintMetrics = {ptPageSize: new Point(prtj.paperWidth, prtj.paperHeight),
										   ptPrintSize: new Point(prtj.pageWidth, prtj.pageHeight)}
						var nChange:Number = _prpv.UpdatePrintMetrics(_obPrintMetrics);
						calibrated = true;
						_pscnv.ForceRelayout();
						validateNow();
						prtj.send(); // "Finish" the empty print job
					}
				} catch (err:Error) {
					PicnikAlert.show(Resource.getString("PrinterOutBridge", "calibration_failed"));
					trace("Ignoring error while calibrating: " + err);
				}
			}
		}
		
		
		private function OnPrintChangeAlert(fPrint:Boolean): void {
			if (fPrint) {
				if (FinishPrinting(true) == knPrintFailed) {
					OnPrintClick(null);
				}
			} else {
				try {
					_prtj.send(); // Print nothing so the print job can end.
				} catch (err:Error) {
					trace("Ignoring error while sending blank print job: " + err);
				}
				_prtj = null;
			}
		}
		
		public function FormatInches(nInches:Number): String {
			nInches = Math.round(nInches * 10) / 10;
			return nInches.toString();
		}
		
		public function FormatCentimeters(nSize:Number): String {
			nSize = Math.round(nSize * 10) / 10;
			return nSize.toString();
		}
		
		public function ReplaceVars(obPrintMetrics:Object, str:String): String {
			if (obPrintMetrics == null) return "";
			var strPageWidthIn:String = FormatInches(obPrintMetrics.ptPageSize.x/knPointsPerIn);
			var strPageHeightIn:String = FormatInches(obPrintMetrics.ptPageSize.y/knPointsPerIn);
			var strPageWidthCm:String = FormatCentimeters(obPrintMetrics.ptPageSize.x/knPointsPerCm);
			var strPageHeightCm:String = FormatCentimeters(obPrintMetrics.ptPageSize.y/knPointsPerCm);
			var strOut:String = str;
			strOut = strOut.replace(/{_strPageWidthIn}/gi, strPageWidthIn);
			strOut = strOut.replace(/{_strPageHeightIn}/gi, strPageHeightIn);
			strOut = strOut.replace(/{_strPageWidthCm}/gi, strPageWidthCm);
			strOut = strOut.replace(/{_strPageHeightCm}/gi, strPageHeightCm);
			return strOut;
		}
		
		private function GetPhotoSizeLogName(): String {
			// Return a nice name of the photo size to use in analytics event logging
			var strPhotoSizeLogName:String = "unknown";
			if (_cmboLayout && _cmboLayout.selectedItem && _cmboLayout.selectedItem.data) {
				strPhotoSizeLogName = String(_cmboLayout.selectedItem.data);
				strPhotoSizeLogName = strPhotoSizeLogName.replace(/ /g, '_');
			}
			return strPhotoSizeLogName;
		}
		
		private const kaanStandardSizes:Array = [
			[13,19],
			[11,17],
			[8.5,11],
			[8,10],
			[5,7],
			[4,6]
		];
		
		// Returns null if no close size was found
		private function MapToStandardSize(nShortSide:Number, nLongSide:Number, nLeniancy:Number=0.05): Array {
			for each (var anSize:Array in kaanStandardSizes) {
				var nDist:Number = Math.max(Math.abs(nShortSide - anSize[0]) / anSize[0], Math.abs(nLongSide - anSize[1]) / anSize[1]);
				if (nDist < nLeniancy)
					return anSize;
			}
			return null;
		}
	
		
		
		private function GetMetricsLogName(obMetrics:Object): String {
			// Standard paper sizes or "other"
			// fCalibrated:false, ptPrintSize:new Point(72*8, 72*10), ptPageSize:new Point(72*8.5, 72*11)}
			if ('fCalibrated' in obMetrics && !obMetrics.fCalibrated)
				return "uncalibrated_8.5x11";
			// Calibrated. Find closes size to one of the following, otherwise return "other/<width>x<height>x<border average>" where sizes are rounded to nearest tenth of an inch
			var nInchWidth:Number = obMetrics.ptPageSize.x / 72;
			var nInchHeight:Number = obMetrics.ptPageSize.y / 72;
			var nShortSide:Number = Math.min(nInchWidth, nInchHeight);
			var nLongSide:Number = Math.max(nInchWidth, nInchHeight);
			var nInchBorderAverage:Number = Math.round((obMetrics.ptPageSize.x - obMetrics.ptPrintSize.x + obMetrics.ptPageSize.y - obMetrics.ptPrintSize.y) / (2 * 72));
			var anSize:Array = MapToStandardSize(nShortSide, nLongSide);
			
			var strResult:String = "";
			if (anSize == null) {
				
				// No close size found. Round to nearest 0.5 inch number and return
				nShortSide = Math.round(nShortSide * 2) / 2;
				nLongSide = Math.round(nLongSide * 2) / 2;
				anSize = [nShortSide, nLongSide];
				strResult += "other/";
			}
			strResult += anSize[0] + "x" + anSize[1];
			strResult += "m" + nInchBorderAverage;
			return strResult;
		}
		
		private function FinishPrinting(fSizeChange:Boolean=false): Number {
			var nRet:Number = knPrinted;
			if (_prtj == null) {
				nRet = knPrintFailed;
			} else {
				try {
					// This "adjusts" our print image so that it can be printed.
					// Not sure why this is necessary. Copied from FlexPrintJob
					UIComponentGlobals.layoutManager.usePhasedInstantiation = false;
					UIComponentGlobals.layoutManager.validateNow();
					
					_prtj.addPage(Sprite(_imgPrint), null, new PrintJobOptions(true));
					_prtj.send();
				
					PicnikBase.app.Notify(_strSentToPrinterNotifyMessage);
					ReportSuccess(null, "print");
					// Log the print: /r/localPrinting/<ignoredSizeChange or calibrated>/<pageSize>[/<prewarning page size>]/<photoSize>/<Scaled or cropped>
					var strReport:String = "/localPrinting";
					strReport += fSizeChange ? "/ignoredSizeChange" : "/calibrated";
					strReport += "/" + GetMetricsLogName(_prpv.PrintMetrics);
					strReport += _strPreviousMetricsLogEntry;
					strReport += "/" + GetPhotoSizeLogName();
					strReport += _rbtnCrop.selected ? "/croppped" : "/scaled";
					Util.UrchinLogReport(strReport);
				} catch (err:Error) {
					PicnikService.Log("Error printing:2: " + err + ", " + err.getStackTrace(), PicnikService.knLogSeverityInfo);
					trace("print error: " + err);
					nRet = knPrintFailed;
				}
				_prtj = null;
			}
			return nRet;
		}
	}
}
