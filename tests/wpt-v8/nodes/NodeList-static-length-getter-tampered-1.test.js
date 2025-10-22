// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/NodeList-static-length-getter-tampered-1.html

// Setup HTML structure
document.body.innerHTML = `

<script src="support/NodeList-static-length-tampered.js"></script>
<script>
test(() => {
    const nodeList = makeStaticNodeList(100);

    for (var i = 0; i < 50; i++) {
        if (i === 25)
            Object.defineProperty(nodeList, "length", { get() { return 10; } });

        assert_equals(indexOfNodeList(nodeList), i >= 25 ? -1 : 50);
    }
});
</script>
`;

test(() => {
    const nodeList = makeStaticNodeList(100);

    for (var i = 0; i < 50; i++) {
        if (i === 25)
            Object.defineProperty(nodeList, "length", { get() { return 10; } });

        assert_equals(indexOfNodeList(nodeList), i >= 25 ? -1 : 50);
    }
});

