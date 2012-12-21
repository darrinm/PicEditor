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
	import controls.ImageSprite;
	
	import imagine.documentObjects.DocumentObjectContainer;
	import imagine.documentObjects.DocumentObjectUtil;
	import imagine.documentObjects.DocumentStatus;
	import imagine.documentObjects.IDocumentObject;
	import imagine.documentObjects.IDocumentStatus;
	import imagine.documentObjects.PSWFLoader;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import mx.events.PropertyChangeEvent;
	import mx.resources.ResourceBundle;
	
	public class StatusViewObject extends ViewObject {
  		[ResourceBundle("StatusViewObject")] private var _rb:ResourceBundle;
		[Embed(source="/theme/pngs/broken_image.png")] public static var s_clsBrokenImage:Class;
		
		private var _dobStatus:DisplayObject;
		private var _sprProgress:Sprite;
		private var _tf:TextField;
		private var _imgsprPreview:ImageSprite;
		
		public function StatusViewObject(imgv:ImageView, dob:DisplayObject) {
			super();
			_imgv = imgv;
			target = dob;
			mouseEnabled = false;
			mouseChildren = false;
		}
		
		override protected function Listen(): void {
			super.Listen();
			if (_dob) UpdateStatus(IDocumentStatus(_dob).status);
		}
		
		override protected function OnTargetPropertyChange(evt:PropertyChangeEvent): void {
			super.OnTargetPropertyChange(evt);
			if (evt.property == "status")
				UpdateStatus(Number(evt.newValue));
			
			if (evt.property == "fractionLoaded")
				UpdateProgress(Number(evt.newValue));
		}
		
		private function UpdateProgress(nFractionLoaded:Number): void {
			if (_sprProgress == null)
				return;
			var rcTextBounds:Rectangle = _tf.getBounds(_tf);
			with (_sprProgress.graphics) {
				clear();
				lineStyle(3, 0xb2cc8f);
				moveTo(0, 0);
				
				// Because of the way drawing happens, usually the progress indicator
				// will be hidden before it hits 100%. Not very satisfying so we give
				// the indicator a 1.2x boost.
				lineTo(Math.min(rcTextBounds.width * nFractionLoaded * 1.2, rcTextBounds.width), 0);
			}					
		}
		
		private function UpdateStatus(nStatus:Number): void {
			// Only show status indicators for leaf nodes
			if (DocumentObjectContainer(target).childStatus < DocumentStatus.Loaded && DocumentObjectContainer(target).showChildStatus)
				return;
				
			if (_dobStatus != null) {
				// hide & destroy
				removeChild(_dobStatus);
				if (_imgsprPreview) removeChild(_imgsprPreview);
				_imgsprPreview = null;
				_dobStatus = null;
			}
				
			// Create if appropriate
			if (nStatus < DocumentStatus.Preview) {
				// UNDONE: this is a total hack. We really want to be able to use UIComponents here
				if (nStatus == DocumentStatus.Error) {
					_dobStatus = new s_clsBrokenImage();
				} else {
					var sprContainer:Sprite = new Sprite();
					_dobStatus = sprContainer;
					var tf:TextField = new TextField();
					_tf = tf;
					tf.text = Resource.getString("StatusViewObject", nStatus == DocumentStatus.Loading ? "loading" : "error");
					tf.autoSize = TextFieldAutoSize.LEFT;
					tf.antiAliasType = AntiAliasType.ADVANCED;
					tf.embedFonts = true;
					tf.setTextFormat(new TextFormat("trebuchetMS", 13, 0xffffff, true));
					sprContainer.addChild(tf);
					var rcTextBounds:Rectangle = tf.getBounds(tf);
					
					// Add the loading progress bar
					_sprProgress = new Sprite();
					sprContainer.addChild(_sprProgress);
					_sprProgress.x = tf.x;
					_sprProgress.y = tf.y + tf.height - 2;
					
					// Draw the surrounding rounded rectangle
					rcTextBounds.inflate(4, 1);
					with (sprContainer.graphics) {
						lineStyle(1, 0xb2cc8f);
						beginFill(0x79994c, 0.85);
						drawRoundRect(rcTextBounds.x, rcTextBounds.y, rcTextBounds.width, rcTextBounds.height, 8, 8);
						endFill();
					}
					
					if (_dob is PSWFLoader && nStatus == DocumentStatus.Loading) {
						var pswfldr:PSWFLoader = _dob as PSWFLoader;
						if (pswfldr.previewUrl) {
							_imgsprPreview = new ImageSprite();
							_imgsprPreview.source = pswfldr.previewUrl
							_imgsprPreview.width = pswfldr.previewWidth;
							_imgsprPreview.height = pswfldr.previewHeight;
							_imgsprPreview.rotation = DocumentObjectUtil.GetDocumentRotation(IDocumentObject(target));
							addChild(_imgsprPreview);
							_imgsprPreview.x = -(pswfldr.previewWidth / 2);
							_imgsprPreview.y = -(pswfldr.previewHeight / 2);
						}			
					}	
				}
				addChild(_dobStatus);
				PositionStatus();
			}
			InvalidateDisplayList();
		}
		
		// Position the child status component
		private function PositionStatus(): void {
			if (_dobStatus != null) {
				_dobStatus.x = -(_dobStatus.width / 2);
				_dobStatus.y = -(_dobStatus.height / 2);
			}
		}

		override public function UpdateDisplayList(): void {
//			super.UpdateDisplayList();
			InitializeFromDisplayObjectState();
			PositionStatus();
		}
	}
}
