// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/collections/namednodemap-supported-property-names.html

test(function() {
    var elt = document.querySelector('#simple');
    assert_array_equals(Object.getOwnPropertyNames(elt.attributes),
        ['0','1','id','class']);
}, "Object.getOwnPropertyNames on NamedNodeMap");

test(function() {
    var result = document.getElementById("result");
    assert_array_equals(Object.getOwnPropertyNames(result.attributes),
        ['0','1','2','3','id','type','value','width']);
}, "Object.getOwnPropertyNames on NamedNodeMap of input");

test(function() {
    var result = document.getElementById("result");
    result.removeAttribute("width");
    assert_array_equals(Object.getOwnPropertyNames(result.attributes),
        ['0','1','2','id','type','value']);
}, "Object.getOwnPropertyNames on NamedNodeMap after attribute removal");

