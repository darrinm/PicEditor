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
package bridges.projects {
	import bridges.Bridge;
	
	import dialogs.DialogManager;
	
	import flash.events.*;
	
	import imagine.ImageDocument;
	
	import mx.containers.Canvas;
	import mx.events.FlexEvent;
	import mx.resources.ResourceBundle;
		
	public class ProjectsInBridgeBase extends Bridge {
		// MXML-specified variables
		[Bindable] public var _cnvBlankCanvas:Canvas;
		[Bindable] public var _cnvCreateCollage:Canvas;
		[Bindable] public var _cnvCreateGallery:Canvas;
		[ResourceBundle("ProjectsInBridge")] private var _rb:ResourceBundle;
	
		override protected function OnInitialize(evt:FlexEvent): void {
			super.OnInitialize(evt);
			_cnvBlankCanvas.addEventListener(MouseEvent.CLICK, OnBlankCanvasClick);
			_cnvCreateCollage.addEventListener(MouseEvent.CLICK, OnGridCollageClick);
			_cnvCreateGallery.addEventListener(MouseEvent.CLICK, OnGalleryClick);
		}
		
		public override function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
		}
		
		public override function OnDeactivate(): void {
			super.OnDeactivate();
		}
		
		private function OnBlankCanvasClick(evt:MouseEvent): void {
			// Prompt to save unsaved doc
			if (doc != null && doc.isDirty) {
				DialogManager.Show('ConfirmLoadOverEditDialog', PicnikBase.app, function (res:Object): void {
					if (res.success) {
						DialogManager.Show('NewCanvasDialog', PicnikBase.app, OnNewCanvasComplete);
					}
				});
			} else {
				DialogManager.Show('NewCanvasDialog', PicnikBase.app, OnNewCanvasComplete);
			}
		}

		public function OnNewCanvasComplete(obResult:Object):void {
			if (obResult.success) {
				var imgd:ImageDocument = new ImageDocument();
				imgd.Init(obResult.cx, obResult.cy, obResult.co);
				imgd.isDirty = true;
				imgd.properties.title = Resource.getString("ProjectsInBridge", "new_document_title");
				imgd.properties./*bridge*/serviceid = "MyComputer";
				PicnikBase.app.activeDocument = imgd;
				
				PicnikBase.app.uimode = PicnikBase.kuimPhotoEdit;
				PicnikBase.app.activeTabId = PicnikBase.EDIT_CREATE_TAB;
			}
		}
		
		static public function OnGridCollageClick(evt:MouseEvent=null): void {
			// removed premium previewness, clicking always navs to Collage now
			SafeNavigateToCollage(PicnikBase.kuimCollage, PicnikBase.COLLAGE_TAB);
		}

		static private function SafeNavigateToCollage(strUIMode:String, strTab:String): void {
			var doc:GenericDocument = PicnikBase.app.activeDocument;
			if (doc != null && doc.isDirty) {
				DialogManager.Show('ConfirmLoadOverEditDialog', PicnikBase.app, function (res:Object): void {
					if (res.success)
						NavigateToCollage(strUIMode, strTab);
				});
			} else {
				NavigateToCollage(strUIMode, strTab);
			}
		}
		
		static private function NavigateToCollage(strUIMode:String, strTab:String): void {
			PicnikBase.app.activeDocument = null;
			PicnikBase.app.uimode = strUIMode;
			PicnikBase.app.activeTabId = strTab;
		}

		static public function OnAdvancedCollageClick(evt:Event=null): void {
			SafeNavigateToCollage(PicnikBase.kuimAdvancedCollage, PicnikBase.ADVANCED_COLLAGE_TAB);
		}

		static public function OnGalleryClick(evt:Event=null): void {
			if (PicnikConfig.galleryAccess) {
				PicnikBase.app.NavigateTo(PicnikBase.IN_BRIDGES_TAB,'_brgGalleryIn');
			} else if (PicnikConfig.galleryUpgradeForAccess) {
				DialogManager.ShowUpgrade('/in_projects/previewshow');					
			}
		}
	}
}
