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
package effects
{
	import containers.EffectCanvas;
	import containers.NestedControlCanvasBase;
	import containers.NestedControlEvent;
	
	import imagine.documentObjects.FrameObject;
	
	import flash.geom.Rectangle;
	
	import imagine.imageOperations.RasterizeImageOperation;
	
	import imagine.objectOperations.SetPropertiesObjectOperation;
	
	import util.frameEngine.FrameEngine;
	
	public class FrameEffectBase extends EffectCanvas
	{
		[Bindable] public var _strFrameLayout:String = null;
		[Bindable] public var _strFrameName:String = null;
		[Bindable] public var frameColor:Number = 0;
		
		private var _strFrameNameCreated:String = null;
		
		public function FrameEffectBase()
		{
			super();
			_strFrameName = Util.GetUniqueId();
			_strFrameNameCreated = null;
			
			this.addEventListener(NestedControlEvent.SELECTED_EFFECT_UPDATED_BITMAPDATA, OnEffectUpdated);
		}
		
		protected function get frameXML(): XML {
			if (!('_xmlFrame' in this))
				throw new Error("Sub-classes of FrameEffectBase must define _xmlFrame or override function get frameXML()");
			return this['_xmlFrame'];
		}
		
		override public function Deselect(fForceRollOutEffect:Boolean=true, efcvsNew:NestedControlCanvasBase=null):void {
			super.Deselect(fForceRollOutEffect, efcvsNew);
			_strFrameName = Util.GetUniqueId(); // Create a new unique ID for next time.
			_strFrameNameCreated = null;
		}
		
		override protected function UpdateBitmapData():void {
			UpdateFrameLayout(frameXML, imagewidth, imageheight);
			super.UpdateBitmapData();
		}
		
		
		protected function OnFrameParamChange(): void {
			UpdateFrameLayout(frameXML, imagewidth, imageheight);
			OnFramePropsChanged();
		}
		
		private function OnEffectUpdated(evt:Event):void {
			_strFrameNameCreated = _strFrameName;
		}
		
		protected function GetExtraParams(): Object {
			return {};
		}
		
		private function MergeObjects(ob1:Object, ob2:Object): Object {
			var obOut:Object = {};
			var strKey:String;
			for (strKey in ob1)
				obOut[strKey] = ob1[strKey];
			for (strKey in ob2)
				obOut[strKey] = ob2[strKey];
			return obOut;
		}
		
		protected function OnFramePropsChanged(): void {
			var fSelected:Boolean = (this._imgd != null);
			if (fSelected && _strFrameName == _strFrameNameCreated && _strFrameNameCreated != null) {
				var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(_strFrameName,
					MergeObjects({ layout: _strFrameLayout, color:frameColor }, GetExtraParams()));
				spop.Do(_imgd);
			}
		}
		
		protected function UpdateFrameLayout(xmlFrame:XML, nWidth:Number, nHeight:Number, nRandSeed:Number=1): void {
			var frmeng:FrameEngine = new FrameEngine(new Rectangle(-nWidth/2, -nHeight/2, nWidth, nHeight), xmlFrame, nRandSeed);
			_strFrameLayout = FrameObject.LayoutObToStr(frmeng.layout);
		}
		
		public override function Apply(): void {
			var spop:SetPropertiesObjectOperation = new SetPropertiesObjectOperation(_strFrameName,
				{ interactiveMode:false });
			spop.Do(_imgd);
			// Force double composite validation
			// Frames invalide the composite during validation - which can result in an
			// invalid composite.
			// UNDONE: Fix this properly in ImageDocument.ValidateComposite()
			_imgd.composite; // Force composite validation.
			_imgd.InvalidateComposite();
			_imgd.composite; // Force composite validation.
			
			super.Apply();
		}
	}
}