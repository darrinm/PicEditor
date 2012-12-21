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
	import containers.EffectCanvasBase;
	import containers.NestedControlCanvasBase;
	
	import controls.shapeList.SubGroupHeader;
	import controls.shapeList.TemplateSubGroup;
	
	import events.HelpEvent;
	
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.VRule;
	
	import util.LocUtil;
	import util.TemplateGroup;

	public class TemplateGroupItemRendererBase extends EffectCanvasBase
	{
		[Bindable] public var templateGroup:TemplateGroup;
		[Bindable] public var _vbxContents:VBox;
		
		public function TemplateGroupItemRendererBase()
		{
			super();
		}
		
		public static const kstrFancyCollageGroupInfoVisibleKey:String = "FancyCollage.InfoVisible";
		
		override protected function get helpPersistentStateKey(): String {
			return kstrFancyCollageGroupInfoVisibleKey;
		}
		
		override protected function get showHelpDefault(): Boolean {
			return true;
		}
		
		[Bindable(event="changeHeight")]
		override public function get fullHeight(): Number {
			validateSize(true);
			return measuredHeight + 1;
		}
		
		protected function OnContentResize(): void {
			height = fullHeight;
			return;
		}

		override protected function DispatchHelpEvent(strEventType:String): void {
			dispatchEvent(new HelpEvent(strEventType, null, null, this));
		}
		
		public override function set data(value:Object):void {
			super.data = value;
			templateGroup = TemplateGroup(data);
			id = "_tgrprdr_" + templateGroup.title;
		}
		
		override protected function OnAllStagesCreated(): void {
			if (templateGroup != null)
				UpdateUI();
				
			// super's OnAllStagesCreated sets the effect button's height and starts animating it open
			super.OnAllStagesCreated();
		}
		
		override protected function UpdateZoomviewForSelected(fSelected:Boolean): void {
			// Do nothing - leave the zoom view as is
		}

		override public function Select(efcnvCleanup:NestedControlCanvasBase): Boolean {
			var fSelected:Boolean = super.Select(efcnvCleanup);
			if (fSelected)
				UpdateUI();
			return fSelected;
		}
		
		override protected function UpdateStateForSelected(fSelected:Boolean): void {
			// Do nothing
		}
		
		private function GetSubHead(obTemplate:Object): String {
			if ((obTemplate == null) || !('title' in obTemplate))
				return null;
			var strTitle:String = obTemplate.title;
			if (strTitle == null || strTitle.length == 0)
				return null;
			var nBreak:Number = strTitle.indexOf(':');
			if (nBreak == -1)
				return null;
			var strSubHead:String = strTitle.substr(nBreak+1);
			if (strSubHead.length == 0)
				return null;
			return strSubHead;
		}
		
		private function UpdateUI(): void {
			if (_vbxContents.numChildren > 0) return;
			if (templateGroup == null) return;
			
			var hbx:HBox = null;
			var strPrevSubHead:String = null;
			var iSubChild:Number = 0;
			var vbxChildren:VBox = _vbxContents;
			for (var i:Number = 0; i < templateGroup.children.length; i++) {
				var obTemplate:Object = templateGroup.children[i];
				var strSubHead:String = GetSubHead(obTemplate);
				if (strSubHead != strPrevSubHead && strSubHead != null) {
					strPrevSubHead = strSubHead;
					iSubChild = 0; // Restart child position
					var tsg:TemplateSubGroup = new TemplateSubGroup();
					tsg.data = {title1:LocUtil.EnglishToLocalized(strSubHead), title2:'', premium:false};
					_vbxContents.addChild(tsg);
					vbxChildren = tsg._vbxChildren;
				}
				if (iSubChild % 2 == 0) {
					// Left child, create new hbox
					hbx = new HBox();
					hbx.percentWidth = 100;
					hbx.height = 156;
					hbx.setStyle('horizontalGap',0);
					hbx.setStyle('borderStyle','solid');
					hbx.setStyle('borderColor',0xd9d9d9);
					hbx.setStyle('borderSides','top');
					vbxChildren.addChild(hbx);
				}
				// Create the item
				var tmpl:ScrapbookItemRenderer = new ScrapbookItemRenderer();
				tmpl.data = obTemplate;
				hbx.addChild(tmpl);

				if (iSubChild % 2 == 0) {
					// Left child, insert divider
					var vr:VRule = new VRule();
					hbx.addChild(vr);
					vr.percentHeight = 100;
					vr.setStyle('strokeColor',0xd9d9d9);
					vr.setStyle('strokeWidth',1);
				}
				iSubChild++;
			}
		}

	}
}