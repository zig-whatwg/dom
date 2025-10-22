// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/non-cancelable-when-passive/passive-touchmove-event-listener-on-document.html

document.body.onload = () => runTest({
    target: document,
    eventName: 'touchmove',
    passive: true,
    expectCancelable: false,
  });

