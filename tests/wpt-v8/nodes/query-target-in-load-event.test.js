// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/query-target-in-load-event.html

let test = async_test('document.querySelector(":target") must work when called in the window.load event');
  let iframe = document.querySelector("iframe");
  window.addEventListener("message", test.step_func_done(event => {
    assert_equals(event.data, "PASS");
  }));
  iframe.src = "./query-target-in-load-event.part.html#target";

