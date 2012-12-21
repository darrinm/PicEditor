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
package {
	import commands.CommandEvent;
	import commands.CommandMgr;
	
	import containers.PaletteWindow;
	
	import creativeTools.ICreativeTool;
	
	import dialogs.DialogManager;
	import dialogs.Purchase.PurchaseManager;
	
	import events.*;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.Canvas;
	import mx.containers.ViewStack;
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.events.IndexChangedEvent;
	
	import pages.Page;
	
	import util.CreditCard;
	import util.CreditCardTransaction;
	import util.FontManager;
	import util.ITabContainer;
	
	public class MyAccountBase extends Page {
		// MXML-defined variables
		[Bindable] public var _myAccount:MyAccountContent;
					
		//
		// Initialization (not including state restoration)
		//
		public function MyAccountBase() {
			super();
		}		
		
		//
		// IActivatable implementation
		//
		override public function OnActivate(strCmd:String=null): void {
			super.OnActivate(strCmd);
			_myAccount.OnActivate(strCmd);
		}
		
		override public function OnDeactivate(): void {
			super.OnDeactivate();
			_myAccount.OnDeactivate();
		}
	}
}


