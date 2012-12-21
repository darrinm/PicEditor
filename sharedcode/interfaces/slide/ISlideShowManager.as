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
	import events.SlideShowAction;
	import flash.display.Sprite;
	import flash.events.IEventDispatcher;
	import flash.geom.Rectangle;
	
	public interface ISlideShowManager{
		function get slideshow():ISlideShow;
		function get imagelist():IImageList;				
		function BuildImageUrl( iimg:IImage, nMaxWidth:int=-1, nMaxHeight:int=-1 ): String;		
		function BuildPicnikApiUrl( oArgs:Object ): String;
		function PositionControlBar( nPosition:int ): Rectangle;
		function OnUserAction( action:SlideShowAction ): void;
	}
}