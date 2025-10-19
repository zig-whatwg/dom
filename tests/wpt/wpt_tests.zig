// Web Platform Tests (WPT) for DOM implementation
// Converted from https://github.com/web-platform-tests/wpt/tree/master/dom
//
// These tests preserve the exact test structure and assertions from WPT.
// File names are kept identical (with .zig extension instead of .html/.js).
// Test setup and assertions remain unchanged to validate spec compliance.

// Node tests
test {
    _ = @import("nodes/Node-appendChild.zig");
    _ = @import("nodes/Node-baseURI.zig");
    _ = @import("nodes/Node-childNodes.zig");
    _ = @import("nodes/Node-cloneNode.zig");
    _ = @import("nodes/Node-compareDocumentPosition.zig");
    _ = @import("nodes/Node-contains.zig");
    _ = @import("nodes/Node-insertBefore.zig");
    _ = @import("nodes/Node-isConnected.zig");
    _ = @import("nodes/Node-isSameNode.zig");
    _ = @import("nodes/Node-nodeName.zig");
    _ = @import("nodes/Node-nodeValue.zig");
    _ = @import("nodes/Node-normalize.zig");
    _ = @import("nodes/Node-parentElement.zig");
    _ = @import("nodes/Node-parentNode.zig");
    _ = @import("nodes/Node-removeChild.zig");
    _ = @import("nodes/Node-replaceChild.zig");
    _ = @import("nodes/Node-textContent.zig");
}

// CharacterData tests
test {
    _ = @import("nodes/CharacterData-appendData.zig");
    _ = @import("nodes/CharacterData-data.zig");
    _ = @import("nodes/CharacterData-deleteData.zig");
    _ = @import("nodes/CharacterData-insertData.zig");
    _ = @import("nodes/CharacterData-replaceData.zig");
    _ = @import("nodes/CharacterData-substringData.zig");
}

// Element tests
test {
    _ = @import("nodes/Element-childElement-null.zig");
    _ = @import("nodes/Element-childElementCount.zig");
    _ = @import("nodes/Element-childElementCount-nochild.zig");
    _ = @import("nodes/Element-children.zig");
    _ = @import("nodes/Element-firstElementChild.zig");
    _ = @import("nodes/Element-hasAttribute.zig");
    _ = @import("nodes/Element-hasAttributes.zig");
    _ = @import("nodes/Element-lastElementChild.zig");
    _ = @import("nodes/Element-nextElementSibling.zig");
    _ = @import("nodes/Element-previousElementSibling.zig");
    _ = @import("nodes/Element-setAttribute.zig");
    _ = @import("nodes/Element-siblingElement-null.zig");
    _ = @import("nodes/Element-tagName.zig");
}

// Document tests
test {
    _ = @import("nodes/Document-createComment.zig");
    _ = @import("nodes/Document-createElement.zig");
    _ = @import("nodes/Document-createTextNode.zig");
    _ = @import("nodes/Document-getElementById.zig");
}

// DocumentFragment tests
test {
    _ = @import("nodes/DocumentFragment-constructor.zig");
}

// Comment tests
test {
    _ = @import("nodes/Comment-constructor.zig");
}

// DOMTokenList tests
test {
    _ = @import("nodes/DOMTokenList-classList.zig");
}
