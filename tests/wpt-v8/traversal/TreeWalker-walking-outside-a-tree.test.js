// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/traversal/TreeWalker-walking-outside-a-tree.html

// Setup HTML structure
document.body.innerHTML = `
<p>[Acid3 - Test 006a] walking outside a tree</p>

`;

test(function () {
    // test 6: walking outside a tree
    var doc = document.createElement("div");
    var head = document.createElement('head');
    var title = document.createElement('title');
    var body = document.createElement('body');
    var p = document.createElement('p');
    doc.appendChild(head);
    head.appendChild(title);
    doc.appendChild(body);
    body.appendChild(p);

    var w = document.createTreeWalker(body, 0xFFFFFFFF, null);
    doc.removeChild(body);
    assert_equals(w.lastChild(), p, "TreeWalker failed after removing the current node from the tree");
    doc.appendChild(p);
    assert_equals(w.previousNode(), title, "failed to handle regrafting correctly");
    p.appendChild(body);
    assert_equals(w.nextNode(), p, "couldn't retrace steps");
    assert_equals(w.nextNode(), body, "couldn't step back into root");
    assert_equals(w.previousNode(), null, "root didn't retake its rootish position");
}, "walking outside a tree");

