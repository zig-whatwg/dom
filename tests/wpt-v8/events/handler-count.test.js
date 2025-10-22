// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/handler-count.html

// Setup HTML structure
document.body.innerHTML = `
  <div id="target"></div>
`;

let eventTally  = 0;
let nextListenerId = 0;

function createEventTallyListener() {
  return (event) => {
    eventTally++;
  }
}

function resetAndRecordEvents() {
  const target = document.getElementById('target');
  eventTally = 0;
  const ready = new Promise(async resolve => {
    target.addEventListener('click', () => {
      requestAnimationFrame(resolve);
    }, { once: true });
    await new test_driver.Actions()
        .pointerMove(0, 0, {origin: target})
        .pointerDown()
        .pointerUp()
        .send();
  });
  return ready;
}

const variant = location.search.substring(1) || 'window';
let source = undefined;
switch(variant) {
  case 'document':
    source = document;
    break;

  case 'window':
    source = window;
    break;

  case 'element':
    source = document.getElementById('target');
    break;

  default:
    source = window;
}

promise_test(async t => {
  // Add listeners
  const first = createEventTallyListener();
  source.addEventListener('click', first, true);
  await resetAndRecordEvents();
  assert_equals(eventTally, 1, 'After adding first listener');
  const second = createEventTallyListener();
  source.addEventListener('click', second, false);
  await resetAndRecordEvents();
  assert_equals(eventTally, 2, 'After adding second listener');

  // Duplicate listener is discarded.
  source.addEventListener('click', second, false);
  await resetAndRecordEvents();
  assert_equals(eventTally, 2,
                'After adding third listener with matching useCapture');

  // Remove first listener
  source.removeEventListener('click', first, true);
  await resetAndRecordEvents();
  assert_equals(eventTally, 1, 'After removing first listener');

  // Try to remove again.
  source.removeEventListener('click', first, true);
  await resetAndRecordEvents();
  assert_equals(eventTally, 1, 'Cannot remove a second time');

  // Try to remove second, but with mismatched capture
  source.removeEventListener('click', second, true);
  await resetAndRecordEvents();
  assert_equals(eventTally, 1, 'Capture argument must match');

  // Remove second listener.
  source.removeEventListener('click', second, false);
  await resetAndRecordEvents();
  assert_equals(eventTally, 0, 'After removal of second listener');
}, `Test addEventListener/removeEventListener on the ${variant}.`);

promise_test(async t => {
  // Add listener
  source.onclick = createEventTallyListener();
  await resetAndRecordEvents();
  assert_equals(eventTally, 1, 'After adding listener');

  // Replace listener.
  source.onclick = createEventTallyListener();
  await resetAndRecordEvents();
  assert_equals(eventTally, 1, 'After replacing listener');

  // Remove listener
  source.onclick = null;
  await resetAndRecordEvents();
  assert_equals(eventTally, 0, 'After removing listener');
}, `Test setting onanimationstart handler on the ${variant}.`);

