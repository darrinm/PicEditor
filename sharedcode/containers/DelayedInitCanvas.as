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
package containers
{
	import mx.core.ComponentDescriptor;
	import mx.core.IFlexDisplayObject;
	import mx.core.mx_internal;

	use namespace mx_internal; // So we can set createdComponents

	public class DelayedInitCanvas extends CanvasPlus
	{
		private var _nInitStage:Number = 0;
		
		// change this in sub-classes as needed
		protected var _nNumStages:Number = 2;

		public function DelayedInitCanvas()
		{
			super();
		}
		
		// Call this to create the next stage
		public function createComponentsIfNeeded(): void {
			if (_nInitStage < _nNumStages) {
				createComponentsForNextStage();
			}
		}
		
		// Override in sub-classes
		protected function initStageForComponent(cd:ComponentDescriptor): Number {
			return 0;
		}
		
		// Override in sub-classes for post-init
		protected function OnAllStagesCreated(): void {
		}

		private function createComponentsForNextStage(fRecurse:Boolean=true): void {
			createComponentsForStage(_nInitStage, fRecurse);
			_nInitStage += 1;
			if (_nInitStage >= _nNumStages) {
				OnAllStagesCreated();
			}
		}

	    private function createComponentsForStage(nStage:Number, fRecurse:Boolean=true):void
	    {
	        var n:int = childDescriptors ? childDescriptors.length : 0;
	        for (var i:int = 0; i < n; i++)
	        {
	        	var nTargetStage:Number = initStageForComponent(childDescriptors[i]);
	        	var fCreate:Boolean = nTargetStage == _nInitStage || (nTargetStage >= _nNumStages && _nInitStage == (_nNumStages - 1));
	        	if (fCreate) {
		            var component:IFlexDisplayObject =
		                createComponentFromDescriptor(childDescriptors[i], fRecurse);
		           
		            createdComponents.push(component);
	        	}
	        }
	    }
		
	    override public function createComponentsFromDescriptors(fRecurse:Boolean = true):void
	    {
	    	_nInitStage = 0;
	        createdComponents = [];
	
			createComponentsForNextStage(fRecurse);
			processedDescriptors = true;
	    }
	}
}