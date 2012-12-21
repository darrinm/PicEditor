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
package imagine.documentObjects {
	import com.adobe.utils.StringUtil;
	
	import flash.geom.Rectangle;
	
	import mx.core.Application;
	
	[Bindable]
	[RemoteClass]
	public class Clipart extends PSWFLoader {
		private var _nCWidth:Number = 0;
		private var _nCHeight:Number = 0;
		private var _nGroupScale:Number = 0.0;
		
		public function set cWidth(n:Number): void {
			_nCWidth = n;
			Invalidate();
		}
		
		public function get cWidth(): Number {
			return _nCWidth;
		}
		
		public function set cHeight(n:Number): void {
			_nCHeight = n;
			Invalidate();
		}
		
		public function get cHeight(): Number {
			return _nCHeight;
		}
		
		public function set groupScale(nScale:Number): void {
			_nGroupScale = nScale;
		}
		
		public function get groupScale(): Number {
			return _nGroupScale;
		}
		
		override public function set localRect(rc:Rectangle): void {
			super.localRect = rc; // Adjusts fontSize to handle scaleY
		}

		override public function get localRect(): Rectangle {
			// While loading super returns a best-guess localRect. Clipart objects
			// have more state and can do better:
			if (status < DocumentStatus.Preview) {
				var cx:Number = unscaledWidth;
				var cy:Number = unscaledHeight;
				return new Rectangle(-cx / 2, -cy / 2, cx, cy);	
			}
			
			var rcSuper:Rectangle = super.localRect;
			if (rcSuper && rcSuper.width != 0 && rcSuper.height != 0 || !(cWidth || cHeight))
				return rcSuper;

			// Return the default local rect
			return new Rectangle(x, y, unscaledWidth, unscaledHeight);
		}
		
		override public function get serializableProperties(): Array {
			return super.serializableProperties.concat(["cWidth", "cHeight", "groupScale"]);
		}
		
		override public function get unscaledWidth(): Number {
			if (cWidth && cHeight) return 100 * cWidth / Math.max(cWidth, cHeight);
			return super.unscaledWidth;
		}
		
		override public function set unscaledWidth(cx:Number): void {
			super.unscaledWidth = cx;
		}
		
		override public function get unscaledHeight(): Number {
			if (cWidth && cHeight) return 100 * cHeight / Math.max(cWidth, cHeight);
			return super.unscaledHeight;
		}

		override public function set unscaledHeight(cy:Number): void {
			super.unscaledHeight = cy;
		}
		

		//
		// IDocumentObject interface
		//
		
		public override function get typeName(): String {
			if (url == null || url.length < 5 || !StringUtil.beginsWith(url, "shape")) {
				return "Clipart";
			} else {
				return "Shape";
			}
		}

		//
		//
		//
		
		public static function GetClipartBasePath(): String {
			var strBase:String;
			if (PicnikBase.IsStandaloneFlashPlayer()) {
				strBase = "../website/clipart/";
			} else {
				strBase = "../clipart/";
			}
			return strBase;
		}
		
		override protected function get urlBasePath(): String {
			return GetClipartBasePath();
		}
	}
}
