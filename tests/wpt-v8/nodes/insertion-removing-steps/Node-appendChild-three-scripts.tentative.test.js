// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/insertion-removing-steps/Node-appendChild-three-scripts.tentative.html

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
  const div = document.createElement("div");
  div.appendChild(s1);
  div.appendChild(s2);
  div.appendChild(s3);

  assert_array_equals(happened, []);
  document.body.appendChild(div);
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
  const div = document.createElement("div");
  div.appendChild(s1);
  div.appendChild(s2);
  div.appendChild(s3);

  assert_array_equals(happened, []);
  document.body.appendChild(div);
  assert_array_equals(happened, ["s3", "s1", "s2"]);
});

