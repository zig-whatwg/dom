// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/getElementsByClassName-whitespace-class-names.html

"use strict";

const spans = document.querySelectorAll("span");

for (const span of spans) {
  test(() => {
    const className = span.getAttribute("class");
    assert_equals(className.length, 1, "Sanity check: the class name was retrieved and is a single character");
    const shouldBeSpan = document.getElementsByClassName(className);
    assert_array_equals(shouldBeSpan, [span]);
  }, `Passing a ${span.textContent} to getElementsByClassName still finds the span`);
}

