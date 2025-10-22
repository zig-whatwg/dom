// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/ParentNode-querySelectors-exclusive.html

"use strict";

setup({ single_test: true });

const button = document.createElement("button");

assert_equals(button.querySelector("*"), null, "querySelector, '*', before modification");
assert_equals(button.querySelector("button"), null, "querySelector, 'button', before modification");
assert_equals(button.querySelector("button, span"), null, "querySelector, 'button, span', before modification");
assert_array_equals(button.querySelectorAll("*"), [], "querySelectorAll, '*', before modification");
assert_array_equals(button.querySelectorAll("button"), [], "querySelectorAll, 'button', before modification");
assert_array_equals(
  button.querySelectorAll("button, span"), [],
  "querySelectorAll, 'button, span', before modification"
);


button.innerHTML = "text";

assert_equals(button.querySelector("*"), null, "querySelector, '*', after modification");
assert_equals(button.querySelector("button"), null, "querySelector, 'button', after modification");
assert_equals(button.querySelector("button, span"), null, "querySelector, 'button, span', after modification");
assert_array_equals(button.querySelectorAll("*"), [], "querySelectorAll, '*', after modification");
assert_array_equals(button.querySelectorAll("button"), [], "querySelectorAll, 'button', after modification");
assert_array_equals(
  button.querySelectorAll("button, span"), [],
  "querySelectorAll, 'button, span', after modification"
);

done();

