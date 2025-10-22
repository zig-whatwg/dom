// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Element-hasAttribute.html

"use strict";

test(() => {

  const el = document.createElement("p");
  el.setAttributeNS("foo", "x", "first");

  assert_true(el.hasAttribute("x"));

}, "hasAttribute should check for attribute presence, irrespective of namespace");

test(() => {

  const el = document.getElementById("t");

  assert_true(el.hasAttribute("data-e2"));
  assert_true(el.hasAttribute("data-E2"));
  assert_true(el.hasAttribute("data-f2"));
  assert_true(el.hasAttribute("data-F2"));

}, "hasAttribute should work with all attribute casings");

