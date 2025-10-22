// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/CharacterData-appendChild.html

function create(type) {
  switch (type) {
    case "Text": return document.createTextNode("test"); break;
    case "Comment": return document.createComment("test"); break;
    case "ProcessingInstruction": return document.createProcessingInstruction("target", "test"); break;
  }
}

function testNode(type1, type2) {
  test(function() {
    var node1 = create(type1);
    var node2 = create(type2);
    assert_throws_dom("HierarchyRequestError", function () {
      node1.appendChild(node2);
    }, "CharacterData type " + type1 + " must not have children");
  }, type1 + ".appendChild(" + type2 + ")");
}

var types = ["Text", "Comment", "ProcessingInstruction"];
types.forEach(function(type1) {
  types.forEach(function(type2) {
    testNode(type1, type2);
  });
});

