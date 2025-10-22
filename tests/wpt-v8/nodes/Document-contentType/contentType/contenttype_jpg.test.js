// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-contentType/contentType/contenttype_jpg.html

async_test(function() {
  var iframe = document.createElement('iframe');
  iframe.addEventListener('load', this.step_func_done(function() {
    assert_equals(iframe.contentDocument.contentType, "image/jpeg");
  }), false);
  iframe.src = "../resources/t.jpg";
  document.body.appendChild(iframe);
});

