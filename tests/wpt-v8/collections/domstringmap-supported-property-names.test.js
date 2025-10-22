// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/collections/domstringmap-supported-property-names.html

test(function() {
    var element = document.querySelector('#edge1');
    assert_array_equals(Object.getOwnPropertyNames(element.dataset),
        [""]);
}, "Object.getOwnPropertyNames on DOMStringMap, empty data attribute");

test(function() {
    var element = document.querySelector('#edge2');
    assert_array_equals(Object.getOwnPropertyNames(element.dataset),
        ["id-"]);
}, "Object.getOwnPropertyNames on DOMStringMap, data attribute trailing hyphen");

test(function() {
    var element = document.querySelector('#user');
    assert_array_equals(Object.getOwnPropertyNames(element.dataset),
        ['id', 'user', 'dateOfBirth']);
}, "Object.getOwnPropertyNames on DOMStringMap, multiple data attributes");

test(function() {
    var element = document.querySelector('#user2');
    element.dataset.middleName = "mark";
    assert_array_equals(Object.getOwnPropertyNames(element.dataset),
        ['uniqueId', 'middleName']);
}, "Object.getOwnPropertyNames on DOMStringMap, attribute set on dataset in JS");

test(function() {
    var element = document.querySelector('#user3');
    element.setAttribute("data-age", 30);
    assert_array_equals(Object.getOwnPropertyNames(element.dataset),
        ['uniqueId', 'age']);
}, "Object.getOwnPropertyNames on DOMStringMap, attribute set on element in JS");

