// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/NodeList-Iterable.html

var paragraphs;
    setup(function() {
        paragraphs = document.querySelectorAll('p');
    })
    test(function() {
        assert_true('length' in paragraphs);
    }, 'NodeList has length method.');
    test(function() {
        assert_true('values' in paragraphs);
    }, 'NodeList has values method.');
    test(function() {
        assert_true('entries' in paragraphs);
    }, 'NodeList has entries method.');
    test(function() {
        assert_true('forEach' in paragraphs);
    }, 'NodeList has forEach method.');
    test(function() {
        assert_true(Symbol.iterator in paragraphs);
    }, 'NodeList has Symbol.iterator.');
    test(function() {
        var ids = "12345", idx=0;
        for(var node of paragraphs){
            assert_equals(node.getAttribute('id'), ids[idx++]);
        }
    }, 'NodeList is iterable via for-of loop.');

    test(function() {
        assert_array_equals(Object.keys(paragraphs), ['0', '1', '2', '3', '4']);
    }, 'NodeList responds to Object.keys correctly');

    test(function() {
        var container = document.getElementById('live');
        var nodeList = container.childNodes;

        var ids = [];
        for (var el of nodeList) {
            ids.push(el.id);
            assert_equals(el.localName, 'b');
            if (ids.length < 3) {
                var newEl = document.createElement('b');
                newEl.id = 'after' + el.id;
                container.appendChild(newEl);
            }
        }

        assert_array_equals(ids, ['b1', 'b2', 'b3', 'afterb1', 'afterb2']);
    }, 'live NodeLists are for-of iterable and update appropriately');

