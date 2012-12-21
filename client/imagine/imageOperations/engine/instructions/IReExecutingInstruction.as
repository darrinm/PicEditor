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
package imagine.imageOperations.engine.instructions
{
	/** IReExecutingInstruction
	 * This instruction has a ReExecute() function which
	 * should be called whenever it is restored from the cache
	 * rather than skipping to the next instruction.
	 *
	 * Currently used by masks which use dirty regions
	 * and want to restore from cache then re-mask the dirty region.
	 *
	 * Typically, these instructions will add extra cache params and
	 * use these params to determine what needs to be updated.
	 */
	import imagine.imageOperations.engine.OpStateMachine;
	
	public interface IReExecutingInstruction
	{
		function ReExecute(opsmc:OpStateMachine, obExtraCacheParams:Object): void;
		function GetExtraCacheParams(): Object;
	}
}