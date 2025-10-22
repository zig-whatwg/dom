// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-type.html

test(function() {
  var e = document.createEvent("Event")
  assert_equals(e.type, "");
}, "Event.type should initially be the empty string");
test(function() {
  var e = document.createEvent("Event")
  e.initEvent("foo", false, false)
  assert_equals(e.type, "foo")
}, "Event.type should be initialized by initEvent");
test(function() {
  var e = new Event("bar")
  assert_equals(e.type, "bar")
}, "Event.type should be initialized by the constructor");

