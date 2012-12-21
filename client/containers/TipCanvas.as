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
package containers {
	import controls.TipBackground;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.events.FlexEvent;
	
	import util.GooglePlusUtil;
	
	[Event(name="close", type="flash.events.Event")]
	
	public class TipCanvas extends Canvas {
		
		[Bindable] public var _aChildren:Array = [];
		
		
		[Embed(source='../theme/pngs/tipdialog/tipCloseUp.png')]
      	private var iconTipCloseUp:Class;
      	
      	[Bindable] public var _tipBg:TipBackground = new TipBackground();
      	[Bindable] public var _btnClose:Button = new Button();
      	
		private static function get isGooglePlus(): Boolean {
			return GooglePlusUtil.UsingGooglePlusAPIKey(PicnikBase.app.parameters);
		}

		public function TipCanvas(): void {
			addEventListener(FlexEvent.INITIALIZE, OnInit);
			
			_tipBg.percentHeight = 100;
			_tipBg.percentWidth = 100;
			_tipBg.id = "_tipBg";
			_aChildren.push(_tipBg);
			
			_btnClose.width = 16;
			_btnClose.height = 16;
			_btnClose.id = "_btnClose";
			
			_btnClose.setStyle("icon", iconTipCloseUp);
			_btnClose.setStyle("overIcon", iconTipCloseUp);
			// icon="@Embed('../theme/pngs/tipdialog/tipCloseUp.png')" overIcon="@Embed('../theme/pngs/tipdialog/tipCloseOver.png')" downIcon="@Embed('../theme/pngs/tipdialog/tipCloseUp.png')"
			_btnClose.setStyle("right", isGooglePlus ? 1 : 1);
			_btnClose.setStyle("top", isGooglePlus ? 3 : 3);
			_btnClose.toolTip = "";
			_btnClose.styleName = "clearButton";
			_btnClose.addEventListener(MouseEvent.CLICK, OnCloseClick);
			_aChildren.push(_btnClose);
		}
		
		private function OnCloseClick(evt:Event=null): void {
			dispatchEvent(new Event('close'));
		}
		
		public function OnInit(evt:Event=null): void {
			var i:Number = 0;
			for each (var dob:DisplayObject in _aChildren) {
				// add the first 1 children below the other children.
				if (i < 1) addChildAt(dob, i);
				else addChild(dob);
				i++;
			}
		}
	}
}
