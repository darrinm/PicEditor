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
package pages {
	import com.adobe.utils.StringUtil;
	
	import containers.SendGreetingPageBase;
	
	import controls.PreviewButtonImage;
	
	import dialogs.EasyDialogBase;
	import dialogs.SendGreetingDialog;
	
	import imagine.documentObjects.DocumentStatus;
	import imagine.documentObjects.EmbeddedBitmap;
	import imagine.documentObjects.FitMethod;
	import imagine.documentObjects.PhotoGrid;
	import imagine.documentObjects.Target;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.containers.Tile;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	
	import imagine.ImageDocument;
	
	import imagine.objectOperations.CreateObjectOperation;
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import util.CollageDocTemplateMgr;
	import util.DrawUtil;
	import util.TemplateGroup;
	import util.TemplateManager;
	import util.TemplateSection;
	
	import viewObjects.UploadTargetViewObject;
	
	import views.TargetAwareView;

	public class SelectStylePageBase extends SendGreetingPageBase {
		private static const kcxNormalResolution:int = 550;
		private static const kcyNormalResolution:int = 550;
		
		[Bindable] public var _tlTemplateThumbs:Tile;
		[Bindable] public var _imgv:TargetAwareView;
		[Bindable] public var _imgVariation1:PreviewButtonImage;
		[Bindable] public var _imgVariation2:PreviewButtonImage;
		[Bindable] public var _imgVariation3:PreviewButtonImage;
		[Bindable] public var allTargetsPopulated:Boolean = false;
		[Bindable] public var templateGroupId:String;
		
		private var _imgd:ImageDocument;
		private var _tgrp:TemplateGroup;
		private var _phgd:PhotoGrid;
		private var _bmActiveDocument:Bitmap;
		private var _strTemplateSelected:String;
		
		protected function OnCreationComplete(evt:FlexEvent): void {
			_imgv.setStyle("color", null); // Otherwise the background of the view is orange!!!
			
			_imgVariation1.addEventListener(MouseEvent.CLICK, OnVariationClick);
			_imgVariation2.addEventListener(MouseEvent.CLICK, OnVariationClick);
			_imgVariation3.addEventListener(MouseEvent.CLICK, OnVariationClick);
			
			LoadTemplateList();
		}
		
		// Get the list of templates
		protected function LoadTemplateList(): void {
			currentState = "templateListLoading";
			TemplateManager.GetTemplateList(AccountMgr.GetInstance().isCollageAuthor ?
					[ "private", "design", "test", "live" ] : [ "live" ], true, OnTemplateListLoadComplete);
		}
		
		private function OnTemplateListLoadComplete(atsect:Array): void {
			if (atsect == null) {
				currentState = "templateListLoadError";
				return;
			}
			
			// Find the TemplateGroup we care about
			for each (var tsect:TemplateSection in atsect) {
				for each (var tgrp:TemplateGroup in tsect.children) {
					if (tgrp.id == templateGroupId) {
						_tgrp = tgrp;
						break;
					}
				}
			}
			
			if (_tgrp == null) {
				currentState = "templateListLoadError";
				return;
			}
			
			currentState = "";
			
			// Populate the Tile container with PreviewImageButtons, one for each template
			var imgFirst:PreviewButtonImage = null;
			
			for (var i:int = 0; i < _tgrp.length; i += 3) { // TODO(darrinm): hardwired +3
				var dctTemplate:Object = _tgrp.children[i];
				var img:PreviewButtonImage = new PreviewButtonImage();
				img.width = 78;	// TODO(darrinm): create a designer friendly ItemRenderer?
				img.height = 78;
				img.addEventListener(MouseEvent.CLICK, OnPreviewClick);
				img.data = dctTemplate;				// Must specify this BEFORE setting source
				img.source = dctTemplate.previewUrl; // Must specify this AFTER setting data
				img.setStyle("backgroundColor", 0xffffff);
				if (imgFirst == null)
					imgFirst = img;
				_tlTemplateThumbs.addChild(img);
			}
			
			// If there is an active ImageDocument use it to prepopulate the greeting --
			// unless asked not to! (e.g. from welcome page)
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			if (imgd != null && (greetingParent.container as SendGreetingDialog).useOpenDocument) {
				var bmd:BitmapData = DrawUtil.GetResizedBitmapData(imgd.composite, kcxNormalResolution, kcyNormalResolution, false, 0, true);
				_bmActiveDocument = new Bitmap(bmd);
			}

			// Create a blank ImageDocument for the greeting
			_imgd = new ImageDocument();
			_imgd.Init(kcxNormalResolution, kcyNormalResolution, 0xffffffff);
			_imgd.isDirty = true;
			_imgv.imageDocument = _imgd;
			_imgv.zoom = _imgv.zoomMin;
			_imgd.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, OnImageDocumentPropertyChange);
			greetingParent.imageDocument = _imgd;
			
			InitFancyCollage();
			
			// Simulate a click on the first preview image to select it.
			imgFirst.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		}
		
		// If there is an active document and it hasn't already been used to act as
		// the first photo of the collage, make it so now.
		private function OnImageDocumentPropertyChange(evt:PropertyChangeEvent): void {
			if (evt.property != "childStatus")
				return;
			
			if (evt.newValue == DocumentStatus.Loaded) {
				if (_bmActiveDocument) {
					// Slot the active document image into the first auto-fill target.
					var atgt:Array = _phgd.GetAutoFillTargets();
					if (atgt.length != 0) {
						var dctProperties:Object = {
							x: 0, y: 0, scaleX: 1, scaleY: 1,
							parent: (atgt[0] as Target).name
						};
						
						// Create an EmbeddedBitmap DocumentObject
						var coop:CreateObjectOperation = new CreateObjectOperation("EmbeddedBitmap", dctProperties);
						coop.Do(_imgd);
						
						var ebm:EmbeddedBitmap = _imgd.getChildByName(dctProperties.name) as EmbeddedBitmap;
						ebm.content = _bmActiveDocument;
						_bmActiveDocument = null;
					}
				}
			}
			
			// Update the allTargetsPopulated property which the 'Next!' button is bound to.
			atgt = _phgd.GetAutoFillTargets();
			var cUnpopulatedTargets:int = 0;
			for each (var tgt:Target in atgt)
				if (!tgt.populated)
					cUnpopulatedTargets++;
			allTargetsPopulated = cUnpopulatedTargets == 0;
		}

		private function OnPreviewClick(evt:MouseEvent): void {
			var dctTemplate:Object = (evt.currentTarget as PreviewButtonImage).data;

			// Show the clicked preview in selected state, deselect all others.
			var iSelected:int = -1;
			for (var i:int = 0; i < _tlTemplateThumbs.numChildren; i++) {
				var img:PreviewButtonImage = _tlTemplateThumbs.getChildAt(i) as PreviewButtonImage;
				img.selected = evt.currentTarget == img;
				if (evt.currentTarget == img)
					iSelected = i * 3;
			}
			
			// Set the sources of the variation preview images
			try {
				var aimgVariations:Array = [ _imgVariation1, _imgVariation2, _imgVariation3 ];
				for each (img in aimgVariations) {
					dctTemplate = _tgrp.children[iSelected];
					img.data = dctTemplate;
					img.source = dctTemplate.previewUrl;
					iSelected++;
				}
				
				// Select the first variation (which will trigger the template load)
				_imgVariation1.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			} catch (err:Error) {
			}
		}

		private function OnVariationClick(evt:MouseEvent): void {
			// Show the clicked variation in selected state, deselect all others.
			var aimgVariations:Array = [ _imgVariation1, _imgVariation2, _imgVariation3 ];
			try {
				for each (var img:PreviewButtonImage in aimgVariations)
					img.selected = evt.currentTarget == img;
			} catch (err:Error) {
			}
			
			var dctTemplate:Object = (evt.currentTarget as PreviewButtonImage).data;
			LoadTemplate(dctTemplate);
		}
		
		private function LoadTemplate(dctTemplate:Object): void {
			var uicThis:UIComponent = this;
			var strTemplate:String = ("template" in dctTemplate) ? dctTemplate.template as String: null;
			_strTemplateSelected = strTemplate;
			
			if (StringUtil.beginsWith(strTemplate, PhotoGrid.DIRECT_FID)) {
				// Convert from a fid template into a pik file template.
				// First, load the pik file
				var fnComplete:Function = function (nError:Number, strError:String, xmlTemplate:XML=null, dctProperties:Object=null): void {
					if (strTemplate != _strTemplateSelected) return; // Already selected a different template.
					if (nError != PicnikService.errNone) {
						CollageDocTemplateMgr.HandleTemplateLoadError(uicThis, nError, strError, strTemplate);
					} else {
						// TODO(darrinm): move this code to CollageDocTemplateMgr to be shared w/ AdvancedCollageBase?
						dctTemplate.templateName = CollageDocTemplateMgr.GetTemplateName(dctTemplate);
						var dctMapTemplateToLocalAsset:Object = CollageDocTemplateMgr.GetAssetToAssetMap(_imgd, dctProperties);
						var fCompressed:Boolean = ('fCompressed' in dctProperties && dctProperties['fCompressed'] == 'true');
						
						// Use the fid for now so we don't fill up our undo history with huge templates
						// We'll switch to the serialized version when we commit.
						// dctTemplate.template = PhotoGrid.SERIALIZED_PIK + CollageDocTemplateMgr.EncodeDocTemplate(xmlTemplate, dctMapTemplateToLocalAsset, fCompressed);
						dctTemplate.template = strTemplate;
						var anAssetRefs:Array = [];
						for each (var nLocalAsset:Number in dctMapTemplateToLocalAsset) {
							anAssetRefs.push(nLocalAsset);
						}
						dctTemplate.strAssetRefs = (anAssetRefs.length > 0) ? anAssetRefs.join(',') : "";
						SetPhotoGridTemplate(dctTemplate);
					}
				}
				CollageDocTemplateMgr.GetDocumentTemplate(strTemplate.substr(PhotoGrid.DIRECT_FID.length), fnComplete, this, dctTemplate.dctProps);
			} else {
				SetPhotoGridTemplate(dctTemplate);
			}
		}
		
		private function SetPhotoGridTemplate(obItem:Object): void {
			var strTemplate:String = obItem.template;
			var strTemplateName:String = obItem.templateName;
			var strAssetRefs:String = obItem.strAssetRefs;
			
			if (strTemplate != _phgd.template) {
				SetPhotoGridProperties(strTemplate, strAssetRefs);
				
				_phgd.templateName = strTemplateName;
				Util.UrchinLogReport("/sendgreeting/view/" + _phgd.templateName);
			}
		}
		
		// A Fancy Collage is just an ImageDocument with a PhotoGrid DocumentObject. The PhotoGrid knows how
		// to take a fid for a template and apply it to create all the DocumentObjects in the template.
		// Afterwards it manages the Targets the user can add photos to. A PhotoGrid instance can (and should)
		// be reused to load different templates. It puts photos the user has added in the right places.
		private function InitFancyCollage(): void {
			// Create a PhotoGrid DocumentObject
			var dctProperties:Object = {
				x: _imgd.width / 2, y: _imgd.height / 2,
				gap: 0,
				backgroundColor: 0xffffff,
				backgroundAlpha: 0.2,
				template: null,
				fitWidth: _imgd.width, fitHeight: _imgd.height, fitMethod: FitMethod.SNAP_TO_MAX_WIDTH_HEIGHT,
				templateName: "default"
			};
			
			var coop:CreateObjectOperation = new CreateObjectOperation("PhotoGrid", dctProperties);
			coop.Do(_imgd);
			
			// Retain the newly created object (.name is filled in by CreateObjectOperation)
			_phgd = PhotoGrid(_imgd.getChildByName(dctProperties.name));
		}
		
		private function SetPhotoGridProperties(strTemplate:String, strAssetRefs:String): void {
			var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(_phgd.name,
					{ numRows: 1, numColumns: 1, appliedTemplate: strTemplate, assetRefs: strAssetRefs });
			spop.Do(_imgd);
		}
	}
}
