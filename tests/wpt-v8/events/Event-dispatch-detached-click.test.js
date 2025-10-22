// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-dispatch-detached-click.html

test(function() {
  var EVENT = "click";
  var TARGET = document.createElement("somerandomelement");
  var t = async_test("Click event can be dispatched to an element that is not in the document.")
  TARGET.addEventListener(EVENT, t.step_func(function(evt) {
    assert_equals(evt.target, TARGET);
    assert_equals(evt.srcElement, TARGET);
    t.done();
  }), true);
  var e = document.createEvent("Event");
  e.initEvent(EVENT, true, true);
  TARGET.dispatchEvent(e);
});

