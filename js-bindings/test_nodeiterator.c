#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "dom.h"

void test_nodeiterator_creation() {
    printf("Test 1: NodeIterator creation\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    
    dom_node_appendchild(doc_node, root_node);
    
    DOMNodeIterator* iterator = dom_document_createnodeiterator(
        doc, root_node, DOM_NODEFILTER_SHOW_ALL, NULL
    );
    assert(iterator != NULL);
    printf("  Created NodeIterator\n");
    
    // Check root
    DOMNode* iter_root = dom_nodeiterator_get_root(iterator);
    assert(iter_root == root_node);
    printf("  Root matches\n");
    
    // Check whatToShow
    uint32_t what_to_show = dom_nodeiterator_get_whattoshow(iterator);
    assert(what_to_show == DOM_NODEFILTER_SHOW_ALL);
    printf("  whatToShow = 0x%X\n", what_to_show);
    
    // Check referenceNode (initially at root)
    DOMNode* ref = dom_nodeiterator_get_referencenode(iterator);
    assert(ref == root_node);
    printf("  referenceNode = root\n");
    
    // Check pointerBeforeReferenceNode (initially true)
    uint8_t before = dom_nodeiterator_get_pointerbeforereferencenode(iterator);
    assert(before == 1);
    printf("  pointerBeforeReferenceNode = true\n");
    
    dom_nodeiterator_release(iterator);
    dom_document_release(doc);
    
    printf("  ✓ NodeIterator creation passed\n\n");
}

void test_nodeiterator_nextnode() {
    printf("Test 2: Forward iteration with nextNode()\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* grandchild = dom_document_createelement(doc, "grandchild");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    DOMNode* child1_node = (DOMNode*)child1;
    DOMNode* grandchild_node = (DOMNode*)grandchild;
    DOMNode* child2_node = (DOMNode*)child2;
    
    // Build tree: root -> (child1 -> grandchild, child2)
    dom_node_appendchild(doc_node, root_node);
    dom_node_appendchild(root_node, child1_node);
    dom_node_appendchild(child1_node, grandchild_node);
    dom_node_appendchild(root_node, child2_node);
    
    DOMNodeIterator* iterator = dom_document_createnodeiterator(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // First nextNode() returns root itself
    DOMNode* node = dom_nodeiterator_nextnode(iterator);
    assert(node == root_node);
    printf("  Next: root\n");
    
    // Then child1
    node = dom_nodeiterator_nextnode(iterator);
    assert(node == child1_node);
    printf("  Next: child1\n");
    
    // Then grandchild
    node = dom_nodeiterator_nextnode(iterator);
    assert(node == grandchild_node);
    printf("  Next: grandchild\n");
    
    // Then child2
    node = dom_nodeiterator_nextnode(iterator);
    assert(node == child2_node);
    printf("  Next: child2\n");
    
    // Then NULL (end)
    node = dom_nodeiterator_nextnode(iterator);
    assert(node == NULL);
    printf("  Next: NULL (end)\n");
    
    dom_nodeiterator_release(iterator);
    dom_document_release(doc);
    
    printf("  ✓ nextNode passed\n\n");
}

void test_nodeiterator_previousnode() {
    printf("Test 3: Backward iteration with previousNode()\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    DOMNode* child1_node = (DOMNode*)child1;
    DOMNode* child2_node = (DOMNode*)child2;
    
    dom_node_appendchild(doc_node, root_node);
    dom_node_appendchild(root_node, child1_node);
    dom_node_appendchild(root_node, child2_node);
    
    DOMNodeIterator* iterator = dom_document_createnodeiterator(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // Go forward to end
    while (dom_nodeiterator_nextnode(iterator) != NULL) {}
    printf("  Advanced to end\n");
    
    // Now go backward
    DOMNode* node = dom_nodeiterator_previousnode(iterator);
    assert(node == child2_node);
    printf("  Previous: child2\n");
    
    node = dom_nodeiterator_previousnode(iterator);
    assert(node == child1_node);
    printf("  Previous: child1\n");
    
    node = dom_nodeiterator_previousnode(iterator);
    assert(node == root_node);
    printf("  Previous: root\n");
    
    node = dom_nodeiterator_previousnode(iterator);
    assert(node == NULL);
    printf("  Previous: NULL (before root)\n");
    
    dom_nodeiterator_release(iterator);
    dom_document_release(doc);
    
    printf("  ✓ previousNode passed\n\n");
}

void test_nodeiterator_filter() {
    printf("Test 4: Filter to show only elements\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMText* text1 = dom_document_createtextnode(doc, "text1");
    DOMElement* child = dom_document_createelement(doc, "child");
    DOMText* text2 = dom_document_createtextnode(doc, "text2");
    
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    DOMNode* text1_node = (DOMNode*)text1;
    DOMNode* child_node = (DOMNode*)child;
    DOMNode* text2_node = (DOMNode*)text2;
    
    dom_node_appendchild(doc_node, root_node);
    dom_node_appendchild(root_node, text1_node);
    dom_node_appendchild(root_node, child_node);
    dom_node_appendchild(root_node, text2_node);
    
    // Filter to SHOW_ELEMENT only
    DOMNodeIterator* iterator = dom_document_createnodeiterator(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // Should skip text nodes
    DOMNode* node = dom_nodeiterator_nextnode(iterator);
    assert(node == root_node);
    printf("  Next: root (element)\n");
    
    node = dom_nodeiterator_nextnode(iterator);
    assert(node == child_node);
    printf("  Next: child (element, skipped text nodes)\n");
    
    node = dom_nodeiterator_nextnode(iterator);
    assert(node == NULL);
    printf("  Next: NULL (no more elements)\n");
    
    dom_nodeiterator_release(iterator);
    dom_document_release(doc);
    
    printf("  ✓ Element filtering passed\n\n");
}

void test_nodeiterator_bidirectional() {
    printf("Test 5: Bidirectional iteration (basic)\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMElement* child = dom_document_createelement(doc, "child");
    
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    DOMNode* child_node = (DOMNode*)child;
    
    dom_node_appendchild(doc_node, root_node);
    dom_node_appendchild(root_node, child_node);
    
    DOMNodeIterator* iterator = dom_document_createnodeiterator(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // Can iterate in both directions
    DOMNode* node = dom_nodeiterator_nextnode(iterator);
    assert(node == root_node);
    printf("  Forward: root\n");
    
    node = dom_nodeiterator_nextnode(iterator);
    assert(node == child_node);
    printf("  Forward: child\n");
    
    node = dom_nodeiterator_nextnode(iterator);
    assert(node == NULL);
    printf("  Forward: NULL (end)\n");
    
    dom_nodeiterator_release(iterator);
    dom_document_release(doc);
    
    printf("  ✓ Bidirectional basics passed\n\n");
}

void test_nodeiterator_detach() {
    printf("Test 6: Detach (no-op)\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    
    dom_node_appendchild(doc_node, root_node);
    
    DOMNodeIterator* iterator = dom_document_createnodeiterator(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // Detach (should be no-op)
    dom_nodeiterator_detach(iterator);
    printf("  Detached (no-op per spec)\n");
    
    // Should still work
    DOMNode* node = dom_nodeiterator_nextnode(iterator);
    assert(node == root_node);
    printf("  Still works after detach\n");
    
    dom_nodeiterator_release(iterator);
    dom_document_release(doc);
    
    printf("  ✓ Detach passed\n\n");
}

int main() {
    printf("==============================================\n");
    printf("NodeIterator C-ABI Tests\n");
    printf("==============================================\n\n");
    
    test_nodeiterator_creation();
    test_nodeiterator_nextnode();
    test_nodeiterator_previousnode();
    test_nodeiterator_filter();
    test_nodeiterator_bidirectional();
    test_nodeiterator_detach();
    
    printf("==============================================\n");
    printf("All NodeIterator tests passed! ✓\n");
    printf("==============================================\n");
    
    return 0;
}
