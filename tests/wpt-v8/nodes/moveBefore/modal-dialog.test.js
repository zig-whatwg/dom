// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/moveBefore/modal-dialog.html

// Setup HTML structure
document.body.innerHTML = `
<section id="old_parent">
    <dialog id="dialog">
    </dialog>
</section>
<section id="new_parent">
</section>
<script>
promise_test(async t => {
    const dialog = document.querySelector("#dialog");
    dialog.showModal();
    document.querySelector("#new_parent").moveBefore(dialog, null);
    assert_equals(document.elementFromPoint(0, 0), dialog);
}, "when reparenting a modal dialog, the dialog should stay modal");
</script>
`;

promise_test(async t => {
    const dialog = document.querySelector("#dialog");
    dialog.showModal();
    document.querySelector("#new_parent").moveBefore(dialog, null);
    assert_equals(document.elementFromPoint(0, 0), dialog);
}, "when reparenting a modal dialog, the dialog should stay modal");

