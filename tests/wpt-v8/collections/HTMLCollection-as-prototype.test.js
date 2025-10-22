// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/collections/HTMLCollection-as-prototype.html

test(function() {
  var obj = Object.create(document.getElementsByTagName("script"));
  assert_throws_js(TypeError, function() {
    obj.length;
  });
}, "HTMLCollection as a prototype should not allow getting .length on the base object")

test(function() {
  var element = document.createElement("p");
  element.id = "named";
  document.body.appendChild(element);
  this.add_cleanup(function() { element.remove() });

  var collection = document.getElementsByTagName("p");
  assert_equals(collection.named, element);
  var object = Object.create(collection);
  assert_equals(object.named, element);
  object.named = "foo";
  assert_equals(object.named, "foo");
  assert_equals(collection.named, element);
}, "HTMLCollection as a prototype and setting own properties")

