// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Element-removeAttributeNS.html

var XML = "http://www.w3.org/XML/1998/namespace"

test(function() {
  var el = document.createElement("foo")
  el.setAttributeNS(XML, "a:bb", "pass")
  attr_is(el.attributes[0], "pass", "bb", XML, "a", "a:bb")
  el.removeAttributeNS(XML, "a:bb")
  assert_equals(el.attributes.length, 1)
  attr_is(el.attributes[0], "pass", "bb", XML, "a", "a:bb")
}, "removeAttributeNS should take a local name.")

