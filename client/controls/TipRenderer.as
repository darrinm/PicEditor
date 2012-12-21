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
	import dialogs.DialogManager;
	
	import mx.core.UIComponent;
	
	import util.TipLoader;
	import util.TipManager;
	
	[Event(name="close", type="flash.events.Event")]

	public class TipRenderer extends PXMLRenderer
	{
		private var _strTipFile:String = null;
		private var _strTipId:String = null;
		
		private var _uicFooter:UIComponent = null;
		
		public function TipRenderer()
		{
			super();
		}
		
		[Bindable]
		public function set footer(uic:UIComponent): void {
			_uicFooter = uic;
			if (uic) addChild(uic);
		}
		public function get footer(): UIComponent {
			return _uicFooter;
		}
		
		// Absolute or relative path (always relative to the base path)
		// Absolute includes a tip file name
		// relative uses the current tip file name and includes only a tip ID
		public function set tipPath(strPath:String): void {
			LoadTip(strPath);
		}
		
		private function GetFullPath(strInitiator:String): String {
			var strPath:String = strInitiator;
			if (_strTipFile)
				strPath += "/" + _strTipFile;
			if (_strTipId)
				strPath += "/" + _strTipId;
			return strPath;
		}
		
		//========= BEGIN: Tip function helpers ===========
		public function Upgrade(strInitiator:String): void {
			TipManager.HideTip(content.@id);
			DialogManager.ShowUpgrade(GetFullPath(strInitiator));
		}
		
		public function ChoosePayment(strInitiator:String=null): void {
			TipManager.HideTip(content.@id);
			
			// Tips can use a context attribute to inform GA logging
			if (strInitiator == null && String(content.@context))
				strInitiator = String(content.@context);
				
			var strPath:String = GetFullPath(strInitiator);
			DialogManager.ShowUpgrade(strPath);
		}
		
		public function Register(): void {
			TipManager.HideTip(id);
			DialogManager.ShowRegister();
		}
		
		public function Renew(): void {
			Close();
			var strPath:String = GetFullPath("AutoRenewDialog");
			DialogManager.ShowUpgrade(strPath);
		}
		
		public function Close(): void {
			dispatchEvent(new Event(Event.CLOSE));
		}
		
		public function LoadTip(strPath:String): void {
			// UNDONE: Remove the footer when navigating?
			footer = null;
			if (strPath == null || strPath.length == 0) {
				content = null;
			} else {
				var strTipFile:String = _strTipFile;
				var strTipId:String = _strTipId;
				var nBreak:Number = strPath.indexOf('/');
				if (nBreak == -1) {
					strTipId = strPath;
				} else {
					strTipFile = strPath.substr(0, nBreak);
					strTipId = strPath.substr(nBreak+1, strPath.length-nBreak-1);
				}
				TipLoader.GetTip(strTipFile, strTipId, OnTipLoaded);
			}
		}
		//========= END: Tip function helpers ===========
		
		protected function OnTipLoaded(xml:XML, strTipFile:String, strTipId:String): void {
			_strTipFile = strTipFile;
			_strTipId = strTipId;
			if (parent is Tip)
				(parent as Tip).content = xml;
			else
				content = xml;
			if (footer)
				addChild(footer);
				
			if (parent is Tip)
				(parent as Tip).RepositionTip(null, true);
		}
	}
}
