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

	public interface IImageList extends IEventDispatcher
	{
		function Init(issm:ISlideShowManager, fSamples:Boolean = false): void;

		// Adjusts CurrentImage index and loads the image
		function GetNextImage(OnLoaded:Function):Boolean;
		function GetPrevImage(OnLoaded:Function):Boolean;
		
		// OnLoaded : called when loaded
		// nPos: pos of image to load, -1 loads the current image
		// fMakeCurrent: make the image specified in {nPos} the current image
		// fPrioritize: cancel other in-progress downloads to make this one go faster
		function GetImage(OnLoaded:Function, nPos:int=-1, fMakeCurrent:Boolean=false, fPrioritize:Boolean=false):Boolean;
				
		function Resize(w:int, h:int):void;
		
		// Set index of currently displayed image
		// Set to -1 to set to last image
		// Currently, however, this does not cause a redisplay, but just sets
		// what image it *thinks* it's currently displaying.  When it's time
		// to advance the image, it would base it off this value.
		function set CurrentImage(pos:int):void;	// -1: end
		
		// return index of currently displayed image
		function get CurrentImage():int;
		
		// Set id of currently displayed image
		function set CurrentImageId(id:String):void;	// -1: end
		
		// return id of currently displayed image
		function get CurrentImageId():String;
		
		// how many images do we have?
		//	if no images in list, how many sample images do we have?
		function get ImageCount():int;
		
		// how many images do we have?
		function get ActualImageCount():int;
		
		// return the image with all its' properties
		function GetImageInfo(pos:int):IImage;
		
		// return the image with all its' properties
		function GetImageInfoById(id:String):IImage;
		
		// returns an image's position
		function GetImagePosition(id:String):int;
		
		// insert image (url only) before position pos.  pos=-1: append to end
		// if ii is an IImage, it'll be inserted.  Otherwise,
		// a new IImage will be created and the object's properties copied to it
		function InsertImage(ii:Object, pos:int=-1):int;

		// delete an image with the given id
		// return true/false as to whether it was successful
		function DeleteImage(id:String):Boolean;
		
		// delete all images in image list
		function DeleteAllImages():void;

		// set image property (currently just one of 'url', 'caption')
		// returns old value or null if this is a new assignment
		// also returns null if pos is out of range or key or value are null
		function SetProperty(id:String, key:String, val:String):String;
		
		// returns image property set by SetProperty()
		// returns null if no value assigned
		// also returns null if pos is out of range or key is null
		function GetProperty(id:String, key:String):String;
		
		// move image at posFrom to just before posTo
		// returns boolean success flag
		function MoveImage(id:String, posTo:int):Boolean;
		
		// pops a dialog box letting the user save an image to the local computer
		// funcCallback looks like function(evt:Event):void
		// funcCallback will receive progress, select, cancel, error, etc., AND complete events
		function DownloadImage(pos:int, funcCallback:Function=null):void;
	}
}