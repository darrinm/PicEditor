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
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	
	import mx.controls.Image;

	public class ImageVer extends Image {

		protected var _oPendingSource:Object = null;

		protected function commitPendingSource(): void {
			if (!autoLoad && !content && visible) {
				this.load();
			}

			if (!_oPendingSource) {
				super.commitProperties();
				return;
			}
			
			SetExplicitSource(_oPendingSource);
		}

		override protected function commitProperties():void {
			commitPendingSource();
			super.commitProperties();
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
		
		protected function SetExplicitSource( value:Object ): void {
            loaderContext = new LoaderContext();
			loaderContext.applicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
			
			_oPendingSource = null;
			if (value is String) {
				value = PicnikBase.StaticUrl(value as String);
			}
			
			if (value)
				super.load(value);
			else
				super.source = value;
		}
	}
}
