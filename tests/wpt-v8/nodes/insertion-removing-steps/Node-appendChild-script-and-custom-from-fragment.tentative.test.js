// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/insertion-removing-steps/Node-appendChild-script-and-custom-from-fragment.tentative.html

// Setup HTML structure
document.body.innerHTML = `
<script>
let customConstructed = false;
let customConstructedDuringEarlierScript = false;
class CustomElement extends HTMLElement {
    constructor() {
        super();
        customConstructed = true;
    }
}
test(() => {
  const script = document.createElement("script");
  script.textContent = \`
    customElements.define("custom-element", CustomElement);
    customConstructedDuringEarlierScript = customConstructed;
  \`;
  const custom = document.createElement("custom-element");
  const df = document.createDocumentFragment();
  df.appendChild(script);
  df.appendChild(custom);
  assert_false(customConstructed);
  assert_false(customConstructedDuringEarlierScript);
  document.head.appendChild(df);
  assert_true(customConstructed);
  assert_true(customConstructedDuringEarlierScript);
}, "An earlier-inserted script can upgrade a later-inserted custom element, " +
   "whose upgrading is synchronously observable to the script, since DOM " +
   "insertion has been completed by the time it runs");
</script>
`;

let customConstructed = false;
let customConstructedDuringEarlierScript = false;
class CustomElement extends HTMLElement {
    constructor() {
        super();
        customConstructed = true;
    }
}
test(() => {
  const script = document.createElement("script");
  script.textContent = `
    customElements.define("custom-element", CustomElement);
    customConstructedDuringEarlierScript = customConstructed;
  `;
  const custom = document.createElement("custom-element");
  const df = document.createDocumentFragment();
  df.appendChild(script);
  df.appendChild(custom);
  assert_false(customConstructed);
  assert_false(customConstructedDuringEarlierScript);
  document.head.appendChild(df);
  assert_true(customConstructed);
  assert_true(customConstructedDuringEarlierScript);
}, "An earlier-inserted script can upgrade a later-inserted custom element, " +
   "whose upgrading is synchronously observable to the script, since DOM " +
   "insertion has been completed by the time it runs");

