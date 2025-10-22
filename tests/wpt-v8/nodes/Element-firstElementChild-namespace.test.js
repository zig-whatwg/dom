// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Element-firstElementChild-namespace.html

test(function() {
  var parentEl = document.getElementById("parentEl")
  var el = document.createElementNS("http://ns.example.org/pickle", "pickle:dill")
  el.setAttribute("id", "first_element_child")
  parentEl.appendChild(el)
  var fec = parentEl.firstElementChild
  assert_true(!!fec)
  assert_equals(fec.nodeType, 1)
  assert_equals(fec.getAttribute("id"), "first_element_child")
  assert_equals(fec.localName, "dill")
})

