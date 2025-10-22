// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/webkit-animation-start-event.html

// Setup HTML structure
document.body.innerHTML = `

<script src="resources/prefixed-animation-event-tests.js"></script>
<script>
'use strict';

runAnimationEventTests({
  unprefixedType: 'animationstart',
  prefixedType: 'webkitAnimationStart',
  animationCssStyle: '1ms',
});
</script>
`;

'use strict';

runAnimationEventTests({
  unprefixedType: 'animationstart',
  prefixedType: 'webkitAnimationStart',
  animationCssStyle: '1ms',
});

