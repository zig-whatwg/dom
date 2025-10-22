// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/DOMImplementation-createHTMLDocument-with-null-browsing-context-crash.html

var doc = i.contentDocument;
i.remove();
doc.implementation.createHTMLDocument();

