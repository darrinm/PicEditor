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
	import creativeTools.ShapeDragImage;
	
	import dialogs.DialogManager;
	
	import imagine.documentObjects.IDocumentObject;
	import imagine.documentObjects.PShape;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import imagine.ImageDocument;
	
	import mx.controls.Button;
	import mx.controls.scrollClasses.ScrollBar;
	import mx.core.DragSource;
	import mx.core.EventPriority;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.events.ResizeEvent;
	import mx.managers.DragManager;
	
	import imagine.objectOperations.CreateObjectOperation;
	
	import overlays.helpers.RGBColor;
	
	import util.PicnikFont;
	import util.TargetColors;

	public class UIDocumentObjectBase extends UIComponent
	{
		protected var _clrChild:uint = 0x4d4d4d;
		protected var _nChildSizeFactor:Number = 0.75;
		protected var _clrBackground:uint = 0xffffff;
		protected var _nBackgroundAlpha:Number = 0;
		protected var _docoChild:IDocumentObject = null;
		protected var _fPremium:Boolean = false;
		protected var _strAuthorName:String = '';
		protected var _strAuthorUrl:String = '';
		private var _btnInfo:Button;

		protected var _xml:XML = null;
		
		public static const ADD_SHAPE:String = "addShape";
		
		protected var _clrCreated:uint = 0;

	    private var _fDragEnabled:Boolean = false;
	   
	    public function set dragEnabled(value:Boolean):void
	    {
	        if (_fDragEnabled && !value)
	        {
	            removeEventListener(DragEvent.DRAG_START, OnDragStart, false);
	            removeEventListener(DragEvent.DRAG_COMPLETE,
	                                OnDragComplete, false);
	        }
	
	        _fDragEnabled = value;
	
	        if (value)
	        {
	            addEventListener(DragEvent.DRAG_START, OnDragStart, false,
	                             EventPriority.DEFAULT_HANDLER);
	            addEventListener(DragEvent.DRAG_COMPLETE, OnDragComplete,
	                             false, EventPriority.DEFAULT_HANDLER);
	        }
	    }
	   
	    private function OnDragStart(evt:DragEvent): void {
	        if (evt.isDefaultPrevented())
	            return;
	
			if (evt.target is ScrollBar) return;
			
			if (premium && !AccountMgr.GetInstance().isPremium) {
				if (PicnikConfig.freeForAll) {
					DialogManager.ShowFreeForAllSignIn("/create_shapes/shapegroup/" + groupId + "/" + niceName);
				} else {
					DialogManager.ShowUpgrade("/create_shapes/shapegroup/" + groupId + "/" + niceName);
				}
				return;
			}
			
	        var dragSource:DragSource = new DragSource();
	
			var sdgimg:ShapeDragImage = GetDragImage();
	
	        dragSource.addData(this, "uidocob");
			dragSource.addData(sdgimg, "dragImage");
	
			var fDragMoveEnabled:Boolean = false; // UNDONE: Support dragging within a list

			var ptOffset:Point = GetDragImageOffset(evt);

	        DragManager.doDrag(this, dragSource, evt, sdgimg, -ptOffset.x, -ptOffset.y, 0.75, fDragMoveEnabled);
	    }
	   
	    private function GetDragImage(): ShapeDragImage {
	    	var ptOriginalSize:Point = new Point(GetChildProperty('unscaledWidth', 100), GetChildProperty('unscaledHeight', 100));
	    	var img:ShapeDragImage = new ShapeDragImage(ptOriginalSize, GetThumbSize(), GetRealThumbSize(), this);
	    	img.source = dragContent;
	    	return img;
	    }
	   
	    public function DoAdd(imgd:ImageDocument, nScale:Number, ptOrigin:Point): DisplayObject {
			PicnikBase.app.LogNav(niceName);
			if (premium && !AccountMgr.GetInstance().isPremium) {
				if (PicnikConfig.freeForAll) {
					DialogManager.ShowFreeForAllSignIn("/create_shapes/shapegroup/" + groupId + "/" + niceName);
				} else {
					DialogManager.ShowUpgrade("/create_shapes/shapegroup/" + groupId + "/" + niceName);
				}
				return null;
			} else {
				// Create the shape
				var dctProperties:Object = GetObjectProperties();
				dctProperties.x = ptOrigin.x;
				dctProperties.y = ptOrigin.y;
				dctProperties.scaleX = nScale;
				dctProperties.scaleY = nScale;
				dctProperties.scaleY *= GetChildProperty("defaultScaleY", 1);
				
				var strType:String = childType;
				
				if (strType == "Target") {
					dctProperties.color = TargetColors.GetNextColor(imgd);
					dctProperties.x -= nScale * 50;
					dctProperties.y -= nScale * 50;
				}
				
				// Got the type, now create on of these things.
				var coop:CreateObjectOperation = new CreateObjectOperation(strType, dctProperties);
				coop.Do(imgd);
				
				// Select the newly created object
				imgd.selectedItems = [ imgd.getChildByName(dctProperties.name) ];
				return imgd.getChildByName(dctProperties.name);
			}
	    	
	    }
	   
	    protected function GetRealThumbSize(): Point {
	    	return new Point(GetChildProperty('unscaledWidth', 100), GetChildProperty('unscaledHeight', 100));
	    }
	   
	    protected function GetThumbSize(): Point {
	    	return new Point(child["scaleX"] * GetChildProperty('unscaledWidth', 100), child["scaleY"] * GetChildProperty('unscaledHeight', 100));
	    }
	   
   		protected function get dragContent(): Object {
   			var doco:IDocumentObject = ChildFromXML(_xml);
			if ("defaultScaleY" in child)
				doco["scaleY"] = child["defaultScaleY"];
   			doco.Validate();
   			return doco;
   		}

		public function get childIsPShape(): Boolean {
			return child is PShape;
		}
	   
	    private function GetDragImageOffset(evt:DragEvent): Point {
	    	var ptOffset:Point = new Point(0,0);
	    	
	    	if (childIsPShape) {
				// UNDONE: Why are PShapes different? figure this out and fix this in a better way.
				// See also ShapeDragImage.GetUnscaledDropOffset
	    		ptOffset.offset(width / 2, height/2);
	    	} else {
		    	// Offset by the child offset
		    	ptOffset.offset((1-_nChildSizeFactor) * width / 2, (1-_nChildSizeFactor) * height / 2);
	    	}
	    	
	    	return ptOffset;
	    }
		
	    private function OnDragComplete(evt:DragEvent): void {
	    }
		
		protected function GetChildColor(fPremium:Boolean, clrPremium:uint, clrNonPremiumDefault:uint): uint {
			if (_clrCreated != 0 && RGBColor.LuminosityFromUint(_clrCreated) < 200) {
				return _clrCreated;
			} else {
				return fPremium ? clrPremium : clrNonPremiumDefault;
			}
		}
		
		public function UIDocumentObjectBase() {
			addEventListener(MouseEvent.CLICK, OnClick);
			dragEnabled = true;
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);
			addEventListener(ResizeEvent.RESIZE, OnResize);
		}
		
		private function OnResize(evt:ResizeEvent): void {
			Redraw();
		}
		
		private var _fDragging:Boolean = false;
		private var _ptMouseDown:Point = null;
		private static const DRAG_THRESHOLD:Number = 4;
		
		private function OnMouseDown(evt:MouseEvent): void {
			_fDragging = false;
    		if (_fDragEnabled) {
	        	_ptMouseDown = new Point(evt.stageX, evt.stageY);
	    		stage.addEventListener(MouseEvent.MOUSE_MOVE, OnStageMouseMove);
				addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
				stage.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
    		}
		}
		
		private function OnMouseUp(evt:MouseEvent): void {
    		stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnStageMouseMove);
			removeEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
		}
		
		private function OnStageMouseMove(evt:MouseEvent): void {
	        var pt:Point = new Point(evt.stageX, evt.stageY);
            if (Math.abs(_ptMouseDown.x - pt.x) > DRAG_THRESHOLD ||
             		Math.abs(_ptMouseDown.y - pt.y) > DRAG_THRESHOLD) {
                var dragEvent:DragEvent = new DragEvent(DragEvent.DRAG_START);
                dragEvent.dragInitiator = this;
                var ptDrag:Point = globalToLocal(_ptMouseDown);
                dragEvent.localX = ptDrag.x;
                dragEvent.localY = ptDrag.y;
                dragEvent.buttonDown = true;
                dispatchEvent(dragEvent);
                _ptMouseDown = null;
                _fDragging = true;
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, OnStageMouseMove);
            }
		}

		public function get niceName(): String {
			return childType;
		}
		
		protected function init(xml:XML): void {
			_xml = xml;
			if (xml.hasOwnProperty("@color"))
				_clrCreated = Number(xml.@color);
			if (xml.hasOwnProperty("@toolTip"))
				toolTip = xml.@toolTip;
			if (xml.hasOwnProperty("@premium"))
				premium = xml.@premium == "true";
			var strPremiumKey:String = PicnikBase.app.freemiumModel ? "@flickrPremium" : "@picnikPremium";
			if (xml.hasOwnProperty(strPremiumKey))
					premium = xml[strPremiumKey] == "true";
			if (xml.hasOwnProperty("@authorName"))
				authorName = xml.@authorName;
			if (xml.hasOwnProperty("@authorUrl"))
				authorUrl = xml.@authorUrl;
		}
		
		[Bindable]
		public function set premium(f:Boolean): void {
			_fPremium = f;
		}

		public function get premium(): Boolean {
			return _fPremium;
		}
		
		[Bindable]
		public function set authorName(s:String): void {
			_strAuthorName = s;
		}

		public function get authorName(): String {
			return _strAuthorName;
		}
		
		[Bindable]
		public function set authorUrl(s:String): void {
			_strAuthorUrl = s;
		}

		public function get authorUrl(): String {
			return _strAuthorUrl;
		}
		
		public function OnClick(evt:MouseEvent): void {
			if (!_fDragging)
				dispatchEvent(new Event(ADD_SHAPE, true));
		}
		
		[Bindable]
		public function set backgroundColor(clr:uint): void {
			_clrBackground = clr;
			Redraw();
		}
		
		public function get backgroundColor(): uint {
			return _clrBackground;
		}
		
		[Bindable]
		public function set backgroundAlpha(nAlpha:Number): void {
			_nBackgroundAlpha = nAlpha;
			Redraw();
		}
		
		public function get backgroundAlpha(): Number {
			return _nBackgroundAlpha;
		}
		
		// Override in children to react accordingly
		[Bindable]
		public function set childColor(clr:uint): void {
			_clrChild = clr;
		}
		
		public function get childColor(): uint {
			return _clrChild;
		}
		
		[Bindable]
		public function set childSizeFactor(n:Number): void {
			if (_nChildSizeFactor != n) {
				_nChildSizeFactor = n;
			}
		}
		
		public function get childSizeFactor(): Number {
			return _nChildSizeFactor;
		}
		
		protected function Redraw():void {
			graphics.clear();
			graphics.beginFill(_clrBackground, _nBackgroundAlpha);
			graphics.drawRect(0,0,width,height);
			graphics.endFill();
		}
		
		public function set child(doco:IDocumentObject): void {
			_docoChild = doco;
		}
		
		public function get child(): IDocumentObject {
			return _docoChild;
		}
		
		protected function get targetSize(): Number {
			return Math.floor(210/4);
		}
		
		protected override function measure():void {
			measuredWidth = measuredHeight = targetSize;
		}
		
		public function GetObjectProperties(): Object {
			var xmlProperties:XML = ImageDocument.DocumentObjectToXML(child);
			// Convert it into the form CreateObjectOperation likes
			var dctProperties:Object = Util.ObFromXmlProperties(xmlProperties);

			// Don't copy the template object's id/name. New object needs a new id.
			dctProperties.name = Util.GetUniqueId();
			
			if ("color" in dctProperties) {
				dctProperties.color = _clrCreated;
			}

			return dctProperties;
		}

		public function get childType(): String {
			return _xml.localName();
		}
		
		public function get groupId(): String {
			var strGroupId:String = "unknown";
			try {
				strGroupId = XML(_xml.parent().parent()).@id;
			} catch (e:Error) {
				// Ignore errors
			}
			return strGroupId;
		}
		
		public function get data():Object
		{
			return _xml;
		}
		
		public function set data(value:Object):void
		{
			init(value as XML);
		}
		
		public function GetChildProperty(strProperty:String, obDefault:Object): * {
			if (strProperty in child)
				return child[strProperty];
			else
				return obDefault
			// Override in sub-classes as needed. See PreviewUIDocumentObject
		}

		protected function ChildFromXML(xml:XML): IDocumentObject {
			var xmlEmptyChild:XML = <{xml.localName()}/>
			
			var doco:IDocumentObject = ImageDocument.XMLToDocumentObject(xmlEmptyChild);
			doco.color = 0;
			
			for (var nAttribute:String in xml.attributes())
			{
				var strKey:String = xml.attributes()[nAttribute].localName();
				if (strKey in doco) {
					var obValue:* = xml.attribute(strKey);
					if (obValue == "true")
						obValue = true;
					else if (obValue == "false")
						obValue = false;
					doco[strKey] = obValue;
				}
			}
			for each (var xmlChild:XML in xml.children()) {
				if (xmlChild.localName() == "PicnikFont") {
					doco["font"] = new PicnikFont(xmlChild);
				}
			}
			return doco;
		}
		
		//
		// Info button stuff
		//
		
		protected function ShowInfoButton(): void {
			import creativeTools.ShapeToolBase;
			// Only show info if we have full author information to display.
			// It used to be based on whether we were premium or not, but
			// now premium-ness has no bearing on author info availability
			if (authorName == '' || authorUrl == '')
				return;
				
			_btnInfo = new Button();
			_btnInfo.toggle = true;
			//_btnInfo.addEventListener(MouseEvent.MOUSE_DOWN, OnInfoButtonMouseDown, false, 100);
			//_btnInfo.addEventListener(MouseEvent.MOUSE_UP, OnInfoButtonMouseDown, false, 100);
			_btnInfo.addEventListener(MouseEvent.CLICK, OnInfoButtonClick, false, 100);
			addChild(_btnInfo);
			_btnInfo.includeInLayout = false;
			_btnInfo.styleName = "infoButton";
			_btnInfo.width = 17;
			_btnInfo.height = 17;
			_btnInfo.x = (width - _btnInfo.width) - 1;
			_btnInfo.y = (height - _btnInfo.height) - 1;

			// if info window is visible, update it (called on rollover)
			_btnInfo.selected = ShapeArea.IsShapeInfoWindowVisible();
			if (_btnInfo.selected)			
				ShapeArea.ShowShapeInfoWindow(_xml);
		}
		
		protected function HideInfoButton(): void {
			if (_btnInfo != null) {
				removeChild(_btnInfo);
				_btnInfo = null;
			}
		}
		
		private function OnInfoButtonMouseDown(evt:MouseEvent): void {
			evt.stopImmediatePropagation();
		}

		private function OnInfoButtonClick(evt:MouseEvent): void {
			import creativeTools.ShapeToolBase;
			if (evt.target is Button) {
				if (ShapeArea.IsShapeInfoWindowVisible()) {
					ShapeArea.HideShapeInfoWindow();
					_btnInfo.selected = false;
				} else {
					ShapeArea.ShowShapeInfoWindow(_xml);
					_btnInfo.selected = true;
				}
				evt.stopImmediatePropagation();
			}
		}
	}
}
