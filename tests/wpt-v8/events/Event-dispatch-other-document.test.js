// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-dispatch-other-document.html

test(function() {
  var doc = document.implementation.createHTMLDocument("Demo");
  var element = doc.createElement("div");
  var called = false;
  element.addEventListener("foo", this.step_func(function(ev) {
    assert_false(called);
    called = true;
    assert_equals(ev.target, element);
    assert_equals(ev.srcElement, element);
  }));
  doc.body.appendChild(element);

  var event = new Event("foo");
  element.dispatchEvent(event);
  assert_true(called);
});

