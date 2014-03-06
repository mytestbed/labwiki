/* This code started with Bootstrap's scrollspy under the following license.
 *=============================================================
 * bootstrap-scrollspy.js v2.3.2
 * http://getbootstrap.com/2.3.2/javascript.html#scrollspy
 * =============================================================
 * Copyright 2013 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ============================================================== */

define([], function () {
  var offset = 10;
  var watching = null;
  var active_id = -1;
  var scroll_el = null;

  // scroll_el ... Container which scolls
  // observe_els ... Elements to observe and report on
  // callback ... Called with 'active' observed
  //
  var scrollspy = function(scroll_el_, observe_els, callback) {
    scroll_el = scroll_el_;
    watching  = _.sortBy(_.map(observe_els.toArray(), function(e, i) {
                    var el = $(e);
                    var offset = el.position().top;
                    return [offset, el, i];
                }), function (a) { return a[0]; });

    scroll_el.scroll(function() {
      var scrollTop = scroll_el.scrollTop() + offset;
      var scrollHeight = scroll_el[0].scrollHeight;
      var maxScroll = scrollHeight - scroll_el.height();

      if (scrollTop >= maxScroll) {
        return activate(watching.length - 1);
      }

      var f = _.find(watching, function(it) {
        return scrollTop < it[0];
      });
      activate(f[2] - 1);
    });

    function activate(target_id) {
      if (target_id < 0) target_id = 0;
      if (target_id == active_id) return;

      active_id = target_id;
      callback(watching[target_id][1]);
    }

    var ctxt = {};
    ctxt.scrollTo = function(scrollTo, offset) {
      if (offset == undefined) { offset = 0; }
      scroll_el.scrollTop(
        scrollTo.offset().top - scroll_el.offset().top + scroll_el.scrollTop() + offset
      );
    };
    return ctxt;
  };

  return scrollspy;

});
