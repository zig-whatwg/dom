// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/insertion-removing-steps/Node-appendChild-script-and-button-from-div.tentative.html

let button = null;
let buttonForm = null;
test(() => {
  const form = document.getElementById("form");
  const script = document.createElement("script");
  script.textContent = `
    buttonForm = button.form;
  `;
  button = document.createElement("button");
  const div = document.createElement("div");
  div.appendChild(script);
  div.appendChild(button);
  assert_equals(buttonForm, null);
  form.appendChild(div);
  assert_equals(buttonForm, form);
}, "Script inserted before a form-associated button can observe the button's " +
   "form, because by the time the script executes, the DOM insertion that " +
   "associates the button with the form is already done");

