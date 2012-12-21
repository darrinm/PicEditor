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
	import imagine.serialization.SerializationInfo;
	import imagine.imageOperations.paintMask.OperationStrokes;
	
	import util.BitmapCache;
	import util.BitmapCacheEntry;
	import util.IDisposable;
	import util.VBitmapData;
	
	[RemoteClass]
	public class OperationStrokeImageOperation extends BlendImageOperation implements IReExecutingOperation {
		[Bindable] public var strokes:OperationStrokes;

		/*
		public function set strokes(astk:Array): void {
			// Copy the array of polylines in case the caller keeps messing with it
			_astk = astk ? astk.slice() : null; // Can we clone strokes this way?
		}
		*/
		
		public function OperationStrokeImageOperation() {
			strokes = new OperationStrokes();
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['strokes']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			strokes = new OperationStrokes();
			strokes.Deserialize(xmlOp.*[0]); // first child
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			var xml:XML = <OperationStroke/>;
			xml.appendChild(strokes.Serialize());
			return xml;
		}
		
		public function get supportsDirtyUpdate(): Boolean {
			return true;
		}

		override protected function HasBlending(nAlpha:Number): Boolean {
			return false;
		}

		override protected function GetApplyKey():String {
			// var strSuffix:String = customAlpha ? ("|" + this.BlendAlpha) : "";
			// return SerializeSelf().toXMLString() + strSuffix;
			return "OperationStrokeImageOperation:" + _strBlendMode + ":" + _nAlpha;; // Refresh our composite when either of these changes
		}

		// Get any params after applying (and re-applying) the effect
		// so we can use these next time we reapply.
		public function GetPrevApplyParams(): Object {
			if (strokes == null) return null;
			return strokes.GetKeyForCurrentState();
		}

		override protected function get customAlpha():Boolean {
			return true;
		}

		// private static const kstrDoodleResultCacheKey:String = "OperationStrokeResult";
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
					bmdResult = VBitmapData.Construct(bmdOrig.width, bmdOrig.height, true);
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
