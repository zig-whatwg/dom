// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/ranges/Range-collapse.html

"use strict";

function testCollapse(rangeEndpoints, toStart) {
  // Have to account for Ranges involving Documents!
  var ownerDoc = rangeEndpoints[0].nodeType == Node.DOCUMENT_NODE
    ? rangeEndpoints[0]
    : rangeEndpoints[0].ownerDocument;
  var range = ownerDoc.createRange();
  range.setStart(rangeEndpoints[0], rangeEndpoints[1]);
  range.setEnd(rangeEndpoints[2], rangeEndpoints[3]);

  var expectedContainer = toStart ? range.startContainer : range.endContainer;
  var expectedOffset = toStart ? range.startOffset : range.endOffset;

  assert_equals(range.collapsed, range.startContainer == range.endContainer
    && range.startOffset == range.endOffset,
    "collapsed must be true if and only if the start and end are equal");

  if (toStart === undefined) {
    range.collapse();
  } else {
    range.collapse(toStart);
  }

  assert_equals(range.startContainer, expectedContainer,
    "Wrong startContainer");
  assert_equals(range.endContainer, expectedContainer,
    "Wrong endContainer");
  assert_equals(range.startOffset, expectedOffset,
    "Wrong startOffset");
  assert_equals(range.endOffset, expectedOffset,
    "Wrong endOffset");
  assert_true(range.collapsed,
    ".collapsed must be set after .collapsed()");
}

var tests = [];
for (var i = 0; i < testRanges.length; i++) {
  tests.push([
    "Range " + i + " " + testRanges[i] + ", toStart true",
    eval(testRanges[i]),
    true
  ]);
  tests.push([
    "Range " + i + " " + testRanges[i] + ", toStart false",
    eval(testRanges[i]),
    false
  ]);
  tests.push([
    "Range " + i + " " + testRanges[i] + ", toStart omitted",
    eval(testRanges[i]),
    undefined
  ]);
}
generate_tests(testCollapse, tests);

testDiv.style.display = "none";

