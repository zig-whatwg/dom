// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Element-remove.html

var node, parentNode;
setup(function() {
  node = document.createElement("div");
  parentNode = document.createElement("div");
});
testRemove(node, parentNode, "element");

