// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/non-cancelable-when-passive/non-passive-touchmove-event-listener-on-root.html

document.body.onload = () => runTest({
    target: document.documentElement,
    eventName: 'touchmove',
    passive: false,
    expectCancelable: true,
  });

