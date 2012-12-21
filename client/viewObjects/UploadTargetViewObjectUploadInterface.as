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
package viewObjects {
	import bridges.mycomputer.UploadInterface;
	
	import imagine.documentObjects.FitMethod;
	import imagine.documentObjects.Photo;
	import imagine.documentObjects.Target;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import mx.core.UIComponent;
	
	import util.IAssetSource;
	import util.ImagePropertiesUtil;

	// TODO(darrinm): wouldn't a callback or Event be a better way to handle OnAddedNewFids?
	public class UploadTargetViewObjectUploadInterface extends UploadInterface {
		private var _tgt:Target;
		private var _imgv:ImageView;
		
		public function UploadTargetViewObjectUploadInterface(owner:UIComponent, tgt:Target, imgv:ImageView) {
			super(owner);
			_tgt = tgt;
			_imgv = imgv;
		}
		
		// For this interface we know aiinfPending will only have one element.
		override protected function OnAddedNewFids(aiinfPending:Array): void {
			if (_tgt.populated)
				_tgt.DestroyContents();
			
			var iinf:ItemInfo = aiinfPending[0] as ItemInfo;
			var imgp:ImageProperties = iinf.asImageProperties();
			var asrc:IAssetSource = ImagePropertiesUtil.GetAssetSource(imgp);
			var dob:DisplayObject = Photo.Create(_imgv.imageDocument, asrc, new Point(100, 100), new Point(0, 0),
					FitMethod.SNAP_TO_MIN_WIDTH_HEIGHT, _imgv.zoom, _tgt.name);
		}
	}
}
