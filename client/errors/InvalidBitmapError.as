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
package errors {
	public class InvalidBitmapError extends Error {
		
		public static const ERROR_UNKNOWN:Number = 0;
		public static const ERROR_ARGUMENTS:Number = 1;
		public static const ERROR_DISPOSED:Number = 2;
		public static const ERROR_MEMORY:Number = 3;
		public static const ERROR_IS_BACKGROUND:Number = 4;
		public static const ERROR_IS_COMPOSITE:Number = 5;
		public static const ERROR_IS_KEYFRAME:Number = 6;
		
		public var type:Number;
		
		public function InvalidBitmapError(nType:Number = ERROR_UNKNOWN, strMessage:String=null) {
			type = nType;
			if (strMessage == null) {
				switch (type) {
				case ERROR_UNKNOWN:
					strMessage = "InvalidBitmapError (unknown)";
					break;
				
				case ERROR_ARGUMENTS:
					strMessage = "InvalidBitmapError (arguments)";
					break;
				
				case ERROR_DISPOSED:
					strMessage = "InvalidBitmapError (disposed)";
					break;
				
				case ERROR_MEMORY:
					strMessage = "InvalidBitmapError (memory)";
					break;					
				
				case ERROR_IS_BACKGROUND:
					strMessage = "InvalidBitmapError (is background)";
					break;					
				
				case ERROR_IS_COMPOSITE:
					strMessage = "InvalidBitmapError (is composite)";
					break;					
				
				case ERROR_IS_KEYFRAME:
					strMessage = "InvalidBitmapError (is keyframe)";
					break;					
				}
				
			}
			super(strMessage, 103);
		}
	}
}
