// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Node-cloneNode-document-with-doctype.html

"use strict";

test(() => {
  const doctype = document.implementation.createDocumentType("name", "publicId", "systemId");
  const doc = document.implementation.createDocument("namespace", "", doctype);

  const clone = doc.cloneNode(true);

  assert_equals(clone.childNodes.length, 1, "Only one child node");
  assert_equals(clone.childNodes[0].nodeType, Node.DOCUMENT_TYPE_NODE, "Is a document fragment");
  assert_equals(clone.childNodes[0].name, "name");
  assert_equals(clone.childNodes[0].publicId, "publicId");
  assert_equals(clone.childNodes[0].systemId, "systemId");
}, "Created with the createDocument/createDocumentType");

test(() => {
  const doc = document.implementation.createHTMLDocument();

  const clone = doc.cloneNode(true);

  assert_equals(clone.childNodes.length, 2, "Two child nodes");
  assert_equals(clone.childNodes[0].nodeType, Node.DOCUMENT_TYPE_NODE, "Is a document fragment");
  assert_equals(clone.childNodes[0].name, "html");
  assert_equals(clone.childNodes[0].publicId, "");
  assert_equals(clone.childNodes[0].systemId, "");
}, "Created with the createHTMLDocument");

test(() => {
  const parser = new window.DOMParser();
  const doc = parser.parseFromString("<!DOCTYPE html><html></html>", "text/html");

  const clone = doc.cloneNode(true);

  assert_equals(clone.childNodes.length, 2, "Two child nodes");
  assert_equals(clone.childNodes[0].nodeType, Node.DOCUMENT_TYPE_NODE, "Is a document fragment");
  assert_equals(clone.childNodes[0].name, "html");
  assert_equals(clone.childNodes[0].publicId, "");
  assert_equals(clone.childNodes[0].systemId, "");
}, "Created with DOMParser");

