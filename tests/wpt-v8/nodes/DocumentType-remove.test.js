// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/DocumentType-remove.html

var node, parentNode;
setup(function() {
  node = document.implementation.createDocumentType("html", "", "");
  parentNode = document.implementation.createDocument(null, "", null);
});
testRemove(node, parentNode, "doctype");

