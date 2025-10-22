// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/Event-defaultPrevented-after-dispatch.html

// Setup HTML structure
document.body.innerHTML = `
<div id=log></div>
<input id="target" type="hidden" value=""/>
<script>
test(function() {
    var EVENT = "foo";
    var TARGET = document.getElementById("target");
    var evt = document.createEvent("Event");
    evt.initEvent(EVENT, true, true);

    TARGET.addEventListener(EVENT, this.step_func(function(e) {
        e.preventDefault();
        assert_true(e.defaultPrevented, "during dispatch");
    }), true);
    TARGET.dispatchEvent(evt);

    assert_true(evt.defaultPrevented, "after dispatch");
    assert_equals(evt.target, TARGET);
    assert_equals(evt.srcElement, TARGET);
}, "Default prevention via preventDefault");

test(function() {
    var EVENT = "foo";
    var TARGET = document.getElementById("target");
    var evt = document.createEvent("Event");
    evt.initEvent(EVENT, true, true);

    TARGET.addEventListener(EVENT, this.step_func(function(e) {
        e.returnValue = false;
        assert_true(e.defaultPrevented, "during dispatch");
    }), true);
    TARGET.dispatchEvent(evt);

    assert_true(evt.defaultPrevented, "after dispatch");
    assert_equals(evt.target, TARGET);
    assert_equals(evt.srcElement, TARGET);
}, "Default prevention via returnValue");
</script>
`;

test(function() {
    var EVENT = "foo";
    var TARGET = document.getElementById("target");
    var evt = document.createEvent("Event");
    evt.initEvent(EVENT, true, true);

    TARGET.addEventListener(EVENT, this.step_func(function(e) {
        e.preventDefault();
        assert_true(e.defaultPrevented, "during dispatch");
    }), true);
    TARGET.dispatchEvent(evt);

    assert_true(evt.defaultPrevented, "after dispatch");
    assert_equals(evt.target, TARGET);
    assert_equals(evt.srcElement, TARGET);
}, "Default prevention via preventDefault");

test(function() {
    var EVENT = "foo";
    var TARGET = document.getElementById("target");
    var evt = document.createEvent("Event");
    evt.initEvent(EVENT, true, true);

    TARGET.addEventListener(EVENT, this.step_func(function(e) {
        e.returnValue = false;
        assert_true(e.defaultPrevented, "during dispatch");
    }), true);
    TARGET.dispatchEvent(evt);

    assert_true(evt.defaultPrevented, "after dispatch");
    assert_equals(evt.target, TARGET);
    assert_equals(evt.srcElement, TARGET);
}, "Default prevention via returnValue");

