// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-createElement-namespace-tests/xhtml_ns_removed.html

var newRoot = document.createElementNS(null, "html");
    document.removeChild(document.documentElement);
    document.appendChild(newRoot);

