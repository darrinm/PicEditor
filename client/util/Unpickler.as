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
package util
{
	/***
	 * Unpickler provides a way to rehydrate objects pickled in Python
	 * Current classes supported include:
	 *   - None
	 *   - Array
	 *   - Tuple
	 *   - Dictionary
	 *   - integer
	 *   - long integer (will loose precision)
	 *   - float
	 *   - boolean
	 *   - string (unicode, non-unicode)
	 * Unsupported types:
	 *   - classes
	 ***/
	public class Unpickler
	{
		private var _nPos:Number = 0;
		private var _aVars:Array = [];
		private var _strIn:String = "";
		
		public static function loads(strCBParams:String) : Object {
			// Unpickling strings in Python can allow for arbitrary code
			// execution. Thus when pickling on the server we've started
			// prepending an MD5 hash of the pickled string before sending it up
			// to the client (and the client will in some cases will then send
			// it back down to the server). Here, we ignore the hash for a few
			// reasons:
			//
			// 1) the code execution vulnerability doesn't exist in Flash
			// 2) to calculate the correct hash we need to have the secret from
			// the server, but we can't embed secrets in a Flash client
			// 3) if the pickled string is tampered with, then the client will
			// fail to authenticate with an external service, but nothing worse
			// than that
			if (/^[A-Fa-f0-9]{32}/.test(strCBParams)) {
				strCBParams = strCBParams.substring(32);
			}
			return new Unpickler(strCBParams).GetNextObject();
		}
		
		public function Unpickler(strIn:String)
		{
			_strIn = strIn;	
		}
		
		private function DoError(strMessage:String): void {
			var strMessage:String = strMessage + ", " + this;
			throw new Error(strMessage);
		}
		
		public function toString(): String {
			return _strIn +", " + _nPos;
		}
		
		protected function get remaining(): String {
			return _strIn.substr(_nPos);
		}
		
		private function Peek1(strError:String): String {
			var strOut:String = Reads1(strError);
			Unread(strOut);
			return strOut;
		}

		private function Peek(nLen:Number, strError:String): String {
			var strOut:String = Reads(nLen, strError);
			Unread(strOut);
			return strOut;
		}

		private function Reads1(strError:String): String {
			if (_nPos >= _strIn.length) DoError(strError);
			var strOut:String = _strIn.charAt(_nPos);
			_nPos += 1;
			return strOut;
		}
		
		private function Readi(): Number {
			if (_nPos >= _strIn.length) DoError("Could not find an integer");
			var n:Number = 0;
			
			while (_nPos < _strIn.length && isdigit(_strIn.charAt(_nPos))) {
				n = n * 10 + Number(Reads1("Looking for digit"));
			}
			
			return n;
		}
		
		private function Unread(str:String): void {
			_nPos -= str.length;
		}

		private function ReadsThrough(strChFind:String, strName:String=null): String {
			var strOut:String = "";
			var strCh:String = "";
			while (strCh != strChFind) {
				strOut += strCh;
				strCh = Reads1("Missing terminator: " + (strName ? strName : strChFind));
			}
			return strOut;
		}
		
		private function ReadsLine(): String {
			return ReadsThrough('\n', 'new line');
		}
		
		private function Reads(nLen:Number, strLookingFor:String): String {
			var strOut:String = "";
			for (var i:Number = 0; i < nLen; i++) {
				strOut += Reads1("Not enough chars, looking for " + strLookingFor);
			}
			return strOut;
		}
		
		private function ReadStringObTo(chSep:String): String {
			// String
			var strOut:String = "";
			while (true) {
				var chNext:String = Reads(1, "Next char");
				if (chNext == chSep) {
					break;
				} else {
					if (chNext == '\\') {
						// Escaped
						chNext = Reads(1, "Escaped code");
						if (chNext == 'x') {
							// Escaped hex
							strOut += String.fromCharCode(hextoi(Reads(2, "hex code")));
						} else if (chNext == 'u') {
							// Unicode hex
							strOut += String.fromCharCode(hextoi(Reads(4, "hex code")));
						} else if (chNext == 'n') {
							strOut += '\n';
						} else if (chNext == 'r') {
							strOut += '\r';
						} else {
							strOut += chNext;
						}
					} else {
						strOut += chNext;
					}
				}
			}
			return strOut;
		}

		private function ReadUnicodeStringOb(): String {
			// Unicode String, no quotes, terminated by newline
			var strOut:String = ReadStringObTo('\n');
			ReadPut(strOut);
			return strOut;
		}
		
		private function ReadStringOb(): String {
			// String, has quotes, followed by newline
			var chQuote:String = Reads(1, "quote");
			var strOut:String = ReadStringObTo(chQuote);

			// Next should be a newline
			EatNewLine();
			ReadPut(strOut);
			return strOut;
		}
		
		private function ReadArrayOb(): Array {
			var aOut:Array = [];
			ReadPut(aOut);
			
			// Now look for members to add to the dictionary
			
			// Members look like this:
			// OB1
			// a <no trailing newline>
			
			// If the last a is missing, push everything back on the stack and do not add it to the dictionary
			
			var fDone:Boolean = false;
			while (!fDone) {
				var nPrevPos:Number = _nPos;
				try {
					var obVal:Object = GetNextObject();
					Eat('a');
					aOut.push(obVal);
				} catch (e:Error) {
					fDone = true;
					_nPos = nPrevPos;
				}
			}
			
			return aOut;
		}
		
		// tuples are represented as arrays (no way to tell them apart, for now - we may eventually need this to re-pickle)
		private function ReadTupleOb(): Array {
			var aOut:Array = [];
			// Now look for members to add to the dictionary
			
			// Members look like this:
			// OB1
			// ...
			
			// when we encounter a t for the next character, we are at the end of our tuple.
			
			var fDone:Boolean = false;
			while (Peek1("Expecting more chars in tuple") != 't') {
				var obVal:Object = GetNextObject();
				aOut.push(obVal);
			}
			Eat('t');
			ReadPut(aOut);
			return aOut;
		}
		
		private function ReadDictOb(): Object {
			var obOut:Object = new Object();
			ReadPut(obOut);
			
			// Now look for members to add to the dictionary
			
			// Members look like this:
			// OB1
			// OB2
			// s <no trailing newline>
			
			// If the last s is missing, push everything back on the stack and do not add it to the dictionary
			
			var fDone:Boolean = false;
			while (!fDone) {
				var nPrevPos:Number = _nPos;
				try {
					var obKey:Object = GetNextObject();
					var obVal:Object = GetNextObject();
					Eat('s');
					obOut[obKey] = obVal;
				} catch (e:Error) {
					fDone = true;
					_nPos = nPrevPos;
				}
			}
			
			return obOut;
		}
		
		private function Eat(strCh:String, strChDesc:String=null): void {
			if (strChDesc == null) strChDesc = strCh;
			var strFound:String = Reads(1, strChDesc);
			if (strFound != strCh) DoError("Expected " + strChDesc + ", got " + strFound);
		}
		
		private function EatNewline(): void {
			EatNewLine();
		}
		
		private function EatNewLine(): void {
			Eat('\n', 'newline');
		}
		
		private function ReadPut(obPut:Object): void {
			Eat('p');
			_aVars[Readi()] = obPut;
			EatNewLine();
		}
		
		private function ReadNumberOb(): Number {
			var strLine:String = ReadsLine();
			if (strLine.length && (strLine.charAt(strLine.length-1) == 'L'))
				strLine = strLine.substr(0, strLine.length-1);
			return new Number(strLine);
		}
		
		private function ReadBooleanOb(): Boolean {
			return Number(ReadsLine()) != 0;
		}
		
		public function GetNextObject(): Object {
			var strType:String = Reads(1, "Type");

			if (strType == 'S') {
				return ReadStringOb();
			} else if (strType == 'V') {
				return ReadUnicodeStringOb();
			} else if (strType == 'I') {
				var strFirstTwo:String = Peek(2, "integers");
				if (strFirstTwo.charAt(0) == '0' &&
					(strFirstTwo.charAt(1) == '0' || strFirstTwo.charAt(1) == '1')) {
					return ReadBooleanOb();
				} else {
					return ReadNumberOb();
				}
			} else if ((strType == 'F') || (strType == 'L')) {
				return ReadNumberOb();
			} else if (strType == 'N') {
				return null; // None type
			} else if (strType == 'g') {
				var n:Number = Number(ReadsLine());
				return _aVars[n];
			} else if (strType == '(') {
				var strSubType:String = Reads(1, "list subtype");
				if (strSubType == 'l') {
					return ReadArrayOb();
				} else if (strSubType == 'd') {
					return ReadDictOb();
				} else if (strSubType == 't') {
					return ReadTupleOb();
				} else {
					Unread(strSubType);
					return ReadTupleOb();
				}
			} else {
				DoError("Unsuported type: " + strType);
			}
			
			// Figure the type of strIn
			return null;
		}

		private static const kn0Code:Number = String('0').charCodeAt(0);
		private static const knACode:Number = String('A').charCodeAt(0);

		private function isdigit(strCh:String): Boolean {
			var nCode:Number = strCh.charCodeAt(0);
			return (nCode >= kn0Code && nCode < (kn0Code + 10));
		}
		
		private function hextoi(strHex:String): Number {
			strHex = strHex.toUpperCase();
			var nOut:Number = 0;
			for (var i:Number = 0; i < strHex.length; i++) {
				var nDigit:Number = 0;
				var nCode:Number = strHex.charCodeAt(i);
				
				if (nCode >= kn0Code && nCode < (kn0Code + 10)) {
					nDigit = nCode - kn0Code;
				} else if (nCode >= knACode && nCode < (knACode + 6)) {
					nDigit = 10 + nCode - knACode;
				} else {
					DoError("Unable to parse hex: " + strHex);
				}
				
				nOut = nOut * 16 + nDigit;
			}
			return nOut;
		}
	}
}