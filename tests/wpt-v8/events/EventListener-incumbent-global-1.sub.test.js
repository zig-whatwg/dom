// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/EventListener-incumbent-global-1.sub.html

var t = async_test("Check the incumbent global EventListeners  are called with");

onload = t.step_func(function() {
  onmessage = t.step_func_done(function(e) {
    var d = e.data;
    assert_equals(d.actual, d.expected, d.reason);
  });

  frames[0].postMessage("start", "*");
});

