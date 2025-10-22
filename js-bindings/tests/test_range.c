#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "dom.h"

void test_range_creation() {
    printf("Test 1: Range creation and basic properties\n");
    
    DOMDocument* doc = dom_document_new();
    DOMRange* range = dom_document_createrange(doc);
    
    assert(range != NULL);
    printf("  Created range\n");
    
    // Check collapsed (should be true for new range)
    uint8_t collapsed = dom_range_get_collapsed(range);
    assert(collapsed == 1);
    printf("  New range is collapsed: %u\n", collapsed);
    
    // Check boundaries (should be at document root)
    DOMNode* start_container = dom_range_get_startcontainer(range);
    DOMNode* end_container = dom_range_get_endcontainer(range);
    uint32_t start_offset = dom_range_get_startoffset(range);
    uint32_t end_offset = dom_range_get_endoffset(range);
    
    assert(start_container != NULL);
    assert(end_container != NULL);
    assert(start_container == end_container);
    assert(start_offset == 0);
    assert(end_offset == 0);
    printf("  Boundaries: container=%p, offset=%u\n", (void*)start_container, start_offset);
    
    dom_range_release(range);
    dom_document_release(doc);
    
    printf("  ✓ Range creation passed\n\n");
}

void test_range_set_boundaries() {
    printf("Test 2: Setting range boundaries\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "div");
    DOMText* text = dom_document_createtextnode(doc, "Hello World");
    DOMNode* elem_node = (DOMNode*)elem;
    DOMNode* text_node = (DOMNode*)text;
    
    dom_node_appendchild(elem_node, text_node);
    
    DOMRange* range = dom_document_createrange(doc);
    
    // Set range to select "Hello"
    int result = dom_range_setstart(range, text_node, 0);
    assert(result == 0);
    result = dom_range_setend(range, text_node, 5);
    assert(result == 0);
    printf("  Set range to [0, 5] in text node\n");
    
    // Verify boundaries
    assert(dom_range_get_startcontainer(range) == text_node);
    assert(dom_range_get_endcontainer(range) == text_node);
    assert(dom_range_get_startoffset(range) == 0);
    assert(dom_range_get_endoffset(range) == 5);
    assert(dom_range_get_collapsed(range) == 0);
    printf("  Range is not collapsed\n");
    
    dom_range_release(range);
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("  ✓ Setting boundaries passed\n\n");
}

void test_range_collapse() {
    printf("Test 3: Collapsing range\n");
    
    DOMDocument* doc = dom_document_new();
    DOMText* text = dom_document_createtextnode(doc, "Test");
    DOMNode* text_node = (DOMNode*)text;
    
    DOMRange* range = dom_document_createrange(doc);
    
    // Set range
    dom_range_setstart(range, text_node, 0);
    dom_range_setend(range, text_node, 4);
    assert(dom_range_get_collapsed(range) == 0);
    printf("  Range [0, 4] is not collapsed\n");
    
    // Collapse to start
    dom_range_collapse(range, 1);
    assert(dom_range_get_collapsed(range) == 1);
    assert(dom_range_get_startoffset(range) == 0);
    assert(dom_range_get_endoffset(range) == 0);
    printf("  Collapsed to start: [0, 0]\n");
    
    // Set range again
    dom_range_setstart(range, text_node, 1);
    dom_range_setend(range, text_node, 3);
    
    // Collapse to end
    dom_range_collapse(range, 0);
    assert(dom_range_get_collapsed(range) == 1);
    assert(dom_range_get_startoffset(range) == 3);
    assert(dom_range_get_endoffset(range) == 3);
    printf("  Collapsed to end: [3, 3]\n");
    
    dom_range_release(range);
    dom_document_release(doc);
    
    printf("  ✓ Collapse passed\n\n");
}

void test_range_select_node() {
    printf("Test 4: Selecting nodes\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    
    DOMNode* parent_node = (DOMNode*)parent;
    DOMNode* child1_node = (DOMNode*)child1;
    DOMNode* child2_node = (DOMNode*)child2;
    
    dom_node_appendchild(parent_node, child1_node);
    dom_node_appendchild(parent_node, child2_node);
    
    DOMRange* range = dom_document_createrange(doc);
    
    // selectNode (includes the node)
    int result = dom_range_selectnode(range, child1_node);
    assert(result == 0);
    
    assert(dom_range_get_startcontainer(range) == parent_node);
    assert(dom_range_get_endcontainer(range) == parent_node);
    assert(dom_range_get_startoffset(range) == 0);
    assert(dom_range_get_endoffset(range) == 1);
    printf("  selectNode: range in parent [0, 1]\n");
    
    // selectNodeContents (only contents)
    result = dom_range_selectnodecontents(range, parent_node);
    assert(result == 0);
    
    assert(dom_range_get_startcontainer(range) == parent_node);
    assert(dom_range_get_endcontainer(range) == parent_node);
    assert(dom_range_get_startoffset(range) == 0);
    assert(dom_range_get_endoffset(range) == 2);  // 2 children
    printf("  selectNodeContents: range in parent [0, 2]\n");
    
    dom_range_release(range);
    dom_element_release(parent);
    dom_document_release(doc);
    
    printf("  ✓ Select node passed\n\n");
}

void test_range_set_before_after() {
    printf("Test 5: Setting boundaries before/after nodes\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    DOMElement* child3 = dom_document_createelement(doc, "child3");
    
    DOMNode* parent_node = (DOMNode*)parent;
    DOMNode* child1_node = (DOMNode*)child1;
    DOMNode* child2_node = (DOMNode*)child2;
    DOMNode* child3_node = (DOMNode*)child3;
    
    dom_node_appendchild(parent_node, child1_node);
    dom_node_appendchild(parent_node, child2_node);
    dom_node_appendchild(parent_node, child3_node);
    
    DOMRange* range = dom_document_createrange(doc);
    
    // Set start before child2
    int result = dom_range_setstartbefore(range, child2_node);
    assert(result == 0);
    assert(dom_range_get_startoffset(range) == 1);  // Before child2 (index 1)
    printf("  setStartBefore child2: offset=1\n");
    
    // Set end after child2
    result = dom_range_setendafter(range, child2_node);
    assert(result == 0);
    assert(dom_range_get_endoffset(range) == 2);  // After child2 (index 2)
    printf("  setEndAfter child2: offset=2\n");
    
    // Set start after child1
    result = dom_range_setstartafter(range, child1_node);
    assert(result == 0);
    assert(dom_range_get_startoffset(range) == 1);  // After child1 = before child2
    printf("  setStartAfter child1: offset=1\n");
    
    // Set end before child3
    result = dom_range_setendbefore(range, child3_node);
    assert(result == 0);
    assert(dom_range_get_endoffset(range) == 2);  // Before child3 = after child2
    printf("  setEndBefore child3: offset=2\n");
    
    dom_range_release(range);
    dom_element_release(parent);
    dom_document_release(doc);
    
    printf("  ✓ Before/after boundaries passed\n\n");
}

void test_range_comparison() {
    printf("Test 6: Range comparison\n");
    
    DOMDocument* doc = dom_document_new();
    DOMText* text = dom_document_createtextnode(doc, "0123456789");
    DOMNode* text_node = (DOMNode*)text;
    
    DOMRange* range1 = dom_document_createrange(doc);
    DOMRange* range2 = dom_document_createrange(doc);
    
    // range1: [2, 5]
    dom_range_setstart(range1, text_node, 2);
    dom_range_setend(range1, text_node, 5);
    
    // range2: [4, 8]
    dom_range_setstart(range2, text_node, 4);
    dom_range_setend(range2, text_node, 8);
    
    // START_TO_START: range1.start vs range2.start (2 vs 4)
    int16_t result = dom_range_compareboundarypoints(range1, DOM_RANGE_START_TO_START, range2);
    assert(result == -1);  // 2 < 4
    printf("  START_TO_START: -1 (2 < 4)\n");
    
    // START_TO_END: range1.start vs range2.end (2 vs 8)
    result = dom_range_compareboundarypoints(range1, DOM_RANGE_START_TO_END, range2);
    assert(result == -1);  // 2 < 8
    printf("  START_TO_END: -1 (2 < 8)\n");
    
    // END_TO_END: range1.end vs range2.end (5 vs 8)
    result = dom_range_compareboundarypoints(range1, DOM_RANGE_END_TO_END, range2);
    assert(result == -1);  // 5 < 8
    printf("  END_TO_END: -1 (5 < 8)\n");
    
    // END_TO_START: range1.end vs range2.start (5 vs 4)
    result = dom_range_compareboundarypoints(range1, DOM_RANGE_END_TO_START, range2);
    assert(result == 1);  // 5 > 4
    printf("  END_TO_START: 1 (5 > 4)\n");
    
    dom_range_release(range1);
    dom_range_release(range2);
    dom_document_release(doc);
    
    printf("  ✓ Comparison passed\n\n");
}

void test_range_point_operations() {
    printf("Test 7: Point operations\n");
    
    DOMDocument* doc = dom_document_new();
    DOMText* text = dom_document_createtextnode(doc, "Hello");
    DOMNode* text_node = (DOMNode*)text;
    
    DOMRange* range = dom_document_createrange(doc);
    
    // Set range [1, 4]
    dom_range_setstart(range, text_node, 1);
    dom_range_setend(range, text_node, 4);
    
    // isPointInRange
    uint8_t in_range = dom_range_ispointinrange(range, text_node, 2);
    assert(in_range == 1);
    printf("  Point (2) is in range [1, 4]\n");
    
    in_range = dom_range_ispointinrange(range, text_node, 0);
    assert(in_range == 0);
    printf("  Point (0) is not in range [1, 4]\n");
    
    // comparePoint
    int16_t cmp = dom_range_comparepoint(range, text_node, 0);
    assert(cmp == -1);  // 0 < start (1)
    printf("  Point (0) is before range: %d\n", cmp);
    
    cmp = dom_range_comparepoint(range, text_node, 2);
    assert(cmp == 0);  // 2 is in range
    printf("  Point (2) is in range: %d\n", cmp);
    
    cmp = dom_range_comparepoint(range, text_node, 5);
    assert(cmp == 1);  // 5 > end (4)
    printf("  Point (5) is after range: %d\n", cmp);
    
    dom_range_release(range);
    dom_document_release(doc);
    
    printf("  ✓ Point operations passed\n\n");
}

void test_range_intersects() {
    printf("Test 8: intersectsNode\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    DOMElement* outside = dom_document_createelement(doc, "outside");
    
    DOMNode* doc_node = (DOMNode*)doc;
    DOMNode* parent_node = (DOMNode*)parent;
    DOMNode* child1_node = (DOMNode*)child1;
    DOMNode* child2_node = (DOMNode*)child2;
    DOMNode* outside_node = (DOMNode*)outside;
    
    // Attach parent to document so it has a parent
    dom_node_appendchild(doc_node, parent_node);
    dom_node_appendchild(parent_node, child1_node);
    dom_node_appendchild(parent_node, child2_node);
    
    DOMRange* range = dom_document_createrange(doc);
    
    // Select child1
    dom_range_selectnode(range, child1_node);
    
    // child1 should intersect
    uint8_t intersects = dom_range_intersectsnode(range, child1_node);
    assert(intersects == 1);
    printf("  child1 intersects range containing it\n");
    
    // parent should intersect (contains the range)
    intersects = dom_range_intersectsnode(range, parent_node);
    assert(intersects == 1);
    printf("  parent intersects range within it\n");
    
    // outside should not intersect
    intersects = dom_range_intersectsnode(range, outside_node);
    assert(intersects == 0);
    printf("  outside node does not intersect\n");
    
    dom_range_release(range);
    dom_element_release(parent);
    dom_element_release(outside);
    dom_document_release(doc);
    
    printf("  ✓ intersectsNode passed\n\n");
}

void test_range_clone() {
    printf("Test 9: Cloning range\n");
    
    DOMDocument* doc = dom_document_new();
    DOMText* text = dom_document_createtextnode(doc, "Test");
    DOMNode* text_node = (DOMNode*)text;
    
    DOMRange* range1 = dom_document_createrange(doc);
    dom_range_setstart(range1, text_node, 1);
    dom_range_setend(range1, text_node, 3);
    
    // Clone the range
    DOMRange* range2 = dom_range_clonerange(range1);
    assert(range2 != NULL);
    assert(range2 != range1);
    printf("  Cloned range (different pointer)\n");
    
    // Verify clone has same boundaries
    assert(dom_range_get_startcontainer(range2) == text_node);
    assert(dom_range_get_endcontainer(range2) == text_node);
    assert(dom_range_get_startoffset(range2) == 1);
    assert(dom_range_get_endoffset(range2) == 3);
    printf("  Clone has same boundaries [1, 3]\n");
    
    // Modify original, clone should not change
    dom_range_setend(range1, text_node, 4);
    assert(dom_range_get_endoffset(range1) == 4);
    assert(dom_range_get_endoffset(range2) == 3);
    printf("  Modifying original doesn't affect clone\n");
    
    dom_range_release(range1);
    dom_range_release(range2);
    dom_document_release(doc);
    
    printf("  ✓ Clone range passed\n\n");
}

void test_range_common_ancestor() {
    printf("Test 10: Common ancestor\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    DOMElement* div1 = dom_document_createelement(doc, "div1");
    DOMElement* div2 = dom_document_createelement(doc, "div2");
    DOMText* text1 = dom_document_createtextnode(doc, "Text1");
    DOMText* text2 = dom_document_createtextnode(doc, "Text2");
    
    DOMNode* root_node = (DOMNode*)root;
    DOMNode* div1_node = (DOMNode*)div1;
    DOMNode* div2_node = (DOMNode*)div2;
    DOMNode* text1_node = (DOMNode*)text1;
    DOMNode* text2_node = (DOMNode*)text2;
    
    // Build tree: root -> div1 -> text1, root -> div2 -> text2
    dom_node_appendchild(root_node, div1_node);
    dom_node_appendchild(root_node, div2_node);
    dom_node_appendchild(div1_node, text1_node);
    dom_node_appendchild(div2_node, text2_node);
    
    DOMRange* range = dom_document_createrange(doc);
    
    // Range from text1 to text2
    dom_range_setstart(range, text1_node, 0);
    dom_range_setend(range, text2_node, 0);
    
    // Common ancestor should be root
    DOMNode* common = dom_range_get_commonancestorcontainer(range);
    assert(common == root_node);
    printf("  Common ancestor of text1 and text2 is root\n");
    
    // Range within text1
    dom_range_setstart(range, text1_node, 0);
    dom_range_setend(range, text1_node, 3);
    
    common = dom_range_get_commonancestorcontainer(range);
    assert(common == text1_node);
    printf("  Common ancestor within text1 is text1\n");
    
    dom_range_release(range);
    dom_element_release(root);
    dom_document_release(doc);
    
    printf("  ✓ Common ancestor passed\n\n");
}

int main() {
    printf("==============================================\n");
    printf("Range C-ABI Tests\n");
    printf("==============================================\n\n");
    
    test_range_creation();
    test_range_set_boundaries();
    test_range_collapse();
    test_range_select_node();
    test_range_set_before_after();
    test_range_comparison();
    test_range_point_operations();
    test_range_intersects();
    test_range_clone();
    test_range_common_ancestor();
    
    printf("==============================================\n");
    printf("All Range tests passed! ✓\n");
    printf("==============================================\n");
    
    return 0;
}
