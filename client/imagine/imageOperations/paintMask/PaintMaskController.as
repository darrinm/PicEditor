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
package imagine.imageOperations.paintMask
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	
	import util.IUndoRedoSaver;
	
	[Event(name="change", type="flash.events.Event")]

	public class PaintMaskController extends EventDispatcher implements IUndoRedoSaver
	{
		[Bindable] public var mask:PaintPlusImageMask;
		[Bindable] public var canUndo: Boolean = false;
		[Bindable] public var canRedo: Boolean = false;
		
		// Brush/stroke properties
		[Bindable] public var _nBrushAlpha:Number = 1;
		[Bindable] public var _nBrushRotation:Number = 0;
		[Bindable] public var _fErase:Boolean = false;
		[Bindable] public var _obExtraStrokeParams:Object = null;
		[Bindable] public var additive:Boolean = false;
		[Bindable] public var brushSpacing:Number = 0.2;
		
		private var _astkRedo:Array = [];
		private var _stkCurrent:Stroke = null;
		private var _fRedoOrUndo:Boolean = false;
		private var _fActive:Boolean = false;
		
		[Bindable] public var brush:Brush;
		
		public function PaintMaskController(msk:PaintPlusImageMask=null)
		{
			if (msk == null)
				msk = new PaintPlusImageMask();
			mask = msk;
			mask.addEventListener(Event.CHANGE, OnMaskChange);
			brush = new CircularBrush(200, 0);
		}

		[Bindable]
		public function set brushAlpha(n:Number): void {
			_nBrushAlpha = n;
			PrepareForNextStroke();
		}
		public function get brushAlpha(): Number {
			return _nBrushAlpha;
		}

		[Bindable]
		public function set brushRotation(n:Number): void {
			_nBrushRotation = n;
			PrepareForNextStroke();
		}
		public function get brushRotation(): Number {
			return _nBrushRotation;
		}

		[Bindable]
		public function set erase(f:Boolean): void {
			_fErase = f;
			PrepareForNextStroke();
		}
		public function get erase(): Boolean {
			return _fErase;
		}

		[Bindable]
		public function set extraStrokeParams(ob:Object): void {
			_obExtraStrokeParams = ob;
			PrepareForNextStroke();
		}
		public function get extraStrokeParams(): Object {
			return _obExtraStrokeParams;
		}
		
		public function CreateFreshMask(): PaintPlusImageMask {
			if (mask != null) {
				mask.removeEventListener(Event.CHANGE, OnMaskChange);
			}
			mask = new PaintPlusImageMask();
			mask.addEventListener(Event.CHANGE, OnMaskChange);
			return mask;
		}
		
		
		// IUndoRedoSaver implementation
		public function get canSave(): Boolean {
			return false;
		}

		// IUndoRedoSaver implementation
		public function Save(): void {
			throw new Error("Can't save a mask");
		}
		
		// IUndoRedoSaver implementation
		public function Activate(): void {
			_fActive = true;
		}
		
		// IUndoRedoSaver implementation
		public function Deactivate(): void {
			_fActive = false;
			mask.Dispose();
		}
		
		
		public function set width(n:Number): void {
			mask.width = n;
		}
		
		public function set height(n:Number): void {
			mask.height = n;
		}
		
		private function OnMaskChange(evt:Event=null): void {
			canUndo = mask.hasStrokes;
			if (!_fRedoOrUndo) {
				canRedo = false;
				_astkRedo.length = 0;			
			} 
			dispatchEvent(new Event(Event.CHANGE));
		}

		public function Undo(): void {
			_fRedoOrUndo = true;
			Debug.Assert(mask.hasStrokes);
			_astkRedo.push(mask.UndoStroke(_fActive));
			canRedo = _astkRedo.length > 0;
			_fRedoOrUndo = false;
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function Redo(): void {
			_fRedoOrUndo = true;
			Debug.Assert(_astkRedo.length > 0);
			var stk:Stroke = _astkRedo.pop();
			canRedo = _astkRedo.length > 0;
			mask.AddStroke(stk, _fActive);
			_fRedoOrUndo = false;
			PrepareForNextStroke();
		}
		
		public function PrepareForNextStroke(): void {
			mask.PrepareForNextStroke(erase, brushAlpha, brushRotation, extraStrokeParams);
		}
		
		// UNDONE: Add stroke properties? Brush?
		public function StartDrag(ptd:Point): void {
			mask.NewStroke(ptd, brush, erase, brushAlpha, brushRotation, additive, brushSpacing, extraStrokeParams);
		}
		
		public function ContinueDrag(ptd:Point): void {
			mask.AddDragPoint(ptd);
		}
		
		// Drag complete. Update key frames
		public function FinishDrag(): void {
			if (_fActive) mask.UpdateKeyFrames()
			PrepareForNextStroke();
		}

		public function Reset(): void {
			canUndo = false;
			canRedo = false;
			mask.reset();
			_astkRedo.length = 0;
			
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function set reset(ob:Object): void {
			Reset();
		}
	}
}
