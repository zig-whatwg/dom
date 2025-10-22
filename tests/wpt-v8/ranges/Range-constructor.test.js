// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/ranges/Range-constructor.html

"use strict";

test(function() {
    var range = new Range();
    assert_equals(range.startContainer, document, "startContainer");
    assert_equals(range.endContainer, document, "endContainer");
    assert_equals(range.startOffset, 0, "startOffset");
    assert_equals(range.endOffset, 0, "endOffset");
    assert_true(range.collapsed, "collapsed");
    assert_equals(range.commonAncestorContainer, document,
                  "commonAncestorContainer");
});

