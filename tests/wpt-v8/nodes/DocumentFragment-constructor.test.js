// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/DocumentFragment-constructor.html

"use strict";

test(() => {
  const fragment = new DocumentFragment();
  assert_equals(fragment.ownerDocument, document);
}, "Sets the owner document to the current global object associated document");

test(() => {
  const fragment = new DocumentFragment();
  const text = document.createTextNode("");
  fragment.appendChild(text);
  assert_equals(fragment.firstChild, text);
}, "Create a valid document DocumentFragment");

