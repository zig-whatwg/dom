// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Element-setAttribute.html

"use strict";

test(() => {

  const el = document.createElement("p");
  el.setAttributeNS("foo", "x", "first");
  el.setAttributeNS("foo2", "x", "second");

  el.setAttribute("x", "changed");

  assert_equals(el.attributes.length, 2);
  assert_equals(el.getAttribute("x"), "changed");
  assert_equals(el.getAttributeNS("foo", "x"), "changed");
  assert_equals(el.getAttributeNS("foo2", "x"), "second");

}, "setAttribute should change the first attribute, irrespective of namespace");

test(() => {
  // https://github.com/whatwg/dom/issues/31

  const el = document.createElement("p");
  el.setAttribute("FOO", "bar");

  assert_equals(el.getAttribute("foo"), "bar");
  assert_equals(el.getAttribute("FOO"), "bar");
  assert_equals(el.getAttributeNS("", "foo"), "bar");
  assert_equals(el.getAttributeNS("", "FOO"), null);

}, "setAttribute should lowercase before setting");

