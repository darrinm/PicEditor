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
package dialogs.Upsell
{
	import com.adobe.utils.StringUtil;
	
	import containers.ResizingDialog;
	
	import dialogs.DialogManager;
	import dialogs.RegisterHelper.UpgradePathTracker;
	
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	
	import mx.containers.ViewStack;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	import util.AdManager;
	
	public class FreeForAllSignInDialogBase extends TargetedUpsellDialogBase
	{
		public function FreeForAllSignInDialogBase() {
			super();
		}

		override protected function OnShow(): void {
			UpgradePathTracker.LogPageView('Upsell');
			super.OnShow();
		}
	}
}
