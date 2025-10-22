// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/non-cancelable-when-passive/non-passive-touchstart-event-listener-on-window.html

document.body.onload = () => runTest({
    target: window,
    eventName: 'touchstart',
    passive: false,
    expectCancelable: true,
  });

