// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/insertion-removing-steps/Node-appendChild-text-in-script.tentative.html

// Setup HTML structure
document.body.innerHTML = `
  <script id="script"></script>
<script>
const happened = [];
test(() => {
  const script = document.getElementById("script");
  const df = document.createDocumentFragment();
  df.appendChild(new Text("happened.push('t1');"));
  df.appendChild(new Text("happened.push('t2');"));
  assert_array_equals(happened, []);
  script.appendChild(df);
  assert_array_equals(happened, ["t1", "t2"]);
  // At this point it's already executed so further motifications are a no-op
  script.appendChild(new Text("happened.push('t3');"));
  script.textContent = "happened.push('t4');"
  script.text = "happened.push('t5');"
  assert_array_equals(happened, ["t1", "t2"]);
});
</script>
`;

const happened = [];
test(() => {
  const script = document.getElementById("script");
  const df = document.createDocumentFragment();
  df.appendChild(new Text("happened.push('t1');"));
  df.appendChild(new Text("happened.push('t2');"));
  assert_array_equals(happened, []);
  script.appendChild(df);
  assert_array_equals(happened, ["t1", "t2"]);
  // At this point it's already executed so further motifications are a no-op
  script.appendChild(new Text("happened.push('t3');"));
  script.textContent = "happened.push('t4');"
  script.text = "happened.push('t5');"
  assert_array_equals(happened, ["t1", "t2"]);
});

