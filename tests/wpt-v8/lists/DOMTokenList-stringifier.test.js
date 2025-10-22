// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/lists/DOMTokenList-stringifier.html

test(function() {
  assert_equals(String(document.createElement("span").classList), "",
                "String(classList) should return the empty list for an undefined class attribute");
  var span = document.querySelector("span");
  assert_equals(span.getAttribute("class"), "   a  a b ",
                "getAttribute should return the literal value");
  assert_equals(span.className, "   a  a b ",
                "className should return the literal value");
  assert_equals(String(span.classList), "   a  a b ",
                "String(classList) should return the literal value");
  assert_equals(span.classList.toString(), "   a  a b ",
                "classList.toString() should return the literal value");
  assert_class_string(span.classList, "DOMTokenList");
});

