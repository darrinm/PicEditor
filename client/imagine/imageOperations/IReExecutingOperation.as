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
package imagine.imageOperations
{
	import flash.display.BitmapData;
	import imagine.ImageDocument;
	
	/** IReExecutingOperation
	 * An operation should implement this if it wants to cache the result bitmap,
	 * and re-use it next time. This can be used simply to cut down on
	 * the overhead of creating a new bitmap or it can be used when we know what has changed
	 * and only want to update that area.
	 */
	public interface IReExecutingOperation
	{
		// Re-apply an effect. The source and dest were loaded form the
		function ReApplyEffect(imgd:ImageDocument, bmdSource:BitmapData,
				bmdPrevApplied:BitmapData, obPrevApplyParams:Object): void;
		
		// Get any params after applying (and re-applying) the effect
		// so we can use these next time we reapply.
		function GetPrevApplyParams(): Object;
	}
}