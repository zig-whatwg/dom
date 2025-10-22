// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/EventListener-incumbent-global-subframe-1.sub.html

document.domain = "{{host}}";
  onmessage = function(e) {
    if (e.data == "start") {
      frames[0].document.body.addEventListener("click", frames[0].postMessage.bind(frames[0], "respond", "*", undefined));
      frames[0].postMessage("sendclick", "*");
    } else {
      parent.postMessage(e.data, "*");
    }
  }

