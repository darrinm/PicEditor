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
	import com.adobe.utils.StringUtil;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.controls.ColorPicker;
	import mx.controls.TextInput;
	import mx.core.FlexSprite;
	import mx.core.IChildList;
	import mx.core.UIComponent;
	import mx.events.ColorPickerEvent;
	import mx.events.DropdownEvent;
	import mx.events.FlexEvent;
	import mx.managers.SystemManager;
	import mx.skins.halo.SwatchSkin;
	
	import overlays.helpers.Cursor;
	import overlays.helpers.RGBColor;
	
	import util.VBitmapData;

    [Event(name="liveColorChange", type="flash.events.Event")]

	public class HSBColorPickerBase extends ColorPicker
	{
		private var _clrLive:Number = 0;
		private var _bmdSnapshot:BitmapData;
		private var _dobSwatchHilight:DisplayObject;
		private var _sprModal:FlexSprite;
		
		public function set liveColor(clr:Number): void {
			if (_clrLive != clr) {
				_clrLive = clr;
				dispatchEvent(new Event("liveColorChange"));
			}
		}
		
		[Bindable(event="liveColorChange")]
		public function get liveColor(): Number {
			return _clrLive;
		}
		
		private static function map(nIn:Number, nInMin:Number, nInMax:Number, nOutMin:Number, nOutMax:Number): Number {
			return nOutMin + ((nIn - nInMin) / (nInMax - nInMin)) * (nOutMax - nOutMin);
		}
		
		public function HSBColorPickerBase() {
			dataProvider = colors;
			_clrLive = selectedColor;
			addEventListener(ColorPickerEvent.ITEM_ROLL_OVER, OnItemRollOver);
			addEventListener(DropdownEvent.OPEN, OnOpen);
			addEventListener(DropdownEvent.CLOSE, OnClose);
			addEventListener(FlexEvent.VALUE_COMMIT, OnValueCommit);
		}
		
		// HACK: SwatchHilight bug fix
		// The color picker has a bug - it ignores clicks on the top pixel of a swatch hilight
		// This code is internal - but we can get at it through the system manager when
		// the swatch is open. So, browse the system objects to find the one we want:
		//  - SystemManager.SwatchPanel.swatchHilight
		// Clear its mouseEnabled flag so it ignores clicks
		
		// Hack: SwatchHilight bug fix. See above
		private function getSwatchHilight(): DisplayObject {
			var rawChildren:mx.core.IChildList = PicnikBase.app.systemManager.rawChildren;
			for (var i:Number = 0; i < rawChildren.numChildren; i++) {
				var uic:UIComponent = rawChildren.getChildAt(i) as UIComponent;
				if (uic && StringUtil.beginsWith(uic.toString(), "SwatchPanel") && uic.owner == this) {
					return uic.getChildByName("swatchHighlight");
				}
			}
			return null; // Not found
		}
		
		private function OnOpen(evt:Event): void {
			// Hack: SwatchHilight bug fix. See above
			_dobSwatchHilight = getSwatchHilight();
			if (_dobSwatchHilight)
				UIComponent(_dobSwatchHilight).mouseEnabled = false;
			
			// Show the eye-dropper cursor
			Cursor.csrEyedropper.Apply();
			
			// Watch mouse moves so we can update the color to whatever the mouse is over
			// when it is outside the ColorPicker.
			_bmdSnapshot = new VBitmapData(stage.stageWidth, stage.stageHeight, true, 0xffffffff, "HSB Snapshot");
			try {
				_bmdSnapshot.draw(stage);
			} catch (err:Error) {
				// The draw above can fail if DisplayObjects on the stage don't allow crossdomain access.
				if (PicnikBase.app.zoomView != null) {
					var mat:Matrix = new Matrix();
					var pt:Point = PicnikBase.app.zoomView.localToGlobal(new Point());
					mat.translate(pt.x, pt.y);
					_bmdSnapshot.draw(PicnikBase.app.zoomView, mat);
				}
			}
			
			// Throw up an overlay covering the whole SWF, except for the swatch dropdown,
			// so we can swallow all mouse events.
			_sprModal = new FlexSprite();
			_sprModal.tabEnabled = false;
			_sprModal.alpha = 0;
			var gr:Graphics = _sprModal.graphics;
			var rcScreen:Rectangle = systemManager.screen;
			gr.clear()
			gr.beginFill(0xffffff, 100);
			gr.drawRect(rcScreen.x, rcScreen.y, rcScreen.width, rcScreen.height);
			gr.endFill();
			
	        _sprModal.addEventListener(MouseEvent.MOUSE_MOVE, OnModalMouseMove);
	        _sprModal.addEventListener(MouseEvent.MOUSE_DOWN, OnModalMouseDown);
	       
	        // Set the resize handler so the modal object can stay the size of the screen
	        systemManager.addEventListener(Event.RESIZE, OnSystemManagerResize);
	       
	        // Add the modal sprite immediately after the swatch popup
	        var dobcSwatchPanel:DisplayObjectContainer = _dobSwatchHilight.parent;
	        var dobcPopupRoot:DisplayObjectContainer = dobcSwatchPanel.parent;
	        dobcPopupRoot.addChildAt(_sprModal, dobcPopupRoot.getChildIndex(dobcSwatchPanel));
		}
		
		private function OnSystemManagerResize(evt:Event): void {
			if (_sprModal) {
		        var rcScreen:Rectangle = SystemManager(evt.target).screen; 
	            _sprModal.width = rcScreen.width;
	            _sprModal.height = rcScreen.height;
	            _sprModal.x = rcScreen.x;
	            _sprModal.y = rcScreen.y;
	  		}
		}
		
		override public function close(trigger:Event = null):void {
			Cleanup();			
			super.close(trigger);
		}			

		private function OnClose(evt:Event): void {
			Cursor.csrSystem.Apply();
			Cleanup();			
		}
		
		private function Cleanup(): void {
			DisposeSnapshot();
			if (_sprModal) {
		        _sprModal.removeEventListener(MouseEvent.MOUSE_MOVE, OnModalMouseMove);
		        _sprModal.removeEventListener(MouseEvent.MOUSE_DOWN, OnModalMouseDown);
		        _sprModal.parent.removeChild(_sprModal);
		        _sprModal = null;
			}
			
			liveColor = selectedColor;			
		}
		
		
		import mx.core.mx_internal;
		use namespace mx_internal;
		
		private function OnModalMouseMove(evt:MouseEvent): void {
			if (_bmdSnapshot == null)
				return;
				
			// Show eye-dropper mouse cursor
			Cursor.csrEyedropper.Apply();
			
			// If the mouse is in the ImageView sample the color there and use it.
			// CONSIDER: a new property specifying the DisplayObject to sample when the mouse is over it.
			var clr:uint = _bmdSnapshot.getPixel(evt.stageX, evt.stageY);
			liveColor = clr;
			
			// Oh boy the hacking is getting deep in here.
			var obPreview:SwatchSkin = Util.GetChildByName(_dobSwatchHilight.parent, "swatchPreview") as SwatchSkin;
			obPreview.updateSkin(clr);
			var ti:TextInput = Util.GetChildByName(_dobSwatchHilight.parent, "inset") as TextInput;
			ti.text = rgbToHex(clr);
			
			evt.updateAfterEvent();
		}
		
		private function OnModalMouseDown(evt:MouseEvent): void {
//			trace("modal moouse down!");
			DisposeSnapshot();
			selectedColor = liveColor;
			close();
		}

		// From mx.controls.colorPickerClasses.SwatchPanel.as
	    private function rgbToHex(color:uint):String
	    {
	        // Find hex number in the RGB offset
	        var colorInHex:String = color.toString(16);
	        var c:String = "00000" + colorInHex;
	        var e:int = c.length;
	        c = c.substring(e - 6, e);
	        return c.toUpperCase();
	    }
	   
		private function DisposeSnapshot(): void {
			if (_bmdSnapshot) {
				_bmdSnapshot.dispose();
				_bmdSnapshot = null;
			}
		}
		
		private function OnValueCommit(evt:FlexEvent): void {
//			/* Leaving this fix turned off until we need it, to avoid unintentional side-effects
			// When the color is set via the base class's selectedColor property it
			// will fire the VALUE_COMMIT event BEFORE it sets the property (BUG, IMO).
			// We use callLater so we can use the selectedColor's final value.
			callLater(function (): void {
				liveColor = selectedColor;
			});
//			*/
//			liveColor = selectedColor;
		}
		
		private function OnItemRollOver(evt:ColorPickerEvent): void {
			liveColor = evt.color;
		}
		
		protected static var _aclrs:Array = null;
		
		[Bindable(event="changeColors")]
		public function get colors(): Array {
			if (_aclrs == null) {
				_aclrs = InitColors();
			}
			return _aclrs;
		}
		
		public static function InitColors():Array {
			var aclrs:Array = new Array();
			
			var x:Number;
			var y:Number;
			var i:Number;
			
			const knDarkRows:Number = 5;
			var nSatBlocks:Number = 5;
			var nRows:Number = nSatBlocks * knDarkRows;
			var nCols:Number = 32;
			var nRealCols:Number = nCols - 2;
			const knMinSat:Number = 20;
			aclrs.length = nRows * nCols;
			for (x = 0; x < nCols; x++) {
				for (y = 0; y < nRows; y++) {
					i = y * nCols + x;
					if (x == 0) { // First row is grayscale + 0/FF RGB values (max red, green, blue, etc)
						var nR:Number;
						var nG:Number;
						var nB:Number;
						if (y < (nRows-6)) {
							nR = nG = nB = Math.floor(y / (nRows-7) * 255);
						} else {
							// Convert to a binary number between 1 (0b001) and 6 (0b110)
							var nBin:Number = y - (nRows-7); // y == 6 -> nBin == 1
							nR = 0xff * ((nBin & 0x01) / 0x01);
							nG = 0xff * ((nBin & 0x02) / 0x02);
							nB = 0xff * ((nBin & 0x04) / 0x04);
						}
						aclrs[i] = RGBColor.RGBtoUint(nR, nG, nB);
					} else if (x == 1) { // Second row is black
						aclrs[i] = 0;
					} else { // The rest of the rows are the HSB swatch
						var x2:Number = x - 2;
						var h:Number; // 0-360
						var s:Number; // 0-100
						var b:Number; // 0-100
						s = map(Math.floor(y/knDarkRows), 0, nSatBlocks-1, 100, knMinSat);
						h = 360 * x2 / nRealCols;
						b = y % knDarkRows;
						if (0 == (Math.floor(y/knDarkRows) & 0x1)) {
							b = knDarkRows - b - 1;
						}
						var nBFact:Number = ((Math.floor(y/knDarkRows) & 0x1) * 1);
						b = (b+1+nBFact) * 100 / (knDarkRows+nBFact);
						aclrs[i] = RGBColor.HSVtoUint(h, s, b);
					}
				}
			}
			return aclrs;
		}
	}
}