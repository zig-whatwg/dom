// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/replace-event-listener-null-browsing-context-crash.html

var p = document.getElementById("p");
i.contentDocument.adoptNode(p);
p.setAttribute("ontouchcancel", "");
document.body.appendChild(p);
p.setAttribute("ontouchcancel", "");

