// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Node-cloneNode-XMLDocument.html

"use strict";

test(() => {
  const doc = document.implementation.createDocument("namespace", "");

  assert_equals(
    doc.constructor, XMLDocument,
    "Precondition check: document.implementation.createDocument() creates an XMLDocument"
  );

  const clone = doc.cloneNode(true);

  assert_equals(clone.constructor, XMLDocument);
}, "Created with createDocument");

