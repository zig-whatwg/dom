// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/moveBefore/object-crash-regression.html

// Setup HTML structure
document.body.innerHTML = `

<b id="p"><object>

<script>
test(t => {
  // Per https://crbug.com/373924127, simply moving an object element would
  // crash, due to an internal subframe count mechanism getting out of sync.
  p.moveBefore(p.lastChild, p.firstChild);
}, "Moving an object element does not crash");
</script>
`;

test(t => {
  // Per https://crbug.com/373924127, simply moving an object element would
  // crash, due to an internal subframe count mechanism getting out of sync.
  p.moveBefore(p.lastChild, p.firstChild);
}, "Moving an object element does not crash");

