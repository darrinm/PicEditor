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
package util
{
	import events.NavigationEvent;
	
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	
	// Navigation utilities
	public class Navigation
	{
		public static function NavigateToFlashUpgrade(strSource:String="unspecified"): void {
			Util.UrchinLogReport("/fpupgrade/" + strSource);
			PicnikBase.app.NavigateToURLWithIframeBreakout("http://www.adobe.com/go/getflashplayer", "_blank", true);
			
			/*
			// UNDONE: no good for Flickr-lite. Who knows what swfobject, ids, etc they are using
			ExternalInterface.call("expressInstall",
					{ id: "flashcontent_replace", altContentId: "flashcontent_replace", width: "100%" , height: "100%",
					expressInstall: "expressinstall.swf" });
			*/
		}
		
		public static function DispatchNavEvent(ed:EventDispatcher, strTab:String, strSubTab:String, strSampleImage:String, obExtra:Object=null): void {
			ed.dispatchEvent(new NavigationEvent(strTab, strSubTab, strSampleImage, obExtra));
		}
		
		public static function GoToEvent(evt:NavigationEvent): void {
			if (evt.tab != null)
				PicnikBase.app.NavigateTo(evt.tab, evt.subTab);
		}
	}
}