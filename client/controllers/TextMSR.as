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
// - focus is taken
//   - when a Test Properties control (e.g. align) is clicked
// - exit edit mode when focus change? activation change?
// - tab handling
// - remove TextTool's input field
// - "click to type"

package controllers {
	import imagine.documentObjects.DocumentObjectUtil;
	import imagine.documentObjects.Text;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextLineMetrics;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import mx.core.Application;
	import mx.events.PropertyChangeEvent;

	public class TextMSR extends MoveSizeRotate {
		private var _tfInput:TextField;
		private var _shpCaret:Shape;
		private var _tmrBlink:Timer;
		private var _fEditing:Boolean = false;
		private var _ichSelectionDown:int;
		private var _fFadeBack:Boolean = true;
		
		public function TextMSR(imgv:ImageView, dob:DisplayObject, fCrop:Boolean=true) {
			super(imgv, dob, fCrop);
			doubleClickEnabled = true;
		}
		
		override protected function OnAddedToStage(evt:Event): void {
			super.OnAddedToStage(evt);
			addEventListener(MouseEvent.DOUBLE_CLICK, OnDoubleClick);
		}
		
		override protected function OnRemovedFromStage(evt:Event): void {
			super.OnRemovedFromStage(evt);
			_fFadeBack = false;
			editing = false;
			removeEventListener(MouseEvent.DOUBLE_CLICK, OnDoubleClick);
		}
		
		override protected function HitTestTarget(rcl:Rectangle, xl:Number, yl:Number): Number {
			if (editing) {
				var nHitZone:Number = Util.HitTestPaddedRect(rcl, xl, yl, kcxyHitPad, true, true);
				if (nHitZone == 0)
					return 10;
				return nHitZone;
			} else {
				return super.HitTestTarget(rcl, xl, yl);
			}
		}
		
		override protected function OnMouseDown(evt:MouseEvent): void {
			super.OnMouseDown(evt);
			if (_nHitZone != 10) {
				editing = false;
				return;
			}
			
			SetInsertionPointAt(evt.stageX, evt.stageY);
			_ichSelectionDown = _tfInput.selectionBeginIndex;
		}
		
		override protected function OnStageCaptureMouseMove(evt:MouseEvent): void {
			super.OnStageCaptureMouseMove(evt);
			if (!_fMouseDown || _tfInput == null)
				return;
				
			var ich:int = GetCharIndexAtPoint(evt.stageX, evt.stageY, true);
			if (ich != -1) {
				var ichBegin:int = Math.min(_ichSelectionDown, ich);
				var ichEnd:int = Math.max(_ichSelectionDown, ich);
				SetSelection(ichBegin, ichEnd);
			}
		}
		
		private var _strExpectedTextChange:String;
		
		private function OnTextChange(evt:Event): void {
			_strExpectedTextChange =  evt.target.text;
			DocumentObjectUtil.AddPropertyChangeToUndo("Change Text", view.imageDocument, target, { text: evt.target.text }, true);
		}
		
		// Text might be changed by something other than this controller, e.g. Undo/Redo.
		// When it does, reset the input TextField's state.
		override protected function OnTargetPropertyChange(evt:PropertyChangeEvent): void {
			super.OnTargetPropertyChange(evt);
			if (!editing)
				return;
				
			if (evt.property == "text") {
				var strNew:String = evt.newValue as String;
				if (_strExpectedTextChange == null)
					editing = false;
				else if (strNew == _strExpectedTextChange)
					_strExpectedTextChange = null;
			}
		}
		
		private function UpdateCaret(): void {
			var txt:documentObjects.Text = documentObjects.Text(target);
			var tfTarget:TextField = targetTextField;
			
			// Update the target's selection to match our input field's
			if (_tfInput.selectionBeginIndex != tfTarget.selectionBeginIndex ||
					_tfInput.selectionEndIndex != tfTarget.selectionEndIndex) {
				SetTargetSelection(_tfInput.selectionBeginIndex, _tfInput.selectionEndIndex);
			}
			
			InvalidateDisplayList();
			_shpCaret.visible = true;
			_tmrBlink.reset();
			_tmrBlink.start();
		}
		
		private function OnTextInput(evt:TextEvent): void {
//			trace("text_input: " + evt);	
		}
		
		private function OnBlinkTimer(evt:TimerEvent): void {
			_shpCaret.visible = !_shpCaret.visible;
		}
		
		private function OnKeyDown(evt:KeyboardEvent): void {
			if (evt.keyCode == Keyboard.ESCAPE) {
				editing = false;
				return;
			}
			
			// If the KeyboardEvent changed the selection redraw the cursor
//			if (_tfInput.caretIndex != targetTextField.caretIndex)
				Application.application.callLater(UpdateCaret);
		}
		
		private function OnDoubleClick(evt:MouseEvent): void {
			if (editing) {
				SelectWord(GetCharIndexAtPoint(evt.stageX, evt.stageY));
				return;
			}
			editing = true;
			SetInsertionPointAt(evt.stageX, evt.stageY);
		}
		
		private function get text(): String {
			return (target as documentObjects.Text).text;
		}
		
		private function set text(strText:String): void {
			(target as documentObjects.Text).text = strText;
		}
		
		private function get targetTextField(): TextField {
			var txt:documentObjects.Text = documentObjects.Text(target);
			return txt.content as TextField;
		}
		
		private function get editing(): Boolean {
			return _fEditing;
		}
		
		private function set editing(fEditing:Boolean): void {
			if (_fEditing == fEditing)
				return;
				
			_fEditing = fEditing;
			if (_fEditing) {
				_tfInput = new TextField();
	//			stage.addChild(_tfInput);
				_strExpectedTextChange = null;
				_tfInput.type = TextFieldType.INPUT;
				_tfInput.multiline = true;
				_tfInput.text = text;
				_tfInput.addEventListener(Event.CHANGE, OnTextChange);
				_tfInput.addEventListener(TextEvent.TEXT_INPUT, OnTextInput);
				_tfInput.addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown, false, -10);
				_shpCaret = new Shape();
				_shpCaret.blendMode = BlendMode.INVERT;
				_tmrBlink = new Timer(500);
				_tmrBlink.addEventListener(TimerEvent.TIMER, OnBlinkTimer);
				_tmrBlink.start();
				_fFadeBack = true;
				FadeTo(0.2);
				FadeObjectPaletteTo(0.0);
			} else {
				// Anything done to this point should be sealed off
				DocumentObjectUtil.SealUndo(view.imageDocument);
				
				_tmrBlink.removeEventListener(TimerEvent.TIMER, OnBlinkTimer);
				_tmrBlink.stop();
				if (_shpCaret.parent != null)
					removeChild(_shpCaret);
				_shpCaret = null;
				_tmrBlink = null;
				_tfInput.removeEventListener(Event.CHANGE, OnTextChange);
				_tfInput.removeEventListener(TextEvent.TEXT_INPUT, OnTextInput);
				_tfInput.removeEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
				_tfInput = null;
				SetTargetSelection(0, 0);
				if (_fFadeBack) {
					FadeObjectPaletteTo(1.0);
					FadeTo(1.0);
				}
			}
		}
		
		private function SetInsertionPointAt(xs:int, ys:int): void {
			stage.focus = _tfInput;
			var ich:int = GetCharIndexAtPoint(xs, ys, true);
			if (ich != -1) {
				_tfInput.setSelection(ich, ich);
				UpdateCaret();
			}
		}
		
		private function GetCharIndexAtPoint(xs:int, ys:int, fInsertionPoint:Boolean=false): int {
			var txt:documentObjects.Text = documentObjects.Text(target);
			var tfTarget:TextField = txt.content as TextField;
			
			var ptdMouse:Point = view.PtdFromPts(new Point(xs, ys));
			var ptlTarget:Point = tfTarget.globalToLocal(ptdMouse);
			var ich:int = tfTarget.getCharIndexAtPoint(ptlTarget.x, ptlTarget.y);
			
			if (ich != -1) {
				if (fInsertionPoint) {
					// Put the insertion point to the left or right of the clicked char, whichever is
					// closer to the point clicked.
					var rclChar:Rectangle = tfTarget.getCharBoundaries(ich);
					if (ptlTarget.x - rclChar.left >= rclChar.right - ptlTarget.x)
						ich++;
				}
			} else {
				// If the point is not on a character (e.g. off the end of a line)
				// Flash returns -1. It's up to us to handle all these cases.
				
				// If the point is off the top, return top-left (index 0)
				if (ptlTarget.y - 2 < 0)
					ich = 0;
					
				// If the point is off the bottom, return bottom-right (index text.length)
				else if (ptlTarget.y - 2 > tfTarget.textHeight)
					ich = text.length;

				// Left and right are trickier. We need to test them in a way that takes
				// alignment into account.					
				if (ich == -1) {
					// NOTE: this assumes all lines are of the same height
					var tlm:TextLineMetrics = tfTarget.getLineMetrics(0);
					var iach:int = (ptlTarget.y - 2) / tlm.height;
					tlm = tfTarget.getLineMetrics(iach);

					// If the point is off the left, return the index of the left most char on the line
					if (ptlTarget.x < tlm.x)
						ich = tfTarget.getLineOffset(iach);
						
					// If the point is off the right, return the index after of the right most char on the line
					else if (ptlTarget.x > tlm.x + tlm.width) {
						ich = tfTarget.getLineOffset(iach) + tfTarget.getLineLength(iach) - 1;
						if (text.charAt(ich) != "\r")
							ich++;
					}
				}
			}
			
			return ich;
		}
		
		private function SetTargetSelection(ichStart:int, ichEnd:int): void {
			targetTextField.setSelection(ichStart, ichEnd);
			
			// Since we're not setting a doco property we have to invalidate the composite explicitly.
			view.imageDocument.InvalidateComposite();
		}
		
		override public function UpdateDisplayList(): void {
			super.UpdateDisplayList();			
			
			if (_tfInput == null)
				return;
					
			var txt:documentObjects.Text = documentObjects.Text(target);
			var tfTarget:TextField = txt.content as TextField;
			
			// The caret is hidden if there is a selection
			if (_tfInput.selectionBeginIndex != _tfInput.selectionEndIndex) {
				if (_shpCaret.parent != null)
					removeChild(_shpCaret);
			} else {
				if (_shpCaret.parent == null)
					addChild(_shpCaret);
			}
			
			var ichInsertionPoint:int = _tfInput.caretIndex;
			if (ichInsertionPoint == -1)
				ichInsertionPoint = 0;
			
			// Get the bounding rectangle of the character before the insertion point and
			// place the cursor at its right edge.
			var rclChar:Rectangle = null;
			if (ichInsertionPoint > 0) {
				rclChar = tfTarget.getCharBoundaries(ichInsertionPoint - 1);
				if (rclChar != null)
					rclChar.x += rclChar.width;
			}
			
			// When the cursor follows a carriage return or is on blank line rclChar is null.
			// Position the cursor at the beginning of the line.
			if (rclChar == null) {
				var iach:int = tfTarget.getLineIndexOfChar(ichInsertionPoint);
				var tlm:TextLineMetrics;
				// If the insertion point follows a '\r' that has nothing else on the same line as it
				if (iach == -1) {
					tlm = tfTarget.getLineMetrics(0);
					rclChar = new Rectangle(tlm.x, tlm.height * (tfTarget.numLines - 1) + 2, // + 2 pixel gutter
							1, tlm.height + tlm.leading); // BUGBUG: docs say height includes leading but it doesn't look like it
				} else {
					tlm = tfTarget.getLineMetrics(iach);
					rclChar = new Rectangle(tlm.x, tlm.height * iach + 2, // + 2 pixel gutter
							1, tlm.height + tlm.leading); // BUGBUG: docs say height includes leading but it doesn't look like it
				}
			}
//			trace("rclChar: " + rclChar);
				
			var nScaleX:Number = tfTarget.scaleX;
			var nScaleY:Number = tfTarget.scaleY;
			rclChar.x *= nScaleX;
			rclChar.y *= nScaleY;
			rclChar.width *= nScaleX;
			rclChar.height *= nScaleY;
			rclChar.offset(tfTarget.x, tfTarget.y);
			
			var rcvChar:Rectangle = view.RcvFromRcd(rclChar);
			_shpCaret.graphics.clear();
			_shpCaret.graphics.lineStyle(1, 0xffffff);
			_shpCaret.graphics.drawRect(rcvChar.x, rcvChar.y, 1, rcvChar.height);
		}
		
		private function SelectWord(ich:int): void {
			if (IsBreakingChar(text.charAt(ich)))
				return;
				
			var ichBegin:int = ich;
			while (ichBegin > 0 && !IsBreakingChar(text.charAt(ichBegin - 1)))
				ichBegin--;
			var ichEnd:int = ich;
			while (ichEnd < text.length - 1 && !IsBreakingChar(text.charAt(ichEnd + 1)))
				ichEnd++;
			SetSelection(ichBegin, ichEnd + 1);
		}
		
		private function SetSelection(ichBegin:int, ichEnd:int): void {
			_tfInput.setSelection(ichBegin, ichEnd);
			SetTargetSelection(ichBegin, ichEnd);
		}
		
		private function IsBreakingChar(strChar:String): Boolean {
			return strChar == " " || strChar == "\r" || strChar == "\n" || strChar == "\t";
		}
	}
}
