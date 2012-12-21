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
package {
	// PicnikSkin.as helps us to manage some theme/skin functionality

	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.events.StyleEvent;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;

	public class PicnikSkin extends EventDispatcher {
		
		private var _fSkinLoaded:Boolean = false;

		// LoadSkin()
		//
		// strSkinUrl should point to a SWF file that was compiled from a CSS file:
		//		> cd c:\src\picnik\client\theme
		// 		> c:\src\picnik\flexsdk\bin\mxmlc awesome_skin.css
		//		> copy /y awesomeskin.swf ..\..\website\app
		//
		// Note that skin loading is asynchronous.  If you've got components that extract
		// information from styles instead of using the styles directly -- for example,
		// they make a call to PicnikBase.skin.GetColor() and then store the color
		// elsewhere -- then you'll need to monitor the value of skinId to be notified
		// when the skin has changed.  The easiest way to do it is to create a changewatcher:
		//		_chwSkinId = ChangeWatcher.watch( PicnikBase.app.skin, "skinId", OnSkinIdChanged );
		// ... and then in OnSkinIdChanged you should refresh your component so that it'll
		// use the new styling. 
		// ZoomViewBase.as uses this to update the colors of the links in the lite UI footer.
		//
		public function LoadSkin( strSkinUrl:String ) : void {
			if (!strSkinUrl || strSkinUrl.length == 0)
				return;
			strSkinUrl = PicnikBase.StaticUrl(strSkinUrl);
			var myEvent:IEventDispatcher = StyleManager.loadStyleDeclarations(strSkinUrl);
			myEvent.addEventListener( StyleEvent.COMPLETE, OnSkinLoaded )
		}

		// OnSkinLoaded()
		// this function dispatches a StyleEvent.COMPLETE event that other objects can
		// listen for if they need to re-calculate some stuff when the style changes.
		//		
		private function OnSkinLoaded( event:StyleEvent ): void {
			_fSkinLoaded = true;
			dispatchEvent(event);
		}
		
		// GetColor()
		// looks up the style declaration for the given CSS Selector and extracts
		// the value of the color field.
		//
		// strCSSSelector can specify a type, like "Button", or it can specify a
		// class name like ".defaultButton".  The period is important in the latter case.
		// This function will return the value that is specified for the
		// "color" attribute of the given object's current style.
		// If a color attribute can't be found, then black ("000000") is returned.
		//
		// If you're storing this value somewhere (for example, in the font tag of
		// some html text), then you should listen for StyleEvent.COMPLETE events
		// and update appropriately.
		public function GetColor( strCSSSelector:String ) : String {
			var strDefault:String = "000000";
			var cssDecl:CSSStyleDeclaration = StyleManager.getStyleDeclaration( strCSSSelector );
			if (!cssDecl)
				return strDefault;
				
			var obStyle:Object = cssDecl.getStyle( "color" );
			if (!obStyle || !StyleManager.isValidStyleValue(obStyle))
				return strDefault;
				
			var strStyle:String = "000000" + StyleManager.getColorName(obStyle).toString(16)
			return strStyle.substr(-6);
		} 			
	}
}
