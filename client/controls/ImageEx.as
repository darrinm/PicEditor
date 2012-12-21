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
	import flash.events.Event;
	
	import util.BundleDirs;
	import util.ImageBundleManager;

	public class ImageEx extends ImageVer {

		[Bindable] public var bundled:Boolean = false;
		[Bindable] public var nobundle:Boolean = false;

		private var _fExplicitBundle:Boolean = false;
		private var _strBundle:String = null;
		private var _fExplicitImageId:Boolean = false;
		private var _strImageId:String = null;
		//private var _loader:SingleLoader = null;
		
		// bundle will be automatically determined from the path if you don't set it
		[Bindable] public function get bundle():String {
			return _strBundle;
		}
		
		public function set bundle( s:String ):void {
			_strBundle = s;
			_fExplicitBundle = (s != null);
		}
		
		// bundle will be automatically determined from the filename if you don't set it
		[Bindable] public function get imageId():String {
			return _strImageId;
		}
		
		public function set imageId( s:String ):void {
			_strImageId = s;
			_fExplicitImageId = (s != null);
		}		
			
		override protected function commitPendingSource():void {
			if (!autoLoad && !content && visible) {
				this.load();
			}

			if (!_oPendingSource) {
				return;
			}
			
			// we've been given a string, and we'll assume it's a URL.
			var strValue:String = _oPendingSource as String;
			
			if (nobundle) {
				bundled = false;
			} else if (strValue != null && BundleDirFromSource(strValue).substr(3) in BundleDirs.kobBundledDirs) {
				bundled = true; // Always bundle these
			}
			
			if (strValue == null || !bundled) {
				SetExplicitSource(_oPendingSource);
				return;
			}

			// UNDONE: turning off usage of the singleloader for now -- doesn't
			// seem to be having an impact on the loading.
//			// if we're not bundled, then use the SingleLoader class to load
//			// the asset. This way, we only issue one call even when loading the
//			// same image many times.
//			if (!bundled) {
//				var loader:SingleLoader = new SingleLoader();
//				var fnOnComplete:Function = function( evt:Event ):void {
//						loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, fnOnComplete );
//						SetExplicitSource( loader.content );
//					};
//				loader.contentLoaderInfo.addEventListener( Event.COMPLETE, fnOnComplete );
//				loader.load( new URLRequest(strValue) );
//				return;
//			}
//						
			if (!_fExplicitBundle) {
				_strBundle = BundleFromSource(strValue);
			}
			if (!_fExplicitImageId) {
				_strImageId = ImageIdFromSource(strValue);
			}
			var obThis:Object = this;
			ImageBundleManager.GetImageClass( _strImageId, _strBundle, function( clsImage:Class ):void {
					if (clsImage) {
						obThis.SetExplicitSource(clsImage);
					} else {
						// no image class was found, so just pass the string along
						obThis.SetExplicitSource(strValue);
					}
					dispatchEvent( new Event(Event.COMPLETE) );
				});
		}

		override public function set source(value:Object):void {
			if (value == null) {
				SetExplicitSource(value);
			} else {
				if (value is String) {
					var strValue:String = value as String;
					if (strValue.indexOf("../") == 0 && PicnikBase.isDesktop)
						value = strValue.slice(2);
				}
				_oPendingSource = value;
				invalidateProperties();
			}
		}
		
		public override function set visible(value:Boolean): void {
			super.visible = value;
			invalidateProperties();
		}
		
		private function BundleDirFromSource( strSource:String ): String {
			if (strSource == null)
				return null;
			if (strSource.indexOf(PicnikBase.CDNRoot) == 0)
				strSource = strSource.slice(PicnikBase.CDNRoot.length);
			if (strSource.indexOf("/") == -1)
				strSource = "/" + strSource;
			if (strSource.indexOf("..") != 0)
				strSource = ".." + strSource;
			return strSource.substring(0,strSource.lastIndexOf("/"));
		}

		private function BundleFromSource( strSource:String ): String {
			var strBundle:String = BundleDirFromSource(strSource);
			var strBundleKey:String = strBundle.substr(3);
			if (strBundleKey in BundleDirs.kobBundledDirs)
				strBundle = "../" + BundleDirs.kobBundledDirs[strBundleKey];
			else {
				trace("Unknown bundle?!?: " +strSource + ", " + strBundleKey + ", " + strBundle);
				// Ignore the error
				// throw new Error("Unknown bundle?!?: " +strSource + ", " + strBundleKey + ", " + strBundle);
			}
			strBundle += "/Bundle.swf";
			return PicnikBase.StaticUrl(strBundle);
		}
		
		private function ImageIdFromSource( strSource:String ): String {
			if (strSource.indexOf("/") == -1) strSource = "/" + strSource;			
			var strImageId:String = strSource.substring(strSource.lastIndexOf("/") + 1);
			strImageId = "cls" + strImageId.replace( /[\.\-\\\/ ]/g, "_" );
			if (strImageId.indexOf('?') > -1)
				strImageId = strImageId.substr(0,strImageId.indexOf('?'));
			return strImageId;
		}		
	}
}
