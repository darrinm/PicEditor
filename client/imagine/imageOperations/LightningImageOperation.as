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
	import com.oaxoa.fx.Lightning;
	import com.oaxoa.fx.LightningFadeType;
	
	import de.polygonal.math.PM_PRNG;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.BitmapCache;
	import util.BitmapCacheEntry;
	import util.RectUtil;
	import util.VBitmapData;
	
	[RemoteClass]
	public class LightningImageOperation extends BlendImageOperation implements IReExecutingOperation {
		private var _xStart:Number;
		private var _yStart:Number;
		private var _xEnd:Number;
		private var _yEnd:Number;
		private var _co:uint = 0xffffff;
		private var _nThickness:Number = 3;
		private var _nSeed:uint = 1;
		private var _fChildrenDetachedEnd:Boolean = true;
		private var _strAlphaFadeType:String = LightningFadeType.TIP_TO_END;
		private var _strThicknessFadeType:String = LightningFadeType.GENERATION;
		private var _cxyGlowBlur:uint = 10;
		private var _nGlowStrength:uint = 4;
		private var _cChildrenMax:uint = 4;
		private var _nJaggedAmount:Number = 0.0; // 1.0 = +/- 1 step length
		private var _strLightningBlendMode:String = flash.display.BlendMode.NORMAL;
		
		private var _nChildrenLifeSpanMin:Number = 0.1;
		private var _nChildrenLifeSpanMax:Number = 3.0;
		private var _nChildrenProbability:Number = 1.0;
		private var _nChildrenMaxGenerations:Number = 3;
		private var _nSteps:Number = 100;

		private var _obPrevApplyParams:Object;

		public function set startX(x:Number): void {
			_xStart = x;
		}
		
		public function get startX(): Number {
			return _xStart;
		}
		
		public function set startY(y:Number): void {
			_yStart = y;
		}
		
		public function get startY(): Number {
			return _yStart;
		}
		
		public function set endX(x:Number): void {
			_xEnd = x;
		}
		
		public function get endX(): Number {
			return _xEnd;
		}
		
		public function set endY(y:Number): void {
			_yEnd = y;
		}
		
		public function get endY(): Number {
			return _yEnd;
		}
		
		public function set color(co:uint): void {
			_co = co;
		}
		
		public function get color(): uint {
			return _co;
		}
		
		public function set seed(n:uint): void {
			// DWM: go ahead and accept 0 because data-bound UIs have a hard time not passing it
			//			Debug.Assert(n != 0, "random seed cannot be 0!");
			if (n == 0)
				n = 1;
			_nSeed = n;
		}
		
		public function get seed(): uint {
			return _nSeed;
		}
		
		public function set thickness(nThickness:Number): void {
			_nThickness = nThickness;
		}
		
		public function get thickness(): Number {
			return _nThickness;
		}
		
		public function set glowBlur(cxy:uint): void {
			_cxyGlowBlur = cxy;
		}
		
		public function get glowBlur(): uint {
			return _cxyGlowBlur;
		}
		
		public function set glowStrength(n:uint): void {
			_nGlowStrength = n;
		}
		
		public function get glowStrength(): uint {
			return _nGlowStrength;
		}
		
		public function set childrenDetachedEnd(f:Boolean): void {
			_fChildrenDetachedEnd = f;
		}
		
		public function get childrenDetachedEnd(): Boolean {
			return _fChildrenDetachedEnd;
		}
		
		public function set thicknessFadeType(strType:String): void {
			_strThicknessFadeType = strType;
		}
		
		public function get thicknessFadeType(): String {
			return _strThicknessFadeType;
		}
		
		public function set alphaFadeType(strType:String): void {
			_strAlphaFadeType = strType;
		}
		
		public function get alphaFadeType(): String {
			return _strAlphaFadeType;
		}
		
		public function set childrenMaxCount(c:uint): void {
			_cChildrenMax = c;
		}
		
		public function get childrenMaxCount(): uint {
			return _cChildrenMax;
		}
		
		public function set jaggedAmount(n:Number): void {
			_nJaggedAmount = n;
		}
		
		public function get jaggedAmount(): Number {
			return _nJaggedAmount;
		}
		
		public function set lightningBlendMode(strBlendMode:String): void {
			_strLightningBlendMode = strBlendMode;
		}
		
		public function get lightningBlendMode(): String {
			return _strLightningBlendMode;
		}
				
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'startX', 'startY', 'endX', 'endY', 'color', 'seed', 'thickness', 'glowBlur', 'glowStrength', 'childrenDetachedEnd',
			'thicknessFadeType', 'alphaFadeType', 'childrenMaxCount', 'jaggedAmount', 'lightningBlendMode']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		public function LightningImageOperation(xStart:Number=NaN, yStart:Number=NaN, xEnd:Number=NaN, yEnd:Number=NaN,
				co:uint=0xffffff, nThickness:Number=NaN, nSeed:uint=1) {
			_xStart = xStart;
			_yStart = yStart;
			_xEnd = xEnd;
			_yEnd = yEnd;
			_co = co;
			_nThickness = nThickness;
			_nSeed = nSeed;
		}
	
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			Debug.Assert(xmlOp.@startX, "LightningImageOperation startX parameter missing");
			_xStart = Number(xmlOp.@startX);
			Debug.Assert(xmlOp.@startY, "LightningImageOperation startY parameter missing");
			_yStart = Number(xmlOp.@startY);
			Debug.Assert(xmlOp.@endX, "LightningImageOperation endX parameter missing");
			_xEnd = Number(xmlOp.@endX);
			Debug.Assert(xmlOp.@endY, "LightningImageOperation endY parameter missing");
			_yEnd = Number(xmlOp.@endY);
			
			if (xmlOp.hasOwnProperty("@seed"))
				_nSeed = uint(xmlOp.@seed);
			if (xmlOp.hasOwnProperty("@glowBlur"))
				_cxyGlowBlur = uint(xmlOp.@glowBlur);
			if (xmlOp.hasOwnProperty("@glowStrength"))
				_nGlowStrength = uint(xmlOp.@glowStrength);

			if (xmlOp.hasOwnProperty("@color"))
				_co = uint(xmlOp.@color);
			if (xmlOp.hasOwnProperty("@thickness"))
				_nThickness = Number(xmlOp.@thickness);
			if (xmlOp.hasOwnProperty("@childrenDetachedEnd"))
				_fChildrenDetachedEnd = xmlOp.@childrenDetachedEnd == "true";
			if (xmlOp.hasOwnProperty("@childrenMaxCount"))
				_cChildrenMax = uint(xmlOp.@childrenMaxCount);
			if (xmlOp.hasOwnProperty("@alphaFadeType"))
				_strAlphaFadeType = String(xmlOp.@alphaFadeType);
			if (xmlOp.hasOwnProperty("@thicknessFadeType"))
				_strThicknessFadeType = String(xmlOp.@thicknessFadeType);
			if (xmlOp.hasOwnProperty("@jaggedAmount"))
				_nJaggedAmount= Number(xmlOp.@jaggedAmount);
			if (xmlOp.hasOwnProperty("@lightningBlendMode"))
				_strLightningBlendMode = String(xmlOp.@lightningBlendMode);

			return true;
		}
		
		override protected function SerializeSelf(): XML {
			return <Lightning startX={_xStart} startY={_yStart} endX={_xEnd} endY={_yEnd} color={_co}
					thickness={_nThickness} seed={_nSeed} childrenDetachedEnd={_fChildrenDetachedEnd}
					alphaFadeType={_strAlphaFadeType} thicknessFadeType={_strThicknessFadeType}
					glowBlur={_cxyGlowBlur} glowStrength={_nGlowStrength} childrenMaxCount={_cChildrenMax}
					jaggedAmount={_nJaggedAmount} lightningBlendMode={_strLightningBlendMode}/>
		}
		
		override protected function GetApplyKey():String {
			// var strSuffix:String = customAlpha ? ("|" + this.BlendAlpha) : "";
			// return SerializeSelf().toXMLString() + strSuffix;
			return "LightningImageOperation"; // No keys - we are smart about updating the dirty region
		}
		
		// Get any params after applying (and re-applying) the effect
		// so we can use these next time we reapply.
		public function GetPrevApplyParams(): Object {
			return _obPrevApplyParams;
		}
		
		// The idea here is to pull the bitmap which is currently on-screen from the
		// cache and selectively update it. If we can accomplish this then only the
		// updated area will be copied to the screen resulting in a huge speed boost
		// when the lightning covers only a fraction of the image area.
		// CAVEATS: if further compositing, e.g. for DocumentObjects, is necessary then
		// the whole image will be redrawn anyway.
		// UNDONE: have DocumentObject compositing apply the same logic?
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			return DoEffect(imgd, bmdSrc, fDoObjects, fUseCache);
		}


		// Re-apply an effect. The source and dest were loaded form the
		public function ReApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, bmdPrevApplied:BitmapData, obPrevApplyParams:Object): void {
			if ((bmdPrevApplied == null) != (obPrevApplyParams == null))
				throw new Error("Can not reapply with prev bmd null or prev params null");
			DoEffect(imgd, bmdSrc, false, true, bmdPrevApplied, obPrevApplyParams);
		}
		
		private function GetParamKey(): String {
			return super.GetApplyKey();
		}
		
		public function DoEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean,
				bmdPrevApplied:BitmapData=null, obPrevApplyParams:Object=null): BitmapData {
			var strKey:String = GetParamKey();
			if (bmdPrevApplied != null && obPrevApplyParams.strKey == strKey)
				return bmdPrevApplied; // no changes from last time.

			// Create the lightning. This can be an expensive operation if cChildrenMax is large.
			var ltg:com.oaxoa.fx.Lightning = CreateLightning(_xStart, _yStart, _xEnd, _yEnd, _co, _nThickness, _nSeed, _fChildrenDetachedEnd,
					_strAlphaFadeType, _strThicknessFadeType, _cChildrenMax, _nJaggedAmount);
					
			var rcLightning:Rectangle = RectUtil.Integerize(ltg.getBounds(ltg));
			// getBounds seems to miss edge pixels (antialiasing?), hence the "+ 1" inflation.
			var cxyInflate:int = Math.ceil(_nThickness / 2) + _cxyGlowBlur + _nGlowStrength + 1;
			rcLightning.inflate(cxyInflate, cxyInflate);
			
			// Perform a selective update

			var bmdResult:BitmapData;

			// Produce a pristine background image to draw the lightning on, preferably by cleaning up the
			// the one currently being used by the View.
			if (bmdPrevApplied == null) {
				bmdResult = bmdSrc.clone();
			} else {
				bmdResult = bmdPrevApplied;
 				var rcDirty:Rectangle = rcLightning.union(obPrevApplyParams.rcLastDraw);
				bmdResult.copyPixels(bmdSrc, rcDirty, rcDirty.topLeft);
 			}
 			
 			// Draw the lightning
			DrawLightning(ltg, bmdResult, _cxyGlowBlur, _nGlowStrength, _strLightningBlendMode);
			DisposeLightning(ltg);
			
			_obPrevApplyParams = {rcLastDraw:rcLightning, strKey:strKey};
			return bmdResult;
		}
		
		private static function CreateLightning(xStart:Number, yStart:Number, xEnd:Number, yEnd:Number,
				co:uint=0xffffff, nThickness:Number=3.0, nSeed:uint=1, fChildrenDetachedEnd:Boolean=true,
				strAlphaFadeType:String=LightningFadeType.TIP_TO_END, strThicknessFadeType:String=LightningFadeType.GENERATION,
				cChildrenMax:uint=4, nJaggedAmount:Number=0.0): com.oaxoa.fx.Lightning {
			var rnd:PM_PRNG = new PM_PRNG();
			rnd.seed = nSeed;
			var ltg:com.oaxoa.fx.Lightning = new com.oaxoa.fx.Lightning(co, nThickness, 0, rnd, true);

			ltg.startX = xStart;
			ltg.startY = yStart;
			ltg.endX = xEnd;
			ltg.endY = yEnd;
			
			// Set these both to 0 so no Timers are created (we're not animating)
			ltg.childrenLifeSpanMin = 0;
			ltg.childrenLifeSpanMax = 0;
//			ltg.childrenLifeSpanMin=.1;
//			ltg.childrenLifeSpanMax=2;
//			ltg.childrenMaxCountDecay = 0.5;
			
			ltg.childrenProbability=1;
			ltg.childrenMaxGenerations=3;
			ltg.childrenMaxCount = cChildrenMax;
			ltg.childrenAngleVariation=130;
			ltg.thickness = nThickness;
			ltg.steps=200;

			ltg.smoothPercentage=50;
			ltg.wavelength=.3;
			ltg.amplitude=.5;
			ltg.speed=1;
			ltg.maxLength=0;
			ltg.maxLengthVary=0;

			ltg.childrenDetachedEnd = fChildrenDetachedEnd;
			ltg.alphaFadeType = strAlphaFadeType;
			ltg.thicknessFadeType = strThicknessFadeType;
			ltg.jaggedAmount = nJaggedAmount;
			
			ltg.update();
			return ltg;
		}
		
		private static function DrawLightning(ltg:com.oaxoa.fx.Lightning, bmdDst:BitmapData,
				cxyGlowBlur:uint=10, nGlowStrength:uint=4, strBlendMode:String=BlendMode.NORMAL): void {
			if (cxyGlowBlur > 0 && nGlowStrength > 0) {
				var fltGlow:GlowFilter = new GlowFilter();
				fltGlow.color = ltg.color;
				fltGlow.strength = nGlowStrength;
				fltGlow.quality = 3;
				fltGlow.blurX = fltGlow.blurY = cxyGlowBlur;
				
				// UNDONE: this should be a helper function DrawWithFilter(bmdDst, drawable, filter)
				var rcLightning:Rectangle = ltg.getBounds(ltg);
				var rcTmp:Rectangle = bmdDst.generateFilterRect(rcLightning, fltGlow);
				var bmdTmp:BitmapData = VBitmapData.Construct(rcTmp.width, rcTmp.height, true, 0x00000000, "Lightning Temp");
				var mat:Matrix = new Matrix();
				mat.translate(-rcTmp.x - ltg.x, -rcTmp.y - ltg.y);
				bmdTmp.draw(ltg, mat, null, strBlendMode);
				bmdTmp.applyFilter(bmdTmp, bmdTmp.rect, new Point(0, 0), fltGlow);
				mat = new Matrix();
				mat.translate(rcTmp.x + ltg.x, rcTmp.y + ltg.y);
				bmdDst.draw(bmdTmp, mat, null, strBlendMode);
				bmdTmp.dispose();
			} else {
				bmdDst.draw(ltg, null, null, strBlendMode);
			}
		}
		
		private static function DisposeLightning(ltg:com.oaxoa.fx.Lightning): void {
			ltg.kill();
		}
	}
}
