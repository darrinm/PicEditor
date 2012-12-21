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
package imagine.imageOperations.paintMask
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.imageOperations.ImageMask;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	import util.BitmapCache;
	import util.IDisposable;
	import util.VBitmapData;
	
	[Event(name="change", type="flash.events.Event")]
	[RemoteClass]
	public class PaintPlusImageMask extends ImageMask implements IStrokeCanvas, IDisposable
	{
		private var _astkStrokes:Array = [];
		
		private var _bmdComposite:BitmapData;
		private var _bmdStroke:BitmapData;
		private var _bmdMask:BitmapData;
		protected var _bmdOrig:BitmapData;
		
		public function PaintPlusImageMask(rcBounds:Rectangle=null)
		{
			if (rcBounds == null) rcBounds = new Rectangle(0,0,1,1);
			super(rcBounds);
			_fSupportsChangeRegions = true;
		}
		
		protected function IsLatestStroke(stk:Stroke): Boolean {
			if (_astkStrokes.length <= 0) return false;
			return (_astkStrokes[_astkStrokes.length-1] == stk);
		}
		
		public override function set inverted(fInverted:Boolean): void {
			super.inverted = fInverted;
			DispatchChangeEvent();
		}
		
		public function reset(): void {
			Dispose();
			_astkStrokes.length = 0;
		}
		
		private static function LinkageHelper(): void {
			var br1:Brush;
			var br2:CircularBrush;
			var br3:GlitterBrush;
			var br4:DisplayObjectBrush;
			var br5:BeardHairBrush;
		}
		
		override public function readExternal(input:IDataInput):void {
			super.readExternal(input);
			var obMask:Object = input.readObject();
			_astkStrokes = obMask.strokes;
			Debug.Assert(_astkStrokes != null);
			if (_astkStrokes.length > 0)
				Debug.Assert(_astkStrokes[_astkStrokes.length-1] != null);
			Dispose();
			ClearKeyCache();
		}
		
		override public function writeExternal(output:IDataOutput): void {
			super.writeExternal(output);
			var obMask:Object = {};
			Debug.Assert(_astkStrokes != null);
			if (_astkStrokes.length > 0)
				Debug.Assert(_astkStrokes[_astkStrokes.length-1] != null);
			obMask.strokes = _astkStrokes;
			output.writeObject(obMask);
		}

		private function ClearKeyCache(): void {
		}
		
		public override function Deserialize(xml:XML): Boolean {
			var fSuccess:Boolean = super.Deserialize(xml);
			if (fSuccess) {
				DeserializeStrokes(xml.Strokes.toString());
			}
			Dispose();
			Debug.Assert(_astkStrokes != null);
			if (_astkStrokes.length > 0)
				Debug.Assert(_astkStrokes[_astkStrokes.length-1] != null);
			return fSuccess;
		}
		
		protected function DeserializeStrokes(strStrokes:String): void {
			var dec:Base64Decoder = new Base64Decoder();
			dec.decode(strStrokes);
			var ba:ByteArray = dec.drain();
			ba.uncompress();
			ba.position = 0;
			_astkStrokes = ba.readObject();
		}
		
		public override function Serialize(): XML {
			var xml:XML = super.Serialize();
			xml.appendChild(SerializeStrokes());
			return xml;
		}
		
		protected function GetStrokesExcept(stkToIgnore:Stroke=null): Array {
			var astk:Array = _astkStrokes;
			if (stkToIgnore != null) {
				astk = astk.slice(); // Make a copy
				for (var i:Number = astk.length-1; i >= 0; i--) {
					if (astk[i] == stkToIgnore) {
						astk.splice(i, 1); // Remove the element
						break;
					}
				}
			}
			return astk;
		}
		
		protected function SerializeStrokes(stkToIgnore:Stroke=null) : XML {
			var xmlStrokes:XML = <Strokes version="1"/>;

			var ba:ByteArray = new ByteArray();
			var astk:Array = GetStrokesExcept(stkToIgnore);
 			ba.writeObject(astk);
			ba.compress();
			var enc:Base64Encoder = new Base64Encoder();
			enc.encodeBytes(ba);
			xmlStrokes.appendChild(new XML(enc.drain()));
			return xmlStrokes;
		}
		
		public function set compositeBmd(bmd:BitmapData): void {
			_bmdComposite = bmd;
		}
		public function get compositeBmd(): BitmapData {
			return _bmdComposite;
		}
		
		public function get maskBmd(): BitmapData {
			return _bmdMask;
		}
		
		public function get originalBmd(): BitmapData {
			return _bmdOrig;
		}
		
		public function set strokeBmd(bmd:BitmapData): void {
			BitmapCache.AddDisposable(this);
			_bmdStroke = bmd;
		}
		public function get strokeBmd(): BitmapData {
			return _bmdStroke;
		}
		
		public function get hasStrokes(): Boolean {
			return _astkStrokes.length > 0;
		}
		
		public function get numStrokes(): Number {
			return _astkStrokes.length;
		}
		
		public override function set Bounds(rcBounds:Rectangle):void {
			throw new Error("Deprecated");
		}
		
		public override function set width(nWidth:Number):void {
			if (super.width == nWidth) return;
			super.width = nWidth;
			Dispose();
			DispatchChangeEvent();
		}
		
		public override function set height(nHeight:Number):void {
			if (super.height == nHeight) return;
			super.height = nHeight;
			Dispose();
			DispatchChangeEvent();
		}
		
		override public function Dispose(): void {
			DisposeCore();
			DisposeKeyFrames();
		}
		
		public function DisposeCore(): void {
			if (_bmdMask != null) DisposeBaseBitmap();
			_bmdMask = null;
			
			if (_bmdComposite) _bmdComposite.dispose();
			_bmdComposite = null;
			
			if (_bmdStroke) _bmdStroke.dispose();
			_bmdStroke = null;
			
			for each (var stk:Stroke in _astkStrokes) {
				stk.Dispose();
			}
		}
		
		private function DispatchChangeEvent(): void {
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		protected function DisposeBaseBitmap(): void {
			_bmdMask.dispose();
		}

		
		protected function NewBaseBitmap(): BitmapData {
			return VBitmapData.Construct(width, height, true, 0, "paint plus base");
		}
		
		private function GenerateMask(fInteractive:Boolean): void {
			// First, find a key frame to use
			BitmapCache.AddDisposable(this);
			var mkf:MaskKeyFrame;
			var i:Number;
			for (i = 0; i < _amkfKeyFrames.length; i++) {
				if (_amkfKeyFrames[i].depth > numStrokes)
					break;
				mkf = _amkfKeyFrames[i];
			}
			
			if (mkf == null) {
				_bmdMask = NewBaseBitmap();
				i = 0;
			} else {
				_bmdMask = mkf.bitmapData.clone();
				i = mkf.depth;
			}
			
			// Remove key frames after this depth
			var j:Number = 0;
			while (j < _amkfKeyFrames.length) {
				if (_amkfKeyFrames[j].depth > i) {
					MaskKeyFrame(_amkfKeyFrames[j]).Dispose();
					_amkfKeyFrames.splice(j,1);
				} else {
					j++;
				}
			}
			
			while (i < _astkStrokes.length) {
				_astkStrokes[i].Draw(this);
				i++;
				var nMaxAge:Number = GetKeyFrameMaxAge(i);
				var nAge:Number = _astkStrokes.length - i;
				if (nMaxAge > nAge) {
					// Add a key frame
					_amkfKeyFrames.push(new MaskKeyFrame(_bmdMask.clone(), i, nMaxAge));
					BitmapCache.AddDisposable(this);
				}
			}
			// DumpFrames();
			MarkAsDirty(_bmdMask.rect);
		}
		
		private function UpdateMask(fInteractive:Boolean=false): void {
			var fInvalid:Boolean = _bmdMask == null;
			if (!fInvalid) {
				try {
					if (_bmdMask.width <= 0) fInvalid = true;					
				} catch (e:Error) {
					fInvalid = true;
				}
			}
			if (fInvalid && _bmdOrig != null) {
				_bmdMask = null;
				GenerateMask(fInteractive);			
			}
		}
		
		/* Begin: Entry Points */
		override public function Mask(bmdOrig:BitmapData): BitmapData {
			if (_bmdOrig != bmdOrig) {
				if (_bmdOrig != null)
					Dispose();
				_bmdOrig = bmdOrig;
			}
			UpdateMask();
			return _bmdMask;
		}
		
		override public function get maskIsAlpha(): Boolean {
			return true; // our mask is alpha
		}
		
		protected function _NewStroke(stk:Stroke): void {
			Debug.Assert(stk != null);
			UpdateMask();
			_astkStrokes.push(stk);
			MarkAsDirty(stk.Draw(this));
			DispatchChangeEvent();
		}
		
		// UI Entry points - these keep the mask updated
		public function NewStroke(pt:Point, br:Brush, fErase:Boolean=false, nAlpha:Number=1, nRotation:Number=0,
				fAdditive:Boolean=false, nSpacing:Number=0.2, obExtraParams:Object=null): void {
			var stk:Stroke = new Stroke();
			Debug.Assert(stk != null);
			br = br.clone();
			if (fErase) br.inverted = !br.inverted;
			stk.brush = br;
			stk.alpha = nAlpha;
			stk.erase = fErase;
			stk.additive = fAdditive;
			stk.spacing = nSpacing;
			stk.rotation = nRotation;
			stk.push(pt);
			
			_NewStroke(stk);
		}
		
		public function AddDragPoint(pt:Point): void {
			Debug.Assert(_astkStrokes != null);
			Debug.Assert(_astkStrokes.length > 0);
			var stkLast:Stroke = _astkStrokes[_astkStrokes.length - 1];
			Debug.Assert(stkLast != null);
			stkLast.push(pt);
			MarkAsDirty(stkLast.DrawTo(this, stkLast.length-1));
			DispatchChangeEvent();
		}
		
		public function UndoStroke(fInteractive:Boolean): Stroke {
			Debug.Assert(_astkStrokes.length > 0);
			var stk:Stroke = _astkStrokes.pop();
			Debug.Assert(stk != null);
			DisposeCore();
			UpdateMask(fInteractive);
			DispatchChangeEvent();
			stk.Dispose();
			return stk;
		}
		
		public function PrepareForNextStroke(fErase:Boolean=false, nAlpha:Number=1, nRotation:Number=0, obExtraParams:Object=null):void {
			// Called when the UI knows we are getting ready to start
			// painting a new stroke.
		}
		
		public function AddStroke(stk:Stroke, fInteractive:Boolean): void {
			Debug.Assert(stk != null);
			UpdateMask();
			_astkStrokes.push(stk);
			MarkAsDirty(stk.Draw(this));
			DispatchChangeEvent();
			if (fInteractive) UpdateKeyFrames();
		}

		public function DisposeKeyFrames(): void {
			while (_amkfKeyFrames.length > 0) {
				var mkf:MaskKeyFrame = _amkfKeyFrames.pop();
				mkf.Dispose();
			}
		}

		// Each frame represents the depth we save. Key frames stick around for 2 * a[n] + 1 frames
		// Was [4,8] changed to [4] to save memory
		// UNDONE: Do this based on the original image size or, better yet, add these to an improved
		// priority/size sensitive cache with low priority (start medium, go to low as they age)
		private static const kanKeyFrameDepth:Array = [4];
		private var _amkfKeyFrames:Array = [];
		
		public function UpdateKeyFrames(): void {
			PicnikBase.app.callLater(_UpdateKeyFrames);
		}
		
		private function GetKeyFrameMaxAge(nDepth:Number): Number {
			if (nDepth < 1) return 0;
			
			var nMaxAge:Number = 0;
			for each (var nKeyDepth:Number in kanKeyFrameDepth) {
				if ((nDepth % nKeyDepth) == 0)
					nMaxAge = nKeyDepth * 1.5;
			}
			return nMaxAge;
		}
		
		private function _UpdateKeyFrames(): void {
			var nDepth:Number = numStrokes;
			var nMaxAge:Number = 0;
			
			// Remove expired key frames from the head of our list
			var i:Number;
			var mkf:MaskKeyFrame;
			i = 0;
			while (i < _amkfKeyFrames.length) {
				mkf = _amkfKeyFrames[i];
				var nAge:Number = nDepth - mkf.depth;
				if (nAge > mkf.maxAge || nAge <= 0) {
					_amkfKeyFrames.splice(i, 1); // Expired/too young
					mkf.Dispose();
				} else {
					i++;
				}
			}
			
			nMaxAge = GetKeyFrameMaxAge(nDepth);

			if (nMaxAge > 0) {
				// Create a new key frame
				// nMaxAge *= 2;
				_amkfKeyFrames.push(new MaskKeyFrame(_bmdMask.clone(), nDepth, nMaxAge));
				BitmapCache.AddDisposable(this);
			}
			// DumpFrames();
		}
		
		// Prepare to draw a new stroke
		// Gets the stroke and composite bitmaps ready for a new stroke
		public function InitForStroke(stk:Stroke): void {
			if (stk.erase) {
				if (compositeBmd == null) compositeBmd = VBitmapData.Construct(width, height, true, 0);

				// Copy Alpha to Blue, set the rest to 0xFF
				var flt:ColorMatrixFilter = new ColorMatrixFilter(
					[ 0,0,0,0, 255,
					  0,0,0,0, 255,
					  0,0,0,1, 0,
					  0,0,0,0, 255]);
				compositeBmd.applyFilter(maskBmd, compositeBmd.rect, compositeBmd.rect.topLeft, flt);
			} else if (!stk.directDraw) {
				// Fill the composite with the mask
				if (compositeBmd == null) compositeBmd = maskBmd.clone();
				else compositeBmd.copyPixels(maskBmd, maskBmd.rect, maskBmd.rect.topLeft);
				
				// Fill stroke with 0
				if (strokeBmd == null) strokeBmd = VBitmapData.Construct(width, height, true, 0);
				else strokeBmd.fillRect(strokeBmd.rect, 0);
			}
		}


		/*		
		private function DumpFrames(): void {
			var strOut:String = "KeyFrames: ";
			var nPos:Number = 0;
			for each (var mkf:MaskKeyFrame in _amkfKeyFrames) {
				for (var i:Number = nPos; i < mkf.depth; i++) {
					strOut += " ";
					nPos++;
				}
				strOut += "X";
				nPos++;
			}
			trace(strOut);
		}
		*/
		
		/* End: Entry Points */

		
		
	}
}