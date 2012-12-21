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
package controls {
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	
	import util.TipManager;
	
	public class CollageItemRendererBase extends FontItemRendererBase {
		private var _tip:Tip;
		
		[Bindable] public var rightDivider:Boolean = false;
		
		// If items are premium (which is necessary for the click handling below)
		// FontItemRendererBase likes to color them. Keeep it from doing so.
		override protected function updateDisplayList(cxUnscaled:Number, cyUnscaled:Number): void {
			super.updateDisplayList(cxUnscaled, cyUnscaled);
			
			// Restore the ColorTransform that FontItemRenderBase clobbered
			if (_imgPreview) _imgPreview.transform.colorTransform = new ColorTransform();
		}
		
		protected function get passesPremiumTest(): Boolean {
			return !data.premium || AccountMgr.GetInstance().isPremium;
		}
		
		protected function get upgradeTipId(): String {
			if (PicnikConfig.freeForAll)
				return "collage_register";
			return "collage_upgrade";
		}
		
		protected function get templateLogName(): String {
			return data.template ? data.template : data.dims.x + "x" + data.dims.y + "_" + data.props;
		}
		
		protected function get collageType(): String {
			return "collage";
		}
		
		protected function ShowUpgradeTip(): void {
			// Non-paying users can't click on premium collage templates
			
			var strEvent:String = "/" + collageType + "/" + templateLogName;
			
			_tip = TipManager.ShowTip(upgradeTipId, true);
			if (_tip == null)
				return;
				
			var xml:XML = _tip.content;
			if (xml == null)
				return;
				
			xml.@pointAt = id = "point_at_me";
			xml.@context = strEvent;
			_tip.RepositionTip();
			_tip.addEventListener(Event.CLOSE, OnTipClose);
		}

		override protected function OnMouseDown(evt:MouseEvent): void {
			if (!passesPremiumTest) {
				ShowUpgradeTip();
				evt.stopImmediatePropagation();
				evt.preventDefault();
			}
		}
		
		// Clear out "point_at_me" so it doesn't interfere with the next upgrade tip
		private function OnTipClose(evt:Event): void {
			id = null;
			_tip.removeEventListener(Event.CLOSE, OnTipClose);
			_tip = null;
		}
	}
}
