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
package util.collection
{
	import mx.collections.ArrayCollection;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;

	public class ArrayCollectionPlus extends ArrayCollection
	{
	    private var resourceManager:IResourceManager =
                                    ResourceManager.getInstance();

		public function ArrayCollectionPlus(source:Array=null)
		{
			super(source);
		}
		
	    override public function set source(s:Array): void
	    {
	        list = new ArrayListPlus(s);
	    }

	    // Based on ArrayCollection.removeItemAt()
	    public function moveItem(iFrom:int, iTo:int): void
	    {
	    	var iOutOfBounds:Number = NaN;
	        if (iFrom < 0 || iFrom >= length)
	        	iOutOfBounds = iFrom;
	        else if (iTo < 0 || iTo >= length)
	        	iOutOfBounds = iTo;
	        if (!isNaN(iOutOfBounds))
	            throw new RangeError(resourceManager.getString(
	                "collections", "outOfBounds", [ iOutOfBounds ]));
	
	        ArrayListPlus(list).moveItem(iFrom, iTo);
	    }
	}
}