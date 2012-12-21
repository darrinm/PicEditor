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
package creativeTools
{
	public interface ICreativeTool
	{
		function get active(): Boolean;
		function OnActivate(ctrlPrev:ICreativeTool): void;
		function OnDeactivate(ctrlNext:ICreativeTool): void;
		function Deselect(): Boolean; // returns true if it was selected
		function HelpStateChange(fVisible:Boolean): void; // returns true if it was selected
		function PerformActionIfSafe(act:IAction): void;
		function PerformAction(act:IAction): void;
	}
}
