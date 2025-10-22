// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/CharacterData-remove.html

var text, text_parent,
    comment, comment_parent,
    pi, pi_parent;
setup(function() {
  text = document.createTextNode("text");
  text_parent = document.createElement("div");
  comment = document.createComment("comment");
  comment_parent = document.createElement("div");
  pi = document.createProcessingInstruction("foo", "bar");
  pi_parent = document.createElement("div");
});
testRemove(text, text_parent, "text");
testRemove(comment, comment_parent, "comment");
testRemove(pi, pi_parent, "PI");

