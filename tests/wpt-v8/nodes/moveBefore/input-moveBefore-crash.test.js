// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/moveBefore/input-moveBefore-crash.html

// Setup HTML structure
document.body.innerHTML = `
<input id="input">
<script>
window.onload = () => {
    document.body.moveBefore(document.querySelector("#input"), null);
};
</script>
`;

window.onload = () => {
    document.body.moveBefore(document.querySelector("#input"), null);
};

