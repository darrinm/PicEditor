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
 * @fileoverview A javascript implementation of the Actionscript Rectangle
 * class. This class is to ease the porting of Actionscript code to Javascript.
 * If you aren't porting code but need similar functionality, use
 * goog.math.Rect.
 * @author darrinm@google.com (Darrin Massena)
 */
goog.provide('flash.geom.Rectangle');

/**
 * This class mimics the Actionscript flash.geom.Rectangle class.
 * @constructor
 * @param {number=} opt_x The x coordinate of the top-left corner of the
 *     rectangle.
 * @param {number=} opt_y The y coordinate of the top-left corner of the
 *     rectangle.
 * @param {number=} opt_width The width of the rectangle, in pixels.
 * @param {number=} opt_height The height of the rectangle, in pixels.
 */
flash.geom.Rectangle = function(opt_x, opt_y, opt_width, opt_height) {
  /**
   * The left horizontal coordinate.
   * @type {number}
   */
  this.x = opt_x || 0;

  /**
   * The top vertical coordinate.
   * @type {number}
   */
  this.y = opt_y || 0;

  /**
   * The width.
   * @type {number}
   */
  this.width = opt_width || 0;

  /**
   * The height.
   * @type {number}
   */
  this.height = opt_height || 0;
};

/**
 * Adjusts the location of the Rectangle object, as determined by its top-left
 * corner, by the specified amounts.
 * @param {number} offsetX Moves the x value of the Rectangle object by this
 *     amount.
 * @param {number} offsetY Moves the y value of the Rectangle object by this
 *     amount.
 */
flash.geom.Rectangle.prototype.offset = function(offsetX, offsetY) {
  this.x += offsetX;
  this.y += offsetY;
};

/**
 * @return {number} The x coordinate of the top-left corner of the rectangle.
 */
flash.geom.Rectangle.prototype.getLeft = function() {
  return this.x;
};

/**
 * @return {number} The y coordinate of the top-left corner of the rectangle.
 */
flash.geom.Rectangle.prototype.getTop = function() {
  return this.y;
};

/**
 * @return {number} The sum of the x and width properties.
 */
flash.geom.Rectangle.prototype.getRight = function() {
  return this.x + this.width;
};

/**
 * @return {number} The sum of the y and height properties.
 */
flash.geom.Rectangle.prototype.getBottom = function() {
  return this.y + this.height;
};
