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
package util.metadata {
	import flash.errors.EOFError;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class ImageMetadata { // meta
		static private const JPEG_SOI:uint = 0xffd8;	// Start Of Image
		static private const JPEG_EOI:uint = 0xffd9;	// End Of Image
		static private const JPEG_SOS:uint = 0xffda;	// Start Of Scan
		static private const JPEG_APP0:uint = 0xffe0;	// JFIF
		static private const JPEG_APP1:uint = 0xffe1;	// Exif, thumbnail, XMP metadata
		static private const JPEG_APP2:uint = 0xffe2;	// FlashPix (FPX) metadata, ICC color profile
		static private const JPEG_APP12:uint = 0xffec;	// Photoshop "Save for Web" aka "Ducky" (Quality, Comment, Copyright)
		static private const JPEG_APP13:uint = 0xffed;	// Photoshop "Save As" (IRB, 8BIM, IPTC)
		static private const JPEG_APP14:uint = 0xffee;	// Photoshop DCT settings (version, flags, color transform)
		static private const JPEG_COM:uint = 0xfffe;	// Comment marker
		
		private var _aobSegments:Array;
		
		// Return an ImageMetadata instance populated with an array of { segment: int, data: ByteArray }
		// or null if the image has no metadata or is of a type we don't know how to extract from.
		static public function Extract(baImage:ByteArray): ImageMetadata {
			var meta:ImageMetadata = null;
			try {
				baImage.endian = Endian.BIG_ENDIAN;
				
				// Is this a JPEG?
				var us:int = baImage.readUnsignedShort();
				if (us != JPEG_SOI)
					return null;
	
				// Scan segments looking for interesting metadata
				while (true) {
					var cbData:uint;
					us = baImage.readUnsignedShort();
					
					// Reached the start of the scan (just before the image data) or
					// the end of the image? If so we're done looking for metadata
					if (us == JPEG_SOS|| us == JPEG_EOI)
						break;
						
					cbData = baImage.readUnsignedShort() - 2;
					
					// CONSIDER: don't filter these on input so we can present them to interested users
					// Leave it to the output function to decide which segments aren't relevant to new images.
					if (us >= JPEG_APP1 && !(us == JPEG_APP12 || us == JPEG_APP13 || us == JPEG_APP14)) {
						var baData:ByteArray = new ByteArray();
						baImage.readBytes(baData, 0, cbData);
						if (meta == null)
							meta = new ImageMetadata();
//						trace("keeping metadata segment: 0x" + us.toString(16));
						meta.segments.push({ segment: us, data: baData });
					} else {
//						if (us >= JPEG_APP0)
//							trace("dropping metadata segment: 0x" + us.toString(16));
						baImage.position += cbData;
					}
				}
			} catch (err:EOFError) {
				// Break out of scan loop when end of file is past
			}
			
			return meta;
		}
		
		public function ImageMetadata() {
			_aobSegments = [];
		}
		
		public function get segments(): Array {
			return _aobSegments;
		}
	}
}
