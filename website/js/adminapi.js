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

/**
 * @fileoverview Admin api file.
 * @author zhaoz@google.com (Ziling Zhao)
 */


(function($) {
  if (!window.picnik) {
    window.picnik = {};
  }

  /**
   * AdminApi object, wraps around calls to the admin api.
   * @constructor
   * @param {Object=} optional arguments to configure the AdminApi.
   *   basePath: Base path for the admin interface.
   *   ajaxOpts: An object holding default ajax params for jQuery.ajax.
   */
  function AdminApi(opt_options) {
    this.opts = $.extend({}, AdminApi.defaults, opt_options);
  }


  /**
   * Create the URL needed for the api call.
   * @param {String} name Name of the api call.
   */
  AdminApi.prototype.constructUrl = function(name) {
    return this.opts.basePath + '/' + name;
  };


  /**
   * Given a list of user ids, retreive info on users.
   * @param {Array.<string>} ids A list of ids to retreive info on.
   * @param {Object=} opt_ajaxOpts Optional ajax options.
   */
  AdminApi.prototype.getUserInfo = function(ids, opt_ajaxOpts) {
    var ajaxOpts = $.extend({
        dataType: 'json',
        data: {
          'id': ids
        }}, AdminApi.defaults.ajaxOpts, opt_ajaxOpts);

    $.ajax(this.constructUrl('getuserinfo'), ajaxOpts);
  };


  /**
   * Given a list of transactions, get information for the transaction, with
   * some fuzzy dates.
   * @param {Array.<Array.<string, Date>>} trans List of CC nums and dates.
   * @param {Object=} opt_ajaxOpts Optional ajax options.
   */
  AdminApi.prototype.getTransInfo = function(trans, opt_ajaxOpts) {
    var transactionHashes = [];

    var len = trans.length;

    while (len--) {
      var entry = trans[len];
      transactionHashes.push(entry[0] + (+entry[1]));
    }

    var ajaxOpts = $.extend({
        dataType: 'json',
        data: {
          'transHashes': transactionHashes
        }}, AdminApi.defaults.ajaxOpts, opt_ajaxOpts);

    $.ajax(this.constructUrl('gettransinfo'), ajaxOpts);
  };


  /**
   * Given a list of user ids, turn off renew, expire, and add chargeback msg.
   * @param {Array.<string>} ids A list of ids.
   * @param {Object=} opt_ajaxOpts Optional ajax options.
   */
  AdminApi.prototype.chargebackUsers = function(ids, opt_ajaxOpts) {
    var ajaxOpts = $.extend({
        type: 'POST',
        data: {
          'id': ids
        }
      }, AdminApi.defaults.ajaxOpts, opt_ajaxOpts);

    $.ajax(this.constructUrl('chargeback'), ajaxOpts);
  };


  /**
   * Given a list of user ids, refund all.
   * @param {Object} args A dict of arts, including list of ids to refund.
   * @param {Object=} opt_ajaxOpts Optional ajax options.
   */
  AdminApi.prototype.refundUsers = function(args, opt_ajaxOpts) {
    var ajaxOpts = $.extend({
        type: 'POST',
        data: {
          'expire': !!args.expire,
          'id': args.ids
        }
      }, AdminApi.defaults.ajaxOpts, opt_ajaxOpts);

    $.ajax(this.constructUrl('refundall'), ajaxOpts);
  };


  AdminApi.defaults = {
    basePath: '/admin',
    ajaxOpts: {
      dataType: 'json'
    }
  };


  window.picnik.AdminApi = new AdminApi();
}(jQuery));
