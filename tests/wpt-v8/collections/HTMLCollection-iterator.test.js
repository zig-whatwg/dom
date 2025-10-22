// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/collections/HTMLCollection-iterator.html

"use strict";

const paragraphs = document.getElementsByTagName("p");

test(() => {
  assert_true("length" in paragraphs);
}, "HTMLCollection has length method.");

test(() => {
  assert_false("values" in paragraphs);
}, "HTMLCollection does not have iterable's values method.");

test(() => {
  assert_false("entries" in paragraphs);
}, "HTMLCollection does not have iterable's entries method.");

test(() => {
  assert_false("forEach" in paragraphs);
}, "HTMLCollection does not have iterable's forEach method.");

test(() => {
  assert_true(Symbol.iterator in paragraphs);
}, "HTMLCollection has Symbol.iterator.");

test(() => {
  const ids = "12345";
  let idx = 0;
  for (const element of paragraphs) {
    assert_equals(element.getAttribute("id"), ids[idx++]);
  }
}, "HTMLCollection is iterable via for-of loop.");

