// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/webkit-transition-end-event.html

// Setup HTML structure
document.body.innerHTML = `

<script src="resources/prefixed-animation-event-tests.js"></script>
<script>
'use strict';

runAnimationEventTests({
  isTransition: true,
  unprefixedType: 'transitionend',
  prefixedType: 'webkitTransitionEnd',
  animationCssStyle: '1ms',
});
</script>
`;

'use strict';

runAnimationEventTests({
  isTransition: true,
  unprefixedType: 'transitionend',
  prefixedType: 'webkitTransitionEnd',
  animationCssStyle: '1ms',
});

