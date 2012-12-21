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
	import flash.events.IEventDispatcher;
	import flash.display.Bitmap;
		
	public interface IImage2 extends IEventDispatcher
	{
		/*
		function Image():void;
		*/
		function Init( issm:ISlideShowManager ):void;
		function GetUrl( nMaxWidth:int=-1,nMaxHeight:int=-1 ):String;
		function GetThumbUrl( nMaxWidth:int=-1,nMaxHeight:int=-1 ):String;
		function SetProperty(strKey:String, oVal:String):String;
		function GetProperty(strKey:String):String;
		function get oProps():Object;
		function IsLoading():Boolean;
		function IsLoaded():Boolean;
		function IsThumbLoaded():Boolean;
		function get id():String;
		function Unload():void;
		function Load(OnLoaded:Function, nMaxWidth:int=-1, nMaxHeight:int=-1 ):void
		function CancelLoad():void;
		function LoadThumb(OnLoaded:Function, nMaxWidth:int=-1, nMaxHeight:int=-1):void
		function Resize(nWidth:int, nHeight:int):void
		function ResizeThumb(nWidth:int, nHeight:int):void
		function get bmpImage():Bitmap;
		function get bmpThumb():Bitmap;
	}
}