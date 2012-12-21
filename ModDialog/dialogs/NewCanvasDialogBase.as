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
// UNDONE:
// - remember last choice, including custom dims [user attributes?]
// - people will ask for inches/centimeters, DPI
// - new doc from clipboard!
// - transparent
// - thumbnail preview?
// CONSIDER: create a "background DocumentObject" -- can be any DocumentObject type (PRectangle, Shape, Photo)
// but its selection is handled specially, it can't be moved, and resizing an edge changes the document size.
// Most (all?) other DocumentObject properties apply (color, alpha, etc).

package dialogs {
	import containers.CoreDialog;
	
	import controls.HSBColorPicker;
	import controls.ResizingComboBox;
	import controls.TextInputPlus;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.system.Capabilities;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	/**
 	 * The NewCanvasDialogBase class is used in conjunction with NewCanvasDialog.mxml
	 * to allow the user to choose the dimensions and colors for a new ImageDocument.
   	 */
	public class NewCanvasDialogBase extends CoreDialog {
		// MXML-specified variables
		[Bindable] public var _btnOK:Button;
		[Bindable] public var _cmboSizes:ResizingComboBox;
		[Bindable] public var _tiWidth:TextInputPlus;
		[Bindable] public var _tiHeight:TextInputPlus;
		[Bindable] public var _cpkrBackground:HSBColorPicker;
		[Bindable] public var _chkTransparent:CheckBox;
		public var _strYours:String;
		
		static private var s_cxDoc:Number = 1024, s_cyDoc:Number = 768;
		static private var s_coBackground:uint = 0xffffff;
		static private var s_iSizeDefault:int = 1;
		
		// This is here because constructor arguments can't be passed to MXML-generated classes
		override public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object = null): void {
			super.Constructor(fnComplete, uicParent, obParams);
		}

		override protected function OnInitialize(evt:Event): void {
			super.OnInitialize(evt);
			_btnOK.addEventListener(MouseEvent.CLICK, OnOKClick);
			_cmboSizes.addEventListener(Event.CHANGE, OnSizeComboChange);
			_chkTransparent.addEventListener(Event.CHANGE, OnTransparentChange);
			
			// Point out the user which desktop resolution is theirs
			var fUsersResolutionFound:Boolean = false;
			var acol:ArrayCollection = _cmboSizes.dataProvider as ArrayCollection;
			for (var i:Number = 0; i < acol.length; i++) {
				var ob:Object = acol.getItemAt(i);
				var	strConstraint:String = ob.data;
				var astrT:Array = strConstraint.split(",");
				var cx:Number = Number(astrT[0]);
				var cy:Number = Number(astrT[1]);
				if (cx == Capabilities.screenResolutionX && cy == Capabilities.screenResolutionY) {
					ob.label += _strYours;
					fUsersResolutionFound = true;
					break;
				}
			}
			
			// Maybe they have an unusual resolution that's not on the list. Add it to the beginning.
			if (!fUsersResolutionFound) {
				ob = {
					label: Capabilities.screenResolutionX.toString() + "x" + Capabilities.screenResolutionY + " " + _strYours,
					data: Capabilities.screenResolutionX.toString() + "," + Capabilities.screenResolutionY + ",1"
				}
				acol.addItemAt(ob, 4);
			}
	
			_cmboSizes.selectedIndex = s_iSizeDefault;
			SetSize(s_cxDoc, s_cyDoc);
			_cpkrBackground.selectedColor = s_coBackground;
		}

		override protected function OnCreationComplete(evt:FlexEvent): void {
			super.OnCreationComplete(evt);
			// OnInitialize is too early for this
			_btnCancel.setFocus();
		}
		
		private function OnOKClick(evt:Event): void {
			Hide();
			if (_fnComplete != null) {
				s_cxDoc = Number(_tiWidth.text);
				s_cyDoc = Number(_tiHeight.text);
				var ptLimited:Point = Util.GetLimitedImageSize(s_cxDoc, s_cyDoc);
				if (ptLimited.x != s_cxDoc || ptLimited.y != s_cyDoc) {
					Util.ShowAlertWithoutLogging(Resource.getString("NewCanvasDialog", "canvas_too_big"),
							Resource.getString("NewCanvasDialog", "error"), Alert.OK);
					return;
				}
				s_coBackground = _chkTransparent.selected ? _cpkrBackground.selectedColor & 0x00ffffff : _cpkrBackground.selectedColor | 0xff000000;
				s_iSizeDefault = _cmboSizes.selectedIndex;
				_fnComplete({ success: true, cx: s_cxDoc, cy: s_cyDoc, co: s_coBackground });
			}
		}
		
		private function GetSelectedConstraints(): Point {
			var	strConstraint:String = _cmboSizes.selectedItem.data;
			var astrT:Array = strConstraint.split(",");
			var cx:Number = Number(astrT[0]);
			var cy:Number = Number(astrT[1]);
			return new Point(cx, cy);
		}
	
		private function OnSizeComboChange(evt:Event): void {
			var ptSize:Point = GetSelectedConstraints();
			SetSize(ptSize.x, ptSize.y);
		}
		
		private function SetSize(cx:Number, cy:Number): void {
			_tiWidth.text = String(cx);
			_tiHeight.text = String(cy);
		}
		
		private function OnTransparentChange(evt:Event): void {
			_cpkrBackground.enabled = !_chkTransparent.selected;
		}
	}
}
