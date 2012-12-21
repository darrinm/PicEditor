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
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.events.FlexEvent;
	
	import util.LocUtil;
	
	public class TipNextPrevFooterBase extends Canvas {
		[Bindable] public var _btnPrevious:Button;
		[Bindable] public var _btnNext:Button;
		[Bindable] public var _lbXofY:LabelPlus;
		[Bindable] public var index:Number;
		[Bindable] public var total:Number;
		[Bindable] public var tipRenderer:TipRenderer;
		
		public function TipNextPrevFooterBase() {
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}
		
		private function OnCreationComplete(evt:FlexEvent): void {
			_btnPrevious.addEventListener(MouseEvent.CLICK, OnPreviousClick);
			_btnNext.addEventListener(MouseEvent.CLICK, OnNextClick);
			
			if (index == 1)
				_btnPrevious.visible = false;
			if (index == total)
				_btnNext.label = Resource.getString("TipNextPrevFooter", "start_over");
				
			_lbXofY.text = LocUtil.rbSubst("LocUtil", "XofY", index, total);
		}
		
		private function OnPreviousClick(evt:MouseEvent): void {
			var strPath:String = GetPathPrefix() + "_" + (index - 1);
			tipRenderer.LoadTip(strPath);
		}
		
		private function OnNextClick(evt:MouseEvent): void {
			var strPath:String = GetPathPrefix() + "_" + (index == total ? 1 : index + 1);
			tipRenderer.LoadTip(strPath);
		}
		
		private function GetPathPrefix(): String {
			var strPath:String = String(tipRenderer.content.@id);
			return "tips.xml/" + strPath.substr(0, strPath.lastIndexOf("_"));
		}
	}
}
