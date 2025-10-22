// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/abort/reason-constructor.html

test(() => {
    const aborted = iframe.contentWindow.AbortSignal.abort();
    assert_equals(aborted.reason.constructor, iframe.contentWindow.DOMException, "DOMException is using the correct global");
  }, "AbortSignal.reason.constructor should be from iframe");

