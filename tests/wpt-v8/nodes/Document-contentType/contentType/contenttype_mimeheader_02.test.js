// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-contentType/contentType/contenttype_mimeheader_02.html

async_test(function() {
  var iframe = document.createElement('iframe');
  iframe.addEventListener('load', this.step_func_done(function() {
    assert_equals(iframe.contentDocument.contentType, "text/html");
  }), false);
  iframe.src = "../support/contenttype_setter.py?type=text&subtype=html&mimeHead=text%2Fxml";
  document.body.appendChild(iframe);
});

