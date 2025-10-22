// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-contentType/contentType/contenttype_javascripturi.html

async_test(function() {
  var iframe = document.createElement('iframe');
  iframe.addEventListener('load', this.step_func_done(function() {
    assert_equals(iframe.contentDocument.contentType, "text/html");
    assert_equals(iframe.contentDocument.documentElement.textContent, "text/html");
  }), false);
  iframe.src = "javascript:document.contentType";
  document.body.appendChild(iframe);
});

