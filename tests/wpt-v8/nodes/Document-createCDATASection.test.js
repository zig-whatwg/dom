// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-createCDATASection.html

"use strict";

setup({ single_test: true });

assert_throws_dom("NotSupportedError", () => document.createCDATASection("foo"));

done();

