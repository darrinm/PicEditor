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
package effects.basic {
	import containers.EffectCanvasBase;
	import containers.NestedControlCanvasBase;
	
	import errors.InvalidBitmapError;
	
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	import imagine.imageOperations.*;
	
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.effects.Resize;
	import mx.events.ResizeEvent;
	
	import overlays.helpers.Cursor;
	import overlays.helpers.FloodFill;
	import overlays.helpers.IRedTester;
	import overlays.helpers.PetEyeFinder;
	import overlays.helpers.RGBHybridRedTester;
	
	import util.VBitmapData;

	public class RedEyeEffectBase extends EffectCanvasBase implements IOverlay {
		// MXML-defined variables
		[Bindable] public var _nFeedbackSecs:Number;
		[Bindable] public var _cxyMinFeedbackDim:Number;
		[Bindable] public var _imgFeedback:Image;
		[Bindable] protected var _fHumanEyes:Boolean = true;

		[Embed(source="/assets/swfs/redeye_success.swf")]
		[Bindable] public var _clsSuccessSwf:Class;

		private var _mcOverlay:MovieClip;
		private var _ptClicked:Point = null;

		private const knEyeToImageRatio:Number = 1.0/6;
		// This is probably fine, even for >2800px images
		private const knMaxImageDim:Number = 2800;

		public function RedEyeEffectBase() {
		}
		
		override public function Select(efcnvCleanup:NestedControlCanvasBase):Boolean {
			if (super.Select(efcnvCleanup)) {
				HideFeedback();
				NestedImageOperation(operation).children = [];
				_mcOverlay = _imgv.CreateOverlay(this);
				_imgv.overlayCursor = Cursor.csrRedEye;
				
				return true;
			}
			return false;
		}
		
		override public function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null):void {
			HideFeedback();
			if (_mcOverlay) {
				_imgv.DestroyOverlay(_mcOverlay);
				_mcOverlay = null;
			}
			super.Deselect(fForceRollOutEffect, efcvsNew);
		}

		public override function OnSelectedEffectReallyDone():void {
			super.OnSelectedEffectReallyDone();
			// When NestedControlCanvasBase first calculates the height of this control,
			// the help text isn't laid out and wrapped yet, so the initial height that we animate to is too low.
			// This block makes sure that we animate to the true full height of the control in that case.
			UpdateHeight();
			if (this.height != this.fullHeight) {
				var resize:Resize = new Resize(this);
				resize.heightFrom = this.height;
				resize.heightTo = this.fullHeight;
				resize.duration = 200;
				resize.play();
			}
		}

		protected function FindEyeMask(ptEye:Point): ImageMask {
			ptEye = new Point(Math.round(ptEye.x), Math.round(ptEye.y)); // Make sure we start on an even pixel boundary
		
			var bmdSrc:BitmapData = _imgd.background;

			var bmdFullMask:BitmapData = new VBitmapData(bmdSrc.width, bmdSrc.height, true, 0);
			
			// First, find a start pixel (expand a bit from the center in case they clicked on something white)
			var rtst:IRedTester = new RGBHybridRedTester();

			if (!rtst.Calibrate(bmdSrc, ptEye)) {
				bmdFullMask.dispose();
				return null;		
			}
			ptEye = rtst.StartPoint;

			var fill:FloodFill = new FloodFill();
			fill.SetFill(rtst, 0xff000000);
			// Fail before we fill too many pixels. Make sure we fill enough to know we overflowed
			fill.MaxPixelsFilled = 1 + knMaxImageDim * knEyeToImageRatio * knMaxImageDim * knEyeToImageRatio;
			fill.Fill(bmdSrc, ptEye, bmdFullMask);
			
			var rcMask:Rectangle = bmdFullMask.getColorBoundsRect(0xff000000, 0xff000000);
			
			var nElipseArea:Number = Math.PI * rcMask.width * rcMask.height / 4;
			var nActualArea:Number = fill.PixelsFilled;
			var nRoundness:Number = nActualArea / nElipseArea;
			var nAspect:Number = Math.max(rcMask.width, rcMask.height) / Math.min(rcMask.width, rcMask.height);

			if (rcMask.width > 25 || rcMask.height > 25) {
				if ((rcMask.width > bmdSrc.width*knEyeToImageRatio) || (rcMask.height > bmdSrc.height*knEyeToImageRatio)) {
					bmdFullMask.dispose();
					return null;
				}
				if ((nAspect > 2.2) || (nRoundness < 0.65) || ((nRoundness + nAspect/1) < 1.3)) {
					bmdFullMask.dispose();
					return null;
				}
			}

			rcMask.inflate(3, 3); // Make room for the blurred pixels
			
			// Now we have the mask rectangle. Make sure we return it!
			var bmdCroppedMask:BitmapData = new VBitmapData(rcMask.width, rcMask.height, true);
			
			bmdCroppedMask.copyChannel(bmdFullMask, rcMask, new Point(0,0), BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);

			const knBlurXY:Number = 3;
			const knBlurQ:Number = 4;
			const knXBlurThreshold:Number = 0x42000000;
			
			var fltBlur:BlurFilter = new BlurFilter(knBlurXY, knBlurXY, knBlurQ);
			bmdCroppedMask.applyFilter(bmdFullMask, rcMask, new Point(0,0), fltBlur);
			
			var bmdAlphaFF:BitmapData = new VBitmapData(bmdCroppedMask.width, bmdCroppedMask.height, true, 0xff000000);
	
			bmdAlphaFF.threshold(bmdCroppedMask, bmdCroppedMask.rect, new Point(0,0), "<", knXBlurThreshold, 0x00000000, 0xff000000);

			var fltFeather:BlurFilter = new BlurFilter(2, 2, 1);
			bmdCroppedMask.applyFilter(bmdAlphaFF, bmdAlphaFF.rect, new Point(0,0), fltFeather);			
			bmdAlphaFF.dispose();
			bmdFullMask.dispose();
			
			return new BitmapImageMask(bmdCroppedMask, rcMask);
		}
		
		public function OnOverlayMouseMove(): Boolean {
			return true;
		}
		
		public function OnOverlayDoubleClick():Boolean {
			return true;
		}
		
		public function OnOverlayMouseMoveOutside():Boolean {
			return true;
		}
		
		public function OnOverlayRelease():Boolean {
			return true;
		}
		
		public function OnOverlayReleaseOutside():Boolean {
			return true;
		}
		
		// Returns a rectangle containing the area effected
		// Returns NULL if no redeye was detected.
		protected function RemoveRedEye(ptEye:Point): Rectangle {
			var msk:ImageMask = null;
			
			try {
				msk = FindEyeMask(ptEye);
			} catch (e:InvalidBitmapError) {	
				PicnikBase.app.OnMemoryError(e);	
			}			
			
			if (msk == null) return null; // No eye found.

			var anMatrix:Array = [
					.050, .600, .350, 0, 0,
					.000, .800, .200, 0, 0,
					.000, .200, .800, 0, 0,
					0, 0, 0, 1, 0 ];
			var op:BlendImageOperation = new ColorMatrixImageOperation(anMatrix);
			op.Mask = msk;
			NestedImageOperation(this.operation).children.push(op);

			this.OnOpChange();
			return msk.Bounds;
		}
		
		// Returns a rectangle containing the area effected
		// Returns NULL if no redeye was detected.
		protected function RemovePetEye(ptEye:Point): Rectangle {
			var msk:ImageMask = null;
			var clrClicked:uint;
			var rcMask:Rectangle;
			
			try {
				var obMask:Object = PetEyeFinder.FindPetEye(_imgd.background, ptEye);
				if (obMask) {
					var bmdMask:BitmapData = obMask.mask;
					rcMask = bmdMask.rect.clone();
					rcMask.offsetPoint(obMask.offset);

					// UNDONE: Who is managing bmdMask disposal?
					msk = new BitmapImageMask(obMask.mask, rcMask);
					clrClicked = obMask.clr;
				}
			} catch (e:InvalidBitmapError) {	
				PicnikBase.app.OnMemoryError(e);	
			}			
			
			if (msk == null) return null; // No eye found.

 			var anMatrix:Array = [
					0, 0, 0, 0, 20,
					0, 0, 0, 0, 12,
					0, 0, 0, 0, 3,
					0, 0, 0, 1, 0 ];

			var opDarken:BlendImageOperation = new ColorMatrixImageOperation(anMatrix);
			opDarken.BlendAlpha = 0.99;
			opDarken.Mask = msk;
			
			var opLight:DoodleImageOperation = null;
			
			if (rcMask.width >= 6 && rcMask.height >= 6) {
				// Draw a catchlight
				var aapt:Array = [];
				var apt:Array;
				
				var nSize:Number = Math.max(1,Math.min(rcMask.width, rcMask.height) * 0.1);
				var x:Number = rcMask.x + rcMask.width*0.39;
				var y:Number = rcMask.y+rcMask.height*0.45;
				if (rcMask.width > 50) {
					// Offset a bit more for larger eyes.
					x -= rcMask.width * 0.1;
					y -= rcMask.height * 0.1;
				}
				if (nSize <= 1) {
					apt = [];
					apt.width = nSize;
					apt.color = 0xffffff;
					apt.push(new Point(x, y));
					apt.push(new Point(x+0.5, y-0.5));
					aapt.push(apt);
				} else {
					// Draw a larger light for a larger eye. Add a splash of anti-aliasing
					var nOffset:Number;

					apt = [];
					apt.color = 0xffffff;
					apt.width = 1 + Math.sqrt(nSize);
					apt.width = nSize;
					nOffset = apt.width;
					
					var ptCenter:Point = new Point(rcMask.x + rcMask.width/2, rcMask.y + rcMask.height/2);
					var radStart:Number = Math.atan2(y - ptCenter.y, x - ptCenter.x);
					var radStop:Number = Math.atan2(y-nOffset - ptCenter.y, x+nOffset - ptCenter.x);
					
					var nDistX:Number = ptCenter.x - x;
					var nDistY:Number = ptCenter.y - y;
					var nDist:Number = Math.sqrt(nDistX * nDistX + nDistY * nDistY);
					
					for (var i:Number = 0; i < nOffset; i++) {
						var rad:Number = radStart + (radStop - radStart) * i / nOffset;
						apt.push(new Point(ptCenter.x + nDist * Math.cos(rad), ptCenter.y + nDist * Math.sin(rad)));
					}
					aapt.push(apt);
				}
				opLight = new DoodleImageOperation(1, aapt);
			}
			
			var op:NestedImageOperation = NestedImageOperation(this.operation);
			op.children.push(opDarken);
			
			if (opLight) op.children.push(opLight);

			this.OnOpChange();
			return msk.Bounds;
		}
		
		private var tmrFeedback:Timer = null;
		
		protected function HideFeedback(evt:Event = null): void {
			if (tmrFeedback != null) {
				tmrFeedback.stop();
				tmrFeedback.removeEventListener(TimerEvent.TIMER, HideFeedback);
			}
			tmrFeedback = null;
			_imgFeedback.visible = false;
		}


//		No failure swf, for now	
//		[Embed(source="/assets/swfs/redeye_failure.swf")]
//		[Bindable]
//		public var _clsFailureSwf:Class;
		
		protected function ShowFeedback(clsSwf:Class, rcEffect:Rectangle): void {
			if (tmrFeedback != null) {
				// We are currently showing an animation. Remove the old one.
				HideFeedback();
			}

			var pt:Point = rcEffect.topLeft;
			pt = _mcOverlay.localToGlobal(pt); // Convert from overaly to stage coords
			pt = _imgv.globalToLocal(pt); // Convert from stage to local
			
			_imgFeedback.x = pt.x;
			_imgFeedback.y = pt.y;
			_imgFeedback.width = rcEffect.width;
			_imgFeedback.height = rcEffect.height;
			
			_imgFeedback.source = new clsSwf();
			
			var mcNew:MovieClip = new MovieClip();
			
			_imgFeedback.visible = true;
			_imgv.addChild(_imgFeedback);

			tmrFeedback = new Timer(0, 1);
			tmrFeedback.delay = _nFeedbackSecs * 1000;
			tmrFeedback.addEventListener(TimerEvent.TIMER, HideFeedback);
			tmrFeedback.start();
		}
		
		protected function AnimateResult(rcdEffect:Rectangle): void {
			var clsSwf:Class;
			var rclEffect:Rectangle;
			if (rcdEffect == null) {
				return; // No failure swf, for now
//				if (_ptClicked == null) return; // no point? no animation!
//				rcdEffect = new Rectangle(_ptClicked.x, _ptClicked.y, 0, 0);
//				rclEffect = _imgv.RclFromRcd(rcdEffect);
//				rcdEffect.inflate(knFailureFeedbackDim/2, knFailureFeedbackDim/2);
//				clsSwf = _clsFailureSwf;
			} else {
				rclEffect = _imgv.RclFromRcd(rcdEffect);
				clsSwf = _clsSuccessSwf;
			}
			var cxyEffectDim:Number = Math.max(_cxyMinFeedbackDim, rclEffect.width, rclEffect.height);
			rclEffect.inflate((cxyEffectDim - rclEffect.width) / 2, (cxyEffectDim - rclEffect.height) / 2);
			ShowFeedback(clsSwf, rclEffect);
		}

		public function OnOverlayPress(evt:MouseEvent): Boolean {
			if (_ptClicked != null) return true;
			
			var rclClick:Rectangle = new Rectangle(_mcOverlay.mouseX, _mcOverlay.mouseY, 0, 0);
			var rcdClick:Rectangle = _imgv.RcdFromRcl(rclClick);

			var bmd:BitmapData = _imgv.imageDocument.background;

			var ptClick:Point = rcdClick.topLeft;
			if (ptClick.x < 0 || ptClick.y < 0 || ptClick.x >= bmd.width || ptClick.y >= bmd.height) {
				// Out of bounds
			} else {
				_ptClicked = ptClick;
				_imgv.overlayCursor = Cursor.csrRedEyeBusy;
				// We need to give Flash two frames to update the cursor
				// before we do our work. Call callLater twice to accomplish this.
				callLater(DoRedEyeLater);
			}
			return true; // handled the event.
		}
		
		public function DoRedEyeLater(): void {
			callLater(DoRedEye);
		}
		
		public function DoRedEye(): Boolean {
			if (_ptClicked != null) {
				var rcEffect:Rectangle = null;
				if (_fHumanEyes) {
					rcEffect = RemoveRedEye(_ptClicked);
					if (!rcEffect) {
						rcEffect = RemovePetEye(_ptClicked);
						if (rcEffect) _fHumanEyes = false;
					}
				} else {
					rcEffect = RemovePetEye(_ptClicked);
					if (!rcEffect) {
						rcEffect = RemoveRedEye(_ptClicked);
						if (rcEffect) _fHumanEyes = true;
					}
				}
				if (rcEffect) {
					AnimateResult(rcEffect);
				}
				_imgv.overlayCursor = Cursor.csrRedEye;
				_ptClicked = null;
			}
			return true;
		}
	}
}
