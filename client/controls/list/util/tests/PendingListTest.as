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
package controls.list.util.tests
{
	import controls.list.ITileListItem;
	
	import flexunit.framework.*;

	public class PendingListTest extends TestCase
	{
		public static function RunAllTests(): void {
			var tpl:PendingListTest = new PendingListTest();
			tpl.testEmpty();
			tpl.testAddOne();
			tpl.testAddAndRemoveSome();
			tpl.testUpdateIndices();
			tpl.testLargeDelete();
			tpl.testDeleteAll();
		}
		
		public function PendingListTest()
		{
			super();
		}
		
		public function testEmpty(): void {
			var plts:PendingListTestState = new PendingListTestState();
			
			// Do nothing
			
			plts.Validate();
		}
		
		public function testAddOne(): void {
			var plts:PendingListTestState = new PendingListTestState();
			
			// Add one item
			var tli:ITileListItem = plts.Create(1);
			plts.pl.Enqueue(tli, "1");
			plts.Validate(true);
		}
		
		public function testAddAndRemoveSome(): void {
			var plts:PendingListTestState = new PendingListTestState();
			
			// Add one item
			plts.pl.Enqueue(plts.Create(1), "1");
			plts.pl.Enqueue(plts.Create(2), "2");
			plts.pl.Enqueue(plts.Create(3), "3");
			
			plts.aobFree.push(plts.pl.Dequeue());
			plts.pl.Enqueue(plts.Create(4), "4");
			plts.aobFree.push(plts.pl.Fetch("2"));
			plts.pl.Enqueue(plts.Create(5), "5");
			plts.pl.RemoveIfFound("9", plts.aobFree);
			plts.pl.RemoveIfFound("1", plts.aobFree);
			
			plts.Validate(true);
		}

		public function testLargeDelete(): void {
			var plts:PendingListTestState = new PendingListTestState();
			for (var i:Number = 1; i < 30; i++) {
				plts.pl.Enqueue(plts.Create(i), i.toString());
				plts.pl.Validate();
			}
			
			plts.pl.UpdateIndices(10, -100, plts.aobFree);
			plts.Validate(true);
		}
			
		public function testDeleteAll(): void {
			var i:Number;
			var plts:PendingListTestState = new PendingListTestState();
			for (i = 1; i < 30; i++) {
				plts.pl.Enqueue(plts.Create(i), i.toString());
				plts.pl.Validate();
			}
			
			plts.pl.UpdateIndices(0, -100, plts.aobFree);
			plts.Validate(true);
			
			for (i = 1; i < 30; i++) {
				plts.pl.Enqueue(plts.Create(i), i.toString());
				plts.pl.UpdateIndices(0,-10, plts.aobFree);
				plts.pl.Validate();
			}
			
		}
			

		public function testUpdateIndices(): void {
			var plts:PendingListTestState = new PendingListTestState();
			for (var i:Number = 1; i < 30; i++) {
				plts.pl.Enqueue(plts.Create(i), i.toString());
				plts.pl.Validate();
			}
			
			plts.pl.UpdateIndices(4,3,plts.aobFree);
			plts.Validate();
			
			plts.pl.UpdateIndices(10,-3,plts.aobFree);
			plts.Validate();
			
			plts.pl.UpdateIndices(0,1,plts.aobFree);
			plts.Validate();
			
			plts.pl.UpdateIndices(1,0,plts.aobFree);
			plts.Validate();
			
			plts.pl.UpdateIndices(1,0,plts.aobFree, true);
			plts.Validate();
			
			plts.pl.UpdateIndices(1,4,plts.aobFree, true);
			plts.Validate();
			
			plts.pl.UpdateIndices(100,4,plts.aobFree, true);
			plts.Validate();
			
			plts.pl.UpdateIndices(100,-4,plts.aobFree);
			plts.Validate();
			
			plts.pl.UpdateIndices(100,4,plts.aobFree);
			plts.Validate();
			
			
			plts.Validate(true);
		}
		
	}
}
