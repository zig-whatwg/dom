// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/event-global-is-still-set-when-reporting-exception-onerror.html

// Setup HTML structure
document.body.innerHTML = `
<iframe src="resources/empty-document.html"></iframe>
<iframe src="resources/empty-document.html"></iframe>

<script>
setup({ allow_uncaught_exception: true });

async_test(t => {
    window.onload = t.step_func_done(onLoadEvent => {
        frames[0].onerror = new frames[1].Function(\`
            top.eventDuringSecondOnError = top.window.event;
            top.frames[0].eventDuringSecondOnError = top.frames[0].event;
            top.frames[1].eventDuringSecondOnError = top.frames[1].event;
        \`);

        window.onerror = new frames[0].Function(\`
            top.eventDuringFirstOnError = top.window.event;
            top.frames[0].eventDuringFirstOnError = top.frames[0].event;
            top.frames[1].eventDuringFirstOnError = top.frames[1].event;

            foo; // cause second onerror
        \`);

        const myEvent = new ErrorEvent("error", { error: new Error("myError") });
        window.dispatchEvent(myEvent);

        assert_equals(top.eventDuringFirstOnError, onLoadEvent);
        assert_equals(frames[0].eventDuringFirstOnError, myEvent);
        assert_equals(frames[1].eventDuringFirstOnError, undefined);

        assert_equals(top.eventDuringSecondOnError, onLoadEvent);
        assert_equals(frames[0].eventDuringSecondOnError, myEvent);
        assert_equals(frames[1].eventDuringSecondOnError.error.name, "ReferenceError");
    });
});
</script>
`;

setup({ allow_uncaught_exception: true });

async_test(t => {
    window.onload = t.step_func_done(onLoadEvent => {
        frames[0].onerror = new frames[1].Function(`
            top.eventDuringSecondOnError = top.window.event;
            top.frames[0].eventDuringSecondOnError = top.frames[0].event;
            top.frames[1].eventDuringSecondOnError = top.frames[1].event;
        `);

        window.onerror = new frames[0].Function(`
            top.eventDuringFirstOnError = top.window.event;
            top.frames[0].eventDuringFirstOnError = top.frames[0].event;
            top.frames[1].eventDuringFirstOnError = top.frames[1].event;

            foo; // cause second onerror
        `);

        const myEvent = new ErrorEvent("error", { error: new Error("myError") });
        window.dispatchEvent(myEvent);

        assert_equals(top.eventDuringFirstOnError, onLoadEvent);
        assert_equals(frames[0].eventDuringFirstOnError, myEvent);
        assert_equals(frames[1].eventDuringFirstOnError, undefined);

        assert_equals(top.eventDuringSecondOnError, onLoadEvent);
        assert_equals(frames[0].eventDuringSecondOnError, myEvent);
        assert_equals(frames[1].eventDuringSecondOnError.error.name, "ReferenceError");
    });
});

