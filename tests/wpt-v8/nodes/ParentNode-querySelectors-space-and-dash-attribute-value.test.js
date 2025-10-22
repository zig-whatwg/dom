// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/ParentNode-querySelectors-space-and-dash-attribute-value.html

"use strict";
const el = document.getElementById("testme");

test(() => {
  assert_equals(document.querySelector("a[title='test with - dash and space']"), el);
}, "querySelector");

test(() => {
  assert_array_equals(document.querySelectorAll("a[title='test with - dash and space']"), [el]);
}, "querySelectorAll");

