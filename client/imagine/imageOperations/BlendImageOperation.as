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
	import com.adobe.utils.StringUtil;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.getQualifiedClassName;
	
	import imagine.serialization.SerializationInfo;
	import imagine.imageOperations.engine.instructions.ApplyInstruction;
	import imagine.imageOperations.engine.instructions.ApplyReExecutingInstruction;
	import imagine.imageOperations.engine.instructions.BlendInstruction;
	import imagine.imageOperations.engine.instructions.DupeInstruction;
	import imagine.imageOperations.engine.instructions.MaskInstruction;
	import imagine.imageOperations.engine.instructions.MaskWithSourceAlphaInstruction;
	import imagine.imageOperations.engine.instructions.OpInstruction;
	import imagine.imageOperations.engine.instructions.PartialMaskInstruction;
	import imagine.imageOperations.engine.instructions.PopInstruction;
	
	import util.BitmapCache;
	import util.VBitmapData;
	
	[RemoteClass]
	public class BlendImageOperation extends ImageOperation
	{
		protected var _msk:ImageMask = null; // Null means no mask is applied
		protected var _strBlendMode:String = null; // Null means overwrite. See flash.display.BlendMode
		protected var _nAlpha:Number = 1; // Alpha used for blending. Can combine with the mask.
		protected var _fIgnoreObjects:Boolean = false;
		protected var _strTiming:String = null; 	// for debugging -- keep track of how long the operation took
		private var _fMaskWithSourceAlpha:Boolean = false;
		
		private const kstrPreMaskCacheKey:String = "PRE_MASK";
		private const kstrPreAlphaCacheKey:String = "PRE_ALPHA";
		private const kstrCompositeCacheKey:String = "COMPOSITE";
		public static const kstrPostMaskCacheKey:String = "POST_MASK";

		// Set to > 0 when you have an alpha slider (or blend mode drop down)
		// This will cache everything before the alpha is applied
		public var dynamicAlphaCachePriority:Number = 0;
		
		// Set to > 0 when you have dynamic params (e.g. a slider) for the main effect
		// This will cache everything before the effect is applied
		public var dynamicParamsCachePriority :Number = 0;
		
		public var maskCachePriority:Number = 90;
		
		public override function Dispose():void {
			if (_msk != null) {
				_msk.Dispose();
			}			
		}
		
		public function set Mask(msk:ImageMask): void {
			if (_msk != null) {
				_msk.Dispose();
			}
			_msk = msk;
		}
		
		public function get Mask(): ImageMask {
			return _msk;
		}
		
		public function set BlendMode(strBlendMode:String): void {
			_strBlendMode = strBlendMode;
		}
		
		public function get BlendMode(): String {
			return _strBlendMode;
		}
		
		public function set Timing(strTiming:String): void {
			_strTiming = strTiming;
		}
		
		public function get Timing(): String {
			return _strTiming;
		}
		
		public function set BlendAlpha(nAlpha:Number): void {
			_nAlpha = nAlpha;
			if (_nAlpha < 0) _nAlpha = 0;
			else if (_nAlpha > 1) _nAlpha = 1;
		}
		
		public function get BlendAlpha(): Number {
			return _nAlpha;
		}
		
		public function set ignoreObjects(fIgnoreObjects:Boolean): void {
			_fIgnoreObjects = fIgnoreObjects;
		}
		
		public function get ignoreObjects(): Boolean {
			return _fIgnoreObjects;
		}
		
		public function set maskWithSourceAlpha(fMask:Boolean): void {
			_fMaskWithSourceAlpha = fMask;
		}
		
		public function get maskWithSourceAlpha(): Boolean {
			return _fMaskWithSourceAlpha;
		}
		
		public function DisposeIfNotNeeded(bmd:BitmapData): void {
			if (bmd && !BitmapCache.Contains(bmd)) bmd.dispose();
		}
				
		/** DoBlend
		 *  - if ((_strBlendMode != null && _strBlendMode != flash.display.BlendMode.NORMAL) || (_nAlpha < 1)) :
		 *  - if not the above, don't do anything (just pop -1)
		 */
		
		protected function get customAlpha(): Boolean {
			return false;
		}
		
		protected function get cachePreAlpha(): Boolean {
			return false;
		}
		
		protected function HasBlending(nAlpha:Number): Boolean {
			return ((_strBlendMode != null && _strBlendMode != flash.display.BlendMode.NORMAL) || (nAlpha < 1));
		}
		
		protected function GetBlendInstruction(nAlpha:Number): OpInstruction {
			return new BlendInstruction(nAlpha, this.BlendMode);
		}
		
		/** Blend Steps
		 *
		 * 0. Track initial undo step so we can put it in our cache
		 *
		 * 1. push apply(bmdOrig)
		 *
		 * 2. if (mask with source alpha):
		 *    bmdMasked = VBitmapData.Construct(bmdNew.width, bmdNew.height, true, 0xffffffff, thisType + " mask with source alpha");
		 *    bmdMasked.copyPixels(bmdNew, bmdNew.rect, new Point(0, 0), bmdOrig);
		 *    bmdNew.dispose();
		 *    bmdNew = bmdMasked;
		 *   
		 * -----> alpha slider cache point
		 *
		 * 3. Apply blend mode with alpha if any:
		 *  - if ((_strBlendMode != null && _strBlendMode != flash.display.BlendMode.NORMAL) || (_nAlpha < 1)) {
		 *   DoBlend()
		 */

		override public function Compile(ainst:Array): void {
			var nAlpha:Number = customAlpha ? 1 : this.BlendAlpha;
			var fHasBlending:Boolean = HasBlending(nAlpha);
			
			if (applyHasNoEffect && !fHasBlending && !(dynamicAlphaCachePriority > 0))
				return; // NOP
			
			if (dynamicParamsCachePriority > 0 && ainst.length > 0)
				OpInstruction(ainst[ainst.length-1]).SetCachePriorityToAtLeast(dynamicParamsCachePriority);
			
			CompileApplyEffect(ainst); // Override in sub-classes as needed (e.g. Nested)

			if (_fMaskWithSourceAlpha) {
				ainst.push(new MaskWithSourceAlphaInstruction());
			}
			
			if (dynamicAlphaCachePriority > 0 && ainst.length > 0)
				OpInstruction(ainst[ainst.length-1]).SetCachePriorityToAtLeast(dynamicAlphaCachePriority);

			if (fHasBlending) 
				ainst.push(GetBlendInstruction(nAlpha));

			// At thist point, our stack contains a base and an applied bmd
			// Now we apply the mask.
			
			// Special instruction knows how to add extra info to the cache and re-run that info
			if (_msk) {
				// Cache the state before any masking
				if (ainst.length > 0)
					OpInstruction(ainst[ainst.length-1]).SetCachePriorityToAtLeast(maskCachePriority);
				
				if (_msk.supportsChangeRegions && _msk.maskIsAlpha) { // && _msk.Mask(bmdOrig) != null
					// New style masking
					ainst.push(new MaskInstruction(_msk)); // After this, our stack is: base, applied, masked
					ainst.push(new PopInstruction(1)); // Change stack to: base, masked
				} else {
					// Partial masking
					ainst.push(new PartialMaskInstruction(_msk));
				}
			}
			ainst.push(new PopInstruction(1)); // Remove the base
		}
		
		protected function GetApplyKey(): String {
			var ba:ByteArray = new ByteArray();
			if (customAlpha)
				ba.writeObject(BlendAlpha);
			writeExternalSubClassOnly(ba);
			return ba.toString();
		}
		
		protected function get applyHasNoEffect(): Boolean {
			return false;
		}
		
		// Override in sub-classes as needed (e.g. Nested)
		protected function CompileApplyEffect(ainst:Array): void {
			if (applyHasNoEffect)
				ainst.push(new DupeInstruction());
			else if (this is IReExecutingOperation)
				ainst.push(new ApplyReExecutingInstruction(IReExecutingOperation(this), GetApplyKey()));
			else
				ainst.push(new ApplyInstruction(this, GetApplyKey()));
		}
		
		protected function DeserializeSelf(xnodOp:XML): Boolean {
			// Default is do nothing. Children should override this
			return true;
		}

		static protected function IsBlendChild(xmlOpChild:XML): Boolean {
			var strName:String = xmlOpChild.name();
			return ImageMask.IsImageMask(xmlOpChild) || strName == "BlendMode" || strName == "BlendAlpha";
		}

		override public function Deserialize(xmlOp:XML): Boolean {
			// Find children of type blendMode or mask
			_msk = null;
			_strBlendMode = null;
			_strTiming = null;
			
			if (xmlOp.hasOwnProperty("@maskWithSourceAlpha"))
				_fMaskWithSourceAlpha = xmlOp.@maskWithSourceAlpha == "true";
							
			var xmlBlendMode:XML = xmlOp.BlendMode[0];
			if (xmlBlendMode) {
				Debug.Assert(xmlBlendMode.@mode, "BlendMode mode argument missing");
				_strBlendMode = xmlBlendMode.@mode;
			}
			var xmlBlendAlpha:XML = xmlOp.BlendAlpha[0];
			if (xmlBlendAlpha) {
				Debug.Assert(xmlBlendAlpha.@alpha, "BlendAlpha alpha argument missing");
				_nAlpha = xmlBlendAlpha.@alpha;
			}
			_fIgnoreObjects = xmlOp.IgnoreObjects[0];
			
			if (xmlOp.children().length() > 0) {			
				_strTiming = xmlOp.children()[0].@Timing;
			}
			
			// Look for a mask child
			for each (var xmlChild:XML in xmlOp.children()) {
				if (ImageMask.IsImageMask(xmlChild)) {
					_msk = ImageMask.ImageMaskFromXML(xmlChild);
					if (_msk == null) return false;
					break;
				}
			}
			return DeserializeSelf(xmlOp);
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo(['Mask', 'BlendMode', 'BlendAlpha', 'ignoreObjects', 'Timing', 'maskWithSourceAlpha']);
		private var _fDisableBlendSerialization:Boolean = false;

		private function writeExternalSubClassOnly(output:IDataOutput):void {
			_fDisableBlendSerialization = true;
			writeExternal(output);
			_fDisableBlendSerialization = false;
		}

		public override function writeExternal(output:IDataOutput):void {
			if (_fDisableBlendSerialization)
				return;
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			if (_fDisableBlendSerialization)
				return;
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		protected function SerializeSelf(): XML {
			// Default is do nothing. Children must override this
			return null;
		}
		
		override public function Serialize(): XML {
			var xml:XML= SerializeSelf();
			
			if (_msk != null) {
				xml.appendChild(_msk.Serialize());
			}
			if (_strBlendMode != null) {
				xml.appendChild(<BlendMode mode={_strBlendMode}/>);
			}
			if (_nAlpha < 1) {
				xml.appendChild(<BlendAlpha alpha={_nAlpha}/>);
			}
			if (_fIgnoreObjects) {
				xml.appendChild(<IgnoreObjects/>);
			}
			if (_strTiming ) {
				xml.@Timing = _strTiming;
			}

			if (_fMaskWithSourceAlpha)
				xml.@maskWithSourceAlpha = true;			
			return xml;
		}
	}
}
