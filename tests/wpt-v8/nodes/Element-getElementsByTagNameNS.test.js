// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Element-getElementsByTagNameNS.html

var element;
setup(function() {
  element = document.createElement("div");
  element.appendChild(document.createTextNode("text"));
  var p = element.appendChild(document.createElement("p"));
  p.appendChild(document.createElement("a"))
   .appendChild(document.createTextNode("link"));
  p.appendChild(document.createElement("b"))
   .appendChild(document.createTextNode("bold"));
  p.appendChild(document.createElement("em"))
   .appendChild(document.createElement("u"))
   .appendChild(document.createTextNode("emphasized"));
  element.appendChild(document.createComment("comment"));
});

test_getElementsByTagNameNS(element, element);

test(function() {
  assert_array_equals(element.getElementsByTagNameNS("*", element.localName), []);
}, "Matching the context object (wildcard namespace)");

test(function() {
  assert_array_equals(
    element.getElementsByTagNameNS("http://www.w3.org/1999/xhtml",
                                   element.localName),
    []);
}, "Matching the context object (specific namespace)");

