// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/ParentNode-querySelector-scope.html

"use strict";
const div = document.querySelector("div");
const p = document.querySelector("p");

test(() => {
  assert_equals(div.querySelector(":scope > p"), p);
  assert_equals(div.querySelector(":scope > span"), null);
}, "querySelector with :scope");

test(() => {
  assert_equals(div.querySelector("#test + p"), p);
  assert_equals(p.querySelector("#test + p"), null);
}, "querySelector with id and sibling");

test(() => {
  assert_array_equals(div.querySelectorAll(":scope > p"), [p]);
  assert_array_equals(div.querySelectorAll(":scope > span"), []);
}, "querySelectorAll with :scope");

test(() => {
  assert_array_equals(div.querySelectorAll("#test + p"), [p]);
  assert_array_equals(p.querySelectorAll("#test + p"), []);
}, "querySelectorAll with id and sibling");

