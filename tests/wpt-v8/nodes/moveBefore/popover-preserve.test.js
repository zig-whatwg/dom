// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/moveBefore/popover-preserve.html

// Setup HTML structure
document.body.innerHTML = `
<section id="old_parent">
<div popover>
Popover
</div>
</section>
<section id="new_parent">
</section>
<script>
promise_test(async t => {
    const popover = document.querySelector("div[popover]");
    popover.showPopover();
    await new Promise(resolve => requestAnimationFrame(() => resolve()));
    assert_equals(document.querySelector(":popover-open"), popover);
    document.querySelector("#new_parent").moveBefore(popover, null);
    assert_equals(document.querySelector(":popover-open"), popover);
}, "when reparenting an open popover, it shouldn't be closed automatically");
</script>
`;

promise_test(async t => {
    const popover = document.querySelector("div[popover]");
    popover.showPopover();
    await new Promise(resolve => requestAnimationFrame(() => resolve()));
    assert_equals(document.querySelector(":popover-open"), popover);
    document.querySelector("#new_parent").moveBefore(popover, null);
    assert_equals(document.querySelector(":popover-open"), popover);
}, "when reparenting an open popover, it shouldn't be closed automatically");

