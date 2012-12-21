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
 * @fileoverview Bulkedit client side logic for picnik admin page.
 * @author zhaoz@google.com (Ziling Zhao)
 */

(function($) {
  var picnik = window.picnik = window.picnik || {};

  window.console = window.console || {
    'log': $.noop,
    'debug': $.noop
  };

  /**
   * Generic NotImplemented class, throws exception when called.
   */
  function NotImplemented() {
    throw 'NotImplemented Exception.';
  }


  /**
   * Defines the Component interface, basically can be enabled and disabled.
   * @interface
   */
  function Component() {}


  /** Object pointing to the bulk edit instance it should be editing. */
  Component.prototype.bulkEdit = null;


  /** Enable component. */
  Component.prototype.enable = $.noop;


  /** Disable component. */
  Component.prototype.disable = $.noop;


  /**
   * Defines the InputFilter interface, handles initial processing of raw input.
   * @interface
   * @extends {Component}
   */
  function InputFilter() {}


  InputFilter.prototype = new Component();


  /** Element to output to. */
  InputFilter.prototype.outputElem = null;


  /** Type of output expected from InputFilter */
  InputFilter.prototype.outputType = '';


  /**
   * Initialization function.
   * @param {Object} bulkEdit The bulk edit instance to associate with this
   *     InputFilter.
   */
  InputFilter.prototype.init = function(bulkEdit) {
    this.bulkEdit = bulkEdit;

    this.rowTemplate = this.outputElem.find('.template')
        .clone()
        .removeClass('hidden template');

    this.rowContainer = this.outputElem.children('tbody');

    this.curEntries = {};
  };


  /**
   * Create a row for the given info
   * @param {Object.<string, *>} info on the input.
   * @return {Object} jQuery object wrapping DOM row.
   */
  InputFilter.prototype.createRow = function(info) {
    var row = this.rowTemplate.clone();

    for (var prop in info) {
      row.find('.' + prop).html(info[prop]);
    }
    row.data('info', info);

    if (info.userId) {
      // make userId a link.
      row.attr('id', 'userrow_' + info.userId);
      row.find('.userId').html('<a href="edituser?user=' + info.userId + '">' +
          info.userId + '</a>');
    }

    return row;
  };


  /**
   * Given entry info, create rows and add to table.
   * @param {Object.<string, Object>} info Information object, holding many
   *     trans entries.
   */
  InputFilter.prototype.addEntries = function(info) {
    for (var id in info) {
      if (this.curEntries[id]) {
        continue;
      }
      var row = this.createRow(info[id]);
      this.addRow(row);
    }
  };


  /**
   * Add a row to the table.
   * @param {Object} row jQuery object wrapping a DOM object.
   * @param {Object=} opt_container jQuery object to add the row to .
   */
  InputFilter.prototype.addRow = function(row, opt_container) {
    this.enable();

    var container = opt_container || this.rowContainer;
    container.append(row);
    this.curEntries[row.data('row_id')] = row;
  };


  /**
   * Remove a row from the table.
   * @param {Object} row jQuery object wrapping a DOM object.
   */
  InputFilter.prototype.removeRow = function(row) {
    var row_id = row.data('row_id');
    row.remove();
    delete this.curEntries[row_id];
  };


  /**
   * Map rows.
   * @param {function(Object)} row Function to call on each row.
   * @return {Array.<Object>} Array after mapping.
   */
  InputFilter.prototype.mapRows = function(f) {
    return $.map(this.outputElem.find('tbody tr'), f);
  };


  /**
   * Update entries with given lines.
   */
  InputFilter.prototype.update = $.noop;


  /**
   * Clear completed items from the table.
   */
  InputFilter.prototype.clearCompleted = function() {
    this.outputElem.find('.bulk-done').parents('tr')
        .find('.bulk-remove').trigger('remove');
  };

  /**
   * Remove empty tbody's
   */
  InputFilter.prototype.pruneTable = function() {
    // this is pretty inefficient, since it is triggered on every remove call.
    this.outputElem.find('tbody').not('.orig').each(function() {
      var elem = $(this);
      if (!elem.children().size()) {
        elem.remove();
      }
    });
  };


  /**
   * Handle operation enabling.
   */
  InputFilter.prototype.enable = function() {
    this.outputElem.removeClass('hidden');
  };


  /**
   * Handle operation disabling.
   */
  InputFilter.prototype.disable = function() {
    this.outputElem.addClass('hidden');
    this.empty();
  };


  /**
   * Empty the rows.
   */
  InputFilter.prototype.empty = function() {
    this.outputElem.children('tbody').children().not('.template').remove();
    this.curEntries = {};
    this.pruneTable();
  };


  /**
   * Defines the OpType interface, handles actual processing of input.
   * @interface
   * @extends {Component}
   */
  function OpType() {
    this.name = null;
  }


  /**
   * Handle form submission (usually process input trigger).
   */
  OpType.prototype.submit = NotImplemented;


  /**
   * Input types that the optype would support.
   */
  OpType.prototype.supportedInputs = null;


  /**
   * Retrieve the input data's ids.
   */
  OpType.prototype.getInputIds_ = function() {
    return this.bulkEdit.getInputFilter()
        .mapRows(function(elem) {
          return $(elem).data('row_id');
        });
  };


  /**
   * Handle operation enabling
   */
  OpType.prototype.enable = function() {
    this.bulkEdit.getInputFilter().outputElem.addClass('refund');
    $('.' + this.name + 'Options').show();
  };


  /**
   * Handle operation disabling
   */
  OpType.prototype.disable = function() {
    this.bulkEdit.getInputFilter().outputElem.removeClass('refund');
    $('.' + this.name + 'Options').hide();
  };


  /**
   * @constructor
   * @extends {OpType}
   */
  function RefundOperation() {
    this.name = 'refund';
    this.supportedInputs = ['users'];
  }


  RefundOperation.prototype = new OpType();


  /**
   * Process the entries for a refund.
   */
  RefundOperation.prototype.submit = function() {
    var ids = this.getInputIds_();
    var expire = $('#changeExpire').is(':checked');
    picnik.AdminApi.refundUsers(
      {'ids': ids, 'expire': expire}, {
      success: $.proxy(this, 'handleResponse')
    });
  };


  /**
   * Response from refund call handled here.
   * @param {Object.<string, Object>} data Response from the server with
   *     user ids as keys.
   */
  RefundOperation.prototype.handleResponse = function(data) {
    for (var id in data) {
      var elem = this.bulkEdit.getInputFilter().curEntries[id];
      var cell = elem.find('.refunded');
      cell.text(data[id]);

      if (parseFloat(data[id]) < 1) {
        cell.addClass('bulk-error');
      } else {
        cell.addClass('bulk-done');
      }
    }
  };


  /**
   * @constructor
   * @extends {OpType}
   */
  function ChargebackOperation() {
    this.name = 'chargeback';
    this.supportedInputs = ['transactions'];
  }


  ChargebackOperation.prototype = new OpType();


  /**
   * Process the entries for a chargeback.
   */
  ChargebackOperation.prototype.submit = function() {
    var ids = this.bulkEdit.getInputFilter().mapRows(function(elem) {
      var info = $(elem).data('info');
      return info.userId;
    });

    picnik.AdminApi.chargebackUsers(ids, {
      success: $.proxy(this, 'handleResponse')
    });
  };


  /**
   * Response from refund call handled here.
   * @param {Object.<string, Object>} data Response from the server.
   */
  ChargebackOperation.prototype.handleResponse = function(data) {
    var lookup = {},
        len = data.ids.length;

    while (len--) {
      lookup[data.ids[len]] = 1;
    }

    this.bulkEdit.getInputFilter().mapRows(function(dom) {
      var row = $(dom);

      if (lookup[row.data('info').userId]) {
        row.children().eq(0).addClass('bulk-done');
      }
    });
  };


  /**
   * @constructor
   * @extends {InputFilter}
   * @param {(string|Element|Object)} output The element to output to, a jQuery
   *     compatible argument.
   */
  function TransInputFilter(output) {
    this.outputElem = $(output);
    this.outputType = 'transactions';
  }

  TransInputFilter.prototype = new InputFilter();


  /**
   * Return a string id for given cc, date combo.
   * @param {string} cc The CC number.
   * @param {Date} date The given date.
   * @return {string} The unique id string for given input.
   */
  TransInputFilter.prototype.makeEntryId = function(cc, date) {
    return cc + (+date);
  };


  /**
   * Given a credit card number, mask it so we don't show the full number.
   * @param {string} ccnum The CC number.
   * @return {string} Masked CC number.
   */
  TransInputFilter.prototype.maskCC_ = function(ccnum) {
    return ccnum.slice(0, 6) + '******' + ccnum.slice(12);
  };


  /**
   * Update entries with given lines, calls API (async) and then addEntries
   * @param {Array.<string>} lines Lines to process.
   */
  TransInputFilter.prototype.update = function(lines) {
    var added = [];
    var len = lines.length;

    for (var ii = 0; ii < len; ii++) {
      var entry = $.trim(lines[ii]);
      if (!entry) {
        continue;
      }

      var parts = entry.split(',');

      var cc = $.trim(parts[0]);
      cc = this.maskCC_(cc);

      var dateStr = $.trim(parts[1]);

      var date = new Date(dateStr);

      if (isNaN(date.getTime())) {
        date = new Date(+dateStr);
      }

      if (isNaN(date.getTime())) {
        // we tried :/
        continue;
      }

      var id = this.makeEntryId(cc, date);
      if (this.curEntries[id]) {
        // item exists already
        continue;
      }

      added.push([cc, date]);
    }

    if (!added.length) {
      return;
    }

    picnik.AdminApi.getTransInfo(added, {
        success: $.proxy(function(info) {
          this.addEntries(info, added);
        }, this)
      }
    );
  };

  /**
   * Given trans info, create rows and add to table.
   * @param {Object.<string, Object>} info Transaction information object,
   *     holding many transaction entries.
   */
  TransInputFilter.prototype.addEntries = function(info, orig) {
    // walk through the original entries to recreate the same order
    for (var ii = 0; ii < orig.length; ii++) {
      var cc = orig[ii][0];   // the cc num string
      var ms = +orig[ii][1];  // the time in milliseconds

      if (!info[cc] || !info[cc][ms] || !info[cc][ms].length) {
        // no info found for this cc ms combo
        console.log('no info on this combo found');
        continue;
      }

      var entries = info[cc][ms];
      var len = entries.length;
      var container = $('<tbody>');

      while (len--) {
        var entry = entries[len],
            entry_ms = (new Date(entry.created)).getTime(),
            id = this.makeEntryId(entry.cc, entry_ms);

        if (this.curEntries[id]) {
          // dont' create duplicates
          console.log('already created, ignore');
          continue;
        }

        var row = this.createRow(entry);
        row.data('row_id', id);
        this.addRow(row, container);
      }

      this.outputElem.append(container);
    }
  };


  /**
   * @constructor
   * @extends {InputFilter}
   * @param {(string|Element|Object)} output The element to output to, a jQuery
   *     compatible argument.
   */
  function UserInputFilter(output) {
    this.outputElem = $(output);
    this.outputType = 'users';
  }


  UserInputFilter.prototype = new InputFilter();


  /**
   * Given user info, create rows and add to table.
   * @param {Object.<string, Object>} info User information object, holding many
   *     user entries.
   */
  UserInputFilter.prototype.addEntries = function(info) {
    for (var id in info) {
      if (this.curEntries[id]) {
        continue;
      }
      var entry = info[id];
      entry.userId = id;

      var row = this.createRow(entry);
      row.data('row_id', id);
      this.addRow(row);
    }
  };


  /**
   * Update entries with given lines, calls API (async) and then addEntries
   * @param {Array.<string>} lines Lines to process.
   */
  UserInputFilter.prototype.update = function(lines) {
    lines = $.map(lines, function(entry) {
      return $.trim(entry) || null;
    });

    var added = [];

    // find the new user ids
    for (var ii in lines) {
      var item = lines[ii];

      if (!this.curEntries[item]) {
        // new item
        added.push(item);
      }
    }

    if (!added.length) {
      return;
    }

    picnik.AdminApi.getUserInfo(added, {
        success: $.proxy(this, 'addEntries')
      }
    );
  };


  /**
   * BulkEdit handler, figures out how to process input and talks with the
   * server.
   * @constructor
   * @param {Object.<string, *>=} opt_options Optional parameters.
   */
  function BulkEdit(opt_options) {
    var o = $.extend({}, BulkEdit.defaults, opt_options);
    this.opts = o;

    // set the bulkEdit property on the objects.
    for (var op in o.operations) {
      o.operations[op].bulkEdit = this;
    }

    for (var input in o.inputFilters) {
      input = o.inputFilters[input];
      input.init(this);
    }

    this.form = $(o.form);
    this.textArea = this.form.find('textarea.data');

    this.inputTypeElem_ = this.form.find('.inputType');
    this.curInputType = null;

    this.opTypeElem_ = this.form.find('.opType');
    this.curOpName = null;

    this.handleInputTypeChange_();
    this.attachEvents();
  }


  /**
   * Reset the state of bulkedit, e.g. clear rows and entries.
   */
  BulkEdit.prototype.reset = function() {
    this.opTypeElem_
      .find('option').attr('disabled', false).attr('selected', false);

    this.inputTypeElem_.find('option').eq(0).attr('selected', true);

    var inputFilter = this.getInputFilter();
    inputFilter.disable();

    this.curInputType = null;
    this.curOpName = null;
    this.handleInputTypeChange_();
  };


  /**
   * Get the current operation type object.
   * @param {string=} opt_op The name of the operation.
   * @return {Object} the current operation object.
   */
  BulkEdit.prototype.getOpObject = function(opt_op) {
    return this.opts.operations[opt_op || this.curOpName];
  };


  /**
   * Get the current input processor object.
   * @param {string=} opt_input The name of the input filter.
   * @return {Object} The current input filter object.
   */
  BulkEdit.prototype.getInputFilter = function(opt_input) {
    return this.opts.inputFilters[opt_input || this.curInputType];
  };


  /**
   * On operation type change, call operation handler enable/disable.
   * @private
   */
  BulkEdit.prototype.handleOpChange_ = function() {
    var opName = this.opTypeElem_.val();

    if (opName == this.curOpName) {
      // do nothing
      return;
    }
    if (this.curOpName) {
      this.getOpObject().disable();
    }
    this.getOpObject(opName).enable();
    this.curOpName = opName;
  };


  /**
   * On input type change, call inputType handler enable/disable
   * @private
   */
  BulkEdit.prototype.handleInputTypeChange_ = function() {
    var inputName = this.inputTypeElem_.val();

    if (inputName == this.curInputType) {
      // do nothing
      return;
    }

    if (this.curInputType) {
      this.getInputFilter().disable();
    }
    var inputFilter = this.getInputFilter(inputName);
    inputFilter.enable();
    this.curInputType = inputName;

    var enabled = [];

    // Now check which operations are supported
    for (var opName in this.opts.operations) {
      var op = this.opts.operations[opName];

      if ($.inArray(inputFilter.outputType, op.supportedInputs) == -1) {
        continue;
      }

      // op is supported
      enabled.push(opName);
    }

    var firstEnabled = null;
    var change = false;

    this.opTypeElem_.children('option').each(function() {
      var elem = $(this);

      if ($.inArray(elem.val(), enabled) == -1) {
        elem.attr('disabled', true);
        if (elem.is(':selected')) {
          change = true;
          elem.attr('selected', false);
        }
      } else {
        elem.attr('disabled', false);

        if (!firstEnabled) {
          firstEnabled = elem;
        }
      }
    });

    if (change) {
      if (firstEnabled) {
        firstEnabled.attr('selected', true);
      } else {
        alert('something gone bad.');
      }
    }
    this.handleOpChange_();
  };


  /**
   * Attach events to DOM elements.
   */
  BulkEdit.prototype.attachEvents = function() {
    // on blur process the text in the textArea
    this.textArea.blur($.proxy(this, 'processText'));

    $('table.dataTable a.bulk-remove')
        .live('click', function(eve) {
          $(eve.target).trigger('remove');
        })
        .live('remove',
          $.proxy(function(eve) {
            var elem = $(eve.target);
            var inputFilter = this.getInputFilter();
            inputFilter.removeRow(elem.parents('tr'));
            inputFilter.pruneTable();
            eve.preventDefault();
          }, this)
        );

    this.opTypeElem_.change($.proxy(this, 'handleOpChange_'));
    this.inputTypeElem_.change($.proxy(this, 'handleInputTypeChange_'));

    this.form.submit($.proxy(function(eve) {
      eve.preventDefault();
      this.getOpObject().submit();
    }, this));

    this.form
        .delegate('.clearForm', 'click', $.proxy(this, 'reset'))
        .delegate('.clearComplete', 'click', $.proxy(this, 'clearCompleted'));
  };


  /**
   * Clear completed items from current table.
   */
  BulkEdit.prototype.clearCompleted = function() {
    this.getInputFilter().clearCompleted();
  };


  /**
   * Process the text inside of the text area, update the entry table.
   */
  BulkEdit.prototype.processText = function() {
    var lines = this.textArea.val().split('\n');

    if (!lines.length) {
      return;
    }
    this.textArea.val('');
    this.getInputFilter().update(lines);
  };


  BulkEdit.defaults = {
    inputFilters: {
      'userId': new UserInputFilter('#userEntries'),
      'trans_cc_date': new TransInputFilter('#transEntries')
    },
    operations: {
      'refund': new RefundOperation(),
      'chargeback': new ChargebackOperation()
    },
    form: '#frmMain'
  };


  picnik.BulkEdit = new BulkEdit();
}(jQuery));
