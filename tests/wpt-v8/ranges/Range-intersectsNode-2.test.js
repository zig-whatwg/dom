// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/ranges/Range-intersectsNode-2.html

// Taken from Chromium bug: http://crbug.com/822510
test(() => {
  const range = new Range();
  const div = document.getElementById('div');
  const s0 = document.getElementById('s0');
  const s1 = document.getElementById('s1');
  const s2 = document.getElementById('s2');

  // Range encloses s0
  range.setStart(div, 0);
  range.setEnd(div, 1);
  assert_true(range.intersectsNode(s0), '[s0] range.intersectsNode(s0)');
  assert_false(range.intersectsNode(s1), '[s0] range.intersectsNode(s1)');
  assert_false(range.intersectsNode(s2), '[s0] range.intersectsNode(s2)');

  // Range encloses s1
  range.setStart(div, 1);
  range.setEnd(div, 2);
  assert_false(range.intersectsNode(s0), '[s1] range.intersectsNode(s0)');
  assert_true(range.intersectsNode(s1), '[s1] range.intersectsNode(s1)');
  assert_false(range.intersectsNode(s2), '[s1] range.intersectsNode(s2)');

  // Range encloses s2
  range.setStart(div, 2);
  range.setEnd(div, 3);
  assert_false(range.intersectsNode(s0), '[s2] range.intersectsNode(s0)');
  assert_false(range.intersectsNode(s1), '[s2] range.intersectsNode(s1)');
  assert_true(range.intersectsNode(s2), '[s2] range.intersectsNode(s2)');
}, 'Range.intersectsNode() simple cases');

