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
package bridges.basket
{
	import bridges.BridgeItemBase;
	
	import controls.list.IDragImageFactory;
	import controls.list.PicnikTileList;
	import controls.thumbnails.Thumbnail;
	
	import imagine.documentObjects.DocumentStatus;
	
	import flash.events.ProgressEvent;
	
	import mx.containers.Canvas;
	import mx.controls.ProgressBar;
	import mx.core.IFlexDisplayObject;
	
	import util.IPendingFile;
	import util.ImagePropertiesUtil;
	import util.PendingFileWrapper;
	
	public class BasketItemBase extends BridgeItemBase implements IDragImageFactory
	{
		[Bindable] public var _thumb:Thumbnail;
		[Bindable] protected var _prgb:ProgressBar = null;
		[Bindable] public var _cnvOuter:Canvas;
		private var _pf:IPendingFile;
		
		private var _fNewThumb:Boolean = false;
		
		public function BasketItemBase()
		{
			super();
			_pf = new PendingFileWrapper();
		}
		
		protected function set pendingFile(pf:IPendingFile): void {
			if (_pf != pf) {
				Debug.Assert(pf != null);
				_fNewThumb = true;
				_pf.removeEventListener(ProgressEvent.PROGRESS, OnPendingProgress);
				_pf.removeEventListener("statusupdate", OnPendingStatusUpdate);
				_pf = pf;
				_pf.addEventListener(ProgressEvent.PROGRESS, OnPendingProgress);
				_pf.addEventListener("statusupdate", OnPendingStatusUpdate);
				RemoveProgressBar();
			}
			UpdateProgress();
		}

		private function OnPendingStatusUpdate(evt:Event): void {
			UpdateProgress();
		}
		
		private function OnPendingProgress(evt:Event): void {
			UpdateProgress();
		}
		
		public override function set data(value:Object):void {
			super.data = value;
//			Debug.Assert(value == null || value is ItemInfo, "BasketItemBase.set data() must take ItemInfo!");
			pendingFile = ImagePropertiesUtil.GetPendingFile(value/* as ItemInfo*/);
		}
		
		private function UpdateThumbnailUrl(): void {
			if (!_thumb) return;
			if (!_fNewThumb && _thumb.state == Thumbnail.BROKEN) return; // Failed to load the thumbnail. Don't try to reload
			if (_pf.status >= DocumentStatus.Loaded && (data as ImageProperties))
				_thumb.source = (data as ImageProperties).thumbnailurl;
			else if (_pf.status >= DocumentStatus.Loaded && (data as ItemInfo))
				_thumb.source = (data as ItemInfo).thumbnailurl;
			else if (_fNewThumb)
				_thumb.source = null;
			_fNewThumb = false;
		}
		
		private function RemoveProgressBar():void {
			if (_prgb) {
				_cnvOuter.removeChild(_prgb);
				_prgb = null;
			}
		}

		public function UpdateProgress(): void {
			var fShow:Boolean = false;
			if (_thumb && (_thumb.state != Thumbnail.LOADED)) {
				fShow = (_prgb != null) || (_pf.status == DocumentStatus.Loading && _pf.progress > 0);
			}
			if (fShow) {
				if (_prgb == null) {
					_prgb = new BasketProgressBar();
					_cnvOuter.addChild(_prgb);
					_prgb.validateNow();
				}
				_prgb.setProgress(_pf.progress * 100, 100);
			} else {
				RemoveProgressBar();
			}
			UpdateThumbnailUrl();
		}
		
		public function CreateDragImage(ptl:PicnikTileList): IFlexDisplayObject {
			var bdi:BasketDragImage = new BasketBase._clsBasketDragImage() as BasketDragImage;
			bdi.owner = ptl;
			
			bdi.setThumbnail(_thumb, _thumb.imagePos(), data);

			// Set some stuff, e.g. the source.
			return bdi;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			UpdateProgress();
		}
	}
}