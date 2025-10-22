// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/abort/abort-signal-timeout.html

async_test(t => {
    const signal = iframe.contentWindow.AbortSignal.timeout(5);
    signal.onabort = t.unreached_func("abort must not fire");

    iframe.remove();

    t.step_timeout(() => {
      assert_false(signal.aborted);
      t.done();
    }, 10);
  }, "Signal returned by AbortSignal.timeout() is not aborted after frame detach");

