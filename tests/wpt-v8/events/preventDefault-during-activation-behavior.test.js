// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/preventDefault-during-activation-behavior.html

// Setup HTML structure
document.body.innerHTML = `

<form id="f">
  <input type="submit" id="b">
</form>

<script>

promise_test(async () => {
  let form = document.getElementById("f");
  let button = document.getElementById("b");

  let cached_event;
  let submit_fired = false;

  let click_promise = new Promise((resolve, reject) => {
    button.addEventListener("click", event => {
      assert_false(submit_fired);
      cached_event = event;
      resolve();
    });
  });

  form.addEventListener("submit", event => {
    assert_false(submit_fired);
    assert_true(!!cached_event, "click should have fired");

    // Call preventDefault on the click event during its activation
    // behavior, to test the bug that we're trying to test.
    cached_event.preventDefault();

    // prevent the form submission from navigating the page
    event.preventDefault();

    submit_fired = true;
  });

  assert_false(submit_fired);
  button.click();
  await click_promise;
  assert_true(submit_fired);
}, "behavior of preventDefault during activation behavior");

</script>
`;

promise_test(async () => {
  let form = document.getElementById("f");
  let button = document.getElementById("b");

  let cached_event;
  let submit_fired = false;

  let click_promise = new Promise((resolve, reject) => {
    button.addEventListener("click", event => {
      assert_false(submit_fired);
      cached_event = event;
      resolve();
    });
  });

  form.addEventListener("submit", event => {
    assert_false(submit_fired);
    assert_true(!!cached_event, "click should have fired");

    // Call preventDefault on the click event during its activation
    // behavior, to test the bug that we're trying to test.
    cached_event.preventDefault();

    // prevent the form submission from navigating the page
    event.preventDefault();

    submit_fired = true;
  });

  assert_false(submit_fired);
  button.click();
  await click_promise;
  assert_true(submit_fired);
}, "behavior of preventDefault during activation behavior");

