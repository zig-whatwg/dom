// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/remove-unscopable.html

var result1;
var result2;
var unscopables = [
    "before",
    "after",
    "replaceWith",
    "remove",
    "prepend",
    "append"
];
for (var i in unscopables) {
    var name = unscopables[i];
    window[name] = "Hello there";
    result1 = result2 = undefined;
    test(function () {
        assert_true(Element.prototype[Symbol.unscopables][name]);
        var div = document.querySelector('#testDiv');
        div.setAttribute(
            "onclick", "result1 = " + name + "; result2 = this." + name + ";");
        div.dispatchEvent(new Event("click"));
        assert_equals(typeof result1, "string");
        assert_equals(typeof result2, "function");
    }, name + "() should be unscopable");
}

