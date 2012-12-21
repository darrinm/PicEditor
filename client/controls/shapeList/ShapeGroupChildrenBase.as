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
package controls.shapeList
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.core.ScrollPolicy;
	import mx.events.ResizeEvent;
	
	import util.ShapeGroupLoader;

	public class ShapeGroupChildrenBase extends VBox
	{
		private var _xmlData:XML = null;
		private var _xmlShapeData:XML = null;
		
		private var _obMapCatIdToShapeSect:Object = {};
		
		private var _sprFooter:Sprite = null;
		
		public var footerColor:Number = 0xcccccc;

		public function ShapeGroupChildrenBase()
		{
			super();
			percentWidth = 100;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			addEventListener(ResizeEvent.RESIZE, OnResize);
		}
		
		private var _nFooterWidth:Number = 0;
		
		private function AddFooter(): void {
			if (_sprFooter) return;
			_sprFooter = new Sprite();
			rawChildren.addChild(_sprFooter);
			DrawFooter();
		}
		
		private function RemoveFooter(): void {
			if (!_sprFooter) return;
			rawChildren.removeChild(_sprFooter);
			_sprFooter = null;
		}
		
		private static const knFooterHeight:Number = 4;
		
		private function DrawHRule(y:Number, clr:Number, nAlpha:Number): void {
			var gr:Graphics = _sprFooter.graphics;
			gr.lineStyle(1, clr, nAlpha, true);
			gr.moveTo(0, y);
			gr.lineTo(_nFooterWidth, y);
		}
		
		private function RedrawFooterIfNeeded(): void {
			if (_nFooterWidth != width) {
				DrawFooter();
			}
		}
		
		private function DrawFooter(): void {
			_nFooterWidth = width;
			var gr:Graphics = _sprFooter.graphics;
			var anAlphaMul:Array = [10,25,58];
			for (var i:Number = 0; i < knFooterHeight; i++) {
				// Position knFooterHeight-1 => alpha = 1
				// Position -1 => alpha = 0
				// => alpha = 1 - (position + 1) / knFooterHeight
				DrawHRule(i, footerColor, .30 * anAlphaMul[i] / 100);
			}
		}
		
		private function OnResize(evt:Event): void {
			if (_sprFooter) {
				RedrawFooterIfNeeded();
				_sprFooter.y = Math.max(0,height - knFooterHeight+1);
			}
		}
		
		public override function set data(value:Object):void {
			if (super.data != value) {
				super.data = value;
				_xmlData = value as XML;
				// Data changed. Set up our children
				removeAllChildren();
				RemoveFooter();
				invalidateDisplayList();
			}
		}
		
		protected override function measure():void {
			super.measure();
			if (numChildren == 0)
				measuredHeight = calculateMeasuredHeight();
		}
		
		private function calculateMeasuredHeight(): Number {
			if (_xmlData == null) return 0;
			// _xmlData is the shape category for the group
			// Do something silly for now
			var nHeight:Number = 0;

			nHeight += ShapeTile.calculateHeight(Number(_xmlData.@numShapes));
			
			for each (var xmlShapeCategory:XML in _xmlData.ShapeCategory) {
				nHeight += ShapeTile.calculateHeight(Number(xmlShapeCategory.@numShapes));
				nHeight += SubGroupHeader.knHeight;
			}
			
			return nHeight;
		}
		
		public function set shapeData(xml:XML): void {
			_xmlShapeData = xml;
			// This looks like xmlData but it has some Shapes sections
			if (xml.Shapes.length() > 0) SetShapes(_xmlShapeData.@id, xml.Shapes[0]);
			for each (var xmlShapeCategory:XML in _xmlShapeData.ShapeCategory) {
				if (xmlShapeCategory.Shapes.length() > 0) SetShapes(xmlShapeCategory.@id, xmlShapeCategory.Shapes[0]);
			}
		}
		
		private function SetShapes(strId:String, xmlShapes:XML): void {
			var sgrp:ShapeSubGroup = _obMapCatIdToShapeSect[strId];
			sgrp.shapeData = xmlShapes;
		}
		
		private function GetAreaPrefix(xmlData:XML): String {
			var strAreaPrefix:String = "";
			try {
				while (!xmlData.hasOwnProperty('@area')) {
					xmlData = xmlData.parent();
				}
				strAreaPrefix = xmlData.@area;
				if (strAreaPrefix.length > 0) {
					strAreaPrefix += "/";
				}
			} catch (e:Error) {
				trace(e);
			}
			return strAreaPrefix;
		}
		
		private function LoadChildData(): void {
			var fnOnGroupLoaded:Function = function(xmlShapes:XML, strError:String): void {
				if (strError) {
					Alert.show("Error: " + strError, "Error");
				} else {
					shapeData = xmlShapes;
				}
			}
			
			// UNDONE: Check to see if we already have shapes or of there are no shapes
			// If so, use _xmlData
			// Otherwise, load shapes
			var fAlreadyHaveShapes:Boolean = false;
			if (fAlreadyHaveShapes) {
				shapeData = _xmlData;
			} else {
				ShapeGroupLoader.LoadGroup(_xmlData.@id, GetAreaPrefix(_xmlData), fnOnGroupLoaded);
			}
		}
		
		// Add a child shape section for an xml category (if it has any shapes)
		private function AddShapeSection(xmlShapeCategory:XML, fShowHeader:Boolean): void {
			var nNumShapes:Number = Number(xmlShapeCategory.@numShapes);
			if (nNumShapes < 1) return;
			
			// UNDONE: Everything is an expanding shape sub-group
			// Some have their header hidden.
			
			// For now, everything is a shape tile with no header
			var sgrp:ShapeSubGroup =  new ShapeSubGroup();
			sgrp.data = xmlShapeCategory;
			sgrp.showHeader = fShowHeader;
			addChild(sgrp);
			_obMapCatIdToShapeSect[xmlShapeCategory.@id] = sgrp;
		}
		
		protected override function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if (_xmlData != null && numChildren == 0 && unscaledHeight > 0) {
				// Create the children, load the data, send the data to the children.
				
				// Main group
				AddShapeSection(_xmlData, false);
				for each (var xmlShapeCategory:XML in _xmlData.ShapeCategory) {
					AddShapeSection(xmlShapeCategory, true);
				}
				AddFooter();
				// Add sub groups
				LoadChildData();
			}
		}
	}
}