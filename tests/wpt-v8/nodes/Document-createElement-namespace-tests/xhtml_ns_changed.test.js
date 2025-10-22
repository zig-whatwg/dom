// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-createElement-namespace-tests/xhtml_ns_changed.html

var newRoot = document.createElementNS("http://www.w3.org/2000/svg", "abc");
    document.removeChild(document.documentElement);
    document.appendChild(newRoot);

