// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/insertion-removing-steps/Node-append-form-and-script-from-fragment.tentative.html

test(() => {
    const script = document.createElement("script");
    const form = document.createElement("form");
    form.id = "someForm";
    const fragment = new DocumentFragment();
    script.textContent = `
        window.buttonAssociatedForm = document.querySelector("#someButton").form;
    `;
    fragment.append(script, form);
    document.body.append(fragment);
    assert_equals(window.buttonAssociatedForm, form);
}, "When adding a script+form in a fragment and the form matches an associated element, " +
    "the script that checks whether the button is associated to the form should run after " +
    "inserting the form");

