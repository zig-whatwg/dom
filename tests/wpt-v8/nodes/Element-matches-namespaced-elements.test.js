// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Element-matches-namespaced-elements.html

"use strict";

for (const method of ["matches", "webkitMatchesSelector"]) {
  test(() => {
    assert_true(document.createElementNS("", "element")[method]("element"));
  }, `empty string namespace, ${method}`);

  test(() => {
    assert_true(document.createElementNS("urn:ns", "h")[method]("h"));
  }, `has a namespace, ${method}`);

  test(() => {
    assert_true(document.createElementNS("urn:ns", "h")[method]("*|h"));
  }, `has a namespace, *|, ${method}`);
}

