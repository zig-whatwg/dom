// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-dispatch-throwing.html

setup({allow_uncaught_exception:true})

test(function() {
    var errorEvents = 0;
    window.onerror = this.step_func(function(e) {
        assert_equals(typeof e, 'string');
        ++errorEvents;
    });

    var element = document.createElement('div');

    element.addEventListener('click', function() {
        throw new Error('Error from only listener');
    });

    element.dispatchEvent(new Event('click'));

    assert_equals(errorEvents, 1);
}, "Throwing in event listener with a single listeners");

test(function() {
    var errorEvents = 0;
    window.onerror = this.step_func(function(e) {
        assert_equals(typeof e, 'string');
        ++errorEvents;
    });

    var element = document.createElement('div');

    var secondCalled = false;

    element.addEventListener('click', function() {
        throw new Error('Error from first listener');
    });
    element.addEventListener('click', this.step_func(function() {
        secondCalled = true;
    }), false);

    element.dispatchEvent(new Event('click'));

    assert_equals(errorEvents, 1);
    assert_true(secondCalled);
}, "Throwing in event listener with multiple listeners");

