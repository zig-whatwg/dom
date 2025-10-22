// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/svg-template-querySelector.html

"use strict";

test(() => {
  const fragment = document.querySelector("#template1").content;
  assert_not_equals(fragment.querySelector("div"), null);
}, "querySelector works on template contents fragments with HTML elements (sanity check)");

test(() => {
  const fragment = document.querySelector("#template2").content;
  assert_not_equals(fragment.querySelector("svg"), null);
}, "querySelector works on template contents fragments with SVG elements");

test(() => {
  const fragment = document.querySelector("#template3").content;
  assert_not_equals(fragment.firstChild.querySelector("svg"), null);
}, "querySelector works on template contents fragments with nested SVG elements");

