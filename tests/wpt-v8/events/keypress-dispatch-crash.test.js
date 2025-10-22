// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/keypress-dispatch-crash.html

var newDoc = document.implementation.createDocument( "", null);
var testNode = newDoc.createElement('div');
newDoc.append(testNode);

var syntheticEvent = document.createEvent('KeyboardEvents');
syntheticEvent.initKeyboardEvent("keypress");
testNode.dispatchEvent(syntheticEvent)

