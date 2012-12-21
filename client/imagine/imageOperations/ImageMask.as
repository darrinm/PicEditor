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
	import com.adobe.utils.StringUtil;
	
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import imagine.imageOperations.paintMask.DoodleStrokes;
	import imagine.imageOperations.paintMask.GlitterStrokes;
	import imagine.imageOperations.paintMask.OperationStrokes;
	import imagine.imageOperations.paintMask.PaintPlusImageMask;
	import imagine.serialization.SRectangle;
	
	[RemoteClass]
	public class ImageMask extends EventDispatcher implements IExternalizable
	{
		protected var _rcBounds:SRectangle;
		private var _fInverted:Boolean = false;
		
		protected var _fSupportsChangeRegions:Boolean = false;
		
		private var _rcDirty:Rectangle = null;
		private var _obChangeKey:Object = null;
		
		public function ImageMask(rcBounds:Rectangle = null) {
			_rcBounds = SRectangle.FromRectangle(rcBounds);
			
			if (_rcBounds && (_rcBounds.width == 0 || _rcBounds.height== 0) )
				PicnikService.LogException( "Client Exception: ImageMask width/height set to zero: 1 " + getQualifiedClassName(this).substr(24), new Error( "zero height" ) );
		}
		
		public function get maskIsAlpha(): Boolean {
			return false; // our mask is alpha
		}
		
		public function get supportsChangeRegions(): Boolean {
			return _fSupportsChangeRegions;
		}
		
		// Returns null if not supported
		public function GetKeyForCurrentState(): Object {
			if (!_fSupportsChangeRegions) return null;
			_obChangeKey = new Object();
			_rcDirty = new Rectangle(0,0,0,0);
			return _obChangeKey;
		}
		
		// Returns null if not supported
		// Returns empty rect if no changes
		public function GetChangesFromState(obState:Object): Rectangle {
			if (!_fSupportsChangeRegions || (_obChangeKey != obState) || !_rcDirty)
				return new Rectangle(0,0,width,height);
			else
				return _rcDirty;
		}
		
		protected function MarkAsDirty(rcDirty:Rectangle): void {
			if (!_fSupportsChangeRegions) return;
			if (!_rcDirty) _rcDirty = rcDirty.clone();
			else _rcDirty = _rcDirty.union(rcDirty);
		}
		
		public function Serialize(): XML {
			var strClassName:String = getQualifiedClassName(this);
			// imageOperations and paintMasks were relocated to imagine 03/17/2011
			// This keeps the serialized format of masks unchanged by the repackaging.
			if (strClassName.indexOf("imagine.") == 0)
				strClassName = strClassName.slice(8);
			if (strClassName.indexOf('.') > -1) {
				strClassName = strClassName.replace('::', '.');
			} else {
				strClassName = strClassName.substr(17); // Lop off "imageOperations."
			}
			var xml:XML = <{strClassName} x={_rcBounds.x} y={_rcBounds.y} width={_rcBounds.width} height={_rcBounds.height} inverted={_fInverted}/>
			return xml;
		}
		
		public function writeExternal(output:IDataOutput):void {
			var obMask:Object = {};
			obMask.bounds = _rcBounds;
			obMask.inverted = _fInverted;
			output.writeObject(obMask);
		}
		
		public function readExternal(input:IDataInput):void {
			var obMask:Object = input.readObject();
			_rcBounds = obMask.bounds;
			_fInverted = obMask.inverted;
		}
		
		static public function IsImageMask(xmlOpChild:XML): Boolean {
			return StringUtil.endsWith(xmlOpChild.name(), "ImageMask");
		}

		// Returns NULL on failure.
		public static function ImageMaskFromXML(xml:XML): ImageMask {
			var msk1:BitmapImageMask;
			var msk2:CircularGradientImageMask;
			var msk3:PaintImageMask;
			var msk4:TiledImageMask;
			var msk5:HToneTiledImageMask;
			var msk6:PaintPlusImageMask;
			var msk7:DoodleStrokes;
			var msk8:OperationStrokes;
			var msk9:LightBulbishTiledImageMask;
			var msk10:FlatCircleTiledImageMask;
			var msk11:CirclesTiledImageMask;
			var msk12:GlitterStrokes;
			var msk13:ShapeImageMask;
			var msk14:SVGGradientImageMask;
			
			var strMaskClassName:String = xml.name();
			if (strMaskClassName == "ImageMask") strMaskClassName = "BitmapImageMask";
			// imageOperations and paintMasks were relocated to imagine 03/17/2011
			if (strMaskClassName.indexOf("imageOperations") == 0)
				strMaskClassName = "imagine." + strMaskClassName;
			var nLastDot:Number = strMaskClassName.lastIndexOf('.');
			if (nLastDot > -1) {
				strMaskClassName = strMaskClassName.substr(0, nLastDot) + "::" + strMaskClassName.substr(nLastDot+1);
			} else {
				strMaskClassName = "imagine.imageOperations::" + strMaskClassName;
			}

			var clsImageMask:Class;
			try {
				clsImageMask = getDefinitionByName(strMaskClassName) as Class;
			} catch (err:ReferenceError) {
				Debug.Assert(false, "Unknown ImageMask " + strMaskClassName);
				return null;
			}
			var msk:ImageMask = new clsImageMask();
			if (!msk.Deserialize(xml))
				return null;
			return msk;
		}

		public function Deserialize(xmlOp:XML): Boolean {
			_rcBounds = new SRectangle();
			Debug.Assert(xmlOp.@x, "ImageMask x argument missing");
			_rcBounds.x = Number(xmlOp.@x);
			Debug.Assert(xmlOp.@y, "ImageMask y argument missing");
			_rcBounds.y = Number(xmlOp.@y);
			Debug.Assert(xmlOp.@width, "ImageMask width argument missing");
			_rcBounds.width = Number(xmlOp.@width);
			Debug.Assert(xmlOp.@height, "ImageMask height argument missing");
			_rcBounds.height = Number(xmlOp.@height);
			_fInverted = xmlOp.@inverted == "true";
			
			if (_rcBounds.width == 0 || _rcBounds.height== 0 )
				PicnikService.LogException( "Client Exception: ImageMask.height set to zero: 2 " + getQualifiedClassName(this).substr(24), new Error( "zero height" ) );
			
			return true;
		}

		// If inverted, BlendImageOperation will apply the masked Dst to the Src
		// rather than the usual masked Src to Dst.
		[Bindable]
		public function get inverted(): Boolean {
			return _fInverted;
		}

		public function set inverted(fInverted:Boolean): void {
			_fInverted = fInverted;
		}

		// This is the total area of the image effected		
		public function get Bounds(): Rectangle {
			return _rcBounds;
		}
		
		// Optional - may return null (use Bounds)
		// If this is non-null, it represents the area of the
		// image for which the alpha blending is < 1.
		// It also corresponds to the actual bitmap returned
		public function get AlphaBounds(): Rectangle {
			return null; // Default is the entire area
		}
		
		public function get nOuterAlpha():Number {
			return 0;
		}


		public function set Bounds(rcBounds:Rectangle): void {
			_rcBounds = SRectangle.FromRectangle(rcBounds);
			if (_rcBounds.width == 0 || _rcBounds.height== 0 )
				PicnikService.LogException( "Client Exception: ImageMask width/height set to zero: 3 " + getQualifiedClassName(this).substr(24), new Error( "zero height" ) );
		}
		
		public function set width(nWidth:Number): void {
			if (nWidth == 0)
				PicnikService.LogException( "Client Exception: ImageMask width/height set to zero: 4 " + getQualifiedClassName(this).substr(24), new Error( "zero height" ) );
			if (_rcBounds == null) _rcBounds = new SRectangle();
			_rcBounds.width = nWidth;
		}
		
		public function set height(nHeight:Number): void {
			if (nHeight == 0)
				PicnikService.LogException( "Client Exception: ImageMask width/height set to zer: 5 " + getQualifiedClassName(this).substr(24), new Error( "zero height" ) );
			if (_rcBounds == null) _rcBounds = new SRectangle();
			_rcBounds.height = nHeight;
		}
		
		public function get width(): Number {
			return _rcBounds.width;
		}

		public function get height(): Number {
			return _rcBounds.height;
		}
		
		// Top left point impacted by the mask (Bounds, not AlphaBounds)
		public function get destPoint(): Point {
			return _rcBounds.topLeft;
		}
		
		public function Mask(bmdOrig:BitmapData): BitmapData {
			Debug.Assert(false, "getMask should be overriden by subclasses");
			return null;
		}
		
		public function Dispose(): void {
		}
		
		public function DoneDrawing(): void {
			// Override in sub-classes.
			// Called after a call to Mask()
			// Use to clean up memory, etc.
		}
	}
}
