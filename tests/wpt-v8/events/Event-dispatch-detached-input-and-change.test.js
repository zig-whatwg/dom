// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-dispatch-detached-input-and-change.html

// Setup HTML structure
document.body.innerHTML = `

`;

test(() => {
  const input = document.createElement('input');
  input.type = 'checkbox';

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.click();
  assert_false(inputEventFired);
  assert_false(changeEventFired);
}, 'detached checkbox should not emit input or change events on click().');

test(() => {
  const input = document.createElement('input');
  input.type = 'radio';

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.click();
  assert_false(inputEventFired);
  assert_false(changeEventFired);
}, 'detached radio should not emit input or change events on click().');

test(() => {
  const input = document.createElement('input');
  input.type = 'checkbox';

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.dispatchEvent(new MouseEvent('click'));
  assert_false(inputEventFired);
  assert_false(changeEventFired);
}, `detached checkbox should not emit input or change events on dispatchEvent(new MouseEvent('click')).`);

test(() => {
  const input = document.createElement('input');
  input.type = 'radio';

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.dispatchEvent(new MouseEvent('click'));
  assert_false(inputEventFired);
  assert_false(changeEventFired);
}, `detached radio should not emit input or change events on dispatchEvent(new MouseEvent('click')).`);


test(() => {
  const input = document.createElement('input');
  input.type = 'checkbox';
  document.body.appendChild(input);

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.click();
  assert_true(inputEventFired);
  assert_true(changeEventFired);
}, 'attached checkbox should emit input and change events on click().');

test(() => {
  const input = document.createElement('input');
  input.type = 'radio';
  document.body.appendChild(input);

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.click();
  assert_true(inputEventFired);
  assert_true(changeEventFired);
}, 'attached radio should emit input and change events on click().');

test(() => {
  const input = document.createElement('input');
  input.type = 'checkbox';
  document.body.appendChild(input);

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.dispatchEvent(new MouseEvent('click'));
  assert_true(inputEventFired);
  assert_true(changeEventFired);
}, `attached checkbox should emit input and change events on dispatchEvent(new MouseEvent('click')).`);

test(() => {
  const input = document.createElement('input');
  input.type = 'radio';
  document.body.appendChild(input);

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.dispatchEvent(new MouseEvent('click'));
  assert_true(inputEventFired);
  assert_true(changeEventFired);
}, `attached radio should emit input and change events on dispatchEvent(new MouseEvent('click')).`);


test(() => {
  const input = document.createElement('input');
  input.type = 'checkbox';
  const shadowHost = document.createElement('div');
  document.body.appendChild(shadowHost);
  const shadowRoot = shadowHost.attachShadow({mode: 'open'});
  shadowRoot.appendChild(input);

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.click();
  assert_true(inputEventFired);
  assert_true(changeEventFired);
}, 'attached to shadow dom checkbox should emit input and change events on click().');

test(() => {
  const input = document.createElement('input');
  input.type = 'radio';
  const shadowHost = document.createElement('div');
  document.body.appendChild(shadowHost);
  const shadowRoot = shadowHost.attachShadow({mode: 'open'});
  shadowRoot.appendChild(input);

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.click();
  assert_true(inputEventFired);
  assert_true(changeEventFired);
}, 'attached to shadow dom radio should emit input and change events on click().');

test(() => {
  const input = document.createElement('input');
  input.type = 'checkbox';
  const shadowHost = document.createElement('div');
  document.body.appendChild(shadowHost);
  const shadowRoot = shadowHost.attachShadow({mode: 'open'});
  shadowRoot.appendChild(input);

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.dispatchEvent(new MouseEvent('click'));
  assert_true(inputEventFired);
  assert_true(changeEventFired);
}, `attached to shadow dom checkbox should emit input and change events on dispatchEvent(new MouseEvent('click')).`);

test(() => {
  const input = document.createElement('input');
  input.type = 'radio';
  const shadowHost = document.createElement('div');
  document.body.appendChild(shadowHost);
  const shadowRoot = shadowHost.attachShadow({mode: 'open'});
  shadowRoot.appendChild(input);

  let inputEventFired = false;
  input.addEventListener('input', () => inputEventFired = true);
  let changeEventFired = false;
  input.addEventListener('change', () => changeEventFired = true);
  input.dispatchEvent(new MouseEvent('click'));
  assert_true(inputEventFired);
  assert_true(changeEventFired);
}, `attached to shadow dom radio should emit input and change events on dispatchEvent(new MouseEvent('click')).`);

