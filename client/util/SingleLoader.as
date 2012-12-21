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
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;

	// SingleLoader behaves like a loader, but limits requests to the same URL so that
	// we won't have duplicate outstanding calls.  This prevents us from flooding the server
	// with requests for the same image (due to an IE bug).

	public class SingleLoader extends Loader  {
        private var _aCallbacks:Array = [];
        private var _strRequestHash:String = null;

		// this static element keeps track of loading-in-progress modules
		// so that we only try to load a module once at a time.
		static private var s_obPendingLoadCallbacks:Object = {};

		public function SingleLoader() {
			this.contentLoaderInfo.addEventListener(Event.COMPLETE, OnComplete);
		}
		
	    override public function load(request:URLRequest, context:LoaderContext=null):void {
	    	if (null == request || request.method != "GET") {
	    		// always let NULL urls pass through
	    		// always let POSTs pass through	    	
	    		super.load(request,context);
	    		return;
	    	}
	   
	    	_strRequestHash = request.url;
	   
	    	if (!(_strRequestHash in SingleLoader.s_obPendingLoadCallbacks)) {
	    		// this is the first time we've seen this URL. 
	    		// Set it up as a pending callback, and then set the URL to kick things off
	    		SingleLoader.s_obPendingLoadCallbacks[_strRequestHash] = { loaded: false, callbacks: [] };
	    		super.load(request,context);
	    		return;
	    	}
	    	
	    	var oPending:Object = SingleLoader.s_obPendingLoadCallbacks[_strRequestHash];	    	
	    	if (oPending.loaded) {
	    		// this object has been successfully loaded, so set the URL
	    		super.load(request,context);
	    		return;
	    	} else {
	    		// somebody else is already loading this object.  Queue up our callback
	    		oPending.callbacks.push( {loader:this, request:request, context:context} );	
	    		return;    		
	    	}
	    }

		private function OnComplete(evt:Event): void {
			NotifyPending( true, function(loader:Loader, request:URLRequest, context:LoaderContext):void {
	    			if (loader) loader.load(request,context);
	  			});
		}
	   
		private function NotifyPending( fLoaded:Boolean, fnToDo:Function ):void {
	    	var oPending:Object = SingleLoader.s_obPendingLoadCallbacks[_strRequestHash];	  
	    	if (oPending) {
	    		// we're ready (or error'd) with this module, so tell everyone who's waiting on it and then clear the queue.
	    		// to prevent re-entry and infinite looping, we need to clear out the callbacks before calling them.
	    		oPending.loaded = fLoaded;
	    		var aToCallback:Array = oPending.callbacks;
	    		oPending.callbacks = [];
	    		
	    		for each (var oLoaderInfo:Object in aToCallback) {
	    			fnToDo( oLoaderInfo.loader,oLoaderInfo.request,oLoaderInfo.context  );
	    		}
	    	}
	 	} 		   
    }
}
