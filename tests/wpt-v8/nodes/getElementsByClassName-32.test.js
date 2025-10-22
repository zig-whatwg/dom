// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/getElementsByClassName-32.html

"use strict";

test(() => {

  const p = document.createElement("p");
  p.className = "unknown";
  document.body.appendChild(p);

  const elements = document.getElementsByClassName("first-p");
  assert_array_equals(elements, []);

}, "cannot find the class name");

test(() => {

  const p = document.createElement("p");
  p.className = "first-p";
  document.body.appendChild(p);

  const elements = document.getElementsByClassName("first-p");
  assert_array_equals(elements, [p]);

}, "finds the class name");


test(() => {

  const p = document.createElement("p");
  p.className = "the-p second third";
  document.body.appendChild(p);

  const elements1 = document.getElementsByClassName("the-p");
  assert_array_equals(elements1, [p]);

  const elements2 = document.getElementsByClassName("second");
  assert_array_equals(elements2, [p]);

  const elements3 = document.getElementsByClassName("third");
  assert_array_equals(elements3, [p]);

}, "finds the same element with multiple class names");

test(() => {

  const elements = document.getElementsByClassName("df-article");

  assert_equals(elements.length, 3);
  assert_array_equals(Array.prototype.map.call(elements, el => el.id), ["1", "2", "3"]);

}, "does not get confused by numeric IDs");

