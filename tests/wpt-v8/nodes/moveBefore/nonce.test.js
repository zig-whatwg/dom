// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/moveBefore/nonce.html

// Setup HTML structure
document.body.innerHTML = `

<section id="new_parent"></section>

<script>
test(t => {
  const div = document.createElement('div');
  document.body.append(div);

  const kNonce = '8IBTHwOdqNKAWeKl7plt8g==';
  div.setAttribute('nonce', kNonce);
  assert_equals(div.getAttribute('nonce'), kNonce);

  new_parent.moveBefore(div, null);
  assert_equals(div.getAttribute('nonce'), kNonce);

  new_parent.insertBefore(div, null);
  assert_equals(div.getAttribute('nonce'), "");
}, "Element nonce content attribute is not cleared after move");
</script>
`;

test(t => {
  const div = document.createElement('div');
  document.body.append(div);

  const kNonce = '8IBTHwOdqNKAWeKl7plt8g==';
  div.setAttribute('nonce', kNonce);
  assert_equals(div.getAttribute('nonce'), kNonce);

  new_parent.moveBefore(div, null);
  assert_equals(div.getAttribute('nonce'), kNonce);

  new_parent.insertBefore(div, null);
  assert_equals(div.getAttribute('nonce'), "");
}, "Element nonce content attribute is not cleared after move");

