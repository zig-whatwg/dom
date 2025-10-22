// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-type-empty.html

function do_test(t, e) {
  assert_equals(e.type, "", "type");
  assert_equals(e.bubbles, false, "bubbles");
  assert_equals(e.cancelable, false, "cancelable");

  var target = document.createElement("div");
  var handled = false;
  target.addEventListener("", t.step_func(function(e) {
    handled = true;
  }));
  assert_true(target.dispatchEvent(e));
  assert_true(handled);
}

async_test(function() {
  var e = document.createEvent("Event");
  e.initEvent("", false, false);
  do_test(this, e);
  this.done();
}, "initEvent");

async_test(function() {
  var e = new Event("");
  do_test(this, e);
  this.done();
}, "Constructor");

