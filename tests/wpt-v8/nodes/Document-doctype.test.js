// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-doctype.html

test(function() {
  assert_true(document.doctype instanceof DocumentType,
              "Doctype should be a DocumentType");
  assert_equals(document.doctype, document.childNodes[1]);
}, "Window document with doctype");

test(function() {
  var newdoc = new Document();
  newdoc.appendChild(newdoc.createElement("html"));
  assert_equals(newdoc.doctype, null);
}, "new Document()");

