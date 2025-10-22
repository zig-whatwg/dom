// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/remove-and-adopt-thcrash.html

test(() => {
    d1.appendChild(document.createElement("iframe"));
    d2.remove();
    const adopted_div = d1;
    const popup = window.open();
    assert_equals(adopted_div.ownerDocument, document);
    popup.document.body.appendChild(document.body);
    assert_equals(adopted_div.ownerDocument, popup.document);
  }, "Check that removing a node and then adopting its parent into a different window/document doesn't crash.");

