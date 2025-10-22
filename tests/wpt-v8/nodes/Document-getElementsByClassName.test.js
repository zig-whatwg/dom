// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-getElementsByClassName.html

test(function() {
  var a = document.createElement("a"),
      b = document.createElement("b");
  a.className = "foo";
  this.add_cleanup(function() {document.body.removeChild(a);});
  document.body.appendChild(a);

  var l = document.getElementsByClassName("foo");
  assert_true(l instanceof HTMLCollection);
  assert_equals(l.length, 1);

  b.className = "foo";
  document.body.appendChild(b);
  assert_equals(l.length, 2);

  document.body.removeChild(b);
  assert_equals(l.length, 1);
}, "getElementsByClassName() should be a live collection");

