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
package imagine.serialization.tests
{
  import flash.geom.Point;
  import flash.geom.Rectangle;

  import flexunit.framework.Assert;
  import flexunit.framework.TestCase;

  import imagine.serialization.SPoint;
  import imagine.serialization.SerializationUtil;

  import mx.utils.ObjectUtil;

  public class SerializationUtilTest extends TestCase
  {
    public function testReadWriteFromStringWithMarker():void {
      var obTest:Object = {strTest:"Test String in Test Object"};
      var obSrlzDesrlz:Object = SerializationUtil.ReadFromStringWithMarker(
          SerializationUtil.WriteToStringWithMarker(obTest));
      Assert.assertEquals(0, ObjectUtil.compare(obTest, obSrlzDesrlz));

      obSrlzDesrlz = SerializationUtil.ReadFromStringWithMarker(
          SerializationUtil.WriteToStringWithMarker(obTest, false));
      Assert.assertEquals(0, ObjectUtil.compare(obTest, obSrlzDesrlz));
    }

    public function testDeepCopy():void {
      var obTest:Object = {strTest: "Test String in Test Object"};
      var obTestCopy:Object = SerializationUtil.DeepCopy(obTest);
      Assert.assertEquals(0, ObjectUtil.compare(obTest, obTestCopy));
      Assert.assertTrue(obTest != obTestCopy);
    }

    public function testCleanSrlzReadWriteValue():void {
      var obTest:Object = {strTest: "Test String in Test Object"};
      var obCleanSrlzDesrlz: Object = SerializationUtil.CleanSrlzReadValue(
          SerializationUtil.CleanSrlzWriteValue(obTest));
      Assert.assertEquals(0, ObjectUtil.compare(obTest, obCleanSrlzDesrlz));

      var pTest:Point = new Point(1, 2);
      var pTestCleanSrlzDesrlz: Point = SerializationUtil.CleanSrlzReadValue(
          SerializationUtil.CleanSrlzWriteValue(pTest));
      Assert.assertTrue(pTest.equals(pTestCleanSrlzDesrlz));

      var rTest:Rectangle = new Rectangle(0, 0, 100, 100);
      var rTestCleanSrlzDesrlz: Rectangle =
          SerializationUtil.CleanSrlzReadValue(
          SerializationUtil.CleanSrlzWriteValue(rTest));
      Assert.assertTrue(rTest.equals(rTestCleanSrlzDesrlz));

      var aTest:Array = [new Point(1, 2), new Point(3, 4)];
      SerializationUtil.CleanSrlzWriteValue(aTest);
      Assert.assertTrue(aTest[0] is SPoint);
      Assert.assertTrue(aTest[1] is SPoint);
    }
  }
}
