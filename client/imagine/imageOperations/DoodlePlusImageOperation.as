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
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.imageOperations.paintMask.DoodleStrokes;
	
	import util.BitmapCache;
	import util.BitmapCacheEntry;
	import util.IDisposable;
	import util.VBitmapData;
	
	[RemoteClass]
	public class DoodlePlusImageOperation extends BlendImageOperation implements IReExecutingOperation {
		[Bindable] public var strokes:DoodleStrokes;
		private var _abmdDispose:Array = [];

		/*
		public function set strokes(astk:Array): void {
			// Copy the array of polylines in case the caller keeps messing with it
			_astk = astk ? astk.slice() : null; // Can we clone strokes this way?
		}
		*/
		
		public function DoodlePlusImageOperation() {
			strokes = new DoodleStrokes();
		}
		
		override public function Dispose():void {
			super.Dispose();
			while (_abmdDispose.length > 0) DisposeIfNotNeeded(_abmdDispose.pop());
		}

		override protected function HasBlending(nAlpha:Number): Boolean {
			return false;
		}
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(strokes);
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			strokes = input.readObject();
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			strokes = new DoodleStrokes();
			strokes.Deserialize(xmlOp.*[0]); // first child
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			var xml:XML = <DoodlePlus/>;
			xml.appendChild(strokes.Serialize());
			return xml;
		}
		
		public function get supportsDirtyUpdate(): Boolean {
			return true;
		}

		// private static const kstrDoodleResultCacheKey:String = "DoodlePlusResult";
		
		protected override function get customAlpha():Boolean {
			return true;
		}

		override protected function GetApplyKey():String {
			// var strSuffix:String = customAlpha ? ("|" + this.BlendAlpha) : "";
			// return SerializeSelf().toXMLString() + strSuffix;
			return "DoodlePlusImageOperation:" + _strBlendMode + ":" + _nAlpha; // Refresh our composite when either of these changes
		}

		// Get any params after applying (and re-applying) the effect
		// so we can use these next time we reapply.
		public function GetPrevApplyParams(): Object {
			if (strokes == null) return null;
			return strokes.GetKeyForCurrentState();
		}
		
		/**
		 * 1. ApplyEffect (is a rapplying instruction)
		 *   1. Push strokes.mask(bmdOrig) onto the stack. This is bmdNew
		 *   2. Prepare the composite bitmap and our dirty rect
		 *      A. First time:
		 *         1. Create an alpha writeable clone of bmdOrig. Call it bmdREsult. push(bmdResult).
		 *         2. rcDirty = strokes.getchangesfromstate(null) = all strokes
		 *         3. rcTarget = strokes.Bounds (entire bounds? not sure what this is)
		 *      B. Reapply:
		 *         1. bmdResult = get from stack
		 *         2. Update strokes bitmap (might not change)
		 *         3. rcDirty = strokes.GetChangesFromState(prevState)
		 *         4. if (rcDirty.area > 0)
		 *             - rcTarget = rcDirty.clone, offset by strokes.bounds.
		 *             - bmdResult.copyPixels(bmdOrig, rcTarget, rcTarget.topLeft); // Clear drawing area
		 *   3. Draw the dirty area
		 *      - By now, we have the orig, strokes, and composite on the stack
		 *      - Do some drawing
		 *   4. Cache the current state. prevState = strokes.GetKeyForCurrentState()
		 * 2. Pop the mask. Result should be orig, composite. 
		 */

		// Re-apply an effect. The source and dest were loaded form the
		public function ReApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, bmdPrevApplied:BitmapData, obPrevApplyParams:Object): void {
			if ((bmdPrevApplied == null) != (obPrevApplyParams == null))
				throw new Error("Can not reapply with prev bmd null or prev params null");
			DoEffect(imgd, bmdSrc, false, true, bmdPrevApplied, obPrevApplyParams);
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return DoEffect(imgd, bmdSrc, fDoObjects, fUseCache);
		}

		public function DoEffect(imgd:ImageDocument, bmdOrig:BitmapData, fDoObjects:Boolean, fUseCache:Boolean,
				bmdPrevApplied:BitmapData=null, obPrevApplyParams:Object=null): BitmapData {
			
			// Do some drawing
			var bmdNew:BitmapData = strokes.Mask(bmdOrig);

			var bmdResult:BitmapData;

			// Get dirty mask coordinates.
			// On first call, obPrevApplyParams is null, which is correct
			var rcDirty:Rectangle = strokes.GetChangesFromState(obPrevApplyParams);
			var rcTarget:Rectangle; // Dirty rect in local coords
			
			if (bmdPrevApplied == null) {
				// Not reapplying from cache
				// Create a clone of the source bitmap with alpha enabled
				if (_strBlendMode == flash.display.BlendMode.ALPHA && !bmdOrig.transparent) {
					bmdResult = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true, NaN);
					bmdResult.draw(bmdOrig);
				} else {
					bmdResult = bmdOrig.clone();
				}
				rcTarget = strokes.Bounds;
			} else {
				// Reapplying
				bmdResult = bmdPrevApplied;
				
				// If width/height == 0 we're done
				if (rcDirty.width > 0 || rcDirty.height > 0) {
					// Clear out the area we are re-drawing over
					rcTarget = rcDirty.clone();
					rcTarget.x += strokes.Bounds.x;
					rcTarget.y += strokes.Bounds.y;
					bmdResult.copyPixels(bmdOrig, rcTarget, rcTarget.topLeft);
				}
			}
			if (rcDirty.width > 0 || rcDirty.height > 0) {
				// At this point, bmdResult is our composite with
				// our dirty rect filled in with bmdDrawUnder
				// Draw into this with bmdDrawOver using our mask
				// Note that we have bmdBounds.topLeft as an offset
				// and rcDirty as a dirty rect relative to the mask

				var ctrns:ColorTransform = null;
				if (_nAlpha < 1) {
					ctrns = new ColorTransform();
					ctrns.alphaMultiplier = _nAlpha;
				}
				// UNDONE: Add support for R,G,B (and combination?) blend modes
				if (_strBlendMode == flash.display.BlendMode.ALPHA) {
					bmdResult.copyChannel(bmdNew, rcTarget, rcTarget.topLeft, BitmapDataChannel.ALPHA, BitmapDataChannel.ALPHA);
				} else {
					var w:Number = bmdNew.width;
					bmdResult.draw(bmdNew, null, ctrns, _strBlendMode, rcTarget, true);
				}
			}
			return bmdResult;
		}
	}
}
