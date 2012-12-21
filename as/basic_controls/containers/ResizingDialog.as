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
	import dialogs.DialogContent.IDialogContent;
	import dialogs.DialogContent.IDialogContentContainer;
	
	import flash.display.DisplayObject;
	import flash.events.KeyboardEvent;
	
	import mx.containers.BoxDirection;
	import mx.containers.utilityClasses.BoxLayout;
	import mx.containers.utilityClasses.CanvasLayout;
	import mx.containers.utilityClasses.ConstraintColumn;
	import mx.containers.utilityClasses.ConstraintRow;
	import mx.containers.utilityClasses.IConstraintLayout;
	import mx.containers.utilityClasses.Layout;
	import mx.core.Application;
	import mx.core.Container;
	import mx.core.ContainerLayout;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	import picnik.core.Env;

	[Event(name="close", type="flash.events.Event")]

	[Style(name="horizontalAlign", type="String", enumeration="left,center,right", inherit="no")]
	[Style(name="verticalAlign", type="String", enumeration="bottom,middle,top", inherit="no")]

	public class ResizingDialog extends Container implements IDialogContentContainer, IConstraintLayout {
		private var _nParentHeight:Number = 100;
		private var _fPoppedUp:Boolean = false;
		protected var _uicParent:UIComponent = null;
		protected var _fnComplete:Function;
		protected var _obParams:Object;

		private var layoutObject:Layout;
	    private var _layout:String = ContainerLayout.VERTICAL;

		public function ResizingDialog(): void {
			layoutObject = new BoxLayout();
			layoutObject.target = this;
		}


		// This is here because constructor arguments can't be passed to MXML-generated classes
		// Subclasses will enjoy this function, I'm sure.
		public function Constructor(fnComplete:Function, uicParent:UIComponent, obParams:Object=null): void {
			_fnComplete = fnComplete;
			_uicParent = uicParent;
			_obParams = obParams;
		}


		/** Dynamic layout functionality copied from Panel.as
		 */
	    [Bindable("layoutChanged")]
	    [Inspectable(category="General", enumeration="vertical,horizontal,absolute", defaultValue="vertical")]
	    public function get layout():String
	    {
	        return _layout;
	    }

	    /**
	     *  @private
	     */
	    public function set layout(value:String):void
	    {
	        if (_layout != value)
	        {
	            _layout = value;

	            if (layoutObject)
	                // Set target to null for cleanup.
	                layoutObject.target = null;

	            if (_layout == ContainerLayout.ABSOLUTE)
	                layoutObject = new CanvasLayout();
	            else
	            {
	                layoutObject = new BoxLayout();

	                if (_layout == ContainerLayout.VERTICAL)
	                    BoxLayout(layoutObject).direction
	                        = BoxDirection.VERTICAL;
	                else
	                    BoxLayout(layoutObject).direction
	                        = BoxDirection.HORIZONTAL;
	            }

	            if (layoutObject)
	                layoutObject.target = this;

	            invalidateSize();
	            invalidateDisplayList();

	            dispatchEvent(new Event("layoutChanged"));
	        }
	    }

		public static function Show(dlg:ResizingDialog, uicParent:UIComponent, clsContent:Class=null): void {
			if (clsContent) {
				var fnOnDialogInitialize:Function = function (evt:Event): void {
					dlg.removeEventListener(FlexEvent.INITIALIZE, fnOnDialogInitialize);
					var dcb:IDialogContent = new clsContent() as IDialogContent;
					dcb.container = dlg;
					var uicContentHolder:UIComponent = FindChildByName("contentHolder", dlg) as UIComponent;
					if (uicContentHolder == null)
						dlg.addChildAt(dcb as DisplayObject, dlg.numChildren);
					else
						uicContentHolder.addChildAt(dcb as DisplayObject, uicContentHolder.numChildren);
				}
				dlg.addEventListener(FlexEvent.INITIALIZE, fnOnDialogInitialize);
			}
			if (uicParent == null) uicParent = Env.inst.app as UIComponent;
			if (dlg._fPoppedUp) dlg.Hide();
			dlg._fPoppedUp = true;
			PopUpManager.addPopUp(dlg, uicParent, true);
			PopUpManager.centerPopUp(dlg);
			dlg.OnShow();
		}

		// Recurse through all child containers looking for the specified object by name
		private static function FindChildByName(strName:String, cntr:Container): DisplayObject {
			var dob:DisplayObject = cntr.getChildByName(strName);
			if (dob != null)
				return dob;

			for (var i:int = 0; i < cntr.numChildren; i++) {
				var cntrNested:Container = cntr.getChildAt(i) as Container;
				if (cntrNested == null)
					continue;
				dob = FindChildByName(strName, cntrNested);
				if (dob != null)
					return dob;
			}
			return null;
		}

		[Bindable]
		public function set parentHeight(nParentHeight:Number): void {
			_nParentHeight = nParentHeight;
		}

		public function get parentHeight(): Number {
			return _nParentHeight;
		}

		protected function OnShow(): void {
			Application.application.addEventListener(Event.RESIZE, OnParentResize);
			parentHeight = Application.application.height;
			addEventListener(Event.RESIZE, OnResize);
			addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown, true);
		}

		// Meant for use by subclasses. They should handle escape and call Hide() when appropriate.
		protected function OnKeyDown(evt:KeyboardEvent): void {
		}

		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
	        layoutObject.updateDisplayList(unscaledWidth, unscaledHeight);
		}

	    override protected function measure():void
	    {
	        super.measure();
	        layoutObject.measure();
	    }

		private function Reposition(): void {
			validateSize(true);
			PopUpManager.centerPopUp(this);
		}

		private function OnResize(evt:Event): void {
			Reposition();
		}

		private function OnParentResize(evt:Event): void {
			parentHeight = Application.application.height;
			Reposition();
		}

		protected function OnHide(): void {
			Application.application.removeEventListener(Event.RESIZE, OnParentResize);
			removeEventListener(Event.RESIZE, OnResize);
			removeEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown, true);
//			_vstk.removeEventListener(IndexChangedEvent.CHANGE, OnViewstackChange);
		}
		
		//
		// IDialogContentContainer implementation
		//

		public function Hide(): void {
			_fPoppedUp = false;
			OnHide();
			PopUpManager.removePopUp(this);
			dispatchEvent(new Event(Event.CLOSE));
		}

		private var _aobParameters:Array;

		public function get parameters(): Array {
			return _aobParameters;
		}

		public function set parameters(aobParameters:Array): void {
			_aobParameters = aobParameters;
		}

		//
		// IConstraintLayout implementation
		//

		// Copied from Canvas.as

		//----------------------------------
		//  constraintColumns
		//----------------------------------

	    [ArrayElementType("mx.containers.utilityClasses.ConstraintColumn")]
		[Inspectable(arrayType="mx.containers.utilityClasses.ConstraintColumn")]

		/**
	     *  @private
	     *  Storage for the constraintColumns property.
	     */
	    private var _constraintColumns:Array = [];

		/**
		 *  @copy mx.containers.utilityClasses.IConstraintLayout#constraintColumns
		 */
		public function get constraintColumns():Array
	    {
	        return _constraintColumns;
	    }

	    /**
	     *  @private
	     */
	    public function set constraintColumns(value:Array):void
	    {
	    	if (value != _constraintColumns)
	    	{
		    	var n:int = value.length;
		    	for (var i:int = 0; i < n; i++)
		    	{
		    		ConstraintColumn(value[i]).container = this;
		    	}
		       _constraintColumns = value;

		       invalidateSize();
		       invalidateDisplayList();
	     	}
	    }

		//----------------------------------
		//  constraintRows
		//----------------------------------

		[ArrayElementType("mx.containers.utilityClasses.ConstraintRow")]
		[Inspectable(arrayType="mx.containers.utilityClasses.ConstraintRow")]

		/**
	     *  @private
	     *  Storage for the constraintRows property.
	     */
	    private var _constraintRows:Array = [];

		/**
		 *  @copy mx.containers.utilityClasses.IConstraintLayout#constraintRows
		 */
		public function get constraintRows():Array
	    {
	        return _constraintRows;
	    }

	    /**
	     *  @private
	     */
	    public function set constraintRows(value:Array):void
	    {
	    	if (value != _constraintRows)
	    	{
		    	var n:int = value.length;
		    	for (var i:int = 0; i < n; i++)
	    		{
	    			ConstraintRow(value[i]).container = this;
	    		}
				_constraintRows = value;

				invalidateSize();
		       	invalidateDisplayList();
	     	}
	    }

	}
}
