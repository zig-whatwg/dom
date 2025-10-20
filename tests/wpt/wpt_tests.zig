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
    _ = @import("nodes/Node-childNodes-cache.zig");
    _ = @import("nodes/Node-childNodes-cache-2.zig");
    _ = @import("nodes/Node-cloneNode.zig");
    _ = @import("nodes/Node-compareDocumentPosition.zig");
    _ = @import("nodes/Node-constants.zig");
    _ = @import("nodes/Node-contains.zig");
    _ = @import("nodes/Node-contains-basic.zig");
    _ = @import("nodes/Node-firstChild-types.zig");
    _ = @import("nodes/Node-hasChildNodes.zig");
    _ = @import("nodes/Node-hasChildNodes-basic.zig");
    _ = @import("nodes/Node-insertBefore.zig");
    _ = @import("nodes/Node-isConnected.zig");
    _ = @import("nodes/Node-isConnected-simple.zig");
    _ = @import("nodes/Node-isEqualNode.zig");
    _ = @import("nodes/Node-isSameNode.zig");
    _ = @import("nodes/Node-isSameNode-basic.zig");
    _ = @import("nodes/Node-lastChild-types.zig");
    _ = @import("nodes/Node-nextSibling-types.zig");
    _ = @import("nodes/Node-nodeName.zig");
    _ = @import("nodes/Node-nodeName-doctype.zig");
    _ = @import("nodes/Node-nodeType-values.zig");
    _ = @import("nodes/Node-nodeValue.zig");
    _ = @import("nodes/Node-normalize.zig");
    _ = @import("nodes/Node-normalize-simple.zig");
    _ = @import("nodes/Node-ownerDocument.zig");
    _ = @import("nodes/Node-ownerDocument-various.zig");
    _ = @import("nodes/Node-parentElement.zig");
    _ = @import("nodes/Node-parentNode.zig");
    _ = @import("nodes/Node-parentNode-orphan.zig");
    _ = @import("nodes/Node-previousSibling-types.zig");
    _ = @import("nodes/Node-properties.zig");
    _ = @import("nodes/Node-removeChild.zig");
    _ = @import("nodes/Node-replaceChild.zig");
    _ = @import("nodes/Node-textContent.zig");
}

// CharacterData tests
test {
    _ = @import("nodes/CharacterData-appendChild.zig");
    _ = @import("nodes/CharacterData-appendData.zig");
    _ = @import("nodes/CharacterData-data.zig");
    _ = @import("nodes/CharacterData-deleteData.zig");
    _ = @import("nodes/CharacterData-insertData.zig");
    _ = @import("nodes/CharacterData-length.zig");
    _ = @import("nodes/CharacterData-remove.zig");
    _ = @import("nodes/CharacterData-replaceData.zig");
    _ = @import("nodes/CharacterData-substringData.zig");
}

// Element tests
test {
    _ = @import("nodes/Element-attributes.zig");
    _ = @import("nodes/Element-attributes-count.zig");
    _ = @import("nodes/Element-childElement-null.zig");
    _ = @import("nodes/Element-childElementCount.zig");
    _ = @import("nodes/Element-childElementCount-dynamic-add.zig");
    _ = @import("nodes/Element-childElementCount-dynamic-remove.zig");
    _ = @import("nodes/Element-childElementCount-nochild.zig");
    _ = @import("nodes/Element-children.zig");
    _ = @import("nodes/Element-className.zig");
    _ = @import("nodes/Element-className-property.zig");
    _ = @import("nodes/Element-classlist.zig");
    _ = @import("nodes/Element-firstElementChild.zig");
    _ = @import("nodes/Element-getAttribute-variations.zig");
    _ = @import("nodes/Element-getElementsByClassName.zig");
    _ = @import("nodes/Element-getElementsByTagName.zig");
    _ = @import("nodes/Element-hasAttribute.zig");
    _ = @import("nodes/Element-hasAttribute-variations.zig");
    _ = @import("nodes/Element-hasAttributes.zig");
    _ = @import("nodes/Element-id.zig");
    _ = @import("nodes/Element-id-property.zig");
    _ = @import("nodes/Element-lastElementChild.zig");
    _ = @import("nodes/Element-localName.zig");
    _ = @import("nodes/Element-localName-basic.zig");
    _ = @import("nodes/Element-namespaceURI.zig");
    _ = @import("nodes/Element-nextElementSibling.zig");
    _ = @import("nodes/Element-prefix.zig");
    _ = @import("nodes/Element-previousElementSibling.zig");
    _ = @import("nodes/Element-removeAttribute.zig");
    _ = @import("nodes/Element-removeAttribute-variations.zig");
    _ = @import("nodes/Element-setAttribute.zig");
    _ = @import("nodes/Element-setAttribute-variations.zig");
    _ = @import("nodes/Element-siblingElement-null.zig");
    _ = @import("nodes/Element-tagName.zig");
    _ = @import("nodes/Element-tagName-case.zig");
    _ = @import("nodes/Element-toggleAttribute-basic.zig");
}

// ParentNode tests
test {
    _ = @import("nodes/ParentNode-append.zig");
    _ = @import("nodes/ParentNode-children.zig");
    _ = @import("nodes/ParentNode-prepend.zig");
    _ = @import("nodes/ParentNode-replaceChildren.zig");
}

// ChildNode tests
test {
    _ = @import("nodes/ChildNode-before.zig");
    _ = @import("nodes/ChildNode-after.zig");
    _ = @import("nodes/ChildNode-remove.zig");
    _ = @import("nodes/ChildNode-replaceWith.zig");
}

// Document tests
test {
    _ = @import("nodes/Document-createComment.zig");
    _ = @import("nodes/Document-createComment-basic.zig");
    _ = @import("nodes/Document-createDocumentFragment-basic.zig");
    _ = @import("nodes/Document-createElement.zig");
    _ = @import("nodes/Document-createElement-basic.zig");
    _ = @import("nodes/Document-createProcessingInstruction.zig");
    _ = @import("nodes/Document-createProcessingInstruction-basic.zig");
    _ = @import("nodes/Document-createTextNode.zig");
    _ = @import("nodes/Document-createTextNode-basic.zig");
    _ = @import("nodes/Document-doctype.zig");
    _ = @import("nodes/Document-doctype-property.zig");
    _ = @import("nodes/Document-documentElement.zig");
    _ = @import("nodes/Document-getElementById.zig");
    _ = @import("nodes/Document-getElementsByClassName.zig");
    _ = @import("nodes/Document-getElementsByTagName.zig");
    _ = @import("nodes/Document-importNode.zig");
    _ = @import("nodes/Document-URL.zig");
}

// DocumentFragment tests
test {
    _ = @import("nodes/DocumentFragment-children.zig");
    _ = @import("nodes/DocumentFragment-children-access.zig");
    _ = @import("nodes/DocumentFragment-constructor.zig");
    _ = @import("nodes/DocumentFragment-querySelectorAll.zig");
}

// DocumentType tests
test {
    _ = @import("nodes/DocumentType-literal.zig");
    _ = @import("nodes/DocumentType-name-publicId-systemId.zig");
    _ = @import("nodes/DocumentType-nodeName-property.zig");
    _ = @import("nodes/DocumentType-remove.zig");
}

// Comment tests
test {
    _ = @import("nodes/Comment-constructor.zig");
    _ = @import("nodes/Comment-data.zig");
    _ = @import("nodes/Comment-data-property.zig");
}

// Text tests
test {
    _ = @import("nodes/Text-constructor.zig");
    _ = @import("nodes/Text-data.zig");
    _ = @import("nodes/Text-splitText.zig");
    _ = @import("nodes/Text-wholeText.zig");
    _ = @import("nodes/Text-wholeText-simple.zig");
}

// ProcessingInstruction tests
test {
    _ = @import("nodes/ProcessingInstruction-nodeName.zig");
    _ = @import("nodes/ProcessingInstruction-target.zig");
}

// DOMTokenList tests
test {
    _ = @import("nodes/DOMTokenList-classList.zig");
}

// TreeWalker tests
test {
    _ = @import("traversal/TreeWalker-basic.zig");
    _ = @import("traversal/TreeWalker-currentNode.zig");
    _ = @import("traversal/TreeWalker-traversal-reject.zig");
    _ = @import("traversal/TreeWalker-traversal-skip.zig");
    _ = @import("traversal/TreeWalker-acceptNode-filter.zig");
}

// NodeIterator tests
test {
    _ = @import("traversal/NodeIterator.zig");
    _ = @import("traversal/NodeIterator-removal.zig");
    _ = @import("traversal/NodeFilter-constants.zig");
}

// Range tests
test {
    _ = @import("ranges/Range-constructor.zig");
    _ = @import("ranges/Range-compareBoundaryPoints.zig");
    _ = @import("ranges/Range-deleteContents.zig");
    _ = @import("ranges/Range-extractContents.zig");
    _ = @import("ranges/Range-insertNode.zig");
}

// DOMTokenList WPT tests
test {
    _ = @import("lists/DOMTokenList-Iterable.zig");
    _ = @import("lists/DOMTokenList-iteration.zig");
    _ = @import("lists/DOMTokenList-stringifier.zig");
    _ = @import("lists/DOMTokenList-value.zig");
}

// HTMLCollection WPT tests
test {
    _ = @import("collections/HTMLCollection-iterator.zig");
    _ = @import("collections/HTMLCollection-supported-property-indices.zig");
    _ = @import("collections/HTMLCollection-supported-property-names.zig");
    _ = @import("collections/HTMLCollection-empty-name.zig");
}

// AbortSignal WPT tests
test {
    _ = @import("abort/AbortSignal.zig");
    _ = @import("abort/event.zig");
    _ = @import("abort/AbortSignal-any.zig");
}
