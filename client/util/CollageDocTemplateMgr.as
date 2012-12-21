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
	import com.adobe.utils.StringUtil;
	
	import dialogs.EasyDialogBase;
	
	import imagine.documentObjects.PhotoGrid;
	
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import imagine.ImageDocument;
	
	import mx.core.UIComponent;
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	public class CollageDocTemplateMgr {
		private static var s_nCacheSize:Number = 20; // Cache this many templates. Set to 0 to turn off cache (template testing?)
		
		private static var s_cdtmgr:CollageDocTemplateMgr = null;
		
		private var _dctMapCallerToLoader:Dictionary = new Dictionary();
		
		private static function get instance(): CollageDocTemplateMgr {
			if (s_cdtmgr == null) s_cdtmgr = new CollageDocTemplateMgr();
			return s_cdtmgr;
		}
				
		public static function GetAssetToAssetMap(imgd:ImageDocument, dctProperies:Object): Object {
			var dctMapTemplateToLocalAsset:Object = {};
			for (var strKey:String in dctProperies) {
				// Look for asset<#>, where # is our asset id
				for each (var strPrefix:String in ["asset", "ref:asset"]) {
					if (StringUtil.beginsWith(strKey, strPrefix)) {
						var nLoadedAssetId:Number = Number(strKey.substr(strPrefix.length));
						var nRealAssetId:Number = imgd.AddAsset(dctProperies[strKey]);
						dctMapTemplateToLocalAsset[nLoadedAssetId] = nRealAssetId
					}
				}
			}
			return dctMapTemplateToLocalAsset;
		}
		
		// Returns obData.xml, obData.dctMapTemplateToLocalAsset
		public static function DecodeDocTemplate(strData:String): Object {
			var b64dec:Base64Decoder = new Base64Decoder();
			b64dec.decode(strData);
			var ba:ByteArray = b64dec.drain();
			ba.uncompress();
			var obData:Object = ba.readObject();
			obData.xml = new XML(obData.strXML);
			return obData;
		}
		
		public static function EncodeDocTemplate(xmlTemplate:XML, dctMapTemplateToLocalAsset:Object, fCompressed:Boolean): String {
			var obData:Object = {strXML:xmlTemplate.toXMLString(), dctMapTemplateToLocalAsset:dctMapTemplateToLocalAsset, fCompressed:fCompressed};
			var ba:ByteArray = new ByteArray();
			ba.writeObject(obData);
			ba.compress();
			var b64enc:Base64Encoder = new Base64Encoder();
			b64enc.encodeBytes(ba);
			return b64enc.drain();
		}
		
		// fnComplete(nError:Number, strError:String, xmlTemplate:XML=null, dctProperties:Object=null): void
		public static function GetDocumentTemplate(fid:String, fnComplete:Function, obCallerKey:Object=null, dctProps:Object=null): void {
			if (obCallerKey == null) obCallerKey = {}; // New key
			return instance._GetDocumentTemplate(fid, fnComplete, obCallerKey, dctProps);
		}
		
		// fnGotTemplate(nError:Number, strError:String, strPikTemplate:String): void
		public static function GetSerializedDocumentTemplate(imgd:ImageDocument, fid:String, fnGotTemplate:Function): void {
			var fnOnGotRawTemplate:Function = function(nError:Number, strError:String, xmlTemplate:XML=null, dctProperties:Object=null): void {
				var strPikTemplate:String = null;
				if (nError == PicnikService.errNone) {
					var dctMapTemplateToLocalAsset:Object = CollageDocTemplateMgr.GetAssetToAssetMap(imgd, dctProperties);
					var fCompressed:Boolean = ('fCompressed' in dctProperties && dctProperties['fCompressed'] == 'true');
					strPikTemplate = PhotoGrid.SERIALIZED_PIK + CollageDocTemplateMgr.EncodeDocTemplate(xmlTemplate, dctMapTemplateToLocalAsset, fCompressed);
				}
				fnGotTemplate(nError, strError, strPikTemplate);
			}
			GetDocumentTemplate(fid, fnOnGotRawTemplate);
		}
		
		public static function CancelLoad(obCallerKey:Object): void {
			instance._CancelLoad(obCallerKey);
		}
		
		private function _CancelLoad(obCallerKey:Object): void {
			if (obCallerKey in _dctMapCallerToLoader) {
				var cdtldr:CollageDocTemplateLoader = _dctMapCallerToLoader[obCallerKey];
				cdtldr.Cancel();
				delete _dctMapCallerToLoader[obCallerKey];
			}
		}
		
		/** GetDocTemplate
		 * 1. Check to see if we are currently loading a template for this key
		 *    If so, "stop" the load (will never call callback)
		 * 2. Next, check for a cached doc template.
		 * 2.a. If found, return it (call later)
		 *    Move it to the top of the recently used array
		 * 2.b. If not found, start a load
		 * 2.b.2. When the load completes, add it to the cache and the head of the recently used list.
		 *        Delete the last item in the list if we have too many
		 */
		private function _GetDocumentTemplate(fid:String, fnComplete:Function, obCallerKey:Object, dctProps:Object): void {
			_CancelLoad(obCallerKey);
			
			// TODO: Check cache
			var cdtldr:CollageDocTemplateLoader = new CollageDocTemplateLoader(fid, dctProps, fnComplete);
			_dctMapCallerToLoader[obCallerKey] = cdtldr;
		}
		
		static public function HandleTemplateLoadError(uic:UIComponent, nError:Number, strError:String, strTemplate:String): void {
			EasyDialogBase.Show(uic,
					[Resource.getString('Picnik', 'ok')],
					Resource.getString("AdvancedCollage", 'templateLoadFailedTitle'),
					Resource.getString("AdvancedCollage", 'templateLoadFailed'));
			PicnikService.Log("Template failed to load: " + strTemplate + ": " + nError + ": " + strError, PicnikService.knLogSeverityWarning);  
		}
		
		public static function GetTemplateName(obTemplate:Object): String {
			var strTemplateName:String = "ERROR";
			try {
				var fid:String = obTemplate.fid;
				strTemplateName = "fid:" + fid;
				
				// Try to convert the name to "groupid/templatename"
				var strGroupName:String = (obTemplate.groupid.length > 0) ? obTemplate.groupid : "uncategorized";
				strTemplateName = obTemplate.title + "_" + fid;
				strTemplateName = strGroupName + "/" + strTemplateName;
			} catch (e:Error) {
				// Ignore errors
			}
			return strTemplateName;
		}
	}
}
