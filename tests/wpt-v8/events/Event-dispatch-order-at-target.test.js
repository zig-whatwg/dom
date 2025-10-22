// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-dispatch-order-at-target.html

"use strict";

test(() => {
    const el = document.createElement("div");
    const expectedOrder = ["capturing", "bubbling"];

    let actualOrder = [];
    el.addEventListener("click", evt => {
        assert_equals(evt.eventPhase, Event.AT_TARGET);
        actualOrder.push("bubbling");
    }, false);
    el.addEventListener("click", evt => {
        assert_equals(evt.eventPhase, Event.AT_TARGET);
        actualOrder.push("capturing");
    }, true);

    el.dispatchEvent(new Event("click", {bubbles: true}));
    assert_array_equals(actualOrder, expectedOrder, "bubbles: true");

    actualOrder = [];
    el.dispatchEvent(new Event("click", {bubbles: false}));
    assert_array_equals(actualOrder, expectedOrder, "bubbles: false");
}, "Listeners are invoked in correct order (AT_TARGET phase)");

