// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/non-cancelable-when-passive/non-passive-touchstart-event-listener-on-document.html

document.body.onload = () => runTest({
    target: document,
    eventName: 'touchstart',
    passive: false,
    expectCancelable: true,
  });

