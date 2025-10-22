// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/slot-recalc.html

// Setup HTML structure
document.body.innerHTML = `
<script>
const host = document.createElement('div');
document.body.appendChild(host);
const root = host.attachShadow({mode: 'open'});

const slot = document.createElement('slot');
slot.innerHTML = \`<p>there should be more text below this</p>\`;
root.appendChild(slot);

onload = () => {
  const shouldBeVisible = document.createElement('p');
  shouldBeVisible.textContent = 'PASS if this text is visible';
  slot.appendChild(shouldBeVisible);
};
</script>
`;

const host = document.createElement('div');
document.body.appendChild(host);
const root = host.attachShadow({mode: 'open'});

const slot = document.createElement('slot');
slot.innerHTML = `<p>there should be more text below this</p>`;
root.appendChild(slot);

onload = () => {
  const shouldBeVisible = document.createElement('p');
  shouldBeVisible.textContent = 'PASS if this text is visible';
  slot.appendChild(shouldBeVisible);
};

