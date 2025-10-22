// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/non-cancelable-when-passive/passive-touchstart-event-listener-on-window.html

document.body.onload = () => runTest({
    target: window,
    eventName: 'touchstart',
    passive: true,
    expectCancelable: false,
  });

