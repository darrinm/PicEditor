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
package imagine.serialization
{
	import flash.geom.Rectangle;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	
	/***
	 * Externalizable Rectangle
	 ***/
	[RemoteClass]
	public class SRectangle extends Rectangle implements IExternalizable
	{
		public function SRectangle(x:Number=0, y:Number=0, width:Number=0, height:Number=0)
		{
			super(x, y, width, height);
		}
		
		/***
		 * Create a new SRectangle from an SRectangle.
		 * Instead of:
		 *    var rc:SRectangle = rcIn;
		 * You can use:
		 *    var rc:SRectangle = SRectangle.FromRectangle(rcIn);
		 ***/
		public static function FromRectangle(rc:Rectangle): SRectangle {
			if (rc is SRectangle)
				return rc as SRectangle;
			if (rc is Rectangle)
				return new SRectangle(rc.x, rc.y, rc.width, rc.height);
			return null;
		}
		
		public function writeExternal(output:IDataOutput):void
		{
			output.writeObject(x);
			output.writeObject(y);
			output.writeObject(width);
			output.writeObject(height);
		}
		
		public function readExternal(input:IDataInput):void
		{
			x = input.readObject();
			y = input.readObject();
			width = input.readObject();
			height = input.readObject();
		}
	}
}