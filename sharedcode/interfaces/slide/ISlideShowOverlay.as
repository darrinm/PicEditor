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
package interfaces.slide
{
	import flash.display.DisplayObjectContainer;
	import interfaces.slide.ISlideShowManager
		
	public interface ISlideShowOverlay
	{
		function Init(issm:ISlideShowManager, docParent:DisplayObjectContainer, fnOnReady:Function): void;
		function Unload():void;
		
		function GetProperties():Object;
		function SetProperties(oProps:Object):void;
		function GetProperty(strProp:String):String;
		function SetProperty(strProp:String, strValue:String):Boolean;

		function Resize(nWidth:Number, nHeight:Number):void;
	}
}