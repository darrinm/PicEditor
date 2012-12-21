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
	import flash.geom.Point;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;

	/***
	 * Externalizable Point
	 ***/
	[RemoteClass]
	public class SPoint extends Point implements IExternalizable
	{
		public function SPoint(x:Number=0, y:Number=0)
		{
			super(x, y);
		}
		
		public function writeExternal(output:IDataOutput):void
		{
			output.writeObject(x);
			output.writeObject(y);
		}
		
		public function readExternal(input:IDataInput):void
		{
			x = input.readObject();
			y = input.readObject();
		}
	}
}