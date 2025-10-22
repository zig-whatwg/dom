// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/query-target-in-load-event.part.html

window.onload = function() {
    let target = document.querySelector(":target");
    let expected = document.querySelector("#target");
    window.parent.postMessage(target == expected ? "PASS" : "FAIL", "*");
  };

