// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/collections/HTMLCollection-supported-property-indices.html

test(function() {
  var collection = document.getElementsByTagName("foo");
  assert_equals(collection.item(-2), null);
  assert_equals(collection.item(-1), null);
  assert_equals(collection.namedItem(-2), document.getElementById("-2"));
  assert_equals(collection.namedItem(-1), document.getElementById("-1"));
  assert_equals(collection[-2], document.getElementById("-2"));
  assert_equals(collection[-1], document.getElementById("-1"));
}, "Handling of property names that look like negative integers");

test(function() {
  var collection = document.getElementsByTagName("foo");
  assert_equals(collection.item(0), document.getElementById("-2"));
  assert_equals(collection.item(1), document.getElementById("-1"));
  assert_equals(collection.namedItem(0), document.getElementById("0"));
  assert_equals(collection.namedItem(1), document.getElementById("1"));
  assert_equals(collection[0], document.getElementById("-2"));
  assert_equals(collection[1], document.getElementById("-1"));
}, "Handling of property names that look like small nonnegative integers");

test(function() {
  var collection = document.getElementsByTagName("foo");
  assert_equals(collection.item(2147483645), null);
  assert_equals(collection.item(2147483646), null);
  assert_equals(collection.item(2147483647), null);
  assert_equals(collection.item(2147483648), null);
  assert_equals(collection.item(2147483649), null);
  assert_equals(collection.namedItem(2147483645),
                document.getElementById("2147483645"));
  assert_equals(collection.namedItem(2147483646),
                document.getElementById("2147483646"));
  assert_equals(collection.namedItem(2147483647),
                document.getElementById("2147483647"));
  assert_equals(collection.namedItem(2147483648),
                document.getElementById("2147483648"));
  assert_equals(collection.namedItem(2147483649),
                document.getElementById("2147483649"));
  assert_equals(collection[2147483645], undefined);
  assert_equals(collection[2147483646], undefined);
  assert_equals(collection[2147483647], undefined);
  assert_equals(collection[2147483648], undefined);
  assert_equals(collection[2147483649], undefined);
}, "Handling of property names that look like integers around 2^31");

test(function() {
  var collection = document.getElementsByTagName("foo");
  assert_equals(collection.item(4294967293), null);
  assert_equals(collection.item(4294967294), null);
  assert_equals(collection.item(4294967295), null);
  assert_equals(collection.item(4294967296), document.getElementById("-2"));
  assert_equals(collection.item(4294967297), document.getElementById("-1"));
  assert_equals(collection.namedItem(4294967293),
                document.getElementById("4294967293"));
  assert_equals(collection.namedItem(4294967294),
                document.getElementById("4294967294"));
  assert_equals(collection.namedItem(4294967295),
                document.getElementById("4294967295"));
  assert_equals(collection.namedItem(4294967296),
                document.getElementById("4294967296"));
  assert_equals(collection.namedItem(4294967297),
                document.getElementById("4294967297"));
  assert_equals(collection[4294967293], undefined);
  assert_equals(collection[4294967294], undefined);
  assert_equals(collection[4294967295], document.getElementById("4294967295"));
  assert_equals(collection[4294967296], document.getElementById("4294967296"));
  assert_equals(collection[4294967297], document.getElementById("4294967297"));
}, "Handling of property names that look like integers around 2^32");

test(function() {
  var elements = document.getElementsByTagName("foo");
  var old_item = elements[0];
  var old_desc = Object.getOwnPropertyDescriptor(elements, 0);
  assert_equals(old_desc.value, old_item);
  assert_true(old_desc.enumerable);
  assert_true(old_desc.configurable);
  assert_false(old_desc.writable);

  elements[0] = 5;
  assert_equals(elements[0], old_item);
  assert_throws_js(TypeError, function() {
    "use strict";
    elements[0] = 5;
  });
  assert_throws_js(TypeError, function() {
    Object.defineProperty(elements, 0, { value: 5 });
  });

  delete elements[0];
  assert_equals(elements[0], old_item);

  assert_throws_js(TypeError, function() {
    "use strict";
    delete elements[0];
  });
  assert_equals(elements[0], old_item);
}, 'Trying to set an expando that would shadow an already-existing indexed property');

test(function() {
  var elements = document.getElementsByTagName("foo");
  var idx = elements.length;
  var old_item = elements[idx];
  var old_desc = Object.getOwnPropertyDescriptor(elements, idx);
  assert_equals(old_item, undefined);
  assert_equals(old_desc, undefined);

  // [[DefineOwnProperty]] will disallow defining an indexed expando.
  elements[idx] = 5;
  assert_equals(elements[idx], undefined);
  assert_throws_js(TypeError, function() {
    "use strict";
    elements[idx] = 5;
  });
  assert_throws_js(TypeError, function() {
    Object.defineProperty(elements, idx, { value: 5 });
  });

  // Check that deletions out of range do not throw
  delete elements[idx];
  (function() {
    "use strict";
    delete elements[idx];
  })();
}, 'Trying to set an expando with an indexed property name past the end of the list');

test(function(){
  var elements = document.getElementsByTagName("foo");
  var old_item = elements[0];
  var old_desc = Object.getOwnPropertyDescriptor(elements, 0);
  assert_equals(old_desc.value, old_item);
  assert_true(old_desc.enumerable);
  assert_true(old_desc.configurable);
  assert_false(old_desc.writable);

  Object.prototype[0] = 5;
  this.add_cleanup(function () { delete Object.prototype[0]; });
  assert_equals(elements[0], old_item);

  delete elements[0];
  assert_equals(elements[0], old_item);

  assert_throws_js(TypeError, function() {
    "use strict";
    delete elements[0];
  });
  assert_equals(elements[0], old_item);
}, 'Trying to delete an indexed property name should never work');

