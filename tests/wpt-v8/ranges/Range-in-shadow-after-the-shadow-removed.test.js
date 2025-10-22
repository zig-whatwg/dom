// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/ranges/Range-in-shadow-after-the-shadow-removed.html

"use strict";

addEventListener("load", () => {
  const mode = (new URLSearchParams(document.location.search)).get("mode");
  test(() => {
    const host = document.createElement("div");
    host.id = "host";
    const root = host.attachShadow({mode});
    root.innerHTML = '<div id="in-shadow">ABC</div>';
    document.body.appendChild(host);
    const range = document.createRange();
    range.setStart(root.firstChild, 1);
    host.remove();
    assert_equals(range.startContainer, root.firstChild, "startContainer should not be changed");
    assert_equals(range.startOffset, 1, "startOffset should not be changed");
  }, "Range in shadow should stay in the shadow after the host is removed");

  test(() => {
    const wrapper = document.createElement("div");
    wrapper.id = "wrapper";
    const host = document.createElement("div");
    host.id = "host";
    const root = host.attachShadow({mode});
    root.innerHTML = '<div id="in-shadow">ABC</div>';
    wrapper.appendChild(host);
    document.body.appendChild(wrapper);
    const range = document.createRange();
    range.setStart(root.firstChild, 1);
    wrapper.remove();
    assert_equals(range.startContainer, root.firstChild, "startContainer should not be changed");
    assert_equals(range.startOffset, 1, "startOffset should not be changed");
  }, "Range in shadow should stay in the shadow after the host parent is removed");
}, {once: true});

