// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/ParentNode-querySelectors-namespaces.html

"use strict";

setup({ single_test: true });

const el = document.getElementById("thesvg");

assert_equals(document.querySelector("[*|href]"), el);
assert_array_equals(document.querySelectorAll("[*|href]"), [el]);

done();

