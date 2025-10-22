// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/DOMImplementation-createHTMLDocument-with-saved-implementation.html

// Test the document location getter is null outside of browser context
test(function() {
  var iframe = document.createElement("iframe");
  document.body.appendChild(iframe);
  var implementation = iframe.contentDocument.implementation;
  iframe.remove();
  assert_not_equals(implementation.createHTMLDocument(), null);
}, "createHTMLDocument(): from a saved and detached implementation does not return null")

