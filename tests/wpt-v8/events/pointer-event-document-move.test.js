// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/pointer-event-document-move.html

// Setup HTML structure
document.body.innerHTML = `
<script>
  const clone = document.querySelector("template").content.cloneNode(true);
  const p = clone.querySelector("p");

  let gotEvent = false;
  p.addEventListener("pointerup", () => {
    gotEvent = true;
  });

  document.body.append(clone);

  promise_test(async () => {
    await test_driver.click(document.querySelector("p"));
    assert_true(gotEvent);
  }, "Moving a node to new document should move the registered event listeners together");
</script>
`;

const clone = document.querySelector("template").content.cloneNode(true);
  const p = clone.querySelector("p");

  let gotEvent = false;
  p.addEventListener("pointerup", () => {
    gotEvent = true;
  });

  document.body.append(clone);

  promise_test(async () => {
    await test_driver.click(document.querySelector("p"));
    assert_true(gotEvent);
  }, "Moving a node to new document should move the registered event listeners together");

