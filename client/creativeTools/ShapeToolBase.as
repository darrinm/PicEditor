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
	import controls.ShapeArea;
	import controls.UIDocumentObject;
	
	import imagine.documentObjects.IDocumentObject;
	
	import events.AccountEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.events.CloseEvent;
	
	public class ShapeToolBase extends ObjectToolBase {
		[Bindable] public var _doco:IDocumentObject = null;
		
		override protected function toolName(): String {
			return "clipart tool";
		}
		
		protected override function SetDocumentObject(doco:IDocumentObject): void {
			// Make sure we call super.SetDocOb first.
			// When we call _doco.set, it might trigger binding updates on _idoco which needs to be set first.
            super.SetDocumentObject(doco);
			_doco = doco;
		}
		
		override public function OnDeactivate(ctrlNext:ICreativeTool):void {
			super.OnDeactivate(ctrlNext);
			ShapeArea.HideShapeInfoWindow();
		}
	}
}
