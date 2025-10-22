// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/MutationObserver-nested-crash.html

var observer = new MutationObserver(_ => {
    var otherObserver = new MutationObserver(_ => {});
    otherObserver.observe(target, {characterData: true});
  });
  observer.observe(target, {subtree: true, attributeOldValue: true});
  target.setAttribute("foo", "bar");

