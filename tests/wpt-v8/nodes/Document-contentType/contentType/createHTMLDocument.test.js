// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-contentType/contentType/createHTMLDocument.html

test(function() {
  var doc = document.implementation.createHTMLDocument("test");
  assert_equals(doc.contentType, "text/html");
});

