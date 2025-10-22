// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/event-disabled-dynamic.html

async_test(t => {
  // NOTE: This test will timeout if it fails.
  window.addEventListener('load', t.step_func(() => {
    let e = document.querySelector('input');
    e.disabled = false;
    e.onclick = t.step_func_done(() => {});
    e.click();
  }));
}, "disabled is honored properly in presence of dynamic changes");

