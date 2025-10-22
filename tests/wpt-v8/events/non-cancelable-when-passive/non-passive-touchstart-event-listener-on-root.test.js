// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/non-cancelable-when-passive/non-passive-touchstart-event-listener-on-root.html

document.body.onload = () => runTest({
    target: document.documentElement,
    eventName: 'touchstart',
    passive: false,
    expectCancelable: true,
  });

