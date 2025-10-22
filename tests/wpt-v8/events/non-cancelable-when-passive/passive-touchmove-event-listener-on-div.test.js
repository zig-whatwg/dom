// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/non-cancelable-when-passive/passive-touchmove-event-listener-on-div.html

document.body.onload = () => runTest({
    target: document.getElementById('touchDiv'),
    eventName: 'touchmove',
    passive: true,
    expectCancelable: false,
  });

