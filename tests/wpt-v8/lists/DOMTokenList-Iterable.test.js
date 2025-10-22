// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/lists/DOMTokenList-Iterable.html

var elementClasses;
    setup(function() {
        elementClasses = document.querySelector("span").classList;
    })
    test(function() {
        assert_true('length' in elementClasses);
    }, 'DOMTokenList has length method.');
    test(function() {
        assert_true('values' in elementClasses);
    }, 'DOMTokenList has values method.');
    test(function() {
        assert_true('entries' in elementClasses);
    }, 'DOMTokenList has entries method.');
    test(function() {
        assert_true('forEach' in elementClasses);
    }, 'DOMTokenList has forEach method.');
    test(function() {
        assert_true(Symbol.iterator in elementClasses);
    }, 'DOMTokenList has Symbol.iterator.');
    test(function() {
        var classList = [];
        for (var className of elementClasses){
            classList.push(className);
        }
        assert_array_equals(classList, ['foo', 'Foo']);
    }, 'DOMTokenList is iterable via for-of loop.');

