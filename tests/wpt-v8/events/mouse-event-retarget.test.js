// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/mouse-event-retarget.html

async_test(t => {
  target.addEventListener('click', ev => {
    t.step(() => assert_equals(ev.offsetX, 42));
    t.done();
  });

  const ev = new MouseEvent('click', { clientX: 50 });
  target.dispatchEvent(ev);
}, "offsetX is correctly adjusted");

