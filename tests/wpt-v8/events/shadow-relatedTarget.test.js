// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/shadow-relatedTarget.html

const root = host.attachShadow({ mode: "closed" });
root.innerHTML = "<input id='shadowInput'>";

async_test((test) => {
  root.getElementById("shadowInput").focus();
  window.addEventListener("focus", test.step_func_done((e) => {
    assert_equals(e.relatedTarget, host);
  }, "relatedTarget should be pointing to shadow host."), true);
  lightInput.focus();
}, "relatedTarget should not leak at capturing phase, at window object.");

async_test((test) => {
  root.getElementById("shadowInput").focus();
  lightInput.addEventListener("focus", test.step_func_done((e) => {
    assert_equals(e.relatedTarget, host);
  }, "relatedTarget should be pointing to shadow host."), true);
  lightInput.focus();
}, "relatedTarget should not leak at target.");

