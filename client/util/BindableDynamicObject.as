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
package util {
	// http://jacwright.com/blog/54/actionscript-3-bindable-dynamic-objects/
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	
	[Bindable("propertyChange")]
	dynamic public class BindableDynamicObject extends Proxy implements IEventDispatcher
	{
	    protected var strings:Object;
	    protected var eventDispatcher:EventDispatcher;
	  
		public function BindableDynamicObject(obProps:Object=null) {
	        strings = {};
	        eventDispatcher = new EventDispatcher(this);

			if (obProps != null) {
				for (var strProp:String in obProps)
					this[strProp] = obProps[strProp];
			}
		}
	
		// allow some opportunity for objects to have aliases.
		// used primarily for ItemInfo
		protected function dictionaryAlias(name:*):*
		{
			return name;
		}
		
	    flash_proxy override function getProperty(name:*):*
	    {
	    	name = dictionaryAlias(name);
	        return getProperty_raw(name);
	    }
	    protected function getProperty_raw(name:*):*
	    {
	        return strings[name]; // || name;
	    }
	  
	    flash_proxy override function setProperty(name:*, value:*):void
	    {
	    	name = dictionaryAlias(name);
	    	setProperty_raw(name, value);
	    }
	    protected function setProperty_raw(name:*, value:*):void
	    {
	        var oldValue:* = strings[name];
	        strings[name] = value;
	        var kind:String = PropertyChangeEventKind.UPDATE;
	        dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, false, false, kind, name, oldValue, value, this));
	    }
	   
	    flash_proxy override function hasProperty(name:*): Boolean
	    {
	    	name = dictionaryAlias(name);
	    	return hasProperty_raw(name);
	    }
	    protected function hasProperty_raw(name:*): Boolean
	    {
	    	return (name in strings);
	    }
	   
	    flash_proxy override function deleteProperty(name:*): Boolean {
	    	name = dictionaryAlias(name);
	    	return deleteProperty_raw(name);
	    }
	    protected function deleteProperty_raw(name:*): Boolean {
	    	if (!hasProperty_raw(name))
	    		return false;
	        var oldValue:* = strings[name];
	    	delete strings[name];
	        dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, false, false,
	        		PropertyChangeEventKind.DELETE, name, oldValue, null, this));
	    	return true;
	    }

		protected var _item:Array;
		override flash_proxy function nextNameIndex (index:int):int {
			// initial call
			if (index == 0) {
				_item = new Array();
				for (var x:* in strings)
					_item.push(x);
			}
			
			return (index < _item.length) ? (index + 1) : 0
		}
		override flash_proxy function nextName(index:int):String {
			return _item[index - 1];
		}

		override flash_proxy function nextValue(index:int):* {
			return this[_item[index-1]];
		}
		
	    public function hasEventListener(type:String):Boolean
	    {
	        return eventDispatcher.hasEventListener(type);
	    }
	  
	    public function willTrigger(type:String):Boolean
	    {
	        return eventDispatcher.willTrigger(type);
	    }
	  
	    public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0.0, useWeakReference:Boolean=false):void
	    {
	        eventDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
	    }
	  
	    public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
	    {
	        eventDispatcher.removeEventListener(type, listener, useCapture);
	    }
	  
	    public function dispatchEvent(event:Event):Boolean
	    {
	        return eventDispatcher.dispatchEvent(event);
	    }

		// debugging use only
		public function get dictionary(): Object
		{
			return strings;
		}
    }
}
