// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Element-webkitMatchesSelector.html

async_test(function() {
    var frame = document.createElement("iframe");
    frame.onload = this.step_func_done(e => init(e, "webkitMatchesSelector" ));
    frame.src = "../dom/nodes/ParentNode-querySelector-All-content.html#target";
    document.body.appendChild(frame);
  });

