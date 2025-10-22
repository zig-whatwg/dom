// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-stopPropagation-cancel-bubbling.html

// Setup HTML structure
document.body.innerHTML = `
<script>
test(t => {
  const element = document.createElement('div');

  element.addEventListener('click', () => {
    event.stopPropagation();
  }, { capture: true });

  element.addEventListener('click',
    t.unreached_func('stopPropagation in the capture handler should have canceled this bubble handler.'));

  element.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
});
</script>
`;

test(t => {
  const element = document.createElement('div');

  element.addEventListener('click', () => {
    event.stopPropagation();
  }, { capture: true });

  element.addEventListener('click',
    t.unreached_func('stopPropagation in the capture handler should have canceled this bubble handler.'));

  element.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
});

