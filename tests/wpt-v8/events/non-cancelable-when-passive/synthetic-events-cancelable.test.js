// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/non-cancelable-when-passive/synthetic-events-cancelable.html

const eventsMap = {
  wheel: 'WheelEvent',
  mousewheel: 'WheelEvent',
  touchstart: 'TouchEvent',
  touchmove: 'TouchEvent',
  touchend: 'TouchEvent',
  touchcancel: 'TouchEvent',
}
function isCancelable(eventName, interfaceName) {
  test(() => {
    assert_implements(interfaceName in self, `${interfaceName} should be supported`);
    let defaultPrevented = null;
    addEventListener(eventName, event => {
      event.preventDefault();
      defaultPrevented = event.defaultPrevented;
    });
    const event = new self[interfaceName](eventName);
    assert_false(event.cancelable, 'cancelable');
    const dispatchEventReturnValue = dispatchEvent(event);
    assert_false(defaultPrevented, 'defaultPrevented');
    assert_true(dispatchEventReturnValue, 'dispatchEvent() return value');
  }, `Synthetic ${eventName} event with interface ${interfaceName} is not cancelable`);
}
for (const eventName in eventsMap) {
  isCancelable(eventName, eventsMap[eventName]);
  isCancelable(eventName, 'Event');
}

