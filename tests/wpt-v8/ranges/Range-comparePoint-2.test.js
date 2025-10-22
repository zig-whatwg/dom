// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/ranges/Range-comparePoint-2.html

test(function() {
  var r = document.createRange();
  r.detach()
  assert_equals(r.comparePoint(document.body, 0), 1)
})
test(function() {
  var r = document.createRange();
  assert_throws_js(TypeError, function() { r.comparePoint(null, 0) })
})
test(function() {
  var doc = document.implementation.createHTMLDocument("tralala")
  var r = document.createRange();
  assert_throws_dom("WRONG_DOCUMENT_ERR", function() { r.comparePoint(doc.body, 0) })
})

