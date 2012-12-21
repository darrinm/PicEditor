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
	import flash.events.MouseEvent;
	
	import imagine.ImageDocument;
	import imagine.imageOperations.RasterizeImageOperation;
	
	import mx.controls.LinkButton;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	import util.LocUtil;

	public class EditCreateOptionsBase extends HelpMenuBase {
		public var actionListener:IActionListener = null;
		
		override protected function OnCreationComplete(evt:FlexEvent): void {
			super.OnCreationComplete(evt);
			
			// Disable context-inappropriate menu items
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			if (imgd == null)
				(_ctnr.getChildByName("close") as LinkButton).enabled = false;
			else if (imgd.documentObjects == null || imgd.documentObjects.numChildren == 0)
				(_ctnr.getChildByName("flatten") as LinkButton).enabled = false;
		}
		
		private function PerformActionIfSafe(act:IAction): void {
			if (actionListener != null)
				actionListener.PerformActionIfSafe(act);
			else
				act.Do();
		}
		
		private function flatten(): void {
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			if (imgd == null)
				return;
			imgd.BeginUndoTransaction("Flatten");
			var op:RasterizeImageOperation = new RasterizeImageOperation(null, imgd.width, imgd.height, true);
			if (!op.Do(imgd))
				imgd.AbortUndoTransaction();
			imgd.EndUndoTransaction();
			
			PicnikBase.app.Notify(Resource.getString("EditCreateOptions", "combined"));
		}
		
		private function close(): void {
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			if (imgd == null)
				return;

			PicnikBase.app.CloseActiveDocument();
		}
		
		override protected function OnItemClick(evt:MouseEvent): void {
			PopUpManager.removePopUp(this);
			
			var imgd:ImageDocument = PicnikBase.app.activeDocument as ImageDocument;
			if (imgd == null)
				return;

			PicnikBase.app.LogNav("Options/" + evt.target.name);
			
			switch (evt.target.name) {
			case "flatten":
				PerformActionIfSafe(new Action(flatten));
				break;
				
			case "close":
				PerformActionIfSafe(new Action(close));
				break;
				
			case "resizecanvas":
				break;

			case "help":
				if (PicnikBase.app._pas.googlePlusUI)
					PicnikBase.app.NavigateToURLInPopup("http://www.google.com/support/+/?hl=" + LocUtil.PicnikLocToGoogleLoc() + "&p=photo_editing", 800, 600);
				else
					PicnikBase.app.NavigateToURLInPopup("http://www.google.com/support/picnik/?hl=en", 800, 600);
				break;

			case "fullscreen":
				PicnikBase.app._wndc.ToggleFullscreen();
				break;
			}
		}
	}
}
