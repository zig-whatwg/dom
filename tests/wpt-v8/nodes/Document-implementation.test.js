// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-implementation.html

test(function() {
  var implementation = document.implementation;
  assert_true(implementation instanceof DOMImplementation,
              "implementation should implement DOMImplementation");
  assert_equals(document.implementation, implementation);
}, "Getting implementation off the same document");

test(function() {
  var doc = document.implementation.createHTMLDocument();
  assert_not_equals(document.implementation, doc.implementation);
}, "Getting implementation off different documents");

