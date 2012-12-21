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
package imagine.imageOperations
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.BitmapFilter;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.VBitmapData;

	[RemoteClass]
	public class PuzzleImageOperation extends BlendImageOperation
	{
		import de.polygonal.math.PM_PRNG;

		protected var _nSeed:Number = 1; // Random number seed
		protected var _nPiecesFlyingPct:Number = .01; // 0 to 0.5. # of pieces is rounded up, so 0.01% => 1 piece
		protected var _nEdgePieces:Number = 6+8; // 3 -> 20? # of pieces on top and left side edge (count cornter twice) 
		protected var _nKookiness:Number = 0; // 0 to 100
		
		// Border Info
		
		// White inner drop shadow
		protected var _nDropShadowAlpha:Number = 0.35;
		protected var _nDropShadowDistance:Number = 1;
		protected var _nDropShadowAngle:Number = 45;
		protected var _nDropShadowBlur:Number = 2;
		
		// Black border
		protected var _nBorderAlpha:Number = 0.7;
		protected var _nBorderThickness:Number = 2;

		protected var _coBackground:Number = 0xFFFFFF;
		protected var _coBorder:Number = 0x000000;
		protected var _coShadow:Number = 0xFFFFFF;

		private static const RIGHT:Number = 0;
		private static const LEFT:Number = 1;
		private static const DOWN:Number = 2;
		private static const UP:Number = 3;

		private static const kastrSerializedVars:Array = [	
			"_nSeed",
			"_nPiecesFlyingPct",
			"_nEdgePieces",
			"_nKookiness",
			"_nDropShadowAlpha",
			"_nDropShadowDistance",
			"_nDropShadowAngle",
			"_nDropShadowBlur",
			"_nBorderAlpha",
			"_nBorderThickness",
			"_coBackground",
			"_coBorder",
			"_coShadow",
		];

		// This defines the points in a puzzle curve
		// points alternate anchors and control points
		// Draws a puzzle edge from 0,0 to 100,0
		private static var _aptsPuzzle:Array =
					[new Point(0, 0),
					new Point(45.33, 10.02),
					new Point(38.72, -0.23),
					new Point(25.0, -20.83),
					new Point(50.0, -21.87), // Center
					new Point(75.0, -20.83),
					new Point(61.28, -0.23),
					new Point(54.67, 10.02),
					new Point(100, 0)];
		
		// From 0,0 to 0,100
		private static var _aptsPuzzleVertical:Array = null;

		private static var _spr:Sprite;
		
		public function PuzzleImageOperation()
		{
		}

		public function set Seed(n:Number): void {
			_nSeed = n;
		}
		
		public function get Seed(): Number {
			return _nSeed;
		}
		
		public function set PiecesFlyingPct(n:Number): void {
			_nPiecesFlyingPct = n;
		}
		
		public function get PiecesFlyingPct(): Number {
			return _nPiecesFlyingPct;
		}
		
		public function set EdgePieces(n:Number): void {
			_nEdgePieces = n;
		}
		
		public function get EdgePieces(): Number {
			return _nEdgePieces;
		}
		
		public function set Kookiness(n:Number): void {
			_nKookiness = n;
		}
		
		public function get Kookiness(): Number {
			return _nKookiness;
		}
		
		public function set BorderAlpha(n:Number): void {
			_nBorderAlpha = n;
		}
		
		public function get BorderAlpha(): Number {
			return _nBorderAlpha;
		}
		
		public function set BorderThickness(n:Number): void {
			_nBorderThickness = n;
		}
		
		public function get BorderThickness(): Number {
			return _nBorderThickness;
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
		
		public function set Background(n:Number): void {
			_coBackground = n;
		}
		
		public function get Background(): Number {
			return _coBackground;
		}
		
		public function set Border(n:Number): void {
			_coBorder = n;
		}
		
		public function get Border(): Number {
			return _coBorder;
		}
		
		public function set Shadow(n:Number): void {
			_coShadow = n;
		}
		
		public function get Shadow(): Number {
			return _coShadow;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'Seed', 'PiecesFlyingPct', 'EdgePieces', 'Kookiness', 'BorderAlpha', 'BorderThickness', 'DropShadowAlpha',
			'DropShadowDistance', 'DropShadowAngle', 'DropShadowBlur', 'Background', 'Border', 'Shadow']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		private function VarNameToXmlKey(strVarName:String): String {
			return strVarName.substr(2,1).toLowerCase() + strVarName.substr(3);
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
			var xml:XML = <Puzzle/>
			for each (var strVarName:String in kastrSerializedVars)
				xml.@[VarNameToXmlKey(strVarName)] = this[strVarName];
			return xml;
		}

		private static function InitApts(): void {
			if (_aptsPuzzleVertical) return;
			var mat:Matrix = new Matrix();
			mat.rotate(-Math.PI/2);
			_aptsPuzzleVertical = [];
			for each (var pt:Point in _aptsPuzzle) {
				_aptsPuzzleVertical.push(mat.transformPoint(pt));
			}
		}

		private static function PuzzleLineTo(gr:Graphics, ptStart:Point, nDirection:Number, nLength:Number, fFlip:Boolean): void {
			InitApts();
			var fHoriz:Boolean = nDirection == LEFT || nDirection == RIGHT;
			var fReverse:Boolean = nDirection == LEFT || nDirection == DOWN;
			
			var apts:Array = fHoriz ? _aptsPuzzle : _aptsPuzzleVertical;
			var xMult:Number = nLength / 100;
			var yMult:Number = nLength / 100;
			if (fFlip)
				if (fHoriz)	
					yMult *= -1;
				else
					xMult *= -1;
			
			if (fReverse) {
				if (fHoriz) {
					xMult *= -1;
				} else {
					yMult *= -1;
				}
			}
			
			var i:Number = 1;
			while ((i+1) < apts.length) {
				var ptControl:Point = apts[i++];
				var ptAnchor:Point = apts[i++];
				gr.curveTo(ptStart.x + ptControl.x * xMult, ptStart.y + ptControl.y * yMult,
				 		    ptStart.x + ptAnchor.x * xMult, ptStart.y + ptAnchor.y * yMult);
			}
		}
		
		private static function MoveTo(gr:Graphics, pt:Point): void {
			gr.moveTo(pt.x, pt.y);
		}
		
		private static function LineTo(gr:Graphics, pt:Point): void {
			gr.lineTo(pt.x, pt.y);
		}
		
		private static function SecondOrderDouble(rnd:PM_PRNG, nRange:Number): Number {
			var nVal:Number = rnd.nextDoubleRange(-1, 1);
			return nRange * nVal * Math.abs(nVal);
		}
		
		public static function CalcNumberOfPieces(nDocWidth:Number, nDocHeight:Number, nEdgePieces:Number): Number {
			var ptDim:Point = GetPiecesWideAndTall(nDocWidth, nDocHeight, nEdgePieces);
			return ptDim.x * ptDim.y;
		}
		
		public static function GetPiecesWideAndTall(nDocWidth:Number, nDocHeight:Number, nEdgePieces:Number): Point {
			nEdgePieces = Math.max(3, Math.round(nEdgePieces)); // At least three side pieces
			
			// Suppose we have N side pieces, divide them over the two dimensions to get a rough piece size
			var nPixelsPerEdgePiece:Number = (nDocWidth + nDocHeight) / nEdgePieces;
			
			var nPiecesTall:Number = Math.max(1,Math.round(nDocHeight / nPixelsPerEdgePiece));
			var nPiecesWide:Number = Math.max(1,Math.round(nDocWidth / nPixelsPerEdgePiece));

			if (nPiecesTall == 1 && nPiecesWide == 1)
				if (nDocWidth > nDocHeight)
					nPiecesWide += 1;
				else
					nPiecesTall += 1;

			return new Point(nPiecesWide, nPiecesTall);
		}
		
		public function NumberOfPieces(nDocWidth:Number, nDocHeight:Number): Number {
			return CalcNumberOfPieces(nDocWidth, nDocHeight, _nEdgePieces);
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var bmdOut:BitmapData = VBitmapData.Construct(bmdSrc.width, bmdSrc.height, true, 0xff000000 | _coBackground);
			if (!bmdOut)
				return null;
	
			// Calculate # of pieces wide/tall based on _nEdgePieces
			// Minimum of two pieces
			var ptPieces:Point = GetPiecesWideAndTall(bmdSrc.width, bmdSrc.height, _nEdgePieces);
			var nPiecesTall:Number = ptPieces.y;
			var nPiecesWide:Number = ptPieces.x;
			
			var nPieceHeight:Number = (bmdSrc.height-1) / nPiecesTall;
			var nPieceWidth:Number = (bmdSrc.width-1) / nPiecesWide;
			
			var rnd:PM_PRNG = new PM_PRNG();
			rnd.seed = _nSeed;
			
			if (_spr == null) _spr = new Sprite();
			_spr.filters = [dropShadow];
			var gr:Graphics = _spr.graphics;
			gr.clear();
			
			var i:Number;
			
			var aobPieces:Array = []; // Keep track of per piece settings here
			var obPiece:Object;
			var obPieceFlip:Object = {}; // Keep track of per piece flip vals (right and bottom) here
			
			// Initialize our per piece settings
			for (i = 0; i < nPiecesWide * nPiecesTall; i++) {
				obPiece = {};
				obPiece.ix = i % nPiecesWide;
				obPiece.iy = Math.floor(i / nPiecesWide);
				
				obPieceFlip[obPiece.ix + ":" + obPiece.iy] = {bottom:rnd.nextIntRange(0,1)==1, right:rnd.nextIntRange(0,1)==1};
				
				obPiece.xDiff = SecondOrderDouble(rnd, bmdSrc.width * _nKookiness/100);
				obPiece.yDiff = SecondOrderDouble(rnd, bmdSrc.width * _nKookiness/100);
				obPiece.nAngle = SecondOrderDouble(rnd, Math.PI/4 * _nKookiness/10);
				aobPieces.push(obPiece);
			}
			
			// Scramble our piece array - so we move random pieces
			for (i = 0; i < aobPieces.length; i++) {
				var ob:Object = aobPieces[i];
				var i2:Number = rnd.nextIntRange(0, aobPieces.length-1);
				aobPieces[i] = aobPieces[i2];
				aobPieces[i2] = ob;
			}

			var nFlyingPieces:Number = Math.ceil(aobPieces.length * _nPiecesFlyingPct); // if _nPiecesFlyingPct > 0, let this be at least one piece
			var ix:Number;
			var iy:Number;

			// Count down so that our moving pieces are drawn on top of our immobile pieces
			for (i = aobPieces.length-1; i >=0; i--) {
				obPiece = aobPieces[i];
				ix = obPiece.ix;
				iy = obPiece.iy;

				// Upper left
				var ptOrigin:Point = new Point(ix * nPieceWidth, iy * nPieceHeight);
				
				// Center
				var ptCenter:Point = ptOrigin.add(new Point(nPieceWidth/2, nPieceHeight/2));

				gr.clear();
				gr.lineStyle(_nBorderThickness, _coBorder, _nBorderAlpha);
				
				// Draw it in place
				gr.beginBitmapFill(bmdSrc);
				
				// Draw the piece
				var fFlip:Boolean;
				
				var ptBR:Point = ptOrigin.add(new Point(nPieceWidth, nPieceHeight)); // Bottom right
				var ptUL:Point = ptOrigin; // Upper left
				var ptUR:Point = new Point(ptBR.x, ptUL.y); // Upper right
				var ptBL:Point = new Point(ptUL.x, ptBR.y); // Bottom left

				// Start at the top left
				MoveTo(gr, ptUL);
				
				// Draw left line down
				if (ix == 0) {
					LineTo(gr, ptBL);
				} else {
					fFlip = obPieceFlip[(ix-1) + ":" + iy].right;
					PuzzleLineTo(gr, ptUL, DOWN, nPieceHeight, fFlip);
				}
					
				// Draw bottom line
				if (iy == (nPiecesTall-1)) {
					LineTo(gr, ptBR); // bottom edge
				} else {
					fFlip = obPieceFlip[ix + ":" + iy].bottom;
					PuzzleLineTo(gr, ptBL, RIGHT, nPieceWidth, fFlip);
				}

				// Draw right line
				if (ix == (nPiecesWide-1)) {
					LineTo(gr, ptUR); // right edge
				} else {
					fFlip = obPieceFlip[ix + ":" + iy].right;
					PuzzleLineTo(gr, ptBR, UP, nPieceHeight, fFlip);
				}
					
				// Draw top line
				if (iy == 0) {
					LineTo(gr, ptUL); // top edge
				} else {
					fFlip = obPieceFlip[ix + ":" + (iy-1)].bottom;
					PuzzleLineTo(gr, ptUR, LEFT, nPieceWidth, fFlip);
				}
				gr.endFill();
				
				// Now draw the piece (apply kookiness transformation if needed)
				var mat:Matrix = new Matrix();
				if (i < nFlyingPieces && _nKookiness > 0) {
					var xDiff:Number = obPiece.xDiff;
					var yDiff:Number = obPiece.yDiff;
					var nAngle:Number = obPiece.nAngle;
					
					mat.translate(-ptCenter.x, -ptCenter.y); // First, move the center to the origin
					mat.rotate(nAngle); // Rotate
					mat.translate(ptCenter.x, ptCenter.y); // Move back
					
					mat.translate(xDiff, yDiff);
				}
				
				bmdOut.draw(_spr, mat);
			}
			
			return bmdOut;
		}
			
		private function get dropShadow(): BitmapFilter {
			return new DropShadowFilter(_nDropShadowDistance, _nDropShadowAlpha, _coShadow, _nDropShadowAlpha, _nDropShadowBlur, _nDropShadowBlur, 2, 2, true);
		}
	}
}