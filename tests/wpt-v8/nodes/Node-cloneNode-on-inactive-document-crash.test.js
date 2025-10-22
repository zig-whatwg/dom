// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Node-cloneNode-on-inactive-document-crash.html

var doc = i.contentDocument;
i.remove();
doc.cloneNode();

