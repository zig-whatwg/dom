// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/window-extends-event-target.html

// Setup HTML structure
document.body.innerHTML = `
<script>
"use strict";

test(() => {

  assert_equals(window.addEventListener, EventTarget.prototype.addEventListener);
  assert_equals(window.removeEventListener, EventTarget.prototype.removeEventListener);
  assert_equals(window.dispatchEvent, EventTarget.prototype.dispatchEvent);

}, "EventTarget methods on Window instances are inherited from the EventTarget prototype");

test(() => {

  const kCustom = "custom-event";
  const customEvent = new CustomEvent(kCustom, {
    bubbles: true
  });

  let target;
  window.addEventListener.call(document.body, kCustom, function () {
    target = this;
  });

  document.body.dispatchEvent(customEvent);

  assert_equals(target, document.body);

}, "window.addEventListener respects custom \`this\`");

test(() => {

  const kCustom = "custom-event";
  const customEvent = new CustomEvent(kCustom, {
    bubbles: true
  });

  let target;
  window.addEventListener.call(null, kCustom, function () {
    target = this;
  });

  document.body.dispatchEvent(customEvent);

  assert_equals(target, window);

}, "window.addEventListener treats nullish \`this\` as \`window\`");
</script>
`;

"use strict";

test(() => {

  assert_equals(window.addEventListener, EventTarget.prototype.addEventListener);
  assert_equals(window.removeEventListener, EventTarget.prototype.removeEventListener);
  assert_equals(window.dispatchEvent, EventTarget.prototype.dispatchEvent);

}, "EventTarget methods on Window instances are inherited from the EventTarget prototype");

test(() => {

  const kCustom = "custom-event";
  const customEvent = new CustomEvent(kCustom, {
    bubbles: true
  });

  let target;
  window.addEventListener.call(document.body, kCustom, function () {
    target = this;
  });

  document.body.dispatchEvent(customEvent);

  assert_equals(target, document.body);

}, "window.addEventListener respects custom `this`");

test(() => {

  const kCustom = "custom-event";
  const customEvent = new CustomEvent(kCustom, {
    bubbles: true
  });

  let target;
  window.addEventListener.call(null, kCustom, function () {
    target = this;
  });

  document.body.dispatchEvent(customEvent);

  assert_equals(target, window);

}, "window.addEventListener treats nullish `this` as `window`");

