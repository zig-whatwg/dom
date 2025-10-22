// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/getElementsByClassName-empty-set.html

"use strict";

test(() => {
  const elements = document.getElementsByClassName("");
  assert_array_equals(elements, []);
}, "Passing an empty string to getElementsByClassName should return an empty HTMLCollection");

test(() => {
  const elements = document.getElementsByClassName(" ");
  assert_array_equals(elements, []);
}, "Passing a space to getElementsByClassName should return an empty HTMLCollection");

test(() => {
  const elements = document.getElementsByClassName("   ");
  assert_array_equals(elements, []);
}, "Passing three spaces to getElementsByClassName should return an empty HTMLCollection");

