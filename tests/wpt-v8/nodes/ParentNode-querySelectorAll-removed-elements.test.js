// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/ParentNode-querySelectorAll-removed-elements.html

"use strict";

setup({ single_test: true });

const container = document.querySelector("#container");
function getIDs() {
  return [...container.querySelectorAll("a.test")].map(el => el.id);
}

container.innerHTML = `<a id="link-a" class="test">a link</a>`;
assert_array_equals(getIDs(), ["link-a"], "Sanity check: initial setup");

container.innerHTML = `<a id="link-b" class="test"><img src="foo.jpg"></a>`;
assert_array_equals(getIDs(), ["link-b"], "After replacement");

container.innerHTML = `<a id="link-a" class="test">a link</a>`;
assert_array_equals(getIDs(), ["link-a"], "After changing back to the original HTML");

done();

