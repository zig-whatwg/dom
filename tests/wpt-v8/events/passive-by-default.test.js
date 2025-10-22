// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/passive-by-default.html

// Setup HTML structure
document.body.innerHTML = `
  <div id="div"></div>
<script>
  function isListenerPassive(eventName, eventTarget, passive, expectPassive) {
    test(() => {
      let defaultPrevented = null;
      let handler = event => {
        event.preventDefault();
        defaultPrevented = event.defaultPrevented;
        eventTarget.removeEventListener(eventName, handler);
      };
      if (passive === 'omitted') {
        eventTarget.addEventListener(eventName, handler);
      } else {
        eventTarget.addEventListener(eventName, handler, {passive});
      }
      let dispatchEventReturnValue = eventTarget.dispatchEvent(new Event(eventName, {cancelable: true}));
      assert_equals(defaultPrevented, !expectPassive, 'defaultPrevented');
      assert_equals(dispatchEventReturnValue, expectPassive, 'dispatchEvent() return value');
    }, \`\${eventName} listener is \${expectPassive ? '' : 'non-'}passive \${passive === 'omitted' ? 'by default' : \`with {passive:\${passive}}\`} for \${eventTarget.constructor.name}\`);
  }

  const eventNames = {
    touchstart: true,
    touchmove: true,
    wheel: true,
    mousewheel: true,
    touchend: false
  };
  const passiveEventTargets = [window, document, document.documentElement, document.body];
  const div = document.getElementById('div');

  for (const eventName in eventNames) {
    for (const eventTarget of passiveEventTargets) {
      isListenerPassive(eventName, eventTarget, 'omitted', eventNames[eventName]);
      isListenerPassive(eventName, eventTarget, undefined, eventNames[eventName]);
      isListenerPassive(eventName, eventTarget, false, false);
      isListenerPassive(eventName, eventTarget, true, true);
    }
    isListenerPassive(eventName, div, 'omitted', false);
    isListenerPassive(eventName, div, undefined, false);
    isListenerPassive(eventName, div, false, false);
    isListenerPassive(eventName, div, true, true);
  }
</script>
`;

function isListenerPassive(eventName, eventTarget, passive, expectPassive) {
    test(() => {
      let defaultPrevented = null;
      let handler = event => {
        event.preventDefault();
        defaultPrevented = event.defaultPrevented;
        eventTarget.removeEventListener(eventName, handler);
      };
      if (passive === 'omitted') {
        eventTarget.addEventListener(eventName, handler);
      } else {
        eventTarget.addEventListener(eventName, handler, {passive});
      }
      let dispatchEventReturnValue = eventTarget.dispatchEvent(new Event(eventName, {cancelable: true}));
      assert_equals(defaultPrevented, !expectPassive, 'defaultPrevented');
      assert_equals(dispatchEventReturnValue, expectPassive, 'dispatchEvent() return value');
    }, `${eventName} listener is ${expectPassive ? '' : 'non-'}passive ${passive === 'omitted' ? 'by default' : `with {passive:${passive}}`} for ${eventTarget.constructor.name}`);
  }

  const eventNames = {
    touchstart: true,
    touchmove: true,
    wheel: true,
    mousewheel: true,
    touchend: false
  };
  const passiveEventTargets = [window, document, document.documentElement, document.body];
  const div = document.getElementById('div');

  for (const eventName in eventNames) {
    for (const eventTarget of passiveEventTargets) {
      isListenerPassive(eventName, eventTarget, 'omitted', eventNames[eventName]);
      isListenerPassive(eventName, eventTarget, undefined, eventNames[eventName]);
      isListenerPassive(eventName, eventTarget, false, false);
      isListenerPassive(eventName, eventTarget, true, true);
    }
    isListenerPassive(eventName, div, 'omitted', false);
    isListenerPassive(eventName, div, undefined, false);
    isListenerPassive(eventName, div, false, false);
    isListenerPassive(eventName, div, true, true);
  }

