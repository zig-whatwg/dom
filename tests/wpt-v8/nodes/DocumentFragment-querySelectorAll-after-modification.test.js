// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/DocumentFragment-querySelectorAll-after-modification.html

"use strict";

setup({ single_test: true });

const frag = document.createDocumentFragment();
frag.appendChild(document.createElement("div"));

assert_array_equals(frag.querySelectorAll("img"), [], "before modification");

frag.appendChild(document.createElement("div"));

// If the bug is present, this will throw.
assert_array_equals(frag.querySelectorAll("img"), [], "after modification");

done();

