// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-dispatch-order.html

async_test(function() {
    document.addEventListener('DOMContentLoaded', this.step_func_done(function() {
        var parent = document.getElementById('parent');
        var child = document.getElementById('child');

        var order = [];

        parent.addEventListener('click', this.step_func(function(){ order.push(1) }), true);
        child.addEventListener('click', this.step_func(function(){ order.push(2) }), false);
        parent.addEventListener('click', this.step_func(function(){ order.push(3) }), false);

        child.dispatchEvent(new Event('click', {bubbles: true}));

        assert_array_equals(order, [1, 2, 3]);
    }));
}, "Event phases order");

