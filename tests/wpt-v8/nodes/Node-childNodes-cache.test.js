// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Node-childNodes-cache.html

test(function() {
  let target = document.getElementById("target");
  let second = target.childNodes[1];
  assert_equals(second.id, "second");
  second.remove();
  assert_equals(target.childNodes[4], undefined, "Out of bounds elements are undefined");
  assert_equals(target.childNodes[3], undefined, "Out of bounds elements are undefined");
  assert_equals(target.childNodes.length, 3);
  assert_equals(target.childNodes[0].id, "first");
  assert_equals(target.childNodes[1].id, "third");
  assert_equals(target.childNodes[2].id, "last");
});

