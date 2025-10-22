// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Node-isConnected-shadow-dom.html

// Setup HTML structure
document.body.innerHTML = `
<script>
"use strict";

function testIsConnected(mode) {
  test(() => {
    const host = document.createElement("div");
    document.body.appendChild(host);

    const root = host.attachShadow({ mode });

    const node = document.createElement("div");
    root.appendChild(node);

    assert_true(node.isConnected);
  }, \`Node.isConnected in a \${mode} shadow tree\`);
}

for (const mode of ["closed", "open"]) {
  testIsConnected(mode);
}
</script>
`;

"use strict";

function testIsConnected(mode) {
  test(() => {
    const host = document.createElement("div");
    document.body.appendChild(host);

    const root = host.attachShadow({ mode });

    const node = document.createElement("div");
    root.appendChild(node);

    assert_true(node.isConnected);
  }, `Node.isConnected in a ${mode} shadow tree`);
}

for (const mode of ["closed", "open"]) {
  testIsConnected(mode);
}

