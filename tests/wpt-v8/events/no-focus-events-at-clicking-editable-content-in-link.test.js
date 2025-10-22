// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/no-focus-events-at-clicking-editable-content-in-link.html

// Setup HTML structure
document.body.innerHTML = `
<a href="#"><span contenteditable>Hello</span></a>
<a href="#" contenteditable><span>Hello</span></a>

`;

function promiseTicks() {
  return new Promise(resolve => {
    requestAnimationFrame(() => {
      requestAnimationFrame(resolve);
    });
  });
}

async function clickElementAndCollectFocusEvents(x, y, options) {
  await promiseTicks();
  let events = [];
  for (const eventType of ["focus", "blur", "focusin", "focusout"]) {
    document.addEventListener(eventType, event => {
      events.push(`type: ${event.type}, target: ${event.target.nodeName}`);
    }, {capture: true});
  }

  const waitForClickEvent = new Promise(resolve => {
    addEventListener("click", resolve, {capture: true, once: true});
  });

  await new test_driver
    .Actions()
    .pointerMove(x, y, options)
    .pointerDown()
    .pointerUp()
    .send();

  await waitForClickEvent;
  await promiseTicks();
  return events;
}

promise_test(async t => {
  document.activeElement?.blur();
  const editingHost = document.querySelector("span[contenteditable]");
  editingHost.blur();
  const focusEvents =
    await clickElementAndCollectFocusEvents(5, 5, {origin: editingHost});
  assert_array_equals(
    focusEvents,
    [
      "type: focus, target: SPAN",
      "type: focusin, target: SPAN",
    ],
    "Click event shouldn't cause redundant focus events");
}, "Click editable element in link");

promise_test(async t => {
  document.activeElement?.blur();
  const editingHost = document.querySelector("a[contenteditable]");
  editingHost.blur();
  const focusEvents =
    await clickElementAndCollectFocusEvents(5, 5, {origin: editingHost});
  assert_array_equals(
    focusEvents,
    [
      "type: focus, target: A",
      "type: focusin, target: A",
    ],
    "Click event shouldn't cause redundant focus events");
}, "Click editable link");

