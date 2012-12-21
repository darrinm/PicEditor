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
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import mx.effects.easing.Quadratic;
	
	import util.VBitmapData;
	
	[RemoteClass]
	public class TelevisionImageOperation extends BlendImageOperation
	{
		import de.polygonal.math.PM_PRNG;

		protected var _nFade:Number = .25;
		protected var _nSoftness:Number = 1.0;			// how hard/soft are the raster edges?
		protected var _nScanlineWidth:Number = 2.0;		// How wide should the scanlines be? 
		protected var _nGapWidth:Number = 2.0;			// How wide should the gaps be?
		protected var _nPhaseShift:Number = 0.0;		// phase shift
		protected var _nSnow:Number = 0.0;				// Honey, can you go up and fix that antenna again?
		protected var _coBackground:Number = 0xFFFFFF;

		private static const kastrSerializedVars:Array = [	
			"_nFade",
			"_nSoftness",
			"_nScanlineWidth",
			"_nGapWidth",
			"_nPhaseShift",
			"_nSnow",
			"_coBackground",
		];

		private static var _spr:Sprite;
		
		public function TelevisionImageOperation()
		{
		}

		public function set Fade(n:Number): void {
			_nFade = n;
		}
		
		public function get Fade(): Number {
			return _nFade;
		}
		
		public function set Softness(n:Number): void {
			_nSoftness = n;
		}
		
		public function get Softness(): Number {
			return _nSoftness;
		}
		
		public function set ScanlineWidth(n:Number): void {
			_nScanlineWidth = n;
		}
		
		public function get ScanlineWidth(): Number {
			return _nScanlineWidth;
		}
		
		public function set GapWidth(n:Number): void {
			_nGapWidth = n;
		}
		
		public function get GapWidth(): Number {
			return _nGapWidth;
		}
		
		public function set PhaseShift(n:Number): void {
			_nPhaseShift = n;
		}
		
		public function get PhaseShift(): Number {
			return _nPhaseShift;
		}
		
		public function set Snow(n:Number): void {
			_nSnow = n;
		}
		
		public function get Snow(): Number {
			return _nSnow;
		}
		
		public function set Background(n:Number): void {
			_coBackground = n;
		}
		
		public function get Background(): Number {
			return _coBackground;
		}
		
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'Fade', 'Softness', 'ScanlineWidth', 'GapWidth', 'PhaseShift', 'Snow', 'Background']);
		
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
			var xml:XML = <Television/>
			for each (var strVarName:String in kastrSerializedVars)
				xml.@[VarNameToXmlKey(strVarName)] = this[strVarName];
			return xml;
		}

		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			var bmdOut:BitmapData = VBitmapData.Construct(bmdSrc.width, bmdSrc.height, true, 0xff000000 | _coBackground);
			if (!bmdOut)
				return null;
			if (_spr == null) _spr = new Sprite();
			var gr:Graphics = _spr.graphics;
			gr.clear();
			gr.beginBitmapFill(bmdSrc);
			gr.drawRect(0, 0, bmdSrc.width, bmdSrc.height);
			gr.endFill();

			// rasterized look is accomplished simply by drawing a bunch of
			// horizontal black lines.  But we have fun with alpha levels to
			// get smooth edges.  We model a waveform such that the entire
			// phase consists of one dark gap and one scanline.
			// The phase is divided into 4 sections:
			//
			//		|  /|-------|\  |	    |
			//		| / |       | \ |       |
			//		|/  |       |  \|-------|
			//		a   s1      s2  s3      b
			// a: beginning of phase, alpha is 0.0
			// a-s1: falling edge
			// s1-s2: alpha is 1.0 (black gap is drawn)
			// s2-s3: rising edge
			// s3-b: alpha is 0.0 (scanline with visible image data)
			//
			// the user controls these options on the waveform:
			//	gap width (a-s2)
			//	scanline width (s2-b)
			//	width of rising/falling edges (softness)
			//	overall wave amplitude (fade)
			//  phase shift


			var phase_width:Number = _nScanlineWidth + _nGapWidth;
			var phase_edge:Number = _nGapWidth;
			var s1:Number = phase_edge * _nSoftness;
			if (phase_edge > phase_width/2)
				s1 = (phase_width-phase_edge) * _nSoftness;
			var s2:Number = phase_edge;
			var s3:Number = phase_edge + s1;

/*
			// snow!
			var rnd:PM_PRNG = new PM_PRNG();
			rnd.seed = _nSnow * 100.0;
			
			var num_flakes:int = _nSnow * bmdSrc.width * bmdSrc.height / 100.0;
			var scanline_count:Number = bmdSrc.height/phase_width;
			var scanline_off:Number = (phase_width + s3) / 2.0	// center of scanline
			var scanline_width:Number = phase_width - phase_edge - s1*2;
			gr.beginFill(0xffffff, _nFade/100.0/4.0);
			for (var i:int=0; i<num_flakes; i++) {
				if (i==num_flakes/2)
					gr.beginFill(0x000000, _nFade/100.0/5.0);
				var sy:Number = rnd.nextIntRange(0, scanline_count) * phase_width + scanline_off;
				var sx:Number = rnd.nextIntRange(0, bmdSrc.width);
				gr.drawCircle(sx, sy, phase_edge * rnd.nextDoubleRange(0.9, 1.1));
			}
*/
			// now draw the gaps between the scanlines
			var phase_i:Number = phase_width * _nPhaseShift;
			for (var y:int=0; y<bmdOut.height; y++) {
				var alpha:Number;
				if (phase_i < s1)
					alpha = Quadratic.easeInOut(phase_i, 0.0, 1.0, s1); 
				else if (phase_i < s2)
					alpha = 1.0;
				else if (phase_i < s3) 	 
					alpha = 1.0 - Quadratic.easeInOut(phase_i-s2, 0.0, 1.0, s1); 
				else
					alpha = 0.0;
						
				gr.lineStyle(1.0, _coBackground, alpha * (_nFade/100.0));
				gr.moveTo(0, y);
				gr.lineTo(bmdSrc.width, y);
				phase_i += 1;
				while (phase_i > phase_width)
					phase_i -= phase_width;
			}
			
			bmdOut.draw(_spr);
			return bmdOut;			
		}


	}
}