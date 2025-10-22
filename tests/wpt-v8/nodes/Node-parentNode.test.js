// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Node-parentNode.html

// XXX need to test for more node types
test(function() {
  assert_equals(document.parentNode, null)
}, "Document")
test(function() {
  assert_equals(document.doctype.parentNode, document)
}, "Doctype")
test(function() {
  assert_equals(document.documentElement.parentNode, document)
}, "Root element")
test(function() {
  var el = document.createElement("div")
  assert_equals(el.parentNode, null)
  document.body.appendChild(el)
  assert_equals(el.parentNode, document.body)
}, "Element")
var t = async_test("Removed iframe");
function testIframe(iframe) {
  t.step(function() {
    var doc = iframe.contentDocument;
    iframe.parentNode.removeChild(iframe);
    assert_equals(doc.firstChild.parentNode, doc);
  });
  t.done();
}

