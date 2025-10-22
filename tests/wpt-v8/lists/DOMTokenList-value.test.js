// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/lists/DOMTokenList-value.html

test(function() {
  assert_equals(String(document.createElement("span").classList.value), "",
                "classList.value should return the empty list for an undefined class attribute");
  var span = document.querySelector("span");
  assert_equals(span.classList.value, "   a  a b ",
                "value should return the literal value");
  span.classList.value = " foo bar foo ";
  assert_equals(span.classList.value, " foo bar foo ",
                "assigning value should set the literal value");
  assert_equals(span.classList.length, 2,
                "length should be the number of tokens");
  assert_class_string(span.classList, "DOMTokenList");
  assert_class_string(span.classList.value, "String");
});

