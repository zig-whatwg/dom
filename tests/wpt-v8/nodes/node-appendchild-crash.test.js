// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/node-appendchild-crash.html

window.onload=function() {
    iframe.addEventListener('DOMNodeInsertedIntoDocument',function() {});
    option.remove();
    iframe.contentDocument.body.appendChild(document.body);
  }

