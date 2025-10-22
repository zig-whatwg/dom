// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/non-cancelable-when-passive/passive-touchstart-event-listener-on-body.html

document.body.onload = () => runTest({
    target: document.body,
    eventName: 'touchstart',
    passive: true,
    expectCancelable: false,
  });

