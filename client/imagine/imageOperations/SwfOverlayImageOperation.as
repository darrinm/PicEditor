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
package imagine.imageOperations
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.geom.Matrix;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import imagine.ImageDocument;
	import imagine.serialization.SerializationInfo;
	
	import util.InternalSwfLoader;
	import util.VBitmapData;

	/*** SwfOverlayImageOperation draws an embeded swf on top of the image
	 ***/
	[RemoteClass]
	public class SwfOverlayImageOperation extends BlendImageOperation
	{
		[Embed(source='../../assets/swfs/overlays/polaroidframe.swf')]
		private static var s_polaroidFrame:Class;
		
		private static const kobOverlays:Object =
			{'polaroidFrame':
				{	'class':s_polaroidFrame,
					'dimensions': {}
				}
			};
		
		[Bindable] public var overlay:String = '';
		
		public function SwfOverlayImageOperation()
		{
			super();
		}
		
		// afnLoaders = [fnLoad(fnComplete:Function): void {}];
		// fnComplete(): void {}
		public static function GetInternalLoaders(afnLoaders:Array): void {
			for (var strOverlayKey:String in kobOverlays) {
				var isldr:InternalSwfLoader = new InternalSwfLoader(kobOverlays[strOverlayKey]);
				afnLoaders.push(isldr.Load);
			}
		}

		private static var _srzinfo:SerializationInfo = new SerializationInfo(
			['overlay']);
		
		public override function writeExternal(output:IDataOutput):void {
			super.writeExternal(output); // Always call the super class first
			output.writeObject(_srzinfo.GetSerializationValues(this));
		}
		
		public override function readExternal(input:IDataInput):void {
			super.readExternal(input); // Always call the super class first
			_srzinfo.SetSerializationValues(input.readObject(), this);
		}
		
		override protected function DeserializeSelf(xmlOp:XML): Boolean {
			_srzinfo.DeserializeValuesFromXml(xmlOp, this);
			return true;
		}
		
		override protected function SerializeSelf(): XML {
			var xmlOp:XML = <SwfOverlay/>
			_srzinfo.SerializeValuesToXml(xmlOp, this);
			return xmlOp;
		}
		
		public override function ApplyEffect(imgd:ImageDocument, bmdSrc:BitmapData, fDoObjects:Boolean, fUseCache:Boolean): BitmapData {
			if (!(overlay in kobOverlays)) {
				// Default beahvior (no overlay selected) is do nothing.
				return bmdSrc.clone();
			}
			var bmdNew:BitmapData = bmdSrc.clone();
			if (!bmdNew)
				return null;
			
			var obInfo:Object = kobOverlays[overlay];
			
			var dob:DisplayObject = obInfo.dob;
			var mat:Matrix = new Matrix();
			// UNDONE: Support different types of scaling

			// Stretch to fit.
			mat.scale(bmdNew.width / dob.width, bmdNew.height / dob.height);
			bmdNew.draw(dob, mat, null, null, null, true);
			return bmdNew;
		}
	}
}