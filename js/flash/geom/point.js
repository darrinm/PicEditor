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
 * @fileoverview A javascript implementation of the Actionscript Point class.
 * This class is to ease the porting of Actionscript code to Javascript.
 * If you aren't porting code but need similar functionality, use
 * goog.math.Coordinate.
 * @author darrinm@google.com (Darrin Massena)
 */
goog.provide('flash.geom.Point');

/**
 * This class mimics the Actionscript flash.geom.Point class.
 * @constructor
 * @param {number=} opt_x The horizontal coordinate.
 * @param {number=} opt_y The vertical coordinate.
 */
flash.geom.Point = function(opt_x, opt_y) {
  /**
   * The horizontal coordinate.
   * @type {number}
   */
  this.x = opt_x || 0;

  /**
   * The vertical coordinate.
   * @type {number}
   */
  this.y = opt_y || 0;
};

/**
 * @return {string} A text value listing the properties of the Point object.
 */
flash.geom.Point.prototype.toString = function() {
  return '(x=' + this.x + ', y=' + this.y + ')';
};
