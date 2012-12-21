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
	import controls.shapeList.ImageSlice;
	
	import imagine.documentObjects.IDocumentObject;
	
	import flash.display.Bitmap;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	import mx.events.ResizeEvent;
	import mx.resources.ResourceBundle;
	
	import overlays.helpers.RGBColor;
	
	import util.LocUtil;
	
	public class PreviewUIDocumentObject extends UIDocumentObject
	{
		private var _imgs:ImageSlice = null;
		private var _fReposition:Boolean = false;
		
  		[Bindable] [ResourceBundle("PreviewUIDocumentObject")] protected var rb:ResourceBundle;
		
		public function PreviewUIDocumentObject(xml:XML=null): void {
			addEventListener(ResizeEvent.RESIZE, OnResize);
			init(xml);
		}
		
		public function set active(fActive:Boolean): void {
			if (_imgs == null)
				CreateImage();
		}

		override public function set childColor(clr:uint): void {
			super.childColor = clr;
			if (_imgs) {
				UpdateColorTransform();
			}
		}
		
		override public function get niceName(): String {
			var strName:String = super.niceName;
			if (_xml.hasOwnProperty('@url'))
				return String(_xml.@url).replace(/\//g,'_');
			if (previewUrl && previewUrl.length > 0) {
				if (previewUrl.charAt(0) != '/')
					strName += "/";
				strName += previewUrl;
			}
			return strName;
		}

		override protected function init(xml:XML): void {
			super.init(xml);
			var url:String = xml.@previewUrl;
	
			// first a bit of URL surgery.
			// if it's a glyph we're loading the name to be loaded is the font directory
			// name concatenated with the glyph name itself, with a '_' between them.  So
			// if the preview image is '{etc}/mk_5FBirthdayDigits/1.png', the class name
			// we look for will be based on '{etc}/mk_5FBirthdayDigits_1.png'.
			// Plus, if this Glyph object is part of a ShapeSection with a sectionId,
			// splice it in to the URL so we have the right place to look for the bundle.
			if (xml.localName() == "Glyph") {
				var slash1:int = url.lastIndexOf('/');
				url = url.slice(0, slash1) + '_' + url.slice(slash1+1);

				if (xml.@sectionId != "") {
					var slash2:int = url.lastIndexOf('/');
					url = url.slice(0, slash2) + '/' + xml.@sectionId + url.slice(slash2);
				}
			}
			previewUrl = url;
						
			if ((!toolTip || toolTip == "") && xml.hasOwnProperty("@authorName")) {
				toolTip = LocUtil.rbSubst('PreviewUIDocumentObject', "designedby", xml.@authorName);
				/*
				if (xml.hasOwnProperty("@authorUrl")) {
					toolTip += "\n" + xml.@authorUrl;
				}
				*/
			}			
		}

		protected function OnResize(evt:ResizeEvent): void {
			if (evt.oldHeight != height || evt.oldWidth != width) {
				_fReposition = true;
				invalidateProperties();
			}
		}
		
		protected function get previewUrl(): String {
			if (!_imgs) return "";
			if (!_imgs.source) return "";
			return _imgs.source.toString();
		}
		
		protected function set previewUrl(str:String): void {
			if (_imgs == null)
				CreateImage();

			_imgs.source = str;
			_fReposition = true;
			invalidateProperties();
		}
		
		override protected function commitProperties():void {
			if (_imgs == null)
				CreateImage();

			super.commitProperties();
			_imgs.x = (width - 40) /2;
			_imgs.y = (height - 40) /2;
			_imgs.height = 40;
			_imgs.width = 40;
		}
		
		protected function UpdateColorTransform(): void {
			if (_imgs) {
				var nR:Number = RGBColor.RedFromUint(childColor);
				var nG:Number = RGBColor.GreenFromUint(childColor);
				var nB:Number = RGBColor.BlueFromUint(childColor);
				
				// Leave white where it is.
				// Shift black to nR, nG, nB.
				_imgs.transform.colorTransform = new ColorTransform((255-nR)/255, (255-nG)/255, (255-nB)/255, 1, nR, nG, nB);
			}
		}
		
		override protected function get dragContent(): Object {
			var bm:Bitmap = _imgs.bitmap;
			bm = new Bitmap(bm.bitmapData);
			return bm;
		}
		
	    override protected function GetRealThumbSize(): Point {
	    	return GetThumbSize();
	    }
	   
	    override protected function GetThumbSize(): Point {
	    	return new Point(targetSize * childSizeFactor, targetSize * childSizeFactor);
	    }
	   
		protected function CreateImage(): void {
			_imgs = new ImageSlice();
			addChild(_imgs);
			_imgs.y = _imgs.x = targetSize * (1-childSizeFactor)/2;
			_imgs.width =_imgs.height = targetSize * childSizeFactor;
			UpdateColorTransform();
		}
		
		private static const kobKnownPropTypes:Object = {
				blendMode:String,
				defaultScaleY:Number,
				groupScale:Number,
				alpha:Number};
		
		override public function GetChildProperty(strProperty:String, obDefault:Object): * {
			if (strProperty in kobKnownPropTypes) {
				if (_xml.hasOwnProperty('@' + strProperty))
					return kobKnownPropTypes[strProperty](_xml['@' + strProperty]);
				else
					return obDefault;
			}
			if (_xml.name() == "Clipart") {
				if ((strProperty == "unscaledWidth") || (strProperty == "unscaledHeight")) {
					var cWidth:Number = _xml.hasOwnProperty("@cWidth") ? Number(_xml.@cWidth) : 0;
					var cHeight:Number = _xml.hasOwnProperty("@cWidth") ? Number(_xml.@cHeight) : 0;
					var cMax:Number = Math.max(cWidth, cHeight);
					
					if (cMax <= 0)
						return 100;
					
					if (strProperty == "unscaledWidth")
						return 100 * cWidth / cMax;
					else
						return 100 * cHeight / cMax;
				}
			}
			
			// Default
			return super.GetChildProperty(strProperty, obDefault);
		}
		
		private static const kobClipartTypes:Object = {
				x:"int",
				y:"int",
				alpha:"int",
				rotation:"int",
				scaleX:"int",
				scaleY:"int",
				color:"int",
				cWidth:"int",
				cHeight:"int",
				groupScale:"int",
				name:"String",
				blendMode:"String",
				url:"String",
				maskId:"null",
				visible:"Boolean",
				isVector:"Boolean"
		};
		
		override public function GetObjectProperties(): Object {
			if (_xml.name() == "Clipart") {
				// Convert it into the form CreateObjectOperation likes
				var dctProperties:Object = {};
				for (var nAttribute:String in _xml.attributes())
				{
					var strKey:String = _xml.attributes()[nAttribute].localName();
					if (strKey in kobClipartTypes) {
						var strType:String = kobClipartTypes[strKey];
						var obValue:* = String(_xml.attribute(strKey));
						if (strType == "int")
							obValue = Number(obValue);
						else if (strType == "Boolean")
							obValue = String(obValue) == "true";
						dctProperties[strKey] = obValue;
					}
				}
	
				// Don't copy the template object's id/name. New object needs a new id.
				dctProperties.name = Util.GetUniqueId();
				return dctProperties;
			} else {
				return super.GetObjectProperties();
			}
		}
		
		override public function get childIsPShape(): Boolean {
			if (_xml.name() == "Clipart")
				return false;
			return super.childIsPShape;
		}
	   
		override public function get child(): IDocumentObject {
			if (_docoChild == null) {
				// Create a child from
				_docoChild = ChildFromXML(_xml);
			}
			return super.child;
		}
	}
}
