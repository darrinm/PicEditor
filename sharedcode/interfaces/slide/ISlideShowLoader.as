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
	import flash.display.Sprite;
	import flash.events.IEventDispatcher;
	
	public interface ISlideShowLoader extends ISlideShowManager {
		function SetServerRoot(strServerRoot:String): void;
		function SetImageUrlOverride(fn:Function): void;
		function SetUserActionOverride(fn:Function): void;
		function SetSlideShowId(strId:String): void;
		
		function SetControlVisible( strControl:String, fVisible:Boolean ): void;
		
		function LoadSlideShowFromData(strXML:String=null): void;
		function LoadSlideShowFromId(strSSId:String, OnLoaded:Function=null): void;
		function LoadSlideShowFromUrl(strUrl:String, OnLoaded:Function=null): void;
		function UnloadSlideShow(): void;

		function Resize(w:Number, h:Number): void;
		function SetActive(active:Boolean): void;

		function GetProperties():Object;
		function SetProperties(oProps:Object):void;
		function GetProperty(strProp:String):String;
		function SetProperty(strProp:String, strValue:String):Boolean;
	}
}