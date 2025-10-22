// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/ranges/Range-attributes.html

test(function() {
  var r = document.createRange();
  assert_equals(r.startContainer, document)
  assert_equals(r.endContainer, document)
  assert_equals(r.startOffset, 0)
  assert_equals(r.endOffset, 0)
  assert_true(r.collapsed)
  r.detach()
  assert_equals(r.startContainer, document)
  assert_equals(r.endContainer, document)
  assert_equals(r.startOffset, 0)
  assert_equals(r.endOffset, 0)
  assert_true(r.collapsed)
})

