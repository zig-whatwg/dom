// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/moveBefore/throws-exception.html

// Setup HTML structure
document.body.innerHTML = `

<div></div>

<script>
test(t => {
  const iframe = document.createElement('iframe');
  document.body.append(iframe);
  const connectedCrossDocChild = iframe.contentDocument.createElement('div');
  const connectedLocalParent = document.querySelector('div');

  assert_throws_dom("HIERARCHY_REQUEST_ERR", () => {
    connectedLocalParent.moveBefore(connectedCrossDocChild, null);
  }, "moveBefore on a cross-document target node throws an exception");
}, "moveBefore() on a cross-document target node");
</script>
`;

test(t => {
  const iframe = document.createElement('iframe');
  document.body.append(iframe);
  const connectedCrossDocChild = iframe.contentDocument.createElement('div');
  const connectedLocalParent = document.querySelector('div');

  assert_throws_dom("HIERARCHY_REQUEST_ERR", () => {
    connectedLocalParent.moveBefore(connectedCrossDocChild, null);
  }, "moveBefore on a cross-document target node throws an exception");
}, "moveBefore() on a cross-document target node");

