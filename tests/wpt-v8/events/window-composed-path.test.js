// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/window-composed-path.html

// Setup HTML structure
document.body.innerHTML = `

`;

test(() => {
  const target = window;
  const event = new Event("foo");

  function listener(e) {
    assert_array_equals(e.composedPath(), [target]);
  }
  target.addEventListener("foo", listener);
  target.dispatchEvent(event);
  assert_array_equals(event.composedPath(), []);
}, "window target has an empty path after dispatch");

