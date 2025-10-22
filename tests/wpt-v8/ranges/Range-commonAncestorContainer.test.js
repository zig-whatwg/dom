// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/ranges/Range-commonAncestorContainer.html

"use strict";

testRanges.unshift("[detached]");

for (var i = 0; i < testRanges.length; i++) {
  test(function() {
    var range;
    if (i == 0) {
      range = document.createRange();
      range.detach();
    } else {
      range = rangeFromEndpoints(eval(testRanges[i]));
    }

    // "Let container be start node."
    var container = range.startContainer;

    // "While container is not an inclusive ancestor of end node, let
    // container be container's parent."
    while (container != range.endContainer
    && !isAncestor(container, range.endContainer)) {
      container = container.parentNode;
    }

    // "Return container."
    assert_equals(range.commonAncestorContainer, container);
  }, i + ": range " + testRanges[i]);
}

testDiv.style.display = "none";

