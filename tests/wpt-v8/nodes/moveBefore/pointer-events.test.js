// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/moveBefore/pointer-events.html

promise_test(async function (t) {
        const item = document.querySelector("#item");
        let pointerId = 0;
        item.addEventListener("pointerdown", e => {
            pointerId = e.pointerId;
        });
        await new test_driver.Actions()
            .pointerMove(1, 1, {origin: item})
            .pointerDown()
            .pointerMove(10, 10, {origin: item})
            .send();

        item.setPointerCapture(pointerId);

        assert_true(item.hasPointerCapture(pointerId), "Item has pointer capture before move");
        document.querySelector("#new_parent").moveBefore(item, null);
        assert_true(item.hasPointerCapture(pointerId), "Item has pointer capture after move");
        document.querySelector("#old_parent").insertBefore(item, null);
        assert_false(item.hasPointerCapture(pointerId), "Item lost pointer capture after insert");
    });

