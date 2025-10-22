// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/insertion-removing-steps/Node-appendChild-script-and-div-from-fragment.tentative.html

// Setup HTML structure
document.body.innerHTML = `
<script>
let script = null;
let scriptParent = null;
let div = null;
let divParent = null;
test(() => {
  script = document.createElement("script");
  div = document.createElement("div");
  script.textContent = \`
    divParent = div.parentNode;
    scriptParent = script.parentNode;
  \`;
  const df = document.createDocumentFragment();
  df.appendChild(script);
  df.appendChild(div);
  assert_equals(divParent, null);
  assert_equals(scriptParent, null);
  document.head.appendChild(df);
  assert_equals(divParent, scriptParent);
  assert_equals(divParent, document.head);
}, "Earlier-inserted scripts can observe the parentNode of later-inserted " +
   "nodes, because script runs after DOM insertion completes");
</script>
`;

let script = null;
let scriptParent = null;
let div = null;
let divParent = null;
test(() => {
  script = document.createElement("script");
  div = document.createElement("div");
  script.textContent = `
    divParent = div.parentNode;
    scriptParent = script.parentNode;
  `;
  const df = document.createDocumentFragment();
  df.appendChild(script);
  df.appendChild(div);
  assert_equals(divParent, null);
  assert_equals(scriptParent, null);
  document.head.appendChild(df);
  assert_equals(divParent, scriptParent);
  assert_equals(divParent, document.head);
}, "Earlier-inserted scripts can observe the parentNode of later-inserted " +
   "nodes, because script runs after DOM insertion completes");

