// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/focus-event-document-move.html

function handleDown(node) {
    var d2 = new Document();
    d2.appendChild(node);
  }

const target = document.getElementById('click');
  async_test(t => {
    let actions = new test_driver.Actions()
      .pointerMove(0, 0, {origin: target})
      .pointerDown()
      .pointerUp()
      .send()
      .then(t.step_func_done(() => {
        assert_equals(null,document.getElementById('click'));
      }))
      .catch(e => t.step_func(() => assert_unreached('Error')));
  },'Moving a node during mousedown should not crash');

