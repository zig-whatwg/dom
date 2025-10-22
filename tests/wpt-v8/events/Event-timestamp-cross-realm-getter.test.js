// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-timestamp-cross-realm-getter.html

// Setup HTML structure
document.body.innerHTML = `
<script>
const t = async_test();
t.step_timeout(() => {
  const iframeDelayed = document.createElement("iframe");
  iframeDelayed.onload = t.step_func_done(() => {
    // Use eval() to eliminate false-positive test result for WebKit builds before r280256,
    // which invoked WebIDL accessors in context of lexical (caller) global object.
    const timeStampExpected = iframeDelayed.contentWindow.eval(\`new Event("foo").timeStamp\`);
    const eventDelayed = new iframeDelayed.contentWindow.Event("foo");

    const {get} = Object.getOwnPropertyDescriptor(Event.prototype, "timeStamp");
    assert_approx_equals(get.call(eventDelayed), timeStampExpected, 5, "via Object.getOwnPropertyDescriptor");

    Object.setPrototypeOf(eventDelayed, Event.prototype);
    assert_approx_equals(eventDelayed.timeStamp, timeStampExpected, 5, "via Object.setPrototypeOf");
  });
  document.body.append(iframeDelayed);
}, 1000);
</script>
`;

const t = async_test();
t.step_timeout(() => {
  const iframeDelayed = document.createElement("iframe");
  iframeDelayed.onload = t.step_func_done(() => {
    // Use eval() to eliminate false-positive test result for WebKit builds before r280256,
    // which invoked WebIDL accessors in context of lexical (caller) global object.
    const timeStampExpected = iframeDelayed.contentWindow.eval(`new Event("foo").timeStamp`);
    const eventDelayed = new iframeDelayed.contentWindow.Event("foo");

    const {get} = Object.getOwnPropertyDescriptor(Event.prototype, "timeStamp");
    assert_approx_equals(get.call(eventDelayed), timeStampExpected, 5, "via Object.getOwnPropertyDescriptor");

    Object.setPrototypeOf(eventDelayed, Event.prototype);
    assert_approx_equals(eventDelayed.timeStamp, timeStampExpected, 5, "via Object.setPrototypeOf");
  });
  document.body.append(iframeDelayed);
}, 1000);

