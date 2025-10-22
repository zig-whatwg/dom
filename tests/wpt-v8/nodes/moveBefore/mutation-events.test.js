// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/moveBefore/mutation-events.html

// Setup HTML structure
document.body.innerHTML = `
<p id=reference>reference</p>
<p id=target>target</p>


`;

const reference = document.querySelector('#reference');
  const target = document.querySelector('#target');

  test(() => {
    target.addEventListener('DOMNodeInserted', () => assert_unreached('DOMNodeInserted not called'));
    target.addEventListener('DOMNodeRemoved', () => assert_unreached('DOMNodeRemoved not called'));
    document.body.moveBefore(target, reference);
  }, "MutationEvents (if supported by the UA) are suppressed during `moveBefore()`");

