// Copyright 2010 Google Inc. All Rights Reserved.
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

/**
 * @fileoverview Unit tests for flash.geom.Matrix.
 * @author darrinm@google.com (Darrin Massena)
 */
goog.require('flash.geom.Matrix');
goog.require('flash.geom.Point');
goog.require('goog.testing.jsunit');

function testConstructor() {
  var matrix = new flash.geom.Matrix();
  assertArrayEquals('Empty constructor should produce identity matrix',
      [1, 0, 0, 0, 1, 0, 0, 0, 1], matrix.toRowOrderArray());

  matrix = new flash.geom.Matrix(1, 2, 3, 4, 5, 6);
  assertArrayEquals('Constructor args should initialize the appropriate cells',
      [1, 3, 5, 2, 4, 6, 0, 0, 1], matrix.toRowOrderArray());
}

function testClone() {
  var matrix = new flash.geom.Matrix(1, 2, 3, 4, 5, 6);
  var cloneMatrix = matrix.clone();
  assertEquals('clone should produce an identical matrix',
      '(a=1, b=2, c=3, d=4, tx=5, ty=6)', cloneMatrix.toString());
}

function testScale() {
  var matrix = new flash.geom.Matrix();
  matrix.scale(4, 8);
  assertEquals('Scaling identity matrix should produce a certain matrix',
      '(a=4, b=0, c=0, d=8, tx=0, ty=0)', matrix.toString());

  matrix.scale(.5, .5);
  assertEquals('Scaling a scaled matrix should produce a certain matrix',
      '(a=2, b=0, c=0, d=4, tx=0, ty=0)', matrix.toString());

  matrix = new flash.geom.Matrix(1, 0, 0, 4, 5, 6);
  matrix.scale(3, 4);
  assertEquals('Scaling a certain transform should produce a certain matrix',
      '(a=3, b=0, c=0, d=16, tx=15, ty=24)', matrix.toString());
}

function testTranslate() {
  var matrix = new flash.geom.Matrix();
  matrix.translate(4, 8);
  assertEquals('Translating an identity matrix should produce a certain matrix',
      '(a=1, b=0, c=0, d=1, tx=4, ty=8)', matrix.toString());

  matrix = new flash.geom.Matrix();
  matrix.translate(-50, -100);
  assertEquals('Negative translation of an identity matrix should produce a ' +
      'certain matrix',
      '(a=1, b=0, c=0, d=1, tx=-50, ty=-100)', matrix.toString());

  matrix = new flash.geom.Matrix();
  matrix.translate(-50, -100);
  matrix.translate(-25, -50);
  assertEquals('Translating an identity matrix twice should produce a ' +
      'certain matrix',
      '(a=1, b=0, c=0, d=1, tx=-75, ty=-150)', matrix.toString());
}

function testPrecision() {
  assertEquals('Math.PI toString() should produce a specific string',
      '3.141592653589793', Math.PI.toString());
  assertEquals('Math.PI / 2 should produce a specific value',
      Math.PI / 2, 1.5707963267948966);

  // FF, Chrome, Safari return '1.5707963267948966'
  // IE8/9 returns '1.5707963267948965'
  // So we limit ourselves to 15 digits of precision
  assertEquals('Math.PI / 2 limited to 15 digits of precision should produce ' +
      'a specific value',
      '1.570796326794897', (Math.PI / 2).toFixed(15));

  // Safari, Chrome, and Firefox return 1.2246467991473532e-16
  // IE8/9 returns 1.2246063538223772e-16
  // Flash returns 1.2246063538223773e-16
  assertEquals('Math.sin(Math.PI)) should be a specific value',
      (1.2246467991473532e-16).toFixed(20),
      Math.sin(Math.PI).toFixed(20));

  // Safari, Chrome, and Firefox return 6.123233995736766e-17
  // IE8/9 returns 6.123031769111886e-17
  // So we limit ourselves to 20 digits of precision
  assertEquals('Math.sin(Math.PI / 2)) should be a specific value',
      (6.123233995736766e-17).toFixed(20),
      (Math.sin(Math.PI) / 2).toFixed(20));

  // Safari, Chrome, and Firefox return '1.2246467991473532e-16'
  // IE8/9 returns '1.2246063538223772e-16'
  // Flash returns '1.2246063538223773e-16'
  // So we limit ourselves to 20 digits of precision
  assertEquals('Math.sin(Math.PI)) should be a specific value',
      (1.2246467991473532e-16).toFixed(20),
      Math.sin(Math.PI).toFixed(20));

  // Safari, Chrome, and Firefox return 6.123233995736766e-17
  // IE8/9 returns 6.123031769111886e-17
  // So we limit ourselves to 20 digits of precision
  assertEquals('Math.cos(Math.PI / 2)) should be a specific value',
      (6.123233995736766e-17).toFixed(20),
      Math.cos(Math.PI / 2).toFixed(20));
}

function testRotate() {
  var matrix = new flash.geom.Matrix();
  matrix.rotate(Math.PI / 4);
  assertEquals('Rotating an identity matrix 45 degrees should produce a ' +
      'certain matrix',
      '(a=0.7071067811865476, b=0.7071067811865475, ' +
      'c=-0.7071067811865475, d=0.7071067811865476, tx=0, ty=0)',
      matrix.toString());

  matrix = new flash.geom.Matrix();
  matrix.rotate(Math.PI / 2);
  assertEquals('Rotating an identity matrix 90 degrees should produce a ' +
      'specific matrix',
      '(a=0.0000000000000, b=1.0000000000000, ' +
      'c=-1.0000000000000, d=0.0000000000000, tx=0.0000000000000, ' +
      'ty=0.0000000000000)', toFixed(matrix));

  matrix = new flash.geom.Matrix();
  matrix.translate(-50, -100);
  matrix.rotate(Math.PI / 4);
  assertEquals('Translating and rotating a specific matrix should produce a ' +
      'specific matrix',
      '(a=0.7071067811865476, ' +
      'b=0.7071067811865475, c=-0.7071067811865475, d=0.7071067811865476, ' +
      'tx=35.35533905932736, ty=-106.06601717798213)', matrix.toString());

  matrix = new flash.geom.Matrix();
  matrix.translate(-50, -100);
  matrix.rotate(Math.PI / 4);
  matrix.translate(0, 0);
  assertEquals('Translating, rotating, and translating a specific matrix ' +
      'should produce a specific matrix',
      '(a=0.7071067811865476, ' +
      'b=0.7071067811865475, c=-0.7071067811865475, d=0.7071067811865476, ' +
      'tx=35.35533905932736, ty=-106.06601717798213)', matrix.toString());

  matrix = new flash.geom.Matrix();
  matrix.translate(-50, -100);
  matrix.rotate(0);
  matrix.translate(50, 100);
  assertEquals('Translating, rotating, and translating a specific matrix ' +
      'should produce a specific matrix',
      '(a=1, b=0, c=0, d=1, tx=0, ty=0)', matrix.toString());

  matrix = new flash.geom.Matrix();
  matrix.translate(-50, -100);
  matrix.rotate(Math.PI);
  assertEquals('Translating and rotating a specific matrix should produce a ' +
      'specific matrix',
      '(a=-1.0000000000000, ' +
      'b=0.0000000000000, c=-0.0000000000000, d=-1.0000000000000, ' +
      'tx=50.0000000000000, ty=100.0000000000000)', toFixed(matrix));

  matrix = new flash.geom.Matrix();
  matrix.translate(-50, -100);
  matrix.rotate(Math.PI);
  matrix.translate(50, 100);
  assertEquals('Traslating, rotating, and translating a specific matrix ' +
      'should produce a specific matrix',
      '(a=-1.0000000000000, ' +
      'b=0.0000000000000, c=-0.0000000000000, d=-1.0000000000000, ' +
      'tx=100.0000000000000, ty=200.0000000000000)', toFixed(matrix));

  matrix = new flash.geom.Matrix();
  matrix.translate(-50, -100);
  matrix.rotate(Math.PI / 4);
  matrix.translate(50, 100);
  assertEquals('Translating, rotating, and translating a specific matrix ' +
      'should produce a specific result',
      '(a=0.7071067811865476, ' +
      'b=0.7071067811865475, c=-0.7071067811865475, d=0.7071067811865476, ' +
      'tx=85.35533905932736, ty=-6.066017177982133)', matrix.toString());
}

/**
 * Return a string representation of the matrix with each element 'toFixed' to
 * 13 digits. This is used by tests to overcome differences in numeric
 * precision between Javascript implementations. See testPrecision above for
 * some details.
 * @param {flash.geom.Matrix} matrix The matrix whose values should be fixed.
 * @return {flash.geom.Matrix} The matrix with fixed-precision values.
 */
function toFixed(matrix) {
  return '(a=' + matrix.getA().toFixed(13) + ', b=' +
      matrix.getB().toFixed(13) + ', c=' + matrix.getC().toFixed(13) +
      ', d=' + matrix.getD().toFixed(13) + ', tx=' +
      matrix.getTx().toFixed(13) + ', ty=' + matrix.getTy().toFixed(13) + ')';
}

function testConcat() {
  var matrix = new flash.geom.Matrix();
  var matrix2 = new flash.geom.Matrix();
  matrix.concat(matrix2);
  assertEquals('Concatenating two identity matrix should yield an identity ' +
      'matrix',
      '(a=1, b=0, c=0, d=1, tx=0, ty=0)', matrix.toString());

  matrix = new flash.geom.Matrix(2, 0, 0, 3, 0, 0);
  matrix2 = new flash.geom.Matrix(4, 0, 0, 5, 0, 0);
  matrix.concat(matrix2);
  assertEquals('Concatenating two specific scaling matrices should yield a ' +
      'specific matrix',
      '(a=8, b=0, c=0, d=15, tx=0, ty=0)', matrix.toString());

  matrix = new flash.geom.Matrix(1, 0, 0, 1, 1, 2);
  matrix2 = new flash.geom.Matrix(1, 0, 0, 1, 3, 4);
  matrix.concat(matrix2);
  assertEquals('Concatenating two specific translation matrices should yield ' +
      'a specific matrix',
      '(a=1, b=0, c=0, d=1, tx=4, ty=6)', matrix.toString());

  matrix = new flash.geom.Matrix(2, 0, 0, 3, 1, 2);
  matrix2 = new flash.geom.Matrix(4, 0, 0, 5, 3, 4);
  matrix.concat(matrix2);
  assertEquals('Concatenating two specific transormation matrices should ' +
      'yield a specific matrix',
      '(a=8, b=0, c=0, d=15, tx=7, ty=14)', matrix.toString());

  matrix = new flash.geom.Matrix(2, 0, 0, 3, 1, 2);
  matrix2 = new flash.geom.Matrix(4, 0, 0, 5, 3, 4);
  matrix2.concat(matrix);
  assertEquals('Concatenating two specific transormation matrices should ' +
      'yield a specific matrix',
      '(a=8, b=0, c=0, d=15, tx=7, ty=14)', matrix2.toString());
}

function testTransformPoint() {
  var matrix = new flash.geom.Matrix();
  var point = new flash.geom.Point(50, 25);
  var newPoint = matrix.transformPoint(point);
  assertEquals('Transforming a point through an identity matrix should yield ' +
      'the same point',
      '(x=50, y=25)', newPoint.toString());

  matrix = new flash.geom.Matrix(2, 0, 0, 3);
  point = new flash.geom.Point(50, 25);
  newPoint = matrix.transformPoint(point);
  assertEquals('Transforming a specific point through a specific scaling ' +
      'matrix should yield a specific point',
      '(x=100, y=75)', newPoint.toString());

  matrix = new flash.geom.Matrix();
  matrix.rotate(Math.PI / 4);
  point = new flash.geom.Point(50, 25);
  newPoint = matrix.transformPoint(point);
  assertEquals('Transforming a specific point through a specific scaling ' +
      'matrix should yield a specific point',
      '(x=17.677669529663692, y=53.03300858899106)', newPoint.toString());
}

function testPropertyGetters() {
  var matrix = new flash.geom.Matrix(1, 2, 3, 4, 5, 6);
  assertEquals('getA should return a\'s value', 1, matrix.getA());
  assertEquals('getB should return b\'s value', 2, matrix.getB());
  assertEquals('getC should return c\'s value', 3, matrix.getC());
  assertEquals('getD should return d\'s value', 4, matrix.getD());
  assertEquals('getTx should return tx\'s value', 5, matrix.getTx());
  assertEquals('getTy shoud return ty\'s value', 6, matrix.getTy());
}
