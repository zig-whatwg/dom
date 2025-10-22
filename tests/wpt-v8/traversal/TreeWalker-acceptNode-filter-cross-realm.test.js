// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/traversal/TreeWalker-acceptNode-filter-cross-realm.html

test_onload(() => {
    const nodeFilter = new nodeFilterGlobalObject.Object;

    const walker = document.createTreeWalker(treeWalkerRoot, NodeFilter.SHOW_ELEMENT, nodeFilter);
    assert_throws_js(nodeFilterGlobalObject.TypeError, () => { walker.firstChild(); });
}, "NodeFilter is cross-realm plain object without 'acceptNode' property");

test_onload(() => {
    const nodeFilter = new nodeFilterGlobalObject.Object;
    nodeFilter.acceptNode = {};

    const walker = document.createTreeWalker(treeWalkerRoot, NodeFilter.SHOW_ELEMENT, nodeFilter);
    assert_throws_js(nodeFilterGlobalObject.TypeError, () => { walker.firstChild(); });
}, "NodeFilter is cross-realm plain object with non-callable 'acceptNode' property");

test_onload(() => {
    const { proxy, revoke } = Proxy.revocable(() => {}, {});
    revoke();

    const nodeFilter = new nodeFilterGlobalObject.Object;
    nodeFilter.acceptNode = proxy;

    const walker = document.createTreeWalker(treeWalkerRoot, NodeFilter.SHOW_ELEMENT, nodeFilter);
    assert_throws_js(nodeFilterGlobalObject.TypeError, () => { walker.firstChild(); });
}, "NodeFilter is cross-realm plain object with revoked Proxy as 'acceptNode' property");

test_onload(() => {
    const { proxy, revoke } = nodeFilterGlobalObject.Proxy.revocable({}, {});
    revoke();

    const walker = document.createTreeWalker(treeWalkerRoot, NodeFilter.SHOW_ELEMENT, proxy);
    assert_throws_js(nodeFilterGlobalObject.TypeError, () => { walker.firstChild(); });
}, "NodeFilter is cross-realm non-callable revoked Proxy");

test_onload(() => {
    const { proxy, revoke } = nodeFilterGlobalObject.Proxy.revocable(() => {}, {});
    revoke();

    const walker = document.createTreeWalker(treeWalkerRoot, NodeFilter.SHOW_ELEMENT, proxy);
    assert_throws_js(nodeFilterGlobalObject.TypeError, () => { walker.firstChild(); });
}, "NodeFilter is cross-realm callable revoked Proxy");

function test_onload(fn, desc) {
    async_test(t => { window.addEventListener("load", t.step_func_done(fn)); }, desc);
}

