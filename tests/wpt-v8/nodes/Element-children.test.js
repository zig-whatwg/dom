// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Element-children.html

setup(function() {
  // Add some non-HTML elements in there to test what happens with those.
  var container = document.getElementById("test");
  var child = document.createElementNS("", "img");
  child.setAttribute("id", "baz");
  container.appendChild(child);

  child = document.createElementNS("", "img");
  child.setAttribute("name", "qux");
  container.appendChild(child);
});

test(function() {
  var container = document.getElementById("test");
  var result = container.children.item("foo");
  assert_true(result instanceof Element, "Expected an Element.");
  assert_false(result.hasAttribute("id"), "Expected the IDless Element.")
})

test(function() {
  var container = document.getElementById("test");
  var list = container.children;
  var result = [];
  for (var p in list) {
    if (list.hasOwnProperty(p)) {
      result.push(p);
    }
  }
  assert_array_equals(result, ['0', '1', '2', '3', '4', '5']);
  result = Object.getOwnPropertyNames(list);
  assert_array_equals(result, ['0', '1', '2', '3', '4', '5', 'foo', 'bar', 'baz']);

  // Mapping of exposed names to their indices in the list.
  var exposedNames = { 'foo': 1, 'bar': 3, 'baz': 4 };
  for (var exposedName in exposedNames) {
    assert_true(exposedName in list);
    assert_true(list.hasOwnProperty(exposedName));
    assert_equals(list[exposedName], list.namedItem(exposedName));
    assert_equals(list[exposedName], list.item(exposedNames[exposedName]));
    assert_true(list[exposedName] instanceof Element);
  }

  var unexposedNames = ['qux'];
  for (var unexposedName of unexposedNames) {
    assert_false(unexposedName in list);
    assert_false(list.hasOwnProperty(unexposedName));
    assert_equals(list[unexposedName], undefined);
    assert_equals(list.namedItem(unexposedName), null);
  }
});

