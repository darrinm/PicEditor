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
package dialogs
{
	import bridges.storageservice.IStorageService;
	import bridges.storageservice.StorageServiceError;
	
	import com.adobe.utils.StringUtil;
	
	import containers.ResizingDialog;
	import containers.ShareBridges;
	
	import dialogs.DialogManager;
	import dialogs.EasyDialogBase;
	import dialogs.RegisterHelper.UpgradePathTracker;
	
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.ViewStack;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	import mx.resources.ResourceBundle;
	
	import util.AdManager;
	
	public class ShareContentDialogBase extends CloudyResizingDialog
	{
		[Bindable] public var _brgc:ShareBridges;
		[Bindable] public var item:ItemInfo;
		private var _ldrClouds:Loader = null;
		private var _sprBackground:Sprite;

		// Params to carry forward to old upsell path
		private var _obDefaults:Object;
		
		[Bindable] public var defaultTabName:String = "";
		[Bindable] public var firstRunMode:Boolean = false;

  		[Bindable] [ResourceBundle("ShareContentDialogBase")] protected var _rb:ResourceBundle;

		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		// Subclasses will enjoy this function, I'm sure.
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			super.Constructor(fnComplete, uicParent, obParams);
			
			var fnOnItemNotFound:Function = function():void {
				EasyDialogBase.Show(
					PicnikBase.app,
					[Resource.getString('ShareContentDialogBase', 'ok')],
					Resource.getString('ShareContentDialogBase', 'itemUnavailable'),
					Resource.getString('ShareContentDialogBase', 'itemUnavailableText'),						
					function( obResult:Object ):void {
						fnComplete();
					}
				);							
			}	
				
			var fnOnGetItemInfo:Function = function( err:Number, strErr:String, itemInfo:ItemInfo ):void {
				if (err == StorageServiceError.None) {
					item = itemInfo;
				} else {
					fnOnItemNotFound();
				}
			}				
			
			if ('item' in obParams) {
				item = obParams['item'];
			} else {
				var strService:String = obParams['service'];
				var ss:IStorageService = AccountMgr.GetStorageService(strService);
				if (ss) {
					var strId:String = ("id" in obParams) ? obParams["id"] : null;
					var strSetId:String = ("setid" in obParams) ? obParams["setid"] : null;
					if (strId) {
						ss.GetItemInfo( strSetId, strId, fnOnGetItemInfo );					
					} else if (strSetId) {
						ss.GetSetInfo( strSetId, fnOnGetItemInfo );					
					} else {
						fnOnItemNotFound();
					}
				} else {
					fnOnItemNotFound();
				}
			}
		}

		override protected function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ESCAPE) {
				Hide();
			} else if (evt.keyCode == Keyboard.ENTER) {
				
			}
		}

		override protected function OnShow(): void {
			super.OnShow();
			_brgc.OnActivate();
		}

		override protected function OnHide(): void {
			super.OnHide();
			_brgc.OnDeactivate();
		}
	}
}
