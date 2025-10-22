// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/event-global-is-still-set-when-coercing-beforeunload-result.html

// Setup HTML structure
document.body.innerHTML = `
<script>
window.onload = () => {
  async_test(t => {
    iframe.onload = t.step_func_done(() => {
      assert_equals(typeof window.currentEventInToString, "object");
      assert_equals(window.currentEventInToString.type, "beforeunload");
    });

    iframe.contentWindow.location.href = "about:blank";
  });
};
</script>
`;

window.onload = () => {
  async_test(t => {
    iframe.onload = t.step_func_done(() => {
      assert_equals(typeof window.currentEventInToString, "object");
      assert_equals(window.currentEventInToString.type, "beforeunload");
    });

    iframe.contentWindow.location.href = "about:blank";
  });
};

