// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-contentType/contentType/contenttype_mimeheader_01.html

async_test(function() {
  var iframe = document.createElement('iframe');
  iframe.addEventListener('load', this.step_func_done(function() {
    assert_equals(iframe.contentDocument.contentType, "text/xml");
  }), false);
  iframe.src = "../support/contenttype_setter.py?type=text&subtype=xml";
  document.body.appendChild(iframe);
});

