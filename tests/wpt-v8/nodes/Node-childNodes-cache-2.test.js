// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Node-childNodes-cache-2.html

test(function() {
  let target = document.getElementById("target");
  assert_array_equals(Array.from(target.childNodes).map(node => node.id), ["first", "second", "third", "last"]);
  target.replaceChild(target.childNodes[2], target.childNodes[1]);
  assert_array_equals(Array.from(target.childNodes).map(node => node.id), ["first", "third", "last"]);
});

