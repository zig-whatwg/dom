// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-contentType/contentType/contenttype_txt.html

async_test(function() {
  var iframe = document.createElement('iframe');
  iframe.addEventListener('load', this.step_func_done(function() {
    assert_equals(iframe.contentDocument.contentType, "text/plain");
  }), false);
  iframe.src = "../resources/blob.txt";
  document.body.appendChild(iframe);
});

