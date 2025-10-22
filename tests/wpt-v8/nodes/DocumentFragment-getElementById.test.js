// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/DocumentFragment-getElementById.html

"use strict";

test(() => {
  assert_equals(typeof DocumentFragment.prototype.getElementById, "function", "It must exist on the prototype");
  assert_equals(typeof document.createDocumentFragment().getElementById, "function", "It must exist on an instance");
}, "The method must exist");

test(() => {
  assert_equals(document.createDocumentFragment().getElementById("foo"), null);
  assert_equals(document.createDocumentFragment().getElementById(""), null);
}, "It must return null when there are no matches");

test(() => {
  const frag = document.createDocumentFragment();
  frag.appendChild(document.createElement("div"));
  frag.appendChild(document.createElement("span"));
  frag.childNodes[0].id = "foo";
  frag.childNodes[1].id = "foo";

  assert_equals(frag.getElementById("foo"), frag.childNodes[0]);
}, "It must return the first element when there are matches");

test(() => {
  const frag = document.createDocumentFragment();
  frag.appendChild(document.createElement("div"));
  frag.childNodes[0].setAttribute("id", "");

  assert_equals(
    frag.getElementById(""),
    null,
    "Even if there is an element with an empty-string ID attribute, it must not be returned"
  );
}, "Empty string ID values");

test(() => {
  const frag = document.querySelector("template").content;

  assert_true(frag.getElementById("foo").hasAttribute("data-yes"));
}, "It must return the first element when there are matches, using a template");

