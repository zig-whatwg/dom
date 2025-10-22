// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/moveBefore/fullscreen-preserve.html

promise_test(async function (t) {
        const item = document.querySelector("#item");

        await trusted_click();

        assert_equals(
            document.fullscreenElement,
            null,
            "fullscreenElement before requestFullscreen()"
        );

        await item.requestFullscreen();
        assert_equals(
            document.fullscreenElement,
            item,
            "fullscreenElement before moveBefore()"
        );

        document.querySelector("#new_parent").moveBefore(item, null);

        assert_equals(
            document.fullscreenElement,
            item,
            "fullscreenElement after moveBefore()"
        );

        await Promise.all([document.exitFullscreen(), fullScreenChange()]);

        assert_equals(
            document.fullscreenElement,
            null,
            "fullscreenElement after exiting fullscreen"
        );
    });

