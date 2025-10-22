// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/moveBefore/preserve-render-blocking-script.html

// Setup HTML structure
document.body.innerHTML = `
<div>Some text</div>


`;

window.operations = [];

requestAnimationFrame(() => window.operations.push("render"));

document.head.moveBefore(document.getElementById("target"), null);

promise_test(async () => {
        await new Promise(resolve => requestAnimationFrame(() => resolve()));
        await new Promise(resolve => requestAnimationFrame(() => resolve()));
        assert_array_equals(operations, ["script", "render"]);
    }, "A moved script should keep its render-blocking state");

