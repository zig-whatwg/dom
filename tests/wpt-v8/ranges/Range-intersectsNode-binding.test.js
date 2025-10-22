// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/ranges/Range-intersectsNode-binding.html

test(function() {
  var r = document.createRange();
  assert_throws_js(TypeError, function() { r.intersectsNode(); });
  assert_throws_js(TypeError, function() { r.intersectsNode(null); });
  assert_throws_js(TypeError, function() { r.intersectsNode(undefined); });
  assert_throws_js(TypeError, function() { r.intersectsNode(42); });
  assert_throws_js(TypeError, function() { r.intersectsNode("foo"); });
  assert_throws_js(TypeError, function() { r.intersectsNode({}); });
  r.detach();
  assert_throws_js(TypeError, function() { r.intersectsNode(); });
  assert_throws_js(TypeError, function() { r.intersectsNode(null); });
  assert_throws_js(TypeError, function() { r.intersectsNode(undefined); });
  assert_throws_js(TypeError, function() { r.intersectsNode(42); });
  assert_throws_js(TypeError, function() { r.intersectsNode("foo"); });
  assert_throws_js(TypeError, function() { r.intersectsNode({}); });
}, "Calling intersectsNode without an argument or with an invalid argument should throw a TypeError.")

