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
	import imagine.documentObjects.Photo;
	
	public interface IAssetSource
	{
		// fnOnAssetCreated(err:Number, strError:String, fidCreated:String=null): void
		function CreateAsset(fnOnAssetCreated:Function, fGuaranteedFreshFids:Boolean = false): IPendingAsset; // null if we called the callback already
		
		// context is app-defined -- returns some random thing you probably passed in when creating this asset...
		// Probably the ImageProperties object
		function get context(): Object;	
		
		// A thumbnail url that should (hopefully) be instantly available
		function get thumbUrl(): String;
		
		// The source url from which we're pulling this asset. Might be null
		function get sourceUrl(): String;
	}
}