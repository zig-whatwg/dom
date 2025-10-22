// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/DocumentType-literal.html

test(function() {
  var doctype = document.firstChild;
  assert_true(doctype instanceof DocumentType)
  assert_equals(doctype.name, "html")
  assert_equals(doctype.publicId, 'STAFF')
  assert_equals(doctype.systemId, 'staffNS.dtd')
})

