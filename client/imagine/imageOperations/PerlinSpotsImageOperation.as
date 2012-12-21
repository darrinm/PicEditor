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
	import flash.display.BitmapDataChannel;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.serialization.SerializationInfo;
	import imagine.imageOperations.engine.instructions.OpInstruction;
	import imagine.imageOperations.engine.instructions.PerlinSpotsCreateBitmapInstruction;
	import imagine.imageOperations.engine.instructions.PerlinSpotsFrameInstruction;
	import imagine.imageOperations.engine.instructions.PerlinSpotsInstruction;
	import imagine.imageOperations.engine.instructions.PerlinSpotsNoiseInstruction;
	import imagine.imageOperations.engine.instructions.PopInstruction;
	import imagine.imageOperations.engine.instructions.ResizeInstruction;
	
	[RemoteClass]
	public class PerlinSpotsImageOperation extends BlendImageOperation {
		public var dynamicFrameThresholdCachePriority:Number = 0;
		public var dynamicScaleThresholdColorsCachePriority:Number = 0;

		public var xFrequency:Number = 0.2; // As a percent of min image dimension
		public var yFrequency:Number = 0.2; // As a percent of min image dimension
		public var colors:Array = null;
		public var seed:Number = 0; // Random number seed
		public var fractal:Boolean = true;
		public var octaves:Number = 2;

		public var isFrame:Boolean = false;
		public var frameThreshold:Number;

		public var bottomThreshold:Number;
		public var topThreshold:Number;
		public var topScale:Number = 0.7; // Top layers

		public var pixelation:Number = 0.5; // Value of 0.5 means 2x anti alias
		public var quality:Number = QUALITY_AUTO;
		
		public var frameSize:Number = 50;
		public var frameBleed:Number = 50;
		public var frameRoundedCorners:Boolean = true;

		// Quality determines the size of the base noise image. For now, we will only use one.
		public static const QUALITY_AUTO:Number = 0; // Base noise image is min(4 x image area, 2800*2800)

		public function PerlinSpotsImageOperation() {
			// ImageOperation constructors are called with no arguments during Deserialization
		}
		
		override protected function get applyHasNoEffect(): Boolean {
			return false;
		}

		override protected function CompileApplyEffect(ainst:Array):void {
			// Push the noise.
			ainst.push(new PerlinSpotsNoiseInstruction(quality, pixelation, xFrequency,
					yFrequency, octaves, seed, true, fractal, BitmapDataChannel.BLUE));
			// Stack: [Orig, Noise]
			
			if (dynamicScaleThresholdColorsCachePriority > 0)
				OpInstruction(ainst[ainst.length-1]).SetCachePriorityToAtLeast(dynamicScaleThresholdColorsCachePriority);
				
			// Create the base bitmap
			ainst.push(new PerlinSpotsCreateBitmapInstruction(pixelation, true, 0xff000000 | colors[0]));
			// Stack: [Orig, Noise, Base]

			var iMax:Number = colors.length - 2;
			for (var i:Number = 0; i <= iMax; i++) {
				// nScale goes from 1 to nTopScale (diff = nTopScale - 1) as i goes from 0 to iMax
				var nScale:Number = iMax == 0 ? topScale : (1 + (topScale - 1) * i / iMax);
				var fVFlip:Boolean = (i & 0x01) == 1;
				var fHFlip:Boolean = (i & 0x02) == 2;
				var nThreshold:Number = iMax == 0 ? topThreshold : (Math.round(bottomThreshold + (topThreshold - bottomThreshold) * i / iMax));
				
				ainst.push(new PerlinSpotsInstruction(colors[i+1], nThreshold, nScale, pixelation, fVFlip, fHFlip));
			}
			
			if (isFrame){
				// Stack: [Orig, Noise, Spots]

				if (dynamicFrameThresholdCachePriority > 0)
					OpInstruction(ainst[ainst.length-1]).SetCachePriorityToAtLeast(dynamicFrameThresholdCachePriority);

				ainst.push(new PerlinSpotsFrameInstruction(pixelation, frameSize, frameBleed, frameRoundedCorners));
				// Stack: [Orig, Noise, Result]

				ainst.push(new PopInstruction(1, 1)); // Pop the noise
				// Stack: [Orig, Result]
			} else {
				// No frame
				// Stack: [Orig, Noise, Spots]

				// Drop the noise
				ainst.push(new PopInstruction(1, 1)); // Pop the noise
				// Stack: [Orig, SmallSpots]

				// Resize if needed
				if (pixelation > 1) {
					// base is smaller than our target size for pixelation. Scale back up.
					ainst.push(new ResizeInstruction(1, pixelation));
				}
				// Stack: [Orig, Result]
			}
 		}
	
		private static var _srzinfo:SerializationInfo = new SerializationInfo([
			'xFrequency', 'yFrequency', 'colors', 'seed', 'fractal', 'octaves', 'isFrame', 'frameThreshold',
			'frameSize', 'frameBleed', 'frameRoundedCorners', 'bottomThreshold', 'topThreshold', 'topScale',
			'pixelation', 'quality']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		// CONSIDER: makes more sense to store as elements?
		override protected function DeserializeSelf(xml:XML): Boolean {
			xFrequency = Number(xml.@xFrequency);
			yFrequency = Number(xml.@yFrequency);
			seed = Number(xml.@seed);
			fractal = xml.@fractal == "1";
			octaves = Number(xml.@octaves);
			
			isFrame = xml.@isFrame == "1";
			frameThreshold = Number(xml.@frameThreshold);
			frameSize = Number(xml.@frameSize);
			frameBleed = Number(xml.@frameBleed);
			frameRoundedCorners = xml.@frameRoundedCorners == "1";
			bottomThreshold = Number(xml.@bottomThreshold);
			topThreshold = Number(xml.@topThreshold);
			topScale = Number(xml.@topScale);

			pixelation = Number(xml.@pixelation);
			quality = Number(xml.@quality);

			var strColors:String = xml.@colors;
			colors = new Array();
			var astrColors:Array = strColors.split(',');
			for each (var strColor:String in astrColors)
				colors.push(Number(strColor));

			return true;
		}
		
		override protected function SerializeSelf(): XML {
			var xml:XML = <PerlinSpots/>
			xml.@xFrequency = xFrequency;
			xml.@yFrequency = yFrequency;
			xml.@colors = colors.join(',');
			xml.@seed = seed;
			xml.@fractal = fractal ? "1" : "0";
			xml.@octaves = octaves;

			xml.@isFrame = isFrame ? "1" : "0";
			xml.@frameThreshold = frameThreshold;
			xml.@frameSize = frameSize;
			xml.@frameBleed = frameBleed;
			xml.@frameRoundedCorners = frameRoundedCorners ? "1" : "0";
			xml.@bottomThreshold = bottomThreshold;
			xml.@topThreshold = topThreshold;
			xml.@topScale = topScale;

			xml.@pixelation = pixelation;
			xml.@quality = quality;
			return xml;
		}
	}
}
