// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/non-cancelable-when-passive/passive-touchstart-event-listener-on-div.html

document.body.onload = () => runTest({
    target: document.getElementById('touchDiv'),
    eventName: 'touchstart',
    passive: true,
    expectCancelable: false,
  });

