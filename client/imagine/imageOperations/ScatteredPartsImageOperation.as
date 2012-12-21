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
package imagine.imageOperations {
	import de.polygonal.math.PM_PRNG;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import overlays.helpers.WBAdjustment;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class ScatteredPartsImageOperation extends BlendImageOperation {
		// Overall settings
		protected var _nNumParts:Number = 20;
		protected var _nSeed:Number = 1;
		
		// Which part to copy
		protected var _nSize:Number = 0.3;
		protected var _nSizeVariance:Number = 0.3;
		protected var _nAspectVariance:Number = 0.3;
		protected var _fRotationVariance:Boolean = true;

		// How to change the output bits
		protected var _nExposureError:Number = 0.5;
		protected var _nColorBalanceError:Number = 0.2;
		protected var _nPositionError:Number = 0.01;
		protected var _nSizeError:Number = 0.3;
		protected var _nRotationError:Number = 0.05; // 1 is 90 degrees"

		protected var _coBackground:Number = 0x000000;
		
		protected var _fEvenDistribution:Boolean = true;
		
		protected var _nDropShadowAlpha:Number = 0.2;
		protected var _nDropShadowDistance:Number = 2;
		protected var _nDropShadowAngle:Number = 2;
		protected var _nDropShadowBlur:Number = 2;
		
		protected var _nSkewError:Number = 0;
		
		protected var _nPartAlpha:Number = 1;
		protected var _nPartBorderSize:Number = 0;
		protected var _coPartBorder:Number = 0xffffffff;
		
		private static var _spr:Sprite;
		private static var _spr2:Sprite;
		
		public function ScatteredPartsImageOperation() {
		}

		private static const kastrSerializedVars:Array = [	
			"_nNumParts",
			"_nSeed",	
			"_nSize",
			"_nSizeVariance",
			"_nAspectVariance",
			"_fRotationVariance",
			"_nExposureError",
			"_nColorBalanceError",
			"_nPositionError",
			"_nSizeError",
			"_nRotationError",
			"_coBackground",
			"_fEvenDistribution",
			"_nDropShadowAlpha",
			"_nDropShadowDistance",
			"_nDropShadowAngle",
			"_nDropShadowBlur",
			"_nSkewError",
			"_nPartAlpha",
			"_nPartBorderSize",
			"_coPartBorder",
		];
		
		public function set NumParts(n:Number): void {
			_nNumParts = n;
		}
		
		public function get NumParts(): Number {
			return _nNumParts;
		}
		
		public function set Seed(n:Number): void {
			_nSeed = n;
		}
		
		public function get Seed(): Number {
			return _nSeed;
		}
		
		public function set Size(n:Number): void {
			_nSize = n;
		}
		
		public function get Size(): Number {
			return _nSize;
		}
		
		public function set SizeVariance(n:Number): void {
			_nSizeVariance = n;
		}
		
		public function get SizeVariance(): Number {
			return _nSizeVariance;
		}
		
		public function set AspectVariance(n:Number): void {
			_nAspectVariance = n;
		}
		
		public function get AspectVariance(): Number {
			return _nAspectVariance;
		}
		
		public function set RotationVariance(f:Boolean): void {
			_fRotationVariance = f;
		}
		
		public function get RotationVariance(): Boolean {
			return _fRotationVariance;
		}
		
		public function set ExposureError(n:Number): void {
			_nExposureError = n;
		}
		
		public function get ExposureError(): Number {
			return _nExposureError;
		}
		
		public function set ColorBalanceError(n:Number): void {
			_nColorBalanceError = n;
		}
		
		public function get ColorBalanceError(): Number {
			return _nColorBalanceError;
		}
		
		public function set PositionError(n:Number): void {
			_nPositionError = n;
		}
		
		public function get PositionError(): Number {
			return _nPositionError;
		}
		
		public function set SizeError(n:Number): void {
			_nSizeError = n;
		}
		
		public function get SizeError(): Number {
			return _nSizeError;
		}
		
		public function set RotationError(n:Number): void {
			_nRotationError = n;
		}
		
		public function get RotationError(): Number {
			return _nRotationError;
		}
		
		public function set Background(n:Number): void {
			_coBackground = n;
		}
		
		public function get Background(): Number {
			return _coBackground;
		}
		
		public function set EvenDistribution(f:Boolean): void {
			_fEvenDistribution = f;
		}
		
		public function get EvenDistribution(): Boolean {
			return _fEvenDistribution;
		}
		
		public function set DropShadowAlpha(n:Number): void {
			_nDropShadowAlpha = n;
		}
		
		public function get DropShadowAlpha(): Number {
			return _nDropShadowAlpha;
		}
		
		public function set DropShadowDistance(n:Number): void {
			_nDropShadowDistance = n;
		}
		
		public function get DropShadowDistance(): Number {
			return _nDropShadowDistance;
		}
		
		public function set DropShadowAngle(n:Number): void {
			_nDropShadowAngle = n;
		}
		
		public function get DropShadowAngle(): Number {
			return _nDropShadowAngle;
		}
		
		public function set DropShadowBlur(n:Number): void {
			_nDropShadowBlur = n;
		}
		
		public function get DropShadowBlur(): Number {
			return _nDropShadowBlur;
		}
		
		public function set SkewError(n:Number): void {
			_nSkewError = n;
		}
		
		public function get SkewError(): Number {
			return _nSkewError;
		}
		
		public function set PartAlpha(n:Number): void {
			_nPartAlpha = n;
		}
		
		public function get PartAlpha(): Number {
			return _nPartAlpha;
		}
		
		public function set PartBorderSize(n:Number): void {
			_nPartBorderSize = n;
		}
		
		public function get PartBorderSize(): Number {
			return _nPartBorderSize;
		}
		
		public function set PartBorder(n:Number): void {
			_coPartBorder = n;
		}
		
		public function get PartBorder(): Number {
			return _coPartBorder;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'NumParts', 'Seed', 'Size', 'SizeVariance', 'AspectVariance', 'RotationVariance', 'ExposureError',
			'ColorBalanceError', 'PositionError', 'SizeError', 'RotationError', 'Background', 'EvenDistribution',
			'DropShadowAlpha', 'DropShadowDistance', 'DropShadowAngle', 'DropShadowBlur', 'SkewError', 'PartAlpha',
			'PartBorderSize', 'PartBorder']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		private function VarNameToXmlKey(strVarName:String): String {
			var nPrefixSize:Number = 2;
			while (nPrefixSize < 5 && strVarName.charAt(nPrefixSize) != strVarName.charAt(nPrefixSize).toUpperCase()) {
				nPrefixSize++;
			}
			return strVarName.substr(nPrefixSize,1).toLowerCase() + strVarName.substr(nPrefixSize+1);
		}
	
		override protected function DeserializeSelf(xml:XML): Boolean {
			for each (var strVarName:String in kastrSerializedVars) {
				if (this[strVarName] is Boolean)
					this[strVarName] = xml.@[VarNameToXmlKey(strVarName)] == "true";
				else
					this[strVarName] = xml.@[VarNameToXmlKey(strVarName)];
			}
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			var xml:XML = <ScatteredParts/>
			for each (var strVarName:String in kastrSerializedVars)
				xml.@[VarNameToXmlKey(strVarName)] = this[strVarName];
			return xml;
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var coBack:Number = 0xff000000 | (_coBackground & 0xffffff);
			var bmdNew:BitmapData = VBitmapData.Construct(bmdSrc.width, bmdSrc.height, true, coBack);
			if (!bmdNew)
				return null;
	
			var rnd:PM_PRNG = new PM_PRNG();
			rnd.seed = _nSeed;
			
			var nSqrtParts:Number = _fEvenDistribution ? Math.floor(Math.sqrt(_nNumParts)) : 0;
			if (nSqrtParts < 2) nSqrtParts = 0;
			var nDistributedParts:Number = nSqrtParts * nSqrtParts;

			// Draw it
			if (_spr == null) _spr = new Sprite();
			
			if (_nDropShadowAlpha > 0) {
				_spr.filters = [new DropShadowFilter(_nDropShadowDistance, _nDropShadowAngle, 0, _nDropShadowAlpha, _nDropShadowBlur, _nDropShadowBlur, 1, 3)];
			} else {
				_spr.filters = [];
			}
			
			for (var i:Number = 0; i < _nNumParts; i++) {
				var rcBounds:Rectangle = null;
				if (i < nDistributedParts) {
					var xIndex:Number = Math.floor(i / nSqrtParts);
					var yIndex:Number = i - xIndex * nSqrtParts;
					
					rcBounds = new Rectangle(xIndex * bmdSrc.width / nSqrtParts, yIndex * bmdSrc.height / nSqrtParts,
							bmdSrc.width / nSqrtParts, bmdSrc.height / nSqrtParts);
				}
				RandSquare(bmdSrc, bmdNew, rnd, rcBounds);
			}
	
			return bmdNew;
		}

		private static function RandRotation(rnd:PM_PRNG): Number {
			// This is the linear result
			// return rnd.nextDoubleRange(0, Math.PI);
			// Most photographers tend to stick near landscape or portrait
			// So we will bias our results towards those ends of the spectrum
			// Define it as follows:
			
			// 0 => 0 degrees == 180 degrees
			// 1 => 90 degrees
			// 2 => 180 degrees == 0 degrees
			// So, we need a distribution between 0 and 2, weighted towards whole numbers.
			
			var nAngle:Number = rnd.nextDoubleRange(-1,1); // This sticks to 0
			nAngle *= Math.abs(nAngle); // Second order attraction
			nAngle *= Math.abs(nAngle); // Third order attraction
			
			// let this be offset from our orientation
			
			// Now choose orientation
			nAngle += rnd.nextIntRange(0,1);
			if (nAngle > 2) nAngle -= 2;
			if (nAngle < 0) nAngle += 2;
			nAngle *= Math.PI / 2;
			return nAngle;
		}
		
		private static function RotatePoints(apts:Array, nAngle:Number): Array {
			var aptsOut:Array = [];
			var mat:Matrix = new Matrix();
			mat.rotate(nAngle);
			for each (var pt:Point in apts) {
				aptsOut.push(mat.transformPoint(pt));
			}
			return aptsOut;
		}
		
		private static function SizeToBoundingBoxArray(ptSize:Point): Array {
			var apts:Array = [];
			apts.push(new Point( ptSize.x/2,  ptSize.y/2));
			apts.push(new Point( ptSize.x/2, -ptSize.y/2));
			apts.push(new Point(-ptSize.x/2,  ptSize.y/2));
			apts.push(new Point(-ptSize.x/2, -ptSize.y/2));
			return apts;
		}
		
		private static function GetRotatedSize(ptSize:Point, nAngle:Number): Point {
			var apts:Array = RotatePoints(SizeToBoundingBoxArray(ptSize), nAngle);
			var xMin:Number = apts[0].x;
			var xMax:Number = apts[0].x;
			var yMin:Number = apts[0].y;
			var yMax:Number = apts[0].y;
			
			for each (var pt:Point in apts) {
				xMin = Math.min(pt.x, xMin);
				xMax = Math.max(pt.x, xMax);
				yMin = Math.min(pt.y, yMin);
				yMax = Math.max(pt.y, yMax);
			}
			
			return new Point(xMax - xMin, yMax - yMin);
		}
		
		private function RandSquare(bmdOrig:BitmapData, bmdOut:BitmapData, rnd:PM_PRNG, rcBounds:Rectangle=null): void {
			// NOTE:
			// This function should always use the same number of random() calls, regardless of settings
			// This way, setting something to zero (no impact) will not re-scramble the photo.
			
			// Draw the square
			var nAspect:Number = bmdOrig.width / bmdOrig.height;
			if (_nAspectVariance > 0)
				nAspect += rnd.nextDoubleRange(-_nAspectVariance * nAspect, +_nAspectVariance * nAspect);
			else
				rnd.nextInt(); // Make sure we always have the same # of random calls (see NOTE, above)
			
			var nScaleFactor:Number = _nSize;
			if (_nSizeVariance)
				nScaleFactor += rnd.nextDoubleRange(-nScaleFactor * _nSizeVariance, nScaleFactor * _nSizeVariance);
			else
				rnd.nextInt(); // Make sure we always have the same # of random calls (see NOTE, above)
				
			var nArea:Number = nScaleFactor * nScaleFactor * bmdOrig.width * bmdOrig.height;
			var nYSize:Number = Math.sqrt(nArea / nAspect);
			var ptSize:Point = new Point(nYSize * nAspect, nYSize);
		
			var nRotation:Number = 0;
			if (_fRotationVariance)
				nRotation = RandRotation(rnd);
			else
				RandRotation(rnd); // Make sure we always have the same # of random calls (see NOTE, above)
				
			// Now we have a size
			var nXInset:Number = 0;
			var nYInset:Number = 0;
			if (nRotation != 0) {
				var ptRotatedSize:Point = GetRotatedSize(ptSize, nRotation);
				nXInset = ptRotatedSize.x / 2;
				nYInset = ptRotatedSize.y / 2;
				nXInset = Math.min(nXInset, 0.99 * bmdOrig.width/2);
				nYInset = Math.min(nYInset, 0.99 * bmdOrig.height/2);
			}
			
			var rcDocBounds:Rectangle = bmdOrig.rect.clone();
			rcDocBounds.inflate(-nXInset, -nYInset);
			
			if (rcBounds != null && rcBounds.intersects(rcDocBounds))
				rcBounds = rcBounds.intersection(rcDocBounds);
			else
				rcBounds = rcDocBounds;
			
			var ptCenter:Point = new Point(
					rcBounds.x + rnd.nextIntRange(0, rcBounds.width),
					rcBounds.y + rnd.nextIntRange(0, rcBounds.height));
					
			// Now we have our size and our rotation.
			var rcDraw:Rectangle = new Rectangle(ptCenter.x, ptCenter.y);
			rcDraw.offset(-ptSize.x/2, -ptSize.y/2);
			rcDraw.width = ptSize.x;
			rcDraw.height = ptSize.y;
			
			var mat:Matrix = new Matrix();
			
			// First, offset to the center position.
			
			mat.translate(-rcDraw.x, -rcDraw.y);

			mat.translate(-ptSize.x/2, -ptSize.y/2);
			mat.rotate(nRotation);
			mat.translate(ptSize.x/2, ptSize.y/2);
			
			var gr:Graphics = _spr.graphics;
			
			gr.clear();
			if (_nPartBorderSize > 0) {
				// gr.beginFill(0xff000000 | _coPartBorder, 1);
				gr.beginFill(0xffffff, 1);
				gr.drawRect(-_nPartBorderSize, -_nPartBorderSize,ptSize.x + _nPartBorderSize*2, ptSize.y + _nPartBorderSize*2);
				gr.endFill();
			}
			gr.beginBitmapFill(bmdOrig, mat, true, true);
			gr.drawRect(0,0,ptSize.x,ptSize.y);
			gr.endFill();
			
			// Now we have our sprite set up
			// Calculate a matrix to draw it in the right place (or close to right if we are kooky)
			
			mat = new Matrix();
			mat.translate(-ptSize.x/2, -ptSize.y/2);
			mat.rotate(-nRotation);
			
			if (_nSkewError > 0)
				mat.scale(1 + SecondOrderRandom(rnd, _nSkewError), 1 + SecondOrderRandom(rnd, _nSkewError));
			else {
				// Make sure we always have the same # of random calls (see NOTE, above)
				rnd.nextInt();
				rnd.nextInt();
			}

			if (_nRotationError > 0)
				mat.rotate(SecondOrderRandom(rnd, _nRotationError * Math.PI / 2));
			else
				rnd.nextInt(); // Make sure we always have the same # of random calls (see NOTE, above)

			if (_nSizeError > 0) {
				var nSizeFactor:Number = 1 + SecondOrderRandom(rnd, _nSizeError);
				mat.scale(nSizeFactor, nSizeFactor);
			} else {
				rnd.nextInt(); // Make sure we always have the same # of random calls (see NOTE, above)
			}

			mat.translate(ptSize.x/2, ptSize.y/2);
			
			mat.translate(rcDraw.x, rcDraw.y);
			
			if (_nPositionError > 0)
				mat.translate(SecondOrderRandom(rnd, ptSize.length * _nPositionError),
						SecondOrderRandom(rnd, ptSize.length * _nPositionError));
			else {
				rnd.nextInt(); // Make sure we always have the same # of random calls (see NOTE, above)
				rnd.nextInt();
			}
				

			var ctr:ColorTransform = new ColorTransform();
			if (_nExposureError > 0 || _nColorBalanceError > 0) {
				var nRMult:Number = 1;
				var nGMult:Number = 1;
				var nBMult:Number = 1;
				if (_nColorBalanceError > 0) {
					var wbadj:WBAdjustment = WBAdjustment.WBToNeutralizeRGB(
							200 + SecondOrderRandom(rnd, 50 * _nColorBalanceError),
							200 + SecondOrderRandom(rnd, 50 * _nColorBalanceError),
							200 + SecondOrderRandom(rnd, 50 * _nColorBalanceError));
					nRMult = wbadj.RMult;
					nGMult = wbadj.GMult;
					nBMult = wbadj.BMult;
				} else {
					rnd.nextInt(); // Make sure we always have the same # of random calls (see NOTE, above)
					rnd.nextInt();
					rnd.nextInt();
					rnd.nextInt();
				}
				if (_nExposureError > 0) {
					var nExposureOffset:Number = SecondOrderRandom(rnd, _nExposureError);
					if (nExposureOffset > 0)
						nExposureOffset = Math.sqrt(nExposureOffset);
					nRMult += nExposureOffset;
					nGMult += nExposureOffset;
					nBMult += nExposureOffset;
				} else {
					rnd.nextInt(); // Make sure we always have the same # of random calls (see NOTE, above)
				}
				ctr.redMultiplier = nRMult;
				ctr.greenMultiplier = nGMult;
				ctr.blueMultiplier = nBMult;
			} else {
				rnd.nextInt(); // Make sure we always have the same # of random calls (see NOTE, above)
				rnd.nextInt();
				rnd.nextInt();
				rnd.nextInt();
			}
			
			var spr:Sprite;
			if (_nPartAlpha >= 1) {
				_spr.alpha = 1;
				spr = _spr;
			} else { // Alpha
				_spr.alpha = _nPartAlpha;
				if (_spr2 == null) {
					_spr2 = new Sprite();
					_spr2.addChild(_spr);
				}
				spr = _spr2;
			}
			VBitmapData.RepairedDraw(bmdOut, spr, mat, ctr, null,  null, true);
		}
		
		private static function SecondOrderRandom(rnd:PM_PRNG, nRange:Number): Number {
			// Non weighted:
			// return rnd.nextDoubleRange(-nRange, nRange);
			
			// Weighted:
			var nVal:Number = rnd.nextDoubleRange(-1, 1);
			nVal *= Math.abs(nVal);
			
			nVal *= nRange;
			
			return nVal;		
		}
	}
}
