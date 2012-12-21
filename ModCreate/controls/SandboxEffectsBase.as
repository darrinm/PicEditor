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
	import effects.ShaderEffect;
	
	import flash.display.Shader;
	import flash.display.ShaderInput;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import mx.containers.Canvas;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.events.FlexEvent;
	
	import util.Navigation;
	import util.TipManager;

	public class SandboxEffectsBase extends Canvas
	{
		[Embed("/assets/shaders/Bundled/HexCells.pbj", mimeType="application/octet-stream")]
		private var _clsByteCode1:Class;
		[Embed("/assets/shaders/Bundled/CircleSplash.pbj", mimeType="application/octet-stream")]
		private var _clsByteCode2:Class;
		[Embed("/assets/shaders/Bundled/Crystallize.pbj", mimeType="application/octet-stream")]
		private var _clsByteCode3:Class;
		[Embed("/assets/shaders/Bundled/AdjustableThreshold.pbj", mimeType="application/octet-stream")]
		private var _clsByteCode4:Class;
		[Embed("/assets/shaders/Bundled/HSLFilter.pbj", mimeType="application/octet-stream")]
		private var _clsByteCode5:Class;
		[Embed("/assets/shaders/Bundled/RippleBlocks.pbj", mimeType="application/octet-stream")]
		private var _clsByteCode7:Class;
		[Embed("/assets/shaders/Bundled/smudger.pbj", mimeType="application/octet-stream")]
		private var _clsByteCode8:Class;
		[Embed("/assets/shaders/Bundled/Hypnotic.pbj", mimeType="application/octet-stream")]
		private var _clsByteCode9:Class;
		[Embed("/assets/shaders/Bundled/waterfall.pbj", mimeType="application/octet-stream")]
		private var _clsByteCode11:Class;

		[Bindable] public var _btnUpload:Button;
		[Bindable] public var _btnInfo:Button;
		[Bindable] public var _cbShaders:ComboBox;
		[Bindable] public var _vbUser:VBox;
		[Bindable] public var _vb:VBox;

		private var _tip:Tip;
		private var _fr:FileReference;
		private static const kafilf:Array = [ new FileFilter("Pixel Bender file", "*.pbj") ];
		static private var s_aclsByteCodes:Array;
		
		public function SandboxEffectsBase()
		{
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}

		[Bindable]
		public function set embeddedShaders(aob:Array): void {
			// this space intentionally left blank
		}
		
		public function get embeddedShaders(): Array {
			if (s_aclsByteCodes == null) {
				var acls:Array = [
					_clsByteCode1, _clsByteCode2, _clsByteCode3, _clsByteCode4, _clsByteCode5,
					_clsByteCode7, _clsByteCode8, _clsByteCode9, _clsByteCode11
				];
				s_aclsByteCodes = acls;
			}
			return s_aclsByteCodes;
		}
		
		private function OnCreationComplete(evt:FlexEvent): void {
			if (!Util.DoesUserHaveGoodFlashPlayer10()) {
				currentState = "RequiresFlash10";
			} else {
				// UNDONE: this sucks. We should establish and enforce a rule that OnActivate calls
				// ALWAYS come after CREATION_COMPLETE. NOTE: testing 'initialized' isn't good enough.
				CompleteInitialization();
			}
		}
		
		private function CompleteInitialization(): void {
			if (currentState == "RequiresFlash10")
				return;

			var aobShaderDesc:Array = embeddedShaders;
			for each (var clsByteCode:Class in aobShaderDesc) {
				var baByteCode:ByteArray = new clsByteCode();
				AddShaderEffect(baByteCode);
			}
			_btnUpload.addEventListener(MouseEvent.CLICK, OnUploadClick);
			_btnInfo.addEventListener(MouseEvent.CLICK, OnInfoClick);
		}
		
		public function OnDeactivate():void {
			HideTips();
		}
		
		private function OnInfoClick(evt:MouseEvent): void {
			if (_btnInfo.selected)
				ShowTips(true);
			else
				HideTips(true);				
		}
		
		private function AddShaderEffect(baByteCode:ByteArray, fTop:Boolean=false, fOpen:Boolean=false): void {
			var eff:ShaderEffect = new ShaderEffect();
			eff.initialize();
			eff.bytecode = baByteCode;
			if (fTop)
				_vbUser.addChildAt(eff, 0);
			else
				_vb.addChild(eff);
				
			if (fOpen)
				eff.OpenEffect();
		}
		
		private function OnUploadClick(evt:MouseEvent): void {
			_fr = new FileReference();
			_fr.addEventListener(Event.SELECT, OnBrowseSelect);
			_fr.addEventListener(Event.CANCEL, OnBrowseCancel);
			_fr.browse(kafilf);
		}
		
		private function OnBrowseCancel(evt:Event): void {
			_fr = null;			
		}
		
		private function OnBrowseSelect(evt:Event): void {
			_fr.addEventListener(Event.COMPLETE, OnLoadComplete);
			_fr.addEventListener(IOErrorEvent.IO_ERROR, OnIOError);
			_fr.load();
		}
		
		// Called when the file has completed loading
		private function OnLoadComplete(evt:Event): void {
			// Check the file for incompatibility
			// - more than one input
			// - input that is not an image type we can provide (image1, image2)
			// - Shader incompatible with Flash
			// - output type we don't know how to consume? (pixel1, pixel2)
			var shdr:Shader = new Shader(_fr.data);
			
			// If it has more than one input or its one input is not an image we don't
			// know how to deal with it. Let the user know and bail.
			var cshdi:int = 0;
			for (var strProp:String in shdr.data) {
				var obT:Object = shdr.data[strProp];
				if (obT is ShaderInput) {
					if (ShaderInput(obT).channels < 3)
						cshdi++;
					cshdi++;
					if (cshdi > 1)
						break;
				}
			}
			
			if (cshdi > 1) {
				Util.ShowAlertWithoutLogging(Resource.getString("UserEffects", "incompatible_shader_message"),
						Resource.getString("UserEffects", "incompatible_shader_title"));
				_fr = null;
				return;
			}
			
			/* UNDONE: replace ShaderEffect if already present
			var shdr:Shader = new Shader(_fr.data);
			var strName:String = shdr.data.name;
			var arrc:ArrayCollection = _cbShaders.dataProvider as ArrayCollection;
			for (var i:int = 0; i < arrc.length; i++) {
				var ob:Object = arrc[i];
				if (ob.label == strName) {
					arrc[i] = { label: strName, data: _fr.data };
					break;
				}
			}
			
			if (i == arrc.length)
				arrc.addItem({ label: strName, data: _fr.data });
			_cbShaders.selectedIndex = i;
			*/
			
			AddShaderEffect(_fr.data, true, true);
			_fr = null;
		}

		// Called if an error occurs while loading the file contents
		private function OnIOError(evt:IOErrorEvent): void {
			trace("Error loading file : " + evt.text);
			_fr = null;
		}
		
		//
		// Tip stuff
		//
		
		private function ShowTips(fForce:Boolean=false): void {
			_tip = TipManager.ShowTip("sandbox_main", fForce);
			if (_tip != null) {
				_btnInfo.selected = true;
				_tip.addEventListener(Event.REMOVED, OnTipHide);
			}
		}
		
		private function HideTips(fClose:Boolean=false): void {
			TipManager.HideTip("sandbox_main", false, fClose); // don't fade out the tip
		}
		
		private function OnTipHide(evt:Event): void {
			if (_tip) {
				_tip.removeEventListener(Event.REMOVED, OnTipHide);
				_tip = null;
			}
			_btnInfo.selected = false;
		}
		
		public function ExpressInstall(): void {
			Navigation.NavigateToFlashUpgrade("sandbox");
		}
	}
}