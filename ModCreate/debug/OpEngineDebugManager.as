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
package debug
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import imagine.imageOperations.ImageOperation;
	
	import imagine.ImageDocument;
	
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	public class OpEngineDebugManager
	{
		public function OpEngineDebugManager()
		{
		}
		
		private var _opengdbg:OpEngineDebugger = null;
		
		public function RequestToUpdate(imgd:ImageDocument, op:ImageOperation): void {
			if (_opengdbg == null)
				ShowDebugger(imgd, op);
			else
				_opengdbg.RequestToUpdate(imgd, op);
		}
		
		public function ShowDebugger(imgd:ImageDocument, op:ImageOperation): void {
			_opengdbg = new OpEngineDebugger();
			_opengdbg.Init(op, imgd);
			
			_opengdbg.percentWidth = 100;
			_opengdbg.percentHeight = 100;
			
			var pnl:ResizablePanel = new ResizablePanel();
			pnl.title = 'op debugger';
			pnl.width = PicnikBase.app.width * 0.8;
			pnl.height = PicnikBase.app.height * 0.8;
			pnl.addChild(_opengdbg);
			pnl.setStyle("backgroundAlpha", 1);
			
			pnl.addEventListener(CloseEvent.CLOSE, function(evt:Event): void {
				PopUpManager.removePopUp(pnl);
				_opengdbg = null;
			});
			
			PopUpManager.addPopUp(pnl, PicnikBase.app as DisplayObject, false);
		}
	}
}