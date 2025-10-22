// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/webkit-animation-iteration-event.html

// Setup HTML structure
document.body.innerHTML = `

<script src="resources/prefixed-animation-event-tests.js"></script>
<script>
'use strict';

runAnimationEventTests({
  unprefixedType: 'animationiteration',
  prefixedType: 'webkitAnimationIteration',
  // Use a long duration to avoid missing the animation due to slow machines,
  // but set a negative delay so that the iteration boundary happens shortly
  // after the animation starts.
  animationCssStyle: '100s -99.9s 2',
});
</script>
`;

'use strict';

runAnimationEventTests({
  unprefixedType: 'animationiteration',
  prefixedType: 'webkitAnimationIteration',
  // Use a long duration to avoid missing the animation due to slow machines,
  // but set a negative delay so that the iteration boundary happens shortly
  // after the animation starts.
  animationCssStyle: '100s -99.9s 2',
});

