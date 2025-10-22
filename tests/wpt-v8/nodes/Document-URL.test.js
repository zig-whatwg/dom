// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Document-URL.html

async_test(function() {
  var iframe = document.createElement("iframe");
  iframe.src = "../common/redirect.py?location=/common/blank.html";
  document.body.appendChild(iframe);
  this.add_cleanup(function() { document.body.removeChild(iframe); });
  iframe.onload = this.step_func_done(function() {
    assert_equals(iframe.contentDocument.URL,
                  location.origin + "../common/blank.html");
  });
})

