// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/ranges/Range-compareBoundaryPoints-crash.html

const selection = document.getSelection();
const range = new Range();
const cell = row.insertCell();
range.setEndBefore(cell);
selection.addRange(range);
selection.removeRange(range);
table.tHead = null;
range.compareBoundaryPoints(Range.START_TO_END, range);

