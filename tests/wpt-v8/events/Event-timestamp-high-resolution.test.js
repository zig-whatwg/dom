// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-timestamp-high-resolution.html

'use strict';
for (let eventType of ["MouseEvent", "KeyboardEvent", "WheelEvent", "FocusEvent"]) {
    test(function() {
        let before = performance.now();
        let e = new window[eventType]('test');
        let after = performance.now();
        assert_greater_than_equal(e.timeStamp, before, "Event timestamp should be greater than performance.now() timestamp taken before its creation");
        assert_less_than_equal(e.timeStamp, after, "Event timestamp should be less than performance.now() timestamp taken after its creation");
    }, `Constructed ${eventType} timestamp should be high resolution and have the same time origin as performance.now()`);
}

