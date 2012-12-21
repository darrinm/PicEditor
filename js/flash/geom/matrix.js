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
 * @fileoverview A javascript implementation of the Actionscript Matrix class.
 * To ease in the porting of Actionscript code to Javascript, we offer up this
 * Flash-like wrapper of goog.math.Matrix.
 * @author darrinm@google.com (Darrin Massena)
 *
 * NOTE: Flash matrices are laid out in ROW MAJOR order. WebGL assumes COLUMN
 * MAJOR order. So we must transpose Flash matrices before passing to WebGL.
 */
goog.provide('flash.geom.Matrix');

goog.require('flash.geom.Point');
goog.require('goog.math.Matrix');

// TODO(darrinm): horribly inefficient. Something like glMatrix.js would provide
// a faster base.

/**
 * This class mimics the Actionscript flash.geom.Matrix class.
 * @constructor
 * @param {number=} opt_a The value that affects the positioning of pixels along
 *     the x axis when scaling or rotating an image.
 * @param {number=} opt_b The value that affects the positioning of pixels along
 *     the y axis when rotating or skewing an image.
 * @param {number=} opt_c The value that affects the positioning of pixels along
 *     the x axis when rotating or skewing an image.
 * @param {number=} opt_d The value that affects the positioning of pixels along
 *     the y axis when scaling or rotating an image.
 * @param {number=} opt_tx The distance by which to translate each point along
 *     the x axis.
 * @param {number=} opt_ty The distance by which to translate each point along
 *     the y axis.
 */
flash.geom.Matrix = function(opt_a, opt_b, opt_c, opt_d, opt_tx, opt_ty) {
  /**
   * @type {goog.mat.Matrix}
   * @private
   */
  this.mat3_ = new goog.math.Matrix([
    [goog.isDefAndNotNull(opt_a) ? opt_a : 1, opt_c || 0, opt_tx || 0],
    [opt_b || 0, goog.isDefAndNotNull(opt_d) ? opt_d : 1, opt_ty || 0],
    [0, 0, 1]
  ]);
};

/**
 * @return {number} The value that affects the positioning of pixels along
 *     the x axis when scaling or rotating an image.
 */
flash.geom.Matrix.prototype.getA = function() {
  return this.mat3_.getValueAt(0, 0);
};

/**
 * @return {number} The value that affects the positioning of pixels along
 *     the y axis when rotating or skewing an image.
 */
flash.geom.Matrix.prototype.getB = function() {
  return this.mat3_.getValueAt(1, 0);
};

/**
 * @return {number} The value that affects the positioning of pixels along
 *     the x axis when rotating or skewing an image.
 */
flash.geom.Matrix.prototype.getC = function() {
  return this.mat3_.getValueAt(0, 1);
};

/**
 * @return {number} The value that affects the positioning of pixels along
 *     the y axis when scaling or rotating an image.
 */
flash.geom.Matrix.prototype.getD = function() {
  return this.mat3_.getValueAt(1, 1);
};

/**
 * @return {number} The distance by which to translate each point along the
 *     x axis.
 */
flash.geom.Matrix.prototype.getTx = function() {
  return this.mat3_.getValueAt(0, 2);
};

/**
 * @return {number} The distance by which to translate each point along the
 *     y axis.
 */
flash.geom.Matrix.prototype.getTy = function() {
  return this.mat3_.getValueAt(1, 2);
};

/**
 * @return {flash.geom.Matrix} A clone of this matrix, with an exact copy of
 *     the contained object.
 */
flash.geom.Matrix.prototype.clone = function() {
  return new flash.geom.Matrix(this.getA(), this.getB(), this.getC(),
      this.getD(), this.getTx(), this.getTy());
};

/**
 * Translates the matrix along the x and y axes, as specified by the deltaX
 * and deltaY parameters.
 * @param {number} deltaX The amount of movement along the x axis to the
 *     right, in pixels.
 * @param {number} deltaY The amount of movement down along the y axis,
 *     in pixels.
 */
flash.geom.Matrix.prototype.translate = function(deltaX, deltaY) {
  this.mat3_ = this.mat3_.add(
      new goog.math.Matrix([[0, 0, deltaX], [0, 0, deltaY], [0, 0, 0]]));
};

/**
 * Applies a scaling transformation to the matrix.
 * @param {number} scaleX A multiplier used to scale the object along the
 *     x axis.
 * @param {number} scaleY A multiplier used to scale the object along the
 *     y axis.
 */
flash.geom.Matrix.prototype.scale = function(scaleX, scaleY) {
  var scaleMatrix = new flash.geom.Matrix(scaleX, 0, 0, scaleY);
  scaleMatrix.concat(this);
  this.mat3_ = scaleMatrix.mat3_;
};

/**
 * Applies a rotation transformation to the Matrix object.
 * @param {number} angle The rotation angle in radians.
 */
flash.geom.Matrix.prototype.rotate = function(angle) {
  var mat = new flash.geom.Matrix(Math.cos(angle), Math.sin(angle),
      -Math.sin(angle), Math.cos(angle));
  this.mat3_ = mat.mat3_.multiply(this.mat3_);
};

/**
 * Concatenates a matrix with the current matrix, effectively combining
 * the geometric effects of the two.
 * @param {flash.geom.Matrix} matrix The matrix to be concatenated to the source
 *     matrix.
 */
flash.geom.Matrix.prototype.concat = function(matrix) {
  this.mat3_ = this.mat3_.multiply(matrix.mat3_);
};

/**
 * @param {flash.geom.Point} point The point for which you want to get the
 *     result of the Matrix transformation.
 * @return {flash.geom.Point} The result of applying the geometric
 *     transformation represented by the Matrix object to the specified point.
 */
flash.geom.Matrix.prototype.transformPoint = function(point) {
  var vector = new goog.math.Matrix([[point.x], [point.y], [0]]);
  vector = this.mat3_.multiply(vector);
  return new flash.geom.Point(vector.getValueAt(0, 0), vector.getValueAt(1, 0));
};

/**
 * @return {string} A text value listing the properties of the Matrix object.
 */
flash.geom.Matrix.prototype.toString = function() {
  var array = this.toRowOrderArray();
  return ['(a=', array[0], ', b=', array[3], ', c=', array[1], ', d=',
      array[4], ', tx=', array[2], ', ty=', array[5], ')'].join('');
};

//
// Not part of the Flash API
//

/**
 * @return {Array.<number>} An array of matrix elements in row major order.
 */
flash.geom.Matrix.prototype.toRowOrderArray = function() {
  var mat3Array = [0, 0, 0, 0, 0, 0, 0, 0, 0];
  var k = 0;
  for (var row = 0; row < 3; row++) {
    for (var col = 0; col < 3; col++) {
      mat3Array[k++] = this.mat3_.getValueAt(row, col);
    }
  }
  return mat3Array;
};

/**
 * @return {Array.<number>} An array of matrix elements in column major order.
 */
flash.geom.Matrix.prototype.toColumnOrderArray = function() {
  var mat3Array = [0, 0, 0, 0, 0, 0, 0, 0, 0];
  var k = 0;
  for (var col = 0; col < 3; col++) {
    for (var row = 0; row < 3; row++) {
      mat3Array[k++] = this.mat3_.getValueAt(row, col);
    }
  }
  return mat3Array;
};
