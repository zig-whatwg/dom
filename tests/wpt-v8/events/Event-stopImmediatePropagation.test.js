// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-stopImmediatePropagation.html

"use strict";

setup({ single_test: true });

const target = document.querySelector("#target");

let timesCalled = 0;
target.addEventListener("test", e => {
  ++timesCalled;
  e.stopImmediatePropagation();
  assert_equals(e.cancelBubble, true, "The stop propagation flag must have been set");
});
target.addEventListener("test", () => {
  ++timesCalled;
});

const e = new Event("test");
target.dispatchEvent(e);
assert_equals(timesCalled, 1, "The second listener must not have been called");

done();

