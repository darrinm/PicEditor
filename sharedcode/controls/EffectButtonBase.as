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
package controls
{
	import flash.events.Event;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.core.UIComponent;
	import mx.effects.Effect;
	import mx.events.FlexEvent;
	import mx.utils.ObjectUtil;
	
	[Style(name="upGradientFillColors", type="Array", arrayType="Number", inherit="no")]
	[Style(name="upGradientFillAlphas", type="Array", arrayType="Number", inherit="no")]
	[Style(name="upGradientFillRatios", type="Array", arrayType="Number", inherit="no")]
	
	[Style(name="overGradientFillColors", type="Array", arrayType="Number", inherit="no")]
	[Style(name="overGradientFillAlphas", type="Array", arrayType="Number", inherit="no")]
	[Style(name="overGradientFillRatios", type="Array", arrayType="Number", inherit="no")]
	
	[Style(name="downGradientFillColors", type="Array", arrayType="Number", inherit="no")]
	[Style(name="downGradientFillAlphas", type="Array", arrayType="Number", inherit="no")]
	[Style(name="downGradientFillRatios", type="Array", arrayType="Number", inherit="no")]
	
	public class EffectButtonBase extends Canvas
	{
		private var _bkgmd:BackgroundGradientModes;

		// public settings
		[Bindable]
		[Inspectable(defaultValue="by Picnik")]
		public var strAuthor:String = "by Picnik";
		
		[Bindable]
		[Inspectable(defaultValue="")]
		public var strImageSource:Object = "";
		
		[Bindable]
		[Inspectable(defaultValue=false)]
		public var newEffect:Boolean = false;
		
		[Bindable]
		[Inspectable(defaultValue=5)]
		public var cornerRadius:Number = 5;
		
		[Bindable]
		[Inspectable(defaultValue=false)]
		public var booleanBeta:Boolean = false;
		
		[Bindable]
		[Inspectable(defaultValue=false)]
		public var booleanAdmin:Boolean = false;

		[Bindable]
		[Inspectable(defaultValue=false)]
		public var isFancyCollage:Boolean = false;
		
		[Bindable]
		[Inspectable(defaultValue=false)]
		public var premium:Boolean = false;

		[Bindable]
		[Inspectable(defaultValue="Title")]
		public var strTitle:String = "Title";

		[Bindable] public var _btnInfo:Button;
		[Bindable] public var _efSelect:Effect;
		[Bindable] public var _efDeselect:Effect;
		[Bindable] public var _efRollOut:Effect;
		[Bindable] public var inspirationTarget:UIComponent;

		public function EffectButtonBase()
		{
			super();
			addEventListener(FlexEvent.INITIALIZE, Init);
		}
		
		private function Init(evt:Event): void {
			_bkgmd = new BackgroundGradientModes(this, ['up', 'over', 'down']);
			_bkgmd.mode = GetModeForState(currentState);
		}
		
		private function GetModeForState(strState:String): String {
			if (currentState == "RollOver") {
				return 'over';
			} else if (currentState == "Selected") {
				return 'down';
			}
			// default
			return 'up';
		}
		
		public override function set currentState(value:String):void {
			super.currentState = value;
			if (_bkgmd != null)
				_bkgmd.mode = GetModeForState(currentState);
		}
}
}