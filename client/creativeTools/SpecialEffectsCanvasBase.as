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
package creativeTools {
	import containers.NestedControlEvent;
	
	import controls.ShapeArea;
	
	import dialogs.DialogManager;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	
	import imagine.ImageDocument;
	
	import mx.core.Container;
	
	import util.SaveToHistory;

	[Style(name="tabIcon", type="Class", inherit="no")]

	public class SpecialEffectsCanvasBase extends NestedControlsCanvas {
		// UNDONE: functionality not related to my sibling class GalleryStylesCanvasBase should be demoted to here
		
		public var googlePlus:Boolean = false;
		public var googlePlusExclusive:Boolean = false;
		
		public function SpecialEffectsCanvasBase(): void {
			addEventListener("selectingShapeGroup", OnSelectingShapeGroup);
		}
		
		override public function styleChanged(strStyleProp:String):void
		{
			this.icon = getStyle("tabIcon");
		}
		
		private function OnSelectingShapeGroup(evt:Event): void {
			DeselectEffect(true);
		}

		override protected function OnEffectSelected(evt:NestedControlEvent): void {
			super.OnEffectSelected(evt);
			DeselectActiveShapes(_vb);
		}
		
		override public function OnDeactivate(ctrlNext:ICreativeTool):void {
			super.OnDeactivate(ctrlNext);
			ShapeArea.HideShapeInfoWindow();
		}
		
		private function DeselectActiveShapes(doc:DisplayObjectContainer): void {
			if (doc != null) {
				for (var i:Number = 0; i < doc.numChildren; i++) {
					var dobChild:DisplayObject = doc.getChildAt(i);
					if (dobChild is ShapeArea) {
						(dobChild as ShapeArea).CloseAllGroups();
					} else if (dobChild is Container) {
						DeselectActiveShapes(dobChild as DisplayObjectContainer);
					}
				}
			}
		}
		
		static private function SafeNavigateToProject(strUIMode:String, strTab:String, strLogSource:String = ""): void {
			var doc:GenericDocument = PicnikBase.app.activeDocument;
			if (doc != null) {
				DialogManager.Show("ConfirmLoadOverEditDialog",
						PicnikBase.app,
						function (res:Object): void {
								if ("choice" in res) {
									if (res.choice == "save") {
										SaveToHistory.Save( PicnikBase.app,
															PicnikBase.app.activeDocument as ImageDocument,
															function( err:Number, obResult:Object ): void {
																	NavigateToProject(strUIMode, strTab, "_brgHistoryIn", strLogSource);
															} );
									} else if (res.choice == "discard") {
										NavigateToProject(strUIMode, strTab, null, strLogSource);
									}
								}
						},
						{'fClosing': true, strAltTitle:Resource.getString("ConfirmLoadOverEditDialog", "_txtSaveToHistory")}
					);
			} else {
				NavigateToProject(strUIMode, strTab, null, strLogSource);
			}
		}
		
		static private function NavigateToProject(strUIMode:String, strTab:String, strService:String = null, strLogSource:String = ""): void {
			PicnikBase.app.activeDocument = null;
			PicnikBase.app.uimode = strUIMode;
			PicnikBase.app.activeTabId = strTab;
			if (null != strService) {
				PicnikBase.app.basket.SelectBridge(strService);
			}
			Util.UrchinLogReport("/project_nav/" + strTab + "/" + strLogSource);

		}

		static public function OnAdvancedCollageClick(evt:Event=null, strLogSource:String = ""): void {
			SafeNavigateToProject(PicnikBase.kuimAdvancedCollage, PicnikBase.ADVANCED_COLLAGE_TAB, strLogSource);
		}

		static public function OnSeasonalClick(evt:Event=null): void {
			PicnikBase.app.NavigateTo(PicnikBase.EDIT_CREATE_TAB, "_ctSeasonal");
			//SafeNavigateToProject(PicnikBase.kuimAdvancedCollage, PicnikBase.ADVANCED_COLLAGE_TAB, strLogSource);
		}
		
		static public function OnShowClick(evt:Event=null, strLogSource:String = ""): void {
			SafeNavigateToProject(PicnikBase.kuimGallery, PicnikBase.GALLERY_STYLE_TAB, strLogSource);
		}
	}
}
