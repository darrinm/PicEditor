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
package util.tests {
import flexunit.framework.*;
import util.Unpickler;

public class UnpicklerTest extends TestCase {

  public function testUnpicklingWithChecksum(): void {
    var input:String = "c69c99bbe4bf062f389b06cde7e1130d(dp0\nS'callback_verify'\np1\nS'fd77d26cf4944b9e01cc25652297f1b2'\np2\ns.";
    var result:Object = Unpickler.loads(input);
    assertEquals(result['callback_verify'], 'fd77d26cf4944b9e01cc25652297f1b2');
  }

  public function testUnpickling(): void {
    var input:String = "(dp0\nS'callback_verify'\np1\nS'fd77d26cf4944b9e01cc25652297f1b2'\np2\ns.";
    var result:Object = Unpickler.loads(input);
    assertEquals(result['callback_verify'], 'fd77d26cf4944b9e01cc25652297f1b2');
  }
}
}
