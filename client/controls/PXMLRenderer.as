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
package controls
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.getDefinitionByName;
	
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.controls.Spacer;
	import mx.controls.Text;
	import mx.core.Container;
	import mx.core.UIComponent;

	public class PXMLRenderer extends VBox
	{
 		private var _ldr:URLLoader = null;
		public var actionTarget:Object;
		private static const kobEvents:Object = {"click":true};
		private var _xmlContent:XML;

		public function PXMLRenderer()
		{
			super();
			actionTarget = this;
		}
		
 		// Source can be:
 		// XML
 		// string containing a url
 		// urlrequest
 		public function set source(ob:Object): void {
 			if (ob is XML) {
 				content = ob as XML;
 			} else if (ob is URLRequest) {
 				LoadURLR(ob as URLRequest);
 			} else if (ob is String) {
				LoadURLR(new URLRequest(ob as String));
 			}
 		}
 		
 		protected function LoadURLR(urlr:URLRequest): void {
 			_ldr = new URLLoader();
 			_ldr.load(urlr);
 			_ldr.addEventListener(Event.COMPLETE, OnLoadComplete);
 			_ldr.addEventListener(IOErrorEvent.IO_ERROR, OnLoadError);
 			_ldr.addEventListener(SecurityErrorEvent.SECURITY_ERROR, OnLoadError);
 		}

 		protected function OnLoadError(evt:Event): void {
 			trace("Load error: " + evt);
 		}
 		
 		protected function OnLoadComplete(evt:Event): void {
 			content = XML(_ldr.data);
 		}

		public function set content(xml:XML): void {
			_xmlContent = xml;
			
			removeAllChildren();
			// convert the xml into objects
			if (xml) {
				for each (var xmlChild:XML in xml.children()) {
					// Do something with each child.
					parseContent(this, xmlChild);
				}
				validateNow();
			}
		}
		
		public function get content(): XML {
			return _xmlContent;
		}

		// Returns null on failure
		protected function instantiateClass(strClass:String): Object {
			var clsDocumentObject:Class;
			try {
				clsDocumentObject = getDefinitionByName(strClass) as Class;
			} catch (err:ReferenceError) {
				return null;
			}
			return new clsDocumentObject();
		}
		
		private static function dummy(): void {
			var cdbtn:CountdownButton;
			var sad:SquareAd;
			var img:Image;
			var txt:Text;
			var tcb:TipCheckBox;
			var hbx:HBox;
			var vbx:VBox;
			var txt1:TipText;
			var txt2:TipTextHeader;
			var txt3:CanvasTipText;
			var btn1:TipButton;
			var btn2:TipUpgradeButton;
			var tnpf:TipNextPrevFooter;
			var tibtn:TemplateInfoButton;
			var tiabdg:TemplateInfoAttribBadge;
			var spcr:Spacer;
		}
		
		// documentObjects were relocated to imagine.documentObjects 03/17/2011
		private const kastrTypePaths:Array = ['mx.controls', 'mx.containers', 'controls', 'containers', 'imagine'];
		
		protected function instantiateObject(strType:String): Object {
			// try a few different
			var obInst:Object = instantiateClass(strType);
			
			if (!obInst) {
				for each (var strClassPath:String in kastrTypePaths) {
					obInst = instantiateClass(strClassPath + "." + strType);
					if (obInst) break;
				}
			}
			return obInst;
		}

		protected function StrRemoveQuotes(strIn:String): String {
			var nBreak1:Number = strIn.indexOf("'");
			var nBreak2:Number = strIn.indexOf('"');
			if (nBreak1 < 0 && nBreak2 < 0) return strIn;
			
			var nStart:Number;
			var strQuote:String;
			if (nBreak1 == -1 || (nBreak2 >= 0 && nBreak1 > nBreak2)) {
				strQuote = '"';
				nStart = nBreak2;
			} else {
				strQuote = "'";
				nStart = nBreak1;
			}
			
			nStart += 1;
			var nEnd:Number = strIn.lastIndexOf(strQuote);
			
			return strIn.substr(nStart, nEnd - nStart);
		}
		
		protected function ARemoveQuotes(astrArgs:Array): void {
			for (var i:Number = 0; i < astrArgs.length; i++) {
				astrArgs[i] = StrRemoveQuotes(astrArgs[i]);
			}
		}
		
		protected function DoAction(strAction:String, evt:Event=null): Object {
			var obRet:Object = null;
			var nBreak:Number = strAction.indexOf('(');
			if (nBreak > -1) {
				var strFn:String = strAction.substr(0, nBreak);
				var strParams:String = strAction.substr(nBreak+1, strAction.length - nBreak - 2);
				
				var astrArgs:Array;
				if (strParams.length == 0) {
					astrArgs = [];
				} else {
					astrArgs = strParams.split(',');
					ARemoveQuotes(astrArgs);
				}
				
				for (var i:Number = 0; i < astrArgs.length; i++)
					if (astrArgs[i] == "{event}") astrArgs[i] = evt;
				
				var fn:Function = actionTarget[strFn] as Function;
				obRet = fn.apply(actionTarget, astrArgs);
			}
			return obRet;
		}
		
		protected function ChildrenToXmlString(xml:XML): String {
			var strXML:String = "";
			var obPrevSettings:Object = XML.settings();
			XML.prettyPrinting = false;
			for each (var xmlChild:XML in xml.children()) {
				strXML += xmlChild.toXMLString();
			}
			XML.setSettings(obPrevSettings);
			return strXML;
		}
		
		protected function parseContent(ctr:Container, xml:XML): void {
			try {
				if (xml.localName() == null) return;
				var dob:DisplayObject = instantiateObject(xml.localName()) as DisplayObject;
				if (dob == null) {
					trace("Found unknown type: " + xml.localName() + ": " + xml.toXMLString());
					return;
				}
				if ("tipRenderer" in dob)
					dob["tipRenderer"] = this;
					
				if (dob is Text) {
					dob['percentWidth'] = 100;
				}
				
				for each (var xmlAttr:XML in xml.@*) {
					var strAttrName:String = xmlAttr.name();
					if (strAttrName in kobEvents) {
						var evtd:IEventDispatcher = dob as IEventDispatcher;
						// UNDONE: We need to remove these listeners when we are done
						// Weak references were not working.
						var strAction:String = xmlAttr.toXMLString();
						evtd.addEventListener(strAttrName, function (evt:Event): void {DoAction(strAction, evt)});
					} else {
						SetVal(dob, strAttrName, xmlAttr.toXMLString());
					}
				}
				
				if (dob is Text) (dob as Text).htmlText = ChildrenToXmlString(xml);
				if (dob is Button) (dob as Button).label = ChildrenToXmlString(xml).replace(/\&amp\;/gi, '&').replace(/\&gt\;/gi, '>').replace(/\&lt\;/gi, '<');
				// steveler 2010-08-18 removing to reduce build size
				//if (dob is QuestionBox) (dob as QuestionBox).data = ChildrenToXmlString(xml);
	
				else if (xml.hasComplexContent() && dob is Container) {
					for each (var xmlChild:XML in xml.children()) {
						parseContent(dob as Container, xmlChild);
					}
				}
				ctr.addChild(dob);
			} catch (e:Error) {
				trace(e);
				trace(e.getStackTrace());
			}
		}
		
		private function SetFunctionVal(dob:DisplayObject, strAttrName:String, strVal:String): void {
			_SetVal(dob, strAttrName, DoAction(strVal));
		}

		private function _SetVal(dob:DisplayObject, strAttrName:String, obVal:Object): void {
			try {
				if (strAttrName in dob) {
					dob[strAttrName] = obVal;
				} else if (dob is UIComponent) {
					// Is it too early to do this?
					(dob as UIComponent).setStyle(strAttrName, obVal);
				}
			} catch (e:Error) {
				trace(e);
				trace(e.getStackTrace());
			}
		}
		
		private function SetVal(dob:DisplayObject, strAttrName:String, strVal:String): void {
			try {
				var obVal:Object = strVal;
	
				if (strVal.indexOf("(") != -1) {
					callLater(SetFunctionVal, [dob, strAttrName, strVal]);
				} else {
					if (strAttrName in dob) {
						if ((strAttrName == "width" || strAttrName == "height") && (strVal.charAt(strVal.length-1) == "%")) {
							strAttrName = "percent" + strAttrName.charAt(0).toUpperCase() + strAttrName.substr(1); // convert "width" to "percentWidth"
							obVal = strVal.substr(0, strVal.length - 1); // Lop off percent sign
						}
						if (dob[strAttrName] is Boolean && !(obVal is Boolean)) {
							obVal = (obVal == "true" || obVal == "1");
						} else if (dob[strAttrName] is Number) {
							obVal = Number(obVal);
						}
					}
					_SetVal(dob, strAttrName, obVal);
				}
			} catch (e:Error) {
				trace(e);
				trace(e.getStackTrace());
			}
		}
	}
}