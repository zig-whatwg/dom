#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "dom.h"

void test_treewalker_creation() {
    printf("Test 1: TreeWalker creation\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    
    // Attach root to document
    dom_node_appendchild(doc_node, root_node);
    
    // Create tree walker
    DOMTreeWalker* walker = dom_document_createtreewalker(
        doc,
        root_node,
        DOM_NODEFILTER_SHOW_ALL,
        NULL
    );
    assert(walker != NULL);
    printf("  Created TreeWalker\n");
    
    // Check root
    DOMNode* walker_root = dom_treewalker_get_root(walker);
    assert(walker_root == root_node);
    printf("  Root matches\n");
    
    // Check whatToShow
    uint32_t what_to_show = dom_treewalker_get_whattoshow(walker);
    assert(what_to_show == DOM_NODEFILTER_SHOW_ALL);
    printf("  whatToShow = 0x%X\n", what_to_show);
    
    // Check currentNode (should start at root)
    DOMNode* current = dom_treewalker_get_currentnode(walker);
    assert(current == root_node);
    printf("  currentNode = root\n");
    
    dom_treewalker_release(walker);
    dom_document_release(doc);
    
    printf("  ✓ TreeWalker creation passed\n\n");
}

void test_treewalker_firstchild() {
    printf("Test 2: Navigate to first child\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    DOMNode* child1_node = (DOMNode*)child1;
    DOMNode* child2_node = (DOMNode*)child2;
    
    // Build tree: doc -> root -> (child1, child2)
    dom_node_appendchild(doc_node, root_node);
    dom_node_appendchild(root_node, child1_node);
    dom_node_appendchild(root_node, child2_node);
    
    DOMTreeWalker* walker = dom_document_createtreewalker(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // Navigate to first child
    DOMNode* first = dom_treewalker_firstchild(walker);
    assert(first != NULL);
    assert(first == child1_node);
    printf("  First child is child1\n");
    
    // currentNode should now be child1
    DOMNode* current = dom_treewalker_get_currentnode(walker);
    assert(current == child1_node);
    printf("  currentNode = child1\n");
    
    dom_treewalker_release(walker);
    dom_document_release(doc);
    
    printf("  ✓ First child passed\n\n");
}

void test_treewalker_lastchild() {
    printf("Test 3: Navigate to last child\n");
    
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
    
    DOMTreeWalker* walker = dom_document_createtreewalker(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // Navigate to last child
    DOMNode* last = dom_treewalker_lastchild(walker);
    assert(last != NULL);
    assert(last == child2_node);
    printf("  Last child is child2\n");
    
    dom_treewalker_release(walker);
    dom_document_release(doc);
    
    printf("  ✓ Last child passed\n\n");
}

void test_treewalker_siblings() {
    printf("Test 4: Navigate siblings\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    DOMElement* child3 = dom_document_createelement(doc, "child3");
    
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    DOMNode* child1_node = (DOMNode*)child1;
    DOMNode* child2_node = (DOMNode*)child2;
    DOMNode* child3_node = (DOMNode*)child3;
    
    dom_node_appendchild(doc_node, root_node);
    dom_node_appendchild(root_node, child1_node);
    dom_node_appendchild(root_node, child2_node);
    dom_node_appendchild(root_node, child3_node);
    
    DOMTreeWalker* walker = dom_document_createtreewalker(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // Start at child1
    dom_treewalker_firstchild(walker);
    DOMNode* current = dom_treewalker_get_currentnode(walker);
    assert(current == child1_node);
    printf("  Started at child1\n");
    
    // Next sibling -> child2
    DOMNode* next = dom_treewalker_nextsibling(walker);
    assert(next == child2_node);
    printf("  Next sibling is child2\n");
    
    // Next sibling -> child3
    next = dom_treewalker_nextsibling(walker);
    assert(next == child3_node);
    printf("  Next sibling is child3\n");
    
    // Previous sibling -> child2
    DOMNode* prev = dom_treewalker_previoussibling(walker);
    assert(prev == child2_node);
    printf("  Previous sibling is child2\n");
    
    dom_treewalker_release(walker);
    dom_document_release(doc);
    
    printf("  ✓ Siblings passed\n\n");
}

void test_treewalker_parent() {
    printf("Test 5: Navigate to parent\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMElement* child = dom_document_createelement(doc, "child");
    
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    DOMNode* child_node = (DOMNode*)child;
    
    dom_node_appendchild(doc_node, root_node);
    dom_node_appendchild(root_node, child_node);
    
    DOMTreeWalker* walker = dom_document_createtreewalker(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // Navigate to child
    dom_treewalker_firstchild(walker);
    DOMNode* current = dom_treewalker_get_currentnode(walker);
    assert(current == child_node);
    printf("  At child\n");
    
    // Navigate to parent
    DOMNode* parent = dom_treewalker_parentnode(walker);
    assert(parent == root_node);
    printf("  Parent is root\n");
    
    // Try to go past root (should return NULL)
    parent = dom_treewalker_parentnode(walker);
    assert(parent == NULL);
    printf("  Cannot navigate past root\n");
    
    dom_treewalker_release(walker);
    dom_document_release(doc);
    
    printf("  ✓ Parent navigation passed\n\n");
}

void test_treewalker_nextnode() {
    printf("Test 6: Navigate with nextNode()\n");
    
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
    
    DOMTreeWalker* walker = dom_document_createtreewalker(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // Traverse in document order
    DOMNode* node = dom_treewalker_nextnode(walker);  // child1
    assert(node == child1_node);
    printf("  Next: child1\n");
    
    node = dom_treewalker_nextnode(walker);  // grandchild
    assert(node == grandchild_node);
    printf("  Next: grandchild\n");
    
    node = dom_treewalker_nextnode(walker);  // child2
    assert(node == child2_node);
    printf("  Next: child2\n");
    
    node = dom_treewalker_nextnode(walker);  // NULL (end)
    assert(node == NULL);
    printf("  Next: NULL (end of tree)\n");
    
    dom_treewalker_release(walker);
    dom_document_release(doc);
    
    printf("  ✓ nextNode passed\n\n");
}

void test_treewalker_previousnode() {
    printf("Test 7: Navigate with previousNode()\n");
    
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
    
    DOMTreeWalker* walker = dom_document_createtreewalker(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // Go to end
    dom_treewalker_lastchild(walker);
    dom_treewalker_nextsibling(walker);
    // Now at child2
    
    DOMNode* node = dom_treewalker_previousnode(walker);  // child1
    assert(node == child1_node);
    printf("  Previous: child1\n");
    
    node = dom_treewalker_previousnode(walker);  // root
    assert(node == root_node);
    printf("  Previous: root\n");
    
    node = dom_treewalker_previousnode(walker);  // NULL
    assert(node == NULL);
    printf("  Previous: NULL (before root)\n");
    
    dom_treewalker_release(walker);
    dom_document_release(doc);
    
    printf("  ✓ previousNode passed\n\n");
}

void test_treewalker_setcurrentnode() {
    printf("Test 8: Set currentNode\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMElement* child = dom_document_createelement(doc, "child");
    
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    DOMNode* child_node = (DOMNode*)child;
    
    dom_node_appendchild(doc_node, root_node);
    dom_node_appendchild(root_node, child_node);
    
    DOMTreeWalker* walker = dom_document_createtreewalker(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // Initially at root
    DOMNode* current = dom_treewalker_get_currentnode(walker);
    assert(current == root_node);
    printf("  Initial: root\n");
    
    // Set to child
    dom_treewalker_set_currentnode(walker, child_node);
    current = dom_treewalker_get_currentnode(walker);
    assert(current == child_node);
    printf("  Set to: child\n");
    
    dom_treewalker_release(walker);
    dom_document_release(doc);
    
    printf("  ✓ Set currentNode passed\n\n");
}

void test_treewalker_filter_elements() {
    printf("Test 9: Filter to show only elements\n");
    
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
    DOMTreeWalker* walker = dom_document_createtreewalker(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // First child should skip text1 and find child element
    DOMNode* first = dom_treewalker_firstchild(walker);
    assert(first == child_node);
    printf("  First child (filtered) is child element (skipped text nodes)\n");
    
    // No more element siblings
    DOMNode* next = dom_treewalker_nextsibling(walker);
    assert(next == NULL);
    printf("  No more element siblings\n");
    
    dom_treewalker_release(walker);
    dom_document_release(doc);
    
    printf("  ✓ Element filtering passed\n\n");
}

void test_treewalker_no_children() {
    printf("Test 10: Navigate with no children\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* root_node = (DOMNode*)root;
    
    dom_node_appendchild(doc_node, root_node);
    
    DOMTreeWalker* walker = dom_document_createtreewalker(
        doc, root_node, DOM_NODEFILTER_SHOW_ELEMENT, NULL
    );
    
    // No children
    DOMNode* first = dom_treewalker_firstchild(walker);
    assert(first == NULL);
    printf("  No children: NULL\n");
    
    DOMNode* last = dom_treewalker_lastchild(walker);
    assert(last == NULL);
    printf("  No last child: NULL\n");
    
    dom_treewalker_release(walker);
    dom_document_release(doc);
    
    printf("  ✓ No children passed\n\n");
}

int main() {
    printf("==============================================\n");
    printf("TreeWalker C-ABI Tests\n");
    printf("==============================================\n\n");
    
    test_treewalker_creation();
    test_treewalker_firstchild();
    test_treewalker_lastchild();
    test_treewalker_siblings();
    test_treewalker_parent();
    test_treewalker_nextnode();
    test_treewalker_previousnode();
    test_treewalker_setcurrentnode();
    test_treewalker_filter_elements();
    test_treewalker_no_children();
    
    printf("==============================================\n");
    printf("All TreeWalker tests passed! ✓\n");
    printf("==============================================\n");
    
    return 0;
}
