// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/insertion-removing-steps/Node-appendChild-three-scripts-from-fragment.tentative.html

// Setup HTML structure
document.body.innerHTML = `
  <script>
const s1 = document.createElement("script");
const s2 = document.createElement("script");
const s3 = document.createElement("script");
const happened = [];

test(() => {
  s1.textContent = \`
    s3.appendChild(new Text("happened.push('s3');"));
    happened.push("s1");
  \`;
  s2.textContent = \`
    happened.push("s2");
  \`;
  const df = document.createDocumentFragment();
  df.appendChild(s1);
  df.appendChild(s2);
  df.appendChild(s3);

  assert_array_equals(happened, []);
  document.body.appendChild(df);
  assert_array_equals(happened, ["s3", "s1", "s2"]);
});
</script>
`;

const s1 = document.createElement("script");
const s2 = document.createElement("script");
const s3 = document.createElement("script");
const happened = [];

test(() => {
  s1.textContent = `
    s3.appendChild(new Text("happened.push('s3');"));
    happened.push("s1");
  `;
  s2.textContent = `
    happened.push("s2");
  `;
  const df = document.createDocumentFragment();
  df.appendChild(s1);
  df.appendChild(s2);
  df.appendChild(s3);

  assert_array_equals(happened, []);
  document.body.appendChild(df);
  assert_array_equals(happened, ["s3", "s1", "s2"]);
});

