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
package util.frameEngine
{
	import de.polygonal.math.PM_PRNG;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class Frame
	{
		private static const knTop:Number = 1;
		private static const knBottom:Number = 2;
		private static const knLeft:Number = 4;
		private static const knRight:Number = 8;
		
		public static const SVG_FILL_STROKE:String = 'stroke';
		public static const SVG_FILL_OUTER:String = 'outer';
		public static const SVG_FILL_INNER:String = 'inner';
		
		private var _aobChildren:Array = null;
		
		private var _frmeng:FrameEngine;
		
		public function Frame(frmeng:FrameEngine, obParams:Object, nFrameOrder:Number = 0)
		{
			_frmeng = frmeng;
			_nFrameOrder = nFrameOrder;
			InitFrame(obParams);
			_nSeed = frmeng._rnd.nextInt();
		}
		
		private var _obRands:Object = {};
		
		private function GetRand(nPos:Number): PM_PRNG {
			var rnd:PM_PRNG;
			nPos = Math.round(nPos * 100 + _nSeed);
			if (!(nPos in _obRands)) {
				rnd = new PM_PRNG();
				rnd.seed = nPos;
				rnd.nextDouble(); // Advance to make it more random.
				rnd.nextDouble(); // Advance to make it more random.
				_obRands[nPos] = rnd;
			}
			return _obRands[nPos];
		}
		
		private var _fFill:Boolean = false; // If true, stretch all shapes to fill the frame.
		
		private var _nSize:Number;
		private var _nSizeJitter:Number;
		private var _nSizeJitterOrder:Number;
		private var _nSideExtension:Number;
		
		private var _nInset:Number;

		private var _nCornerRounding:Number;
		private var _nAlpha:Number;
		private var _nAlphaJitter:Number;
		private var _nRotationJitter:Number;
		private var _nRotationJitterOrder:Number;
		private var _nRotation:Number;
		
		private var _nPositionJitter:Number;
		private var _nPositionJitterOrder:Number;
		private var _nInsetJitter:Number;
		private var _nInsetJitterOrder:Number;
		
		private var _strSVGPath:String = null;
		
		private var _strSVGFillMode:String = null; // "line", "inner", or "outer"
		
		private var _nColor:Number;
		private var _nDensity:Number;
		private var _nCornerFill:Number;
		private var _fAutoRotate:Number;
		private var _fFillEndToEnd:Boolean
		private var _nSides:Number;
		
		private var _nFrameOrder:Number;
		
		private var _nSeed:Number = 1;
		
		private var _fNoDoubles:Boolean = false;
		private var _aflt:Array = [];

		private function KeyToMember(strKey:String): String {
			return '_n' + strKey.charAt(0).toUpperCase() + strKey.substr(1);
		}

		private function SetDefaultNumber(ob:Object, strParam:String, nDefault:Number): void {
			var strLocalParam:String = KeyToMember(strParam);
			if (strParam in ob)
				this[strLocalParam] = Number(ob[strParam]);
			else
				this[strLocalParam] = nDefault;
		}
		
		private function SetDefaultBoolean(ob:Object, strParam:String, fDefault:Boolean): void {
			var strLocalParam:String = '_f' + strParam.charAt(0).toUpperCase() + strParam.substr(1);
			if (strParam in ob)
				this[strLocalParam] = String(ob[strParam]).toLowerCase() == 'true' || String(ob[strParam]) == '1';
			else
				this[strLocalParam] = fDefault;
		}
		
		private static const kobNumberDefaults:Object = {
			size:0.1,
			sizeJitter:0,
			sizeJitterOrder:1,
			inset:0.5,
			insetJitter:0,
			alpha:1,
			alphaJitter:0,
			rotation:0,
			rotationJitter:0,
			rotationJitterOrder:1,
			positionJitter:0,
			positionJitterOrder:1,
			insetJitter:0,
			insetJitterOrder:1,
			color:0,
			density:1,
			cornerFill:0,
			sideExtension:0
		}
		
		private static const kobBooleanDefaults:Object = {
			autoRotate:true,
			fillEndToEnd:true,
			noDoubles:false,
			fill:false
		}

		private function InitFrame(obFrame:Object): void {
			var strKey:String;
			
			for (strKey in kobNumberDefaults)
				SetDefaultNumber(obFrame, strKey, kobNumberDefaults[strKey]);
			
			for (strKey in kobBooleanDefaults)
				SetDefaultBoolean(obFrame, strKey, kobBooleanDefaults[strKey]);

			if ('svgPath' in obFrame) {
				_strSVGPath = obFrame['svgPath']
				if ('svgFillMode' in obFrame) {
					_strSVGFillMode = String(obFrame['svgFillMode']).toLowerCase();
				}
				if (_strSVGFillMode != SVG_FILL_INNER && _strSVGFillMode != SVG_FILL_OUTER)
					 _strSVGFillMode = SVG_FILL_STROKE; // default
			}

			SetDefaultNumber(obFrame, 'cornerRounding', _nSize);
			
			if ('sides' in obFrame) {
				_nSides = 0;
				var strSides:String = String(obFrame.sides).toLowerCase();
				if (strSides.indexOf('right') > -1)
					_nSides += knRight;
				if (strSides.indexOf('left') > -1)
					_nSides += knLeft;
				if (strSides.indexOf('top') > -1)
					_nSides += knTop;
				if (strSides.indexOf('bottom') > -1)
					_nSides += knBottom;
			} else {
				_nSides = knTop + knRight + knBottom + knLeft; 
			}
			_aobChildren = [];
			_aflt = [];
			for each (var obChild:Object in obFrame.aobChildren) {
				if (obChild.xmlName == "filters") {
					_aflt = obChild.aobChildren.slice();
				} else {
					_aobChildren.push(obChild);
				}
			}
		}
		
		private function get minDimension(): Number {
			return Math.min(_frmeng._rcArea.width, _frmeng._rcArea.height);
		}
		
		private function AddCornerSegments(aobSegments:Array, ptCenter:Point, nStartDeg:Number,
				nCornerRadiusPix:Number, nInsetPix:Number, nSizePix:Number): void {
			var nRadius:Number = nCornerRadiusPix;
			var nMaxRadius:Number = nCornerRadiusPix;
			var nRadiusStepPix:Number = 100;
			if (_nCornerFill > 0) {
				nMaxRadius = Math.SQRT2 * (nRadius + nInsetPix);
				nRadiusStepPix = nSizePix / _nCornerFill;
				nRadiusStepPix = Math.max(10, (nMaxRadius - nRadius) / 6, nRadiusStepPix);
			}
			
			while (nRadius <= nMaxRadius) {
				aobSegments.push(new ArcFrameSegment(ptCenter, nRadius, nStartDeg, 90));
				var arc:ArcFrameSegment = ArcFrameSegment(aobSegments[aobSegments.length-1]);
				nRadius += nRadiusStepPix;
			}
		}

		// A segment is a straight line or the arc of a circle
		// Each segment needs a directional vector
		private function GetSegments(): Array {
			var aobSegments:Array = [];
			
			var nSizePix:Number = minDimension * _nSize;
			var nInsetPix:Number = _nInset * nSizePix;
			
			var rcArea:Rectangle = _frmeng._rcArea.clone();
			rcArea.inflate(-nInsetPix, -nInsetPix);
			
			var ptTopRight:Point = new Point(rcArea.right, rcArea.top);
			var ptBottomLeft:Point = new Point(rcArea.left, rcArea.bottom);
			
			if (_strSVGPath != null) {
				if (_strSVGFillMode == SVG_FILL_STROKE) {
					aobSegments.push(new SVGPathFrameSegment(_strSVGPath, rcArea, true, false));
				} else {
					aobSegments.push(
						new SVGPathFillFrameSegment(_strSVGPath, _frmeng._rcArea, rcArea,
						true, _strSVGFillMode == SVG_FILL_OUTER, nSizePix / _nDensity));
				}
				return aobSegments;
			}
			
			if (_nCornerRounding <= 0) {
				// no corner rounding
				if (_nSides & knTop)
					aobSegments.push(new StraightFrameSegment(rcArea.topLeft, ptTopRight));
				if (_nSides & knRight)
					aobSegments.push(new StraightFrameSegment(ptTopRight, rcArea.bottomRight)); // Right
				if (_nSides & knBottom)
					aobSegments.push(new StraightFrameSegment(rcArea.bottomRight, ptBottomLeft));
				if (_nSides & knLeft)
					aobSegments.push(new StraightFrameSegment(ptBottomLeft, rcArea.topLeft)); // Right
			} else {
				// Round corners
				var nMaxCornerRadius:Number = Math.min(rcArea.width, rcArea.height)/2;
				var nCornerRadiusPix:Number = Math.min(_nCornerRounding * nMaxCornerRadius, nMaxCornerRadius);
				var xStart:Number;
				var xEnd:Number;
				var yStart:Number;
				var yEnd:Number;
				
				var ptCenter:Point;
				
				// Top
				if (_nSides & knTop) {
					xStart = rcArea.left;
					xEnd = rcArea.right;
					if (_nSides & knLeft)
						xStart += nCornerRadiusPix;
					if (_nSides & knRight)
						xEnd -= nCornerRadiusPix;
					if (xStart < xEnd)
						aobSegments.push(new StraightFrameSegment(new Point(xStart, rcArea.top), new Point(xEnd, rcArea.top)));
				}
				// Top right corner
				if ((_nSides & knTop) && (_nSides & knRight)) {
					ptCenter = new Point(rcArea.right - nCornerRadiusPix, rcArea.top + nCornerRadiusPix);
					AddCornerSegments(aobSegments, ptCenter, -90, nCornerRadiusPix, nInsetPix, nSizePix);
				}

				// Right
				if (_nSides & knRight) {
					yStart = rcArea.top;
					yEnd = rcArea.bottom;
					if (_nSides & knTop)
						yStart += nCornerRadiusPix;
					if (_nSides & knBottom)
						yEnd -= nCornerRadiusPix;
					if (yStart < yEnd)
						aobSegments.push(new StraightFrameSegment(new Point(rcArea.right, yStart), new Point(rcArea.right, yEnd)));
				}
				// Bottom right corner
				if ((_nSides & knRight) && (_nSides & knBottom)) {
					ptCenter = new Point(rcArea.right - nCornerRadiusPix, rcArea.bottom - nCornerRadiusPix);
					AddCornerSegments(aobSegments, ptCenter, 0, nCornerRadiusPix, nInsetPix, nSizePix);
				}

				// Bottom
				if (_nSides & knBottom) {
					xStart = rcArea.left;
					xEnd = rcArea.right;
					if (_nSides & knLeft)
						xStart += nCornerRadiusPix;
					if (_nSides & knRight)
						xEnd -= nCornerRadiusPix;
					if (xStart < xEnd)
						aobSegments.push(new StraightFrameSegment(new Point(xEnd, rcArea.bottom), new Point(xStart, rcArea.bottom)));
				}
				// Bottom left corner
				if ((_nSides & knBottom) && (_nSides & knLeft)) {
					ptCenter = new Point(rcArea.left + nCornerRadiusPix, rcArea.bottom - nCornerRadiusPix);
					AddCornerSegments(aobSegments, ptCenter, 90, nCornerRadiusPix, nInsetPix, nSizePix);
				}

				// Left
				if (_nSides & knLeft) {
					yStart = rcArea.top;
					yEnd = rcArea.bottom;
					if (_nSides & knTop)
						yStart += nCornerRadiusPix;
					if (_nSides & knBottom)
						yEnd -= nCornerRadiusPix;
					if (yStart < yEnd)
						aobSegments.push(new StraightFrameSegment(new Point(rcArea.left, yEnd), new Point(rcArea.left, yStart)));
				}
				// Top left corner
				if ((_nSides & knLeft) && (_nSides & knTop)) {
					ptCenter = new Point(rcArea.left + nCornerRadiusPix, rcArea.top + nCornerRadiusPix);
					AddCornerSegments(aobSegments, ptCenter, 180, nCornerRadiusPix, nInsetPix, nSizePix);
				}
			}
			
			if (_nSideExtension != 0)
				for each (var ifsgmt:IFrameSegment in aobSegments)
					if (ifsgmt is StraightFrameSegment)
						StraightFrameSegment(ifsgmt).Extend(_nSideExtension * nSizePix);
			
			return aobSegments;
		}
		
		private var _nPrevShapeTypeId:Number = -1;
		
		private function GetRandomShapeType(): Object {
			var nRand:Number;
			
			if (_fNoDoubles && _aobChildren.length > 1 && _nPrevShapeTypeId >= 0) {
				nRand = GetRand(-1).nextIntRange(0, _aobChildren.length-2);
				if (nRand == _nPrevShapeTypeId)
					nRand = _aobChildren.length - 1;
				_nPrevShapeTypeId = nRand;
			} else {
				nRand = GetRand(-1).nextIntRange(0, _aobChildren.length-1);
			}
				
			return _aobChildren[nRand];
		}
		
		private function GetLoc(aobSegments:Array, nPos:Number): FrameSegmentLoc {
			if (aobSegments.length == 0)
				return null;
			
			var i:Number = 0;
			while (nPos >  IFrameSegment(aobSegments[i]).length) {
				nPos -= IFrameSegment(aobSegments[i]).length;
				i = (i + 1) % aobSegments.length;
			}
			
			return IFrameSegment(aobSegments[i]).GetLoc(nPos);
		}
		
		private function GetDefaultScale(obShapeType:Object): Number {
			var nSizePix:Number = minDimension * _nSize;
			if ('size' in obShapeType)
				nSizePix *= obShapeType.size;
			
			return nSizePix / obShapeType.cHeight;
		}
		
		private function GetDefaultPixelWidth(obShapeType:Object): Number {
			return obShapeType.cWidth * GetDefaultScale(obShapeType);
		}
		
		private function GetValFromKey(obShapeType:Object, strKey:String, nDefault:Number=1): Number {
			if (strKey in obShapeType)
				return Number(obShapeType[strKey]);
				
			strKey = KeyToMember(strKey);
			try {
				return this[strKey];
			} catch (e:Error) {
			}
			return nDefault;
		}
		
		private function DoJitter(iPos:Number, obShapeType:Object, strKey:String, nMaxDelta:Number): Number {
			var nJitter:Number = GetValFromKey(obShapeType, strKey + "Jitter", 0);
			var nJitterOrder:Number = GetValFromKey(obShapeType, strKey + "JitterOrder", 1);
			
			if (nJitter == 0)
				return 0;
			
			var nOffset:Number = GetRand(iPos).nextDoubleRange(-1, 1);
			var fNegative:Boolean = nOffset < 0;
			
			if (nJitterOrder != 1)
				nOffset = Math.pow(Math.abs(nOffset), nJitterOrder);
			
			if (fNegative && nOffset > 0)
				nOffset = -nOffset;
			
			nOffset *= nJitter;

			return nOffset * nMaxDelta;
		}
		
		// Returns the pixel width "value" of the shape added
		// This is the un-jittered pixel width
		private function AddShape(obShapeType:Object, iPos:Number, nPos:Number, aobSegements:Array): void {
			var obShape:Object = {};
			obShape.url = obShapeType.url;
			obShape.filters = _aflt.slice(); // Start with a copy of the global filters
			obShape.isVector = ('isVector' in obShapeType) ? (obShapeType.isVector == 'true') : false;
			
			if (!('filters' in obShapeType) && 'aobChildren' in obShapeType && obShapeType.aobChildren.length > 0)
				obShapeType.filters = obShapeType.aobChildren.slice();
			if ('filters' in obShapeType)
				obShape.filters = obShape.filters.concat(obShapeType.filters);
			
			var frmloc:FrameSegmentLoc = GetLoc(aobSegements, nPos);
			
			var ptLoc:Point = frmloc.loc;
			var ptV2:Point = frmloc.centerVector;
			
			// Apply inset jitter
			var nSizePix:Number = minDimension * _nSize;
			var nInsetJitterPix:Number = DoJitter(nPos, obShapeType, 'inset', nSizePix);
			var ptInsetOffset:Point = new Point(ptV2.x * nInsetJitterPix, ptV2.y * nInsetJitterPix);
			ptLoc = ptLoc.add(ptInsetOffset);
			var ptV1:Point = new Point(0, 1);
			
			var deg:Number;
			
			if (_fAutoRotate) {
				// Rotate to match orientation
				var rad:Number = Math.atan2(ptV2.y, ptV2.x) - Math.atan2(ptV1.y, ptV1.x);
				deg = rad * 180 / Math.PI;
			} else {
				deg = 0;
			}
			obShape.rotation = deg + DoJitter(iPos, obShapeType, 'rotation', 180);
			if ('rotation' in obShapeType)
				obShape.rotation += Number(obShapeType['rotation']);
			
			obShape.x = ptLoc.x;
			obShape.y = ptLoc.y;
			if ('color' in obShapeType)
				obShape.color = Number(obShapeType.color);
			else
				obShape.color = _nColor;
			
			var nScale:Number = GetDefaultScale(obShapeType);
			var nScaleJitter:Number = DoJitter(iPos, obShapeType, 'size', 1);
			if (nScaleJitter > 0)
				nScale *= 1 + nScaleJitter;
			else
				nScale *= 1 / (1 - nScaleJitter);
			
			obShape.scaleX = nScale;
			obShape.scaleY = nScale;
			if ('alpha' in obShapeType)
				obShape.alpha = obShapeType.alpha;
			else
				obShape.alpha = _nAlpha;
			obShape.cWidth = obShapeType.cWidth;
			obShape.cHeight = obShapeType.cHeight;
			
			var nZOrder:Number = GetRand(iPos).nextDoubleRange(0.1, 0.9);
			nZOrder += _nFrameOrder
			// UNDONE: Apply zOrder jitter, smarts
			obShape.zOrder = nZOrder;
			
			_frmeng._aobShapes.push(obShape);
		}
		
		// Returns the pixel width "value" of the shape added
		// This is the un-jittered pixel width
		private function AddFillShape(obShapeType:Object): void {
			var obShape:Object = {};
			obShape.url = obShapeType.url;
			obShape.filters = _aflt.slice(); // Start with a copy of the global filters
			obShape.isVector = ('isVector' in obShapeType) ? (obShapeType.isVector == 'true') : false;
			
			if (!('filters' in obShapeType) && 'aobChildren' in obShapeType && obShapeType.aobChildren.length > 0)
				obShapeType.filters = obShapeType.aobChildren.slice();
			if ('filters' in obShapeType)
				obShape.filters = obShape.filters.concat(obShapeType.filters);
			
			obShape.x = _frmeng._rcArea.x + _frmeng._rcArea.width / 2;
			obShape.y = _frmeng._rcArea.y + _frmeng._rcArea.height / 2;
			if ('color' in obShapeType)
				obShape.color = Number(obShapeType.color);
			else
				obShape.color = _nColor;
			
			obShape.rotation = _nRotation;
			if ((Math.round(_nRotation / 90) % 2) == 0) {
				// Normal orientation
				obShape.scaleX = _frmeng._rcArea.width / obShapeType.cWidth;
				obShape.scaleY = _frmeng._rcArea.height / obShapeType.cHeight;
			} else {
				// Rotated orientation. Swap x and y scale
				obShape.scaleX = _frmeng._rcArea.height / obShapeType.cWidth;
				obShape.scaleY = _frmeng._rcArea.width / obShapeType.cHeight;
			}
			
			if ('alpha' in obShapeType)
				obShape.alpha = obShapeType.alpha;
			else
				obShape.alpha = _nAlpha;
			obShape.cWidth = obShapeType.cWidth;
			obShape.cHeight = obShapeType.cHeight;
			
			_frmeng._aobShapes.push(obShape);
		}
		
		public function Layout(): void {
			if (_frmeng._rcArea.height < 10 || _frmeng._rcArea.width < 10)
				return;
			
			if (_fFill) {
				AddFillShape(_aobChildren[0]);
				return;
			}
				
			// Figoure out our segments
			var aobSegments:Array = GetSegments();
			var nTotalLength:Number = 0;
			var ifsgmt:IFrameSegment;
			for each (ifsgmt in aobSegments)
				nTotalLength += ifsgmt.length;
				
			// This is the length we need to travel
			var aobShapes:Array = [];
			var aobShapeTypes:Array = [];
			
			var nSizePix:Number = minDimension * _nSize;
			var nTotalShapeWidth:Number = 0;
			var obShapeType:Object;
			
			var nAddedWidth:Number = 0;
			var nFirstShapeWidth:Number = 0;
			var fFirst:Boolean = true;

			while ((nTotalShapeWidth - (nFirstShapeWidth/2) - (nAddedWidth/2)) < (nTotalLength * _nDensity)) {
				obShapeType = GetRandomShapeType();
				nAddedWidth = GetDefaultPixelWidth(obShapeType);
				if (fFirst)
					nFirstShapeWidth = nAddedWidth;

				nTotalShapeWidth += nAddedWidth;
				aobShapeTypes.push(obShapeType);
			}
			
			/** calculate actual density, nDensity, such that:
			 * The sum of the width of all shapes * nDensity - half the first and last shape
			 * is equal to our length minus a small number (so we don't overrun)
			 *
			 * Note that we may want to make this configurable
			 */
			
			 if (_fFillEndToEnd)
			 	nTotalShapeWidth -= nFirstShapeWidth/2 + nAddedWidth/2;
			
			// Now we have our shapes. Distribute them properly.
			var nDensity:Number = nTotalShapeWidth * 1.000001 / nTotalLength; // Actual density might be slightly different.
			
			var nPos:Number = 0;
			
			var iPos:Number = 0;
			for each (obShapeType in aobShapeTypes) {
				var nAddedWeight:Number = GetDefaultPixelWidth(obShapeType) / nDensity;
				var nPosJitter:Number = DoJitter(iPos, obShapeType, 'position', nSizePix);
				AddShape(obShapeType, iPos, nPos + DoJitter(iPos, obShapeType, 'position', nSizePix), aobSegments);
				nPos += nAddedWeight;
				iPos += 1;
			}
		}
	}
}