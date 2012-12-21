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
package
{
	import com.adobe.utils.StringUtil;
	
	import containers.TemplateList;
	
	import controls.TemplateFilterPanel;
	import controls.TemplateGroupItemRenderer;
	import controls.TemplateGroupItemRendererBase;
	import controls.TemplatePropertiesDialogBase;
	import controls.Tip;
	
	import dialogs.EasyDialogBase;
	
	import imagine.documentObjects.Photo;
	import imagine.documentObjects.PhotoGrid;
	import imagine.documentObjects.Target;
	
	import events.HelpEvent;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import imagine.imageOperations.RasterizeImageOperation;
	
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	import mx.resources.ResourceBundle;
	
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import util.CollageDocTemplateMgr;
	import util.LocUtil;
	import util.TemplateGroup;
	import util.TemplateManager;
	
	public class AdvancedCollageBase extends CollageBase
	{
		[Bindable] public var _aTemplateSections:Array = null;
		[Bindable] public var _fErrorLoadingTemplates:Boolean = false;
		[Bindable] public var _obTemplateFilter:Object = null; // null is defualt, show non-hidden live templates
		[Bindable] protected var _fFilterPanelVisible:Boolean = false;
		private var _tfp:TemplateFilterPanel = null;
		private var _strTemplateSelected:String = "";
		
		[Bindable] public var _tlist:TemplateList;
		[Bindable] public var defaultToHighQuality:Boolean = false;

		[Bindable] public var _tipGroupInfo:Tip = new Tip();

		private var _strRasterizedPikTemplate:String = null;
		
  		[ResourceBundle("AdvancedCollage")] private var rb:ResourceBundle;
		
		public function AdvancedCollageBase()
		{
			super();
		}
		
		override protected function SetupNewCollageState(): void {
			// ZoomView checks the uimode. Nothing to do here.
		}


		override protected function get defaultGridBackgroundAlpha(): Number {
			return 0;
		}
		
		override protected function get defaultGridBackgroundColor(): Number {
			return 0xffffff;
		}
		
		override protected function initializationComplete():void {
			super.initializationComplete();
			addEventListener("editTemplate", OnEditTemplate);
			addEventListener("selectTemplate", OnSelectTemplate);
		}
		
		private function OnEditTemplate(evt:Event): void {
			var obTemplate:Object = evt.target.data;
			// Open an edit window for this.
			TemplatePropertiesDialogBase.ShowPanel(this, obTemplate);
		}
		
		override protected function get collageType(): String {
			return "fancyCollage";
		}
		
		override protected function OnDoneClick(evt:MouseEvent): void {
			Customize("CREATE_TAB", "_ctType");
		}
		
		private function OnSelectTemplate(evt:Event): void {
			var uicThis:UIComponent = this;
			
			var obTemplate:Object = evt.target.data;
			// Make sure we create a phgd
			if (_phgd == null) {
				// Get things going
				NewCollage(1, 1, 0, null, false, 0);
			}
			
			var strTemplate:String = ("template" in obTemplate) ? obTemplate.template as String: null;
			_strTemplateSelected = strTemplate;
			
			if (StringUtil.beginsWith(strTemplate, PhotoGrid.DIRECT_FID)) {
				// Convert from a fid template into a pik file template.
				// First, load the pik file
				var fnComplete:Function = function(nError:Number, strError:String, xmlTemplate:XML=null, dctProperties:Object=null): void {
					
					if (strTemplate != _strTemplateSelected) return; // Already selected a different template.
					if (nError != PicnikService.errNone) {
						CollageDocTemplateMgr.HandleTemplateLoadError(uicThis, nError, strError, strTemplate);
					} else {
						// Ok, we loaded a template. See if it defaults to high quality
						defaultToHighQuality = obTemplate.defaultToHighQuality;
						if (defaultToHighQuality)
							OnPrintResolutionClick();
						else if (!AccountMgr.GetInstance().isPremium)
							OnNormalResolutionClick(); // Switch back to normal resolution
						
						obTemplate.templateName = CollageDocTemplateMgr.GetTemplateName(obTemplate);
						var dctMapTemplateToLocalAsset:Object = CollageDocTemplateMgr.GetAssetToAssetMap(_imgd, dctProperties);
						var fCompressed:Boolean = ('fCompressed' in dctProperties && dctProperties['fCompressed'] == 'true');
						
						// Use the fid for now so we don't fill up our undo history with huge templates
						// We'll switch to the serialized version when we commit.
						// obTemplate.template = PhotoGrid.SERIALIZED_PIK + CollageDocTemplateMgr.EncodeDocTemplate(xmlTemplate, dctMapTemplateToLocalAsset, fCompressed);
						obTemplate.template = strTemplate;
						var anAssetRefs:Array = [];
						for each (var nLocalAsset:Number in dctMapTemplateToLocalAsset) {
							anAssetRefs.push(nLocalAsset);
						}
						obTemplate.strAssetRefs = (anAssetRefs.length > 0) ? anAssetRefs.join(',') : "";
						SelectTemplate(obTemplate);
					}
				}
				CollageDocTemplateMgr.GetDocumentTemplate(strTemplate.substr(PhotoGrid.DIRECT_FID.length), fnComplete, this, obTemplate.dctProps);
			} else {
				SelectTemplate(obTemplate);
			}
		}

		public function ToggleStageVisibilityPanel(): void {
			if (_fFilterPanelVisible) {
				_tfp.visible = false;
			} else {
				if (_tfp == null) {
					_tfp = new TemplateFilterPanel();				
					_tfp.Constructor(this, GetFilledInTemplateFilter());
					PopUpManager.addPopUp(_tfp, this);
					PopUpManager.centerPopUp(_tfp);
				}
				_tfp.visible = true;
			}
			_fFilterPanelVisible = !_fFilterPanelVisible;
			
		}
		
		public static function GetTemplateStages(): Array {
			return ['private', 'design','test','live'];
		}
		
		private function IsOrHasTarget(dob:DisplayObject): Boolean {
			if (dob is Target) return true;
			var dobc:DisplayObjectContainer = dob as DisplayObjectContainer;
			if (dobc != null) {
				for each (var dobChild:DisplayObject in dobc) {
					if (IsOrHasTarget(dob)) return true;
				}
			}
			return false;
		}

		// Go through photo grid children
		// and figure out the index of the last child to flatten
		// Children after this will not be flattened.
		private function CalcLastChildToFlattenIndex(): Number {
			var i:Number;
			var dobChild:DisplayObject;
			
			// Find the last target
			var iLastTarget:Number = -1;
			for (i = 0; i < _phgd.numChildren; i++) {
				if (IsOrHasTarget(_phgd.getChildAt(i))) {
					iLastTarget = i;
				}
			}
			
			// Find a large photo after this.
			var iNextLargePhoto:Number = -1;
			for (i = iLastTarget + 1; i < _phgd.numChildren; i++) {
				dobChild = _phgd.getChildAt(i);
				if (dobChild is Photo) {
					// phgd.unscaledWidth/Height ~= photo.width/height trace("found photo: phgd size = " + _phgd.width + ", " + _phgd.height + ", " + _phgd.unscaledWidth + ", " + _phgd.unscaledHeight +
					//	", photo size = " + dobChild.width + ", " + dobChild.height + ", " + dobChild.scaleX + ", " + dobChild.scaleY);
					iNextLargePhoto = i;
					break;
				}
			}
			return Math.max(0, iLastTarget, iNextLargePhoto);
		}

		// Returns number of assets left to load
		// Calls callback whenever another asset loads
		// var fnOnAssetLoaded:Function = function(nAssetsLeft:Number): void {
		override protected function WaitForExtraAssetsToLoad(fnOnAssetLoaded:Function): Number {
			// Don't commit until after we have set (and validated) our photo grid template property as serialized pik data
			var strTemplate:String = _phgd.template;
			if (StringUtil.beginsWith(strTemplate, PhotoGrid.DIRECT_FID)) {
				var nAssetsLeft:Number = 1;
				
				var fnGotTemplate:Function = function(nError:Number, strError:String, strPikTemplate:String=null): void {
					if (nError != PicnikService.errNone) {
						CollageDocTemplateMgr.HandleTemplateLoadError(this, nError, strError, strTemplate);
					} else {
						_strRasterizedPikTemplate = strPikTemplate;
					}
					nAssetsLeft = 0;
					fnOnAssetLoaded(nAssetsLeft);
				}
				// Convert a direct fid into a serialized pik file
				CollageDocTemplateMgr.GetSerializedDocumentTemplate(_imgd, strTemplate.substr(PhotoGrid.DIRECT_FID.length), fnGotTemplate);
				return nAssetsLeft;
			} else {
				// Nothing to do
				fnOnAssetLoaded(0);
				return 0;
			}
		}

		override protected function DoRasterize(): void {
			var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(_phgd.name,
					{ appliedTemplate: _strRasterizedPikTemplate });
			spop.Do(_imgd);

			var nNumChildrenToFlatten:Number = CalcLastChildToFlattenIndex() + 1;
			var rop:RasterizeImageOperation = new RasterizeImageOperation(
					_phgd.name, _imgd.width, _imgd.height, true, nNumChildrenToFlatten);
			rop.Do(_imgd);
		}
		
		public function FriendlyCMSStageName(strCMSStage:String): String {
			if (strCMSStage == null) return "NULL";
			var strKey:String = strCMSStage;
			if (strKey == "") strKey= "indevelopment";
			return Resource.getString("AdvancedCollage", strKey);
		}
		
		public function UpdateFilter(astrCMSStages:Array=null, fShowHidden:Boolean=false): void {
			if (astrCMSStages == null || astrCMSStages.length == 0) astrCMSStages = ['live'];
			if (astrCMSStages.length == 1 && astrCMSStages[0] == 'live' && fShowHidden == false) {
				_obTemplateFilter = null;
			} else {
				_obTemplateFilter = {astrCMSStages:astrCMSStages, fShowHidden:fShowHidden};
			}
			LoadTemplates();
		}
		
		public function RefreshTemplateList(): void {
			LoadTemplates();
		}
		
		override public function OnActivate(strCmd:String=null):void {
			super.OnActivate(strCmd);
			LoadTemplates();
			_tlist.OnActivate(null);	
			
			addEventListener(HelpEvent.SHOW_HELP, OnShowHelp, true);
			addEventListener(HelpEvent.HIDE_HELP, OnHideHelp, true);
			addEventListener(HelpEvent.SET_HELP_TEXT, OnSetHelpText, true);
			_tipGroupInfo.Hide(false);
			_tipGroupInfo.x = 341;
			_tipGroupInfo.y = 99;
			_tipGroupInfo.contentWidth = 258 + 12 + 12;
			_tipGroupInfo.fixedPosition = true;
			_tipGroupInfo.addEventListener(CloseEvent.CLOSE, OnGroupInfoTipClose);
			GetBasket().sizerWidth = 339;
		}
		
		override public function OnDeactivate():void {
			super.OnDeactivate();
			if (_fFilterPanelVisible) ToggleStageVisibilityPanel();
			TemplatePropertiesDialogBase.HideAll();
			_tlist.OnDeactivate(null);	
					
			removeEventListener(HelpEvent.SHOW_HELP, OnShowHelp, true);
			removeEventListener(HelpEvent.HIDE_HELP, OnHideHelp, true);
			removeEventListener(HelpEvent.SET_HELP_TEXT, OnSetHelpText, true);
			_tipGroupInfo.removeEventListener(CloseEvent.CLOSE, OnGroupInfoTipClose);
			_tipGroupInfo.Hide(false);
			GetBasket().sizerWidth = NaN;
		}
		
		private function OnGroupInfoTipClose(evt:Event): void {
			_tipGroupInfo.Hide(true);
			PicnikBase.SetPersistentClientState(TemplateGroupItemRendererBase.kstrFancyCollageGroupInfoVisibleKey, false);
			_tlist.HelpStateChange(false);
		}
		
		protected function OnShowHelp(evt:HelpEvent): void {
			OnSetHelpText(evt);
			_tipGroupInfo.quasiModal = false;
			_tipGroupInfo.Show();
		}
		
		protected function OnHideHelp(evt:HelpEvent): void {
			_tipGroupInfo.Hide(true);
		}
		
		protected function OnSetHelpText(evt:HelpEvent): void {
			var tgrprdr:TemplateGroupItemRenderer = (evt.target as TemplateGroupItemRenderer);
			var tgrp:TemplateGroup = tgrprdr.templateGroup;
			var strTipText:String = "by " + tgrp.by;
			var strVisit:String = LocUtil.rbSubst('AdvancedCollage', 'visitForMore', tgrp.attribLinkEntity).replace(/\&amp\;/gi, '&');
			var strByLine:String = LocUtil.rbSubst('AdvancedCollage', 'byline', tgrp.by);
			
			var xmlContent:XML =
				<Tip>
					<TipTextHeader>{tgrp.title}</TipTextHeader>
					<VBox percentWidth="100">
						<TipText>{strByLine}</TipText>
					</VBox>
				</Tip>
			
			var xmlVBox:XML = XML(xmlContent.VBox[0]);
			
			// Group description				
			if (tgrp.groupDesc != null && tgrp.groupDesc.length > 0)
				xmlVBox.appendChild(<TipText>{tgrp.groupDesc}</TipText>);	

			// attrib icon			
			if (tgrp.attribIcon != null && tgrp.attribIcon.length > 0)
				xmlVBox.appendChild(<TemplateInfoAttribBadge source={tgrp.attribIcon}/>);	
			
			// attrib button			
			if (tgrp.attribUrl != null && tgrp.attribUrl.length > 0)
				xmlVBox.appendChild(<TemplateInfoButton url={tgrp.attribUrl}>{strVisit}</TemplateInfoButton>);	
			
			if (xmlVBox.children().length() <= 1) {
				xmlVBox.appendChild(<Spacer height="1"/>);
			}
			
			_tipGroupInfo.content = xmlContent;
			
			var tmr:Timer = new Timer(250, 1);
			tmr.addEventListener(TimerEvent.TIMER, function(evt:Event): void {
				_tipGroupInfo.PointThumbAt(tgrprdr._efbtn.inspirationTarget);
			});
			tmr.start();
		}
		
		override protected function get tipsName(): String {
			return "fancyCollage_1";
		}
		
		protected function GetFilledInTemplateFilter(): Object {
			var astrCMSStages:Array = ['live'];
			var fShowHidden:Boolean = false;
			if (_obTemplateFilter != null) {
				astrCMSStages = _obTemplateFilter.astrCMSStages;
				fShowHidden = _obTemplateFilter.fShowHidden;
			}
			return {astrCMSStages:astrCMSStages, fShowHidden:fShowHidden};
		}
		
		protected function LoadTemplates(): void {
			_fErrorLoadingTemplates = false;
			var obTemplateFilter:Object = GetFilledInTemplateFilter();
			TemplateManager.GetTemplateList(obTemplateFilter.astrCMSStages, obTemplateFilter.fShowHidden,
				function(aTemplateSections:Array): void {
					_aTemplateSections = aTemplateSections;
					_fErrorLoadingTemplates = (_aTemplateSections == null);
				});
		}
	}
}