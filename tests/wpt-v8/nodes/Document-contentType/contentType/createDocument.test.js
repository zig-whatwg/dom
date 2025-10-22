// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-contentType/contentType/createDocument.html

test(function() {
  var doc = document.implementation.createDocument("http://www.w3.org/1999/xhtml", "html", null);
  assert_equals(doc.contentType, "application/xhtml+xml");
});

