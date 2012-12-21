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
// Set the flag s_fDebug to true to enable tracking of all created and disposed bitmaps.
// As bitmaps are created and disposed a mini-stacktrace is traced. VBitmapData also
// watches for redundantly disposed bitmaps, which may indicate a bug.

// NOTE: when s_fDebug is false, VBitmapData.clone() returns a BitmapData, not a VBitmapData.
// This is because VBitmapData cloning requires BitmapData initialization (to a solid color)
// and then a copyPixel(). Presumably Flash's BitmapData.clone() is more efficient.

// NOTE: The client unit tests automatically set s_fDebug to true so they can watch for
// memory leaks.

package util {
	import errors.InvalidBitmapError;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.IBitmapDrawable;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.Dictionary;
	
	import imagine.ImageDocument;
	
	import mx.formatters.NumberFormatter;
	
	public class VBitmapData extends BitmapData {
		public static var s_fDebug:Boolean = false;
		
		// Use s_fLog for performance testing. Turn it on and uncomment the logging lines, below, to
		// get debug output for bitmap actions which might consume time, plus the dimensions of the action (e.g. drawing 1000x1000 pixels)
		private static var s_fLog:Boolean = false;
		private static var s_fLogCreateDispose:Boolean = false;
		private static var s_fHideStackTrace:Boolean = false;
		private static var s_fLogMaxBytes:Boolean = false;
		
		public static var s_dtCreated:Dictionary = null;
		public static var s_nFailOdds:Number = 60;	// used for random cumulative fail testing
		public static var s_cbmdUndisposed:Number = 0;
		public static var s_nEstimatedBytesUndisposed:Number = 0; // 4 bytes per pixel
		public static var s_nMaxBytesUndisposed:Number = 0;
		public static var s_edChangeListener:EventDispatcher = null;
		private static var s_idMax:Number = 1;
		public var _id:Number = 0;
		private var _fDisposed:Boolean = false;
		public var _strCreateStacktrace:String;
		public var _strDisposeStacktrace:String;
		public var _strDebugName:String = null;
		public var _fReferenced:Boolean = false;

		private static var _abmdPool:Array = [];
		private static const knMaxPoolSize:Number = 3;

		private var _fNeedsLockUnlockBeforeDisplay:Boolean = false;

		public static function Construct(cx:int, cy:int, fTransparent:Boolean=true, coFill:Number=0xffffffff, strDebugName:String="untitled"):VBitmapData {
			var vbmdNew:VBitmapData = null;
			for (var i:Number = 0; i < _abmdPool.length; i++) {
				var vbmdPool:VBitmapData = _abmdPool[i];
				if (vbmdPool.width == cx && vbmdPool.height == cy && vbmdPool.transparent == fTransparent) {
					// Found it.
					vbmdNew = vbmdPool;
					vbmdNew._strDebugName = strDebugName;
					vbmdNew._fNeedsLockUnlockBeforeDisplay = true;
					_abmdPool.splice(i, 1);
					if (!isNaN(coFill)) {
						vbmdNew.fillRect(vbmdNew.rect, coFill);
					}
					if (s_fDebug) {
						if (s_fLogCreateDispose) {
							trace("VBitmap:PullingFromFreePool:" + vbmdNew);
						}
						try {
							var err:Error = new Error("stacktrace");
							var strStacktrace:String = err.getStackTrace();
							var astrTrace:Array = strStacktrace.split("\n", 7);
							strStacktrace = astrTrace.slice(2).join("\n");
							if (s_fLogCreateDispose && !s_fHideStackTrace) {
								trace("  " + strStacktrace);
							}
						} catch (err:Error) {}
					}
					break;
				}
			}
			if (vbmdNew == null) {
				// BST: Try not to let the pool increase our max image consumption.
				// If we don't find what we want in the pool free up some memory
				// by removing something from the pool before creating a new bitmap.
				if (_abmdPool.length > 0) {
					var vbmdDispose:VBitmapData = _abmdPool.shift();
					vbmdDispose._dispose();
				}
				vbmdNew = new VBitmapData(cx, cy, fTransparent, coFill, strDebugName);
			}
			return vbmdNew;
		}

		public function VBitmapData(cx:int, cy:int, fTransparent:Boolean=true, coFill:uint=0xffffffff, strDebugName:String="untitled") {
			try {
				super(cx, cy, fTransparent, coFill);
			} catch (e:Error) {
				//PicnikService.Log("Client Exception: VBitmapData ctor (" + cx + "," + cy + "," + fTransparent + "," + coFill + ") memusage:" + System.totalMemory + ";" + e + ", " + e.getStackTrace(), PicnikService.knLogSeverityError);
				if (cx <= 0 || cy <= 0 || cx > Util.GetMaxImageWidth(1) || cy > Util.GetMaxImageHeight(1))
					throw new InvalidBitmapError(InvalidBitmapError.ERROR_ARGUMENTS,
							"InvalidBitmapError (arguments cx: " + cx + ", cy: " + cy + ", FP: " + Util.GetFlashPlayerMajorVersion() + ")");
				else 				
					throw new InvalidBitmapError(InvalidBitmapError.ERROR_MEMORY);
			}				
			_id = s_idMax++;
			_strDebugName = strDebugName;

			s_nEstimatedBytesUndisposed += GetByteSize();
			
			if (s_fDebug) {
				//				// fail randomly!
				//				if (Math.floor( Math.random() * s_nFailOdds ) == 0) {
				//					s_nFailOdds /= 2;
				//					trace( "\n==================\nBLECH!!!!!!!!!!!!!\n==================" );
				//					throw new InvalidBitmapError(InvalidBitmapError.ERROR_ARGUMENTS);							
				//				}
				
				s_cbmdUndisposed++;
				if (s_nEstimatedBytesUndisposed > s_nMaxBytesUndisposed) {
					s_nMaxBytesUndisposed = s_nEstimatedBytesUndisposed;
					if (s_fLogMaxBytes)
						trace("New max bytes undisposed: " + FormatBytes(s_nMaxBytesUndisposed) + ", " + s_cbmdUndisposed);
				}
				if (s_dtCreated == null) {
					s_dtCreated = new Dictionary(true);
				}
				s_dtCreated[this] = this;
				
				if (s_fLogCreateDispose) trace("VBitmap:Created:" + this);			
				try {
					var err:Error = new Error("stacktrace");
					var strStacktrace:String = err.getStackTrace();
					var astrTrace:Array = strStacktrace.split("\n", 7);
					_strCreateStacktrace = astrTrace.slice(2).join("\n");
					if (s_fLogCreateDispose && !s_fHideStackTrace) trace("  " + _strCreateStacktrace);
				} catch (err:Error) {}
				if (s_edChangeListener != null)
					s_edChangeListener.dispatchEvent(new Event("VBitmapChange"));
			}
		}
		
		public function PrepareToDisplay(): void {
			if (_fNeedsLockUnlockBeforeDisplay) {
				lock();
				unlock();
				_fNeedsLockUnlockBeforeDisplay = false;
			}
		}
		
		private static var _snf:NumberFormatter = new NumberFormatter();
		private static const kastrByteUnits:Array = ['B','KB','MB','GB','TB'];
		
		private static function FormatBytes(nBytes:Number): String {
			var nf:NumberFormatter = new NumberFormatter();
			var i:Number = 0;
			while (nBytes >= 1000 && i < (kastrByteUnits.length-1)) {
				i++;
				nBytes /= 1024;
			}
			nBytes = Math.round(nBytes * 10) / 10; // Add one decimal place
			return nBytes.toString() + kastrByteUnits[i];
		}
		
		private function get disposedStatus(): String {
			return " (total undisposed: " + s_cbmdUndisposed + "/" + FormatBytes(s_nEstimatedBytesUndisposed) + "/" + FormatBytes(System.totalMemory) + ")";
		}
		
		public function get valid(): Boolean {
			return (!_fDisposed && _id != 0);
		}		
				
		// override width and height so that we can keep track of whether someone
		// is trying to get the width & height after we've been disposed.
		override public function get width():int {
			try {
				return super.width;
			} catch (e:Error) {
				// Wow, we're hitting this a lot right now.  Turn off while we try to fix it.
				//PicnikService.Log("Client Exception: VBitmapData:width (disp:" + _fDisposed + ") " + e.toString() + ", " + e.getStackTrace(), PicnikService.knLogSeverityError);
				trace("tried to get width for invalid bitmap: " + this);
				throw new InvalidBitmapError( _fDisposed ? InvalidBitmapError.ERROR_DISPOSED : InvalidBitmapError.ERROR_UNKNOWN );
			}			
			return undefined;	
		}
		
		private static function GetBmdByteSize(bmd:BitmapData): Number {
			try {
				return bmd.width * bmd.height * (bmd.transparent ? 4 : 3);
			} catch (e:Error) {
				// fall through
			}
			return 0;
		}
		
		private function GetByteSize(): Number {
			if (_fDisposed) return 0;
			return GetBmdByteSize(this);
		}
		
		public function toString():String {
			var strSize:String = "";
			if (!_fDisposed) {
				try {
					strSize = "|" + this.width + " x " + this.height;
					
				} catch (e:Error) {
					// Ignore errors getting the size
				}
			}
			var strOut:String = "VBitmapData[id=" + _id + "|" + _strDebugName + (this._fDisposed ? "|DISPOSED" : "") + strSize + "|" + FormatBytes(GetByteSize());
			
			if (s_fDebug)
				strOut += "|" + s_cbmdUndisposed + "," + FormatBytes(s_nEstimatedBytesUndisposed); 
			
			return strOut + "]";
		}
		
		override public function get height():int {
			try {
				return super.height;
			} catch (e:Error) {
				// Wow, we're hitting this a lot right now.  Turn off while we try to fix it.
				//PicnikService.Log("Client Exception: VBitmapData:height (disp:" + _fDisposed + ") " + e.toString() + ", " + e.getStackTrace(), PicnikService.knLogSeverityError);
				throw new InvalidBitmapError( _fDisposed ? InvalidBitmapError.ERROR_DISPOSED : InvalidBitmapError.ERROR_UNKNOWN );
			}		
			return undefined;	
		}
		
		override public function clone(): BitmapData {
			if (s_fLog) trace("VBitmap:Cloned: " + this);		
			try {
				var vbmdClone:VBitmapData = Construct(width, height, transparent, NaN, "clone of " + this._strDebugName);
				vbmdClone.copyPixels(this, new Rectangle(0, 0, width, height), new Point(0, 0));
				return vbmdClone;
			} catch (e:InvalidBitmapError) {
				// just pass e along since it's already got the data we want
				throw e;
			} catch (e:Error) {
				throw new InvalidBitmapError( _fDisposed ? InvalidBitmapError.ERROR_DISPOSED : InvalidBitmapError.ERROR_MEMORY );
			}	
			return null;		
		}
		
		public static function TraceUndisposed(): void {
			if (s_fDebug == false) {
				trace("set s_fDebug to true to dump created bitmaps");
			} else {
				var avbmdUndisposed:Array = [];
				var vbmd:VBitmapData;
				for each (vbmd in s_dtCreated)
					avbmdUndisposed.push(vbmd);
				
				avbmdUndisposed.sortOn('_id', Array.NUMERIC);
				
				for each (vbmd in avbmdUndisposed) {
					trace("Undisposed: " + vbmd);
					if (!s_fHideStackTrace) trace("   " + vbmd._strCreateStacktrace);
					// trace(BitmapReferenceData.GetDebugInfo(vbmd));
				}
			}
		}
		
		// Debugging: Uncomment these lines when you set s_fDebug == true
		/*
		override public function copyChannel(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, sourceChannel:uint, destChannel:uint):void {
			if (s_fLog) trace("VBitmap:copyChannel[" + sourceRect.width+ ", " + sourceRect.height + "]");		
			super.copyChannel(sourceBitmapData, sourceRect, destPoint, sourceChannel, destChannel);
		}
		
		override public function copyPixels(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, alphaBitmapData:BitmapData=null, alphaPoint:Point=null, mergeAlpha:Boolean=false):void {
			if (s_fLog) trace("VBitmap:copyPixels[" + sourceRect.width+ ", " + sourceRect.height + "], " + alphaBitmapData);
			super.copyPixels(sourceBitmapData, sourceRect, destPoint, alphaBitmapData, alphaPoint, mergeAlpha);
		}

		override public function applyFilter(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, filter:BitmapFilter):void {
			if (s_fLog) trace("VBitmap:applyFilter[" + sourceRect.width+ ", " + sourceRect.height + "], " + filter);
			super.applyFilter(sourceBitmapData, sourceRect, destPoint, filter);
		}		
		*/
		
		override public function draw(source:IBitmapDrawable, matrix:Matrix=null, colorTransform:ColorTransform=null, blendMode:String=null, clipRect:Rectangle=null, smoothing:Boolean=false):void {
			if (s_fLog) {
				var bmdSrc:BitmapData = (source is BitmapData) ? (source as BitmapData) : this;
				trace("VBitmap:draw[" + bmdSrc.width+ ", " + bmdSrc.height + "], " + blendMode + ", " + smoothing + ", " + clipRect + ", "+ colorTransform);
			}
			try {
				super.draw(source, matrix, colorTransform, blendMode, clipRect, smoothing);
			} catch (err:Error) {
				/* DWM: Don't log this until the HSBColorPicker is revised to stop throwing an exception
				when crossdomain-inaccessable images (e.g. Flickr avatars) are on the stage.
				PicnikService.Log("Client Exception: in VBitmapData.draw(" + (source as Object).toString() + "," +
						(matrix != null ? matrix.toString() : "null") + "," +
						(colorTransform != null ? colorTransform.toString() : "null") + "," +
						blendMode + "," + clipRect + "," + smoothing + ") " + err.getStackTrace(),
						PicnikService.knLogSeverityError);
				*/
				throw err; // match BitmapData's behavior
			}
		}

		public static function SafeDispose(bmd:BitmapData): void {
			// if (true)
			if (s_fDebug && !(bmd is VBitmapData))
				ImageDocument.ValidateBitmapdataUnused(bmd);
			bmd.dispose();
		}
		
		public static function OnBitmapRefCreated(bmd:BitmapData): void {
			if (!(bmd is VBitmapData))
				s_nEstimatedBytesUndisposed += GetBmdByteSize(bmd);
		}
		
		public static function OnBitmapRefDispose(bmd:BitmapData): void {
			if (!(bmd is VBitmapData))
				s_nEstimatedBytesUndisposed -= GetBmdByteSize(bmd);
		}

		override public function dispose(): void {
			if (s_fDebug) {
				if (s_fLogCreateDispose) {
					trace("VBitmap:AddingToFreePool:" + this);
				}
				try {
					var err:Error = new Error("stacktrace");
					var strStacktrace:String = err.getStackTrace();
					var astrTrace:Array = strStacktrace.split("\n", 7);
					strStacktrace = astrTrace.slice(2).join("\n");
					if (s_fLogCreateDispose && !s_fHideStackTrace) {
						trace("  " + strStacktrace);
					}
				} catch (err:Error) {}
			}
			_abmdPool.push(this);
			if (_abmdPool.length > knMaxPoolSize) {
				var vbmd:VBitmapData = _abmdPool.shift();
				vbmd._dispose();
			}
		}
		
		private function _dispose(): void {
			if (_fReferenced)
				throw new Error("Disposing of referenced bitmap. Call bitmapRef.dispose() instead.");

			s_nEstimatedBytesUndisposed -= GetByteSize();
			if (s_fDebug) {
				ImageDocument.ValidateBitmapdataUnused(this);
				if (_fDisposed) {
					trace(this + " being redundantly disposed" + disposedStatus);
					try {
						var err:Error = new Error("stacktrace");
						var strStacktrace:String = err.getStackTrace();
						var astrTrace:Array = strStacktrace.split("\n", 7);
						trace("  " + astrTrace.slice(2).join("\n"));
					} catch (err:Error) {}
					super.dispose(); // match BitmapData's behavior
					return;
				}
				delete s_dtCreated[this];
	
				s_cbmdUndisposed--;
				if (s_fLogCreateDispose) trace("VBitmap:Disposed: " + this);
				try {
					err = new Error("stacktrace");
					strStacktrace = err.getStackTrace();
					astrTrace = strStacktrace.split("\n", 7);
					_strDisposeStacktrace = astrTrace.slice(2).join("\n");
					if (s_fLogCreateDispose && !s_fHideStackTrace) trace("  " + _strDisposeStacktrace);
				} catch (err:Error) {}
				if (s_edChangeListener != null)
					s_edChangeListener.dispatchEvent(new Event("VBitmapChange"));
			}
			_fDisposed = true;
			super.dispose();
		}
		
		
		// Our robust substitute for BitmapData.draw which handles buggy cases like when
		// vector objects are drawn beyond the 4096th pixel.
		static public function RepairedDraw(bmd:BitmapData, source:IBitmapDrawable, matrix:Matrix=null, colorTransform:ColorTransform=null, blendMode:String=null, clipRect:Rectangle=null, smoothing:Boolean=false):void {
			var rcClip:Rectangle = clipRect;
			if (source is DisplayObject) {
				// Flash 10 isn't able to draw vectors past the 4096th pixel (horizontal or vertical).
				// This workaround checks to see if
				// - the image is > 4000 pixels wide/tall (we trigger early because fills near the limit are affected)
				// - any of the DocumentObjects would be clipped
				// and if so it creates a BitmapData the size of the to-be-clipped objects, draws the background
				// into it (so the objects can be blended properly, then the objects, then copies it into the composite.
				// BUGBUG: there is still an edge case not addressed, which is that even for images that are <= 4096
				// pixels wide objects aren't clipped well to the right/bottom edges. It looks like vertices are clipped,
				// not pixels. So weird stuff happens in the 4080-4096 pixel zone.
				
				if (bmd.width > 4096 || bmd.height > 4096) {
					var dob:DisplayObject = DisplayObject(source);
					
					var rcObjectBounds:Rectangle = dob.getBounds(dob.parent);
					if (!rcObjectBounds.isEmpty()) {
						// Take the matrix the DisplayObject will be transformed by into account when figuring out
						// whether the DisplayObject meets the clipping condition and the bounds of the clipped area.
						if (matrix) {
							var matNew:Matrix = dob.transform.matrix;
							matNew.concat(matrix);
							var pt1:Point = matNew.transformPoint(rcObjectBounds.topLeft);
							var pt2:Point = matNew.transformPoint(rcObjectBounds.bottomRight);
							rcObjectBounds = new Rectangle(Math.min(pt1.x, pt2.x), Math.min(pt1.y, pt2.y),
									Math.abs(pt1.x - pt2.x), Math.abs(pt1.y - pt2.y));
						}
					
						// We don't care about the parts of DocumentObjects that are totally off the composite
						rcObjectBounds = rcObjectBounds.intersection(bmd.rect);
						var rcCroppedComposite:Rectangle = bmd.rect.intersection(new Rectangle(0, 0, 4000, 4000));
						
						if (!rcCroppedComposite.containsRect(rcObjectBounds)) {
							// They'll be cropped, draw them into a temp bitmap and draw that into the composite
							var rcCroppedObjects:Rectangle;
							if (bmd.width > 4096)
								rcCroppedObjects = rcObjectBounds.intersection(new Rectangle(4000, 0, 4000, 4096));
							else
								rcCroppedObjects = rcObjectBounds.intersection(new Rectangle(0, 4000, 4096, 4000));
							try {
								// Set the background for the temporary composite
								var bmdTemp:BitmapData = new VBitmapData(rcCroppedObjects.width, rcCroppedObjects.height, true, 0x00000000);
								var mat:Matrix = new Matrix(1, 0, 0, 1, -rcCroppedObjects.x, -rcCroppedObjects.y);
								bmdTemp.draw(bmd, mat);
								
								// Offset the matrix to account for the temporary composite's relative position
								if (matrix == null)
									matrix = new Matrix();
								matrix.translate(-rcCroppedObjects.x, -rcCroppedObjects.y);
								bmdTemp.draw(dob, matrix, colorTransform, blendMode, rcClip, smoothing);
								matrix.translate(rcCroppedObjects.x, rcCroppedObjects.y);
								
								// Copy the temporary composite into the permanent composite
								bmd.copyPixels(bmdTemp, bmdTemp.rect, rcCroppedObjects.topLeft);
								bmdTemp.dispose();
							} catch (err:Error) {
								// Out of memory? Fine then don't draw the clipped part
							}
							
							// Clip the normal draw to avoid the nasty edge artifacts
							if (rcClip)
								rcClip = rcClip.intersection(rcCroppedComposite);
							else
								rcClip = rcCroppedComposite;
						}
					}
				}
			}
			bmd.draw(source, matrix, colorTransform, blendMode, rcClip, smoothing);
		}
	}
}
