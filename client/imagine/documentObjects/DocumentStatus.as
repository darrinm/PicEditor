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
package imagine.documentObjects
{
	public class DocumentStatus
	{
		// Numbers in decending priority order.
		// Thus, Aggregate(status1, status2) == Math.min(status1, status2)
		public static const Error:Number = -1;
		public static const Loading:Number = 0;
		// public static const Preview:Number = 100;
		public static const Preview:Number = 1000;
		public static const Loaded:Number = 10000;
		// Status-checkers know Static means the object and all its children don't need to be monitored
		// for status display purposes (i.e. with a StatusViewObject)
		public static const Static:Number = 100000;

		// Given a set of statuses which apply to an object, returns
		// the overall status (usually the lowest status)
		// Error is strongest, followed by Loading, then loaded.
		public static function Aggregate(... args:Array): Number {
			return AggregateArray(args);
		}
		
		public static function AggregateArray(args:Array): Number {
			return Math.min.apply(null, args);
		}
	}
}