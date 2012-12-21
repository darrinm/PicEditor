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
package imagine.serialization
{
	import com.adobe.utils.StringUtil;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	import mx.utils.ObjectUtil;
	
	public class SerializationUtil
	{
		public function SerializationUtil()
		{
		}

		private static const kstrAMFMarkerPrefix:String = "AMF:";
		private static const kstrAMFMarkerUUEncoded:String = kstrAMFMarkerPrefix + "U:";
		private static const kstrAMFMarkerPlain:String = kstrAMFMarkerPrefix + "P:";
		
		public static function HasAMFMarker(str:String): Boolean {
			return StringUtil.beginsWith(str, kstrAMFMarkerPrefix);
		}

		public static function WriteToStringWithMarker(ob:Object, fUUEncode:Boolean=true): String {
			var ba:ByteArray = WriteToByteArray(ob);
			if (fUUEncode) {
				var enc:Base64Encoder = new Base64Encoder();
				enc.encodeBytes(ba);
				return kstrAMFMarkerUUEncoded + enc.drain();
			} else {
				return kstrAMFMarkerPlain + ba.toString();
			}
		}
		
		public static function ReadFromStringWithMarker(str:String): * {
			var strMarker:String = str.substr(0, kstrAMFMarkerUUEncoded.length);
			var strBytes:String = str.substr(kstrAMFMarkerUUEncoded.length);
			var ba:ByteArray;
			if (strMarker == kstrAMFMarkerUUEncoded) {
				var dec:Base64Decoder = new Base64Decoder();
				dec.decode(strBytes);
				ba = dec.drain();
			} else if (strMarker == kstrAMFMarkerPlain) {
				ba = new ByteArray();
				ba.writeUTFBytes(strBytes);
			} else {
				throw new Error("Unknown marker: " + strMarker);
			}
			ba.position = 0;
			return ba.readObject();
		}
		
		public static function DeepCopy(ob:Object): * {
			var ba:ByteArray = WriteToByteArray(ob);
			ba.position = 0;
			return ba.readObject();
		}

		public static function WriteToString(ob:Object): String {
			var ba:ByteArray = WriteToByteArray(ob);
			return ba.toString();
		}

		public static function WriteToByteArray(ob:Object): ByteArray {
			var ba:ByteArray = new ByteArray();
			ba.writeObject(ob);
			return ba;
		}
			
		/* DEBUG: Use in conjunction with SerializeTest() to test serialization
		private static function LastN(str:String, nChars:Number): String {
			nChars = Math.min(nChars, str.length);
			return str.substr(str.length - nChars);
		}
		
		private static function PrevN(str:String, nPos:Number, nBack:Number): String {
			nBack = Math.min(nBack, nPos);
			return str.substr(nPos - nBack, nBack);
		}

		public static function ValidateStringMatch(str1:String, str2:String): void {
			if (str1 == str2) {
				trace("Strings match");
				return; // Found a match
			}
			
			str1 = StringUtil.replace(str1, "imagine.serialization::SRectangle", "flash.geom::Rectangle");
			str2 = StringUtil.replace(str2, "imagine.serialization::SRectangle", "flash.geom::Rectangle");
			str1 = StringUtil.replace(str1, "imagine.serialization::SPoint", "flash.geom::Point");
			str2 = StringUtil.replace(str2, "imagine.serialization::SPoint", "flash.geom::Point");

			if (str1 == str2) {
				trace("Strings match*");
				return; // Found a match
			}

			var i:Number = 0;
			while (true) {
				if (str1.length <= i) {
					// Ran out of chars in str1
					trace("==== string 1 is too short ====");
					trace("--- Last matching bit ---");
					trace(LastN(str1, 300));
					trace("--- Following bit of string 2 ---");
					trace(str2.substr(i, 300));
					throw new Error("String 1 is too short");
				} else if (str2.length <= i) {
					// Ran out of chars in str2
					trace("==== string 2 is too short ====");
					trace("--- Last matching bit ---");
					trace(LastN(str2, 300));
					trace("--- Following bit of string 1 ---");
					trace(str1.substr(i, 300));
					throw new Error("String 1 is too short");
				} else if (str1.charAt(i) != str2.charAt(i)) {
					// Found a difference
					trace("==== string 2 does not match string 1 at position " + i + " ====");
					trace("--- Last matching bit ---");
					trace(PrevN(str2, i, 300));
					trace("--- Following bit of string 1 ---");
					trace(str1.substr(i, 300));
					trace("--- Following bit of string 2 ---");
					trace(str2.substr(i, 300));
					
					trace("--- All of string 1 ---");
					trace(str1);
					trace("--- All of string 2 ---");
					trace(str2);
					throw new Error("Strings do not match");
				}
				i += 1;
			}
		}
		*/
		
		private static function HasMatchingParams(ob:Object, astrParams:Array): Boolean {
			var strParam:String;
			var obParams:Object = {};
			for each (strParam in astrParams) {
				if (!(strParam in ob))
					return false;
				obParams[strParam] = true;
			}
			for (strParam in ob) {
				if (!(strParam in obParams)) {
					return false;
				}
			}
			return true;
		}
		
		private static function HasPointParams(ob:Object): Boolean {
			return HasMatchingParams(ob, ['x', 'y']);
		}
		
		private static function HasRectParams(ob:Object): Boolean {
			return HasMatchingParams(ob, ['topLeft', 'bottomRight', 'x', 'width', 'left', 'y', 'height', 'bottom', 'right', 'top', 'size']);
		}
		
		private static function DoType(obSupportedTypes:Object, strType:String): Boolean {
			return (obSupportedTypes == null) || (strType in obSupportedTypes);
		}
		
		public static function CleanSrlzReadValue(obInput:Object, obSupportedTypes:Object=null): * {
			if (obInput == null)
				return null;
			var obOutput:Object = obInput;
			if (obInput is Array) {
				var aob:Array = obInput as Array;
				for (var i:Number = 0; i < aob.length; i++) {
					aob[i] = CleanSrlzReadValue(aob[i], obSupportedTypes);
				}
			} else if (getQualifiedClassName(obInput) == "Object") {
				// This is an object. If it has only x and y children, it is a point. Otherwise, check it's children.
				if (DoType(obSupportedTypes, "Point") && HasPointParams(obInput)) {
					obOutput = new Point(obInput.x, obInput.y);
				} else if (DoType(obSupportedTypes, "Rectangle") && HasRectParams(obInput)) {
					obOutput = new Rectangle(obInput.x, obInput.y, obInput.width, obInput.height);
				} else {
					// obOutput is an object with multiple children. See if any of the children are points.
					for (var strParam:String in obInput) {
						obInput[strParam] = CleanSrlzReadValue(obInput[strParam], obSupportedTypes);
					}
				}
			}
			return obOutput;
		}
		
		public static function CleanSrlzWriteValue(obInput:Object, obSupportedTypes:Object=null): * {
			if (obInput == null)
				return null;
			var obOutput:Object = obInput;
			if (obInput is Array) {
				var aob:Array = obInput as Array;
				for (var i:Number = 0; i < aob.length; i++) {
					aob[i] = CleanSrlzWriteValue(aob[i], obSupportedTypes);
				}
			} else if (getQualifiedClassName(obInput) == "Object") {
				// Clean children of this object
				for (var strParam:String in obInput) {
					obInput[strParam] = CleanSrlzWriteValue(obInput[strParam], obSupportedTypes);
				}
			} else if ((obInput is Point) && !(obInput is SPoint) && DoType(obSupportedTypes, "Point")) {
				obOutput = new SPoint(obInput.x, obInput.y);
			} else if ((obInput is Rectangle) && !(obInput is SRectangle) && DoType(obSupportedTypes, "Rectangle")) {
				obOutput = new SRectangle(obInput.x, obInput.y, obInput.width, obInput.height);
			}
			return obOutput;
		}
	}
}