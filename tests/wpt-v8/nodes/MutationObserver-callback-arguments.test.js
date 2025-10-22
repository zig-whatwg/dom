// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/MutationObserver-callback-arguments.html

"use strict";

async_test(t => {
  const moTarget = document.querySelector("#mo-target");
  const mo = new MutationObserver(function(records, observer) {
    t.step(() => {
      assert_equals(this, mo);
      assert_equals(arguments.length, 2);
      assert_true(Array.isArray(records));
      assert_equals(records.length, 1);
      assert_true(records[0] instanceof MutationRecord);
      assert_equals(observer, mo);

      mo.disconnect();
      t.done();
    });
  });

  mo.observe(moTarget, {attributes: true});
  moTarget.className = "trigger-mutation";
}, "Callback is invoked with |this| value of MutationObserver and two arguments");

