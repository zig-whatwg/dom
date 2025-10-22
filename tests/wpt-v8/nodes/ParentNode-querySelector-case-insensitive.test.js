// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/ParentNode-querySelector-case-insensitive.html

"use strict";
const input = document.getElementById("testInput");

test(() => {
  assert_equals(document.querySelector("input[name*=user i]"), input);
}, "querySelector");

test(() => {
  assert_array_equals(document.querySelectorAll("input[name*=user i]"), [input]);
}, "querySelectorAll");

