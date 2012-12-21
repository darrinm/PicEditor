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
// The Target DocumentObject
// - accepts a child object
// - sizes/positions the child to fill the target
// - crops the child

package imagine.documentObjects {
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	
	[Bindable]
	[RemoteClass]
	public class GalleryThumb extends DocumentObjectBase {
		
		private var _strImage1:String = null;
		private var _strImage2:String = null;
		private var _strImage3:String = null;
		private var _nCWidth:Number = 0;
		private var _nCHeight:Number = 0;
		
		private var _gtv:GalleryThumbView = null;		

		override public function get typeName(): String {
			return "GalleryThumb";
		}
								
		public override function get serializableProperties(): Array {
			return super.serializableProperties.concat(["image1", "image2", "image3","cWidth", "cHeight"]);
		}		
				
		override protected function SizeNewContent(dobContent:DisplayObject): void {
			dobContent.width = unscaledWidth;
			dobContent.height = unscaledHeight;
		}
						
		public function GalleryThumb(): void {
			Invalidate();
		}

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

		override public function set localRect(rc:Rectangle): void {
			super.localRect = rc; // Adjusts fontSize to handle scaleY
		}

		override public function get localRect():Rectangle {
			var rcSuper:Rectangle = super.localRect;
			if (rcSuper && rcSuper.width != 0 && rcSuper.height != 0 || !(cWidth || cHeight))
				return rcSuper;

			// Return the default local rect
			return new Rectangle(x, y, unscaledWidth, unscaledHeight);
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

		override protected function SetUnscaledSize(cx:Number, cy:Number): void {
			unscaledWidth = cx;
			unscaledHeight = cy;
		}
		
		public function set image1(s:String): void {
			_strImage1 = s;
			Invalidate();
		}	
			
		public function get image1(): String {
			return _strImage1;
		}
		
		public function set image2(s:String): void {
			_strImage2 = s;
			Invalidate();
		}	
			
		public function get image2(): String {
			return _strImage2;
		}
		
		public function set image3(s:String): void {
			_strImage3 = s;
			Invalidate();
		}	
			
		public function get image3(): String {
			return _strImage3;
		}
		

		override protected function Redraw(): void {
			createThumb();
		}
		
		protected function createThumb(): void {
			if (null == _gtv) {
				_gtv = new GalleryThumbView();
			}

			this.status = DocumentStatus.Loading;
			
			_gtv.image1 = image1;
			_gtv.image2 = image2;
			_gtv.image3 = image3;
			_gtv.LoadImages( _OnLoadImages );
		}
		
		private function _OnLoadImages(oSource:Object) : void {
			if (content != _gtv) {
				SetUnscaledSize(_gtv.width, _gtv.height);
				
				var nScale:Number = Math.min( this.unscaledWidth / _gtv.width, this.unscaledHeight / _gtv.height );
				_gtv.scaleX = nScale;
				_gtv.scaleY = nScale;
				content = _gtv;
				if (content) SizeNewContent(content);
			}
			this.status = DocumentStatus.Loaded;
		}
	}
}