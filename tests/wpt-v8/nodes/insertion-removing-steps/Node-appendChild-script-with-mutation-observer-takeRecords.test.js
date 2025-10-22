// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/insertion-removing-steps/Node-appendChild-script-with-mutation-observer-takeRecords.html

// Setup HTML structure
document.body.innerHTML = `
<main></main>
<script>

test(() => {
  window.mutationObserver = new MutationObserver(() => {});
  window.mutationObserver.observe(document.querySelector("main"), {childList: true});
  const script = document.createElement("script");
  script.textContent = \`
    window.mutationRecords = window.mutationObserver.takeRecords();
  \`;
  document.querySelector("main").appendChild(script);
  assert_equals(window.mutationRecords.length, 1);
  assert_array_equals(window.mutationRecords[0].addedNodes, [script]);
}, "An inserted script should be able to observe its own mutation record with takeRecords");
</script>
`;

test(() => {
  window.mutationObserver = new MutationObserver(() => {});
  window.mutationObserver.observe(document.querySelector("main"), {childList: true});
  const script = document.createElement("script");
  script.textContent = `
    window.mutationRecords = window.mutationObserver.takeRecords();
  `;
  document.querySelector("main").appendChild(script);
  assert_equals(window.mutationRecords.length, 1);
  assert_array_equals(window.mutationRecords[0].addedNodes, [script]);
}, "An inserted script should be able to observe its own mutation record with takeRecords");

