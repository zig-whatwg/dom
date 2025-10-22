// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-contentType/contentType/xhr_responseType_document.html

async_test(function() {
  var xhr = new XMLHttpRequest();
  xhr.open("GET", "../resources/blob.xml");
  xhr.responseType = "document";
  xhr.onload = this.step_func_done(function(response) {
    assert_equals(xhr.readyState, 4);
    assert_equals(xhr.status, 200);
    assert_equals(xhr.responseXML.contentType, "application/xml");
  });
  xhr.send(null);
});

