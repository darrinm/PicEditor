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
// This class looks and acts like a FileReference for upload purposes but is backed by a ByteArray, not a file.

package util {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import imagine.ImageDocument;
	
	import mx.core.Application;

	public class MemoryFileReference extends FileReference {
		private var _ba:ByteArray;
		private var _strName:String;
		private var _urll:URLLoader;
		
		public function MemoryFileReference(ba:ByteArray, strName:String) {
			super();
			_ba = ba;
			_strName = strName;
		}
		
		override public function upload(urlr:URLRequest, uploadDataFieldName:String="Filedata", testUpload:Boolean=false): void {
			var fnOnComplete:Function = function (err:Number, strError:String): void {
				_urll = null;
				if (err != ImageDocument.errNone)
					dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, strError));
				else
					dispatchEvent(new Event(Event.COMPLETE));
			}
			
			var fnOnProgress:Function = function (strStatus:String, nFractionDone:Number): void {
				dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false,
						_ba.length * nFractionDone, _ba.length));
			}

			var baReq:ByteArray = new ByteArray();
			
			const kstrBoundary:String = "---------------------------7d76d1b56035e";
			const kstrCrLf:String = "\r\n";
			
			var urlv:URLVariables = urlr.data as URLVariables;
			if (urlv != null) {
				for (var strVar:String in urlv) {
					baReq.writeUTFBytes("--" + kstrBoundary + kstrCrLf);
					var strValue:String = urlv[strVar];
					
					// WARNING: If "filename" (any case) is in the attribute name FP 10 will complain
					// about the user having to click to initiate the file transfer. So we substitute
					// "fname" for "filename". Our server knows about this.
					if (strVar.toLowerCase().indexOf("filename") != -1)
						strVar = strVar.replace(/filename/i, "fname");
					baReq.writeUTFBytes("Content-Disposition: form-data; name=\"" + strVar + "\"" + kstrCrLf);
					baReq.writeUTFBytes(kstrCrLf);
					baReq.writeUTFBytes(strValue + kstrCrLf);
				}				
			}

			baReq.writeUTFBytes("--" + kstrBoundary + kstrCrLf);
			
			// WARNING: you may feel tempted to have a "filename" attribute here as RFC1867 calls for but
			// DON'T DO IT! FP 10 will complain about the user having to click to initiate the file transfer.
			baReq.writeUTFBytes('Content-Disposition: form-data; name="fname"; f="bogus.txt"' + kstrCrLf);
			baReq.writeUTFBytes("Content-Type: application/octet-stream" + kstrCrLf);
			baReq.writeUTFBytes(kstrCrLf);
			baReq.writeBytes(_ba);
			baReq.writeUTFBytes(kstrCrLf);
			
			baReq.writeUTFBytes("--" + kstrBoundary + kstrCrLf);
			baReq.writeUTFBytes("Content-Disposition: form-data; name=\"Upload\"" + kstrCrLf);
			baReq.writeUTFBytes(kstrCrLf);
			baReq.writeUTFBytes("Submit Query" + kstrCrLf);
			baReq.writeUTFBytes("--" + kstrBoundary + "--" + kstrCrLf);
			baReq.writeUTFBytes(kstrCrLf);
			
			urlr.method = URLRequestMethod.POST;
			urlr.data = baReq;
			urlr.contentType = "multipart/form-data; boundary=" + kstrBoundary;

			_urll = new URLLoaderPlus(); // Hang on to the URLLoader so it won't get GC'ed while pending
			new ImageUploadListener(_urll, fnOnProgress, fnOnComplete);
			try {
				_urll.load(urlr);
			} catch (err:Error) {
				dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, err.message));
			}
			
			// Simulate a real FileReference
			dispatchEvent(new Event(Event.OPEN));
		}
		
		// HACK: A straight "override function load()" won't work when the SWF is loaded by FP9
		// NOTE: All callers of FileReference.load must look for this method.
		public function LoadOverride(): void {
			// Fire events async as callers expect them to be
			Application.application.callLater(_Load);
		}

		// HACK: A straight "override function get data()" won't work when the SWF is loaded by FP9
		// NOTE: All callers of FileReference.data must look for this method.
		public function get dataOverride(): ByteArray {
			return _ba;
		}

		override public function get name(): String {
			return _strName;
		}
		
		override public function get size(): uint {
			return _ba.length;
		}
		
		override public function get type(): String {
			return null;
		}
		
		override public function get creationDate(): Date {
			return new Date();
		}
		
		override public function get modificationDate(): Date {
			return new Date();
		}
		
		override public function get creator(): String {
			return null;
		}

		private function _Load(): void {
			_ba.position = 0;
			dispatchEvent(new Event(Event.OPEN));
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _ba.length, _ba.length));
			dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}
