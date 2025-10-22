// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/non-cancelable-when-passive/generic-events-stay-cancelable.html

async_test((t) => {
    const et = new EventTarget();
    et.addEventListener('test', t.step_func_done((e) => {
        assert_true(e.cancelable);
    }), {passive: true});
    et.dispatchEvent(new Event('test', {cancelable: true}));
}, "A generic event with only passive listeners remains cancelable");

