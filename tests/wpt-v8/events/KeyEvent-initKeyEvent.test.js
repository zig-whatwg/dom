// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/KeyEvent-initKeyEvent.html

// The legacy KeyEvent.initKeyEvent shouldn't be defined in the wild anymore.
// https://www.w3.org/TR/1999/WD-DOM-Level-2-19990923/events.html#Events-Event-initKeyEvent
test(function() {
  const event = document.createEvent("KeyboardEvent");
  assert_true(event?.initKeyEvent === undefined);
}, "KeyboardEvent.initKeyEvent shouldn't be defined (created by createEvent(\"KeyboardEvent\")");

test(function() {
  const event = new KeyboardEvent("keypress");
  assert_true(event?.initKeyEvent === undefined);
}, "KeyboardEvent.initKeyEvent shouldn't be defined (created by constructor)");

test(function() {
  assert_true(KeyboardEvent.prototype.initKeyEvent === undefined);
}, "KeyboardEvent.prototype.initKeyEvent shouldn't be defined");

