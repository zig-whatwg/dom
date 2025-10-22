// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Node-contains.html

"use strict";

testNodes.forEach(function(referenceName) {
  var reference = eval(referenceName);

  test(function() {
    assert_false(reference.contains(null));
  }, referenceName + ".contains(null)");

  testNodes.forEach(function(otherName) {
    var other = eval(otherName);
    test(function() {
      var ancestor = other;
      while (ancestor && ancestor !== reference) {
        ancestor = ancestor.parentNode;
      }
      if (ancestor === reference) {
        assert_true(reference.contains(other));
      } else {
        assert_false(reference.contains(other));
      }
    }, referenceName + ".contains(" + otherName + ")");
  });
});

testDiv.parentNode.removeChild(testDiv);

