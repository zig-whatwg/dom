// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-contentType/contentType/contenttype_datauri_02.html

async_test(function() {
  var iframe = document.createElement('iframe');
  self.onmessage = this.step_func_done(e => {
    assert_equals(e.data, "text/html");
  });
  iframe.src = "data:text/html;charset=utf-8,<!DOCTYPE html><script>parent.postMessage(document.contentType,'*')<\/script>";
  document.body.appendChild(iframe);
});

