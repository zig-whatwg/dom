/**
 * Test Text Nodes (Phase 3)
 * 
 * Tests CharacterData, Text, Comment, CDATASection, and ProcessingInstruction interfaces.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

// Forward declarations
typedef struct DOMDocument DOMDocument;
typedef struct DOMText DOMText;
typedef struct DOMComment DOMComment;
typedef struct DOMCDATASection DOMCDATASection;
typedef struct DOMProcessingInstruction DOMProcessingInstruction;
typedef struct DOMCharacterData DOMCharacterData;

// Document
extern DOMDocument* dom_document_new(void);
extern void dom_document_release(DOMDocument* doc);
extern DOMText* dom_document_createtextnode(DOMDocument* doc, const char* data);
extern DOMComment* dom_document_createcomment(DOMDocument* doc, const char* data);
extern DOMCDATASection* dom_document_createcdatasection(DOMDocument* doc, const char* data);
extern DOMProcessingInstruction* dom_document_createprocessinginstruction(DOMDocument* doc, const char* target, const char* data);

// CharacterData
extern const char* dom_characterdata_get_data(DOMCharacterData* cdata);
extern int dom_characterdata_set_data(DOMCharacterData* cdata, const char* data);
extern unsigned int dom_characterdata_get_length(DOMCharacterData* cdata);
extern int dom_characterdata_appenddata(DOMCharacterData* cdata, const char* data);
extern int dom_characterdata_insertdata(DOMCharacterData* cdata, unsigned int offset, const char* data);
extern int dom_characterdata_deletedata(DOMCharacterData* cdata, unsigned int offset, unsigned int count);
extern int dom_characterdata_replacedata(DOMCharacterData* cdata, unsigned int offset, unsigned int count, const char* data);

// Text
extern DOMText* dom_text_splittext(DOMText* text, unsigned int offset);
extern void dom_text_addref(DOMText* text);
extern void dom_text_release(DOMText* text);

// Comment
extern void dom_comment_addref(DOMComment* comment);
extern void dom_comment_release(DOMComment* comment);

// CDATASection
extern void dom_cdatasection_addref(DOMCDATASection* cdata);
extern void dom_cdatasection_release(DOMCDATASection* cdata);

// ProcessingInstruction
extern const char* dom_processinginstruction_get_target(DOMProcessingInstruction* pi);
extern void dom_processinginstruction_addref(DOMProcessingInstruction* pi);
extern void dom_processinginstruction_release(DOMProcessingInstruction* pi);

int main(void) {
    printf("Testing Text Nodes (Phase 3)\n");
    printf("============================\n\n");

    DOMDocument* doc = dom_document_new();
    assert(doc != NULL);

    // Test 1: Text node with CharacterData methods
    printf("Test 1: Text + CharacterData\n");
    DOMText* text = dom_document_createtextnode(doc, "Hello");
    assert(text != NULL);
    printf("  ✓ Created text node\n");

    // Get data
    const char* data = dom_characterdata_get_data((DOMCharacterData*)text);
    assert(strcmp(data, "Hello") == 0);
    printf("  ✓ data = 'Hello'\n");

    // Get length
    unsigned int len = dom_characterdata_get_length((DOMCharacterData*)text);
    assert(len == 5);
    printf("  ✓ length = 5\n");

    // Append data
    int result = dom_characterdata_appenddata((DOMCharacterData*)text, " World");
    assert(result == 0);
    data = dom_characterdata_get_data((DOMCharacterData*)text);
    assert(strcmp(data, "Hello World") == 0);
    printf("  ✓ appendData: 'Hello World'\n");

    // Insert data
    result = dom_characterdata_insertdata((DOMCharacterData*)text, 5, " Beautiful");
    assert(result == 0);
    data = dom_characterdata_get_data((DOMCharacterData*)text);
    assert(strcmp(data, "Hello Beautiful World") == 0);
    printf("  ✓ insertData: 'Hello Beautiful World'\n");

    // Delete data
    result = dom_characterdata_deletedata((DOMCharacterData*)text, 5, 10);
    assert(result == 0);
    data = dom_characterdata_get_data((DOMCharacterData*)text);
    assert(strcmp(data, "Hello World") == 0);
    printf("  ✓ deleteData: 'Hello World'\n");

    // Replace data
    result = dom_characterdata_replacedata((DOMCharacterData*)text, 6, 5, "Zig");
    assert(result == 0);
    data = dom_characterdata_get_data((DOMCharacterData*)text);
    assert(strcmp(data, "Hello Zig") == 0);
    printf("  ✓ replaceData: 'Hello Zig'\n");

    // Set data
    result = dom_characterdata_set_data((DOMCharacterData*)text, "New content");
    assert(result == 0);
    data = dom_characterdata_get_data((DOMCharacterData*)text);
    assert(strcmp(data, "New content") == 0);
    len = dom_characterdata_get_length((DOMCharacterData*)text);
    assert(len == 11);
    printf("  ✓ setData: 'New content' (length=11)\n");

    dom_text_release(text);
    printf("\n");

    // Test 2: Text splitText
    printf("Test 2: Text.splitText()\n");
    text = dom_document_createtextnode(doc, "Hello World");
    
    DOMText* second = dom_text_splittext(text, 6);
    assert(second != NULL);
    printf("  ✓ Split at offset 6\n");

    data = dom_characterdata_get_data((DOMCharacterData*)text);
    assert(strcmp(data, "Hello ") == 0);
    printf("  ✓ First part: 'Hello '\n");

    const char* second_data = dom_characterdata_get_data((DOMCharacterData*)second);
    assert(strcmp(second_data, "World") == 0);
    printf("  ✓ Second part: 'World'\n");

    dom_text_release(second);
    dom_text_release(text);
    printf("\n");

    // Test 3: Comment node
    printf("Test 3: Comment\n");
    DOMComment* comment = dom_document_createcomment(doc, " This is a comment ");
    assert(comment != NULL);
    printf("  ✓ Created comment node\n");

    data = dom_characterdata_get_data((DOMCharacterData*)comment);
    assert(strcmp(data, " This is a comment ") == 0);
    printf("  ✓ data = ' This is a comment '\n");

    // Modify comment via CharacterData
    result = dom_characterdata_appenddata((DOMCharacterData*)comment, " - Updated");
    assert(result == 0);
    data = dom_characterdata_get_data((DOMCharacterData*)comment);
    assert(strcmp(data, " This is a comment  - Updated") == 0);
    printf("  ✓ appendData works on Comment\n");

    dom_comment_release(comment);
    printf("\n");

    // Test 4: CDATASection
    printf("Test 4: CDATASection\n");
    DOMCDATASection* cdata = dom_document_createcdatasection(doc, "<xml>content</xml>");
    assert(cdata != NULL);
    printf("  ✓ Created CDATA section\n");

    data = dom_characterdata_get_data((DOMCharacterData*)cdata);
    assert(strcmp(data, "<xml>content</xml>") == 0);
    printf("  ✓ data = '<xml>content</xml>'\n");

    // CDATA inherits from Text, so can split
    DOMText* cdata_second = dom_text_splittext((DOMText*)cdata, 5);
    assert(cdata_second != NULL);
    data = dom_characterdata_get_data((DOMCharacterData*)cdata);
    assert(strcmp(data, "<xml>") == 0);
    printf("  ✓ splitText works on CDATASection\n");

    dom_text_release(cdata_second);
    dom_cdatasection_release(cdata);
    printf("\n");

    // Test 5: ProcessingInstruction
    printf("Test 5: ProcessingInstruction\n");
    DOMProcessingInstruction* pi = dom_document_createprocessinginstruction(
        doc,
        "xml-stylesheet",
        "href='style.css' type='text/css'"
    );
    assert(pi != NULL);
    printf("  ✓ Created processing instruction\n");

    const char* target = dom_processinginstruction_get_target(pi);
    assert(strcmp(target, "xml-stylesheet") == 0);
    printf("  ✓ target = 'xml-stylesheet'\n");

    data = dom_characterdata_get_data((DOMCharacterData*)pi);
    assert(strcmp(data, "href='style.css' type='text/css'") == 0);
    printf("  ✓ data = \"href='style.css' type='text/css'\"\n");

    // Modify PI data
    result = dom_characterdata_set_data((DOMCharacterData*)pi, "href='new.css'");
    assert(result == 0);
    data = dom_characterdata_get_data((DOMCharacterData*)pi);
    assert(strcmp(data, "href='new.css'") == 0);
    printf("  ✓ setData works on ProcessingInstruction\n");

    dom_processinginstruction_release(pi);
    printf("\n");

    // Test 6: Memory management
    printf("Test 6: Reference counting\n");
    text = dom_document_createtextnode(doc, "Shared");
    dom_text_addref(text); // Share ownership
    printf("  ✓ Added reference to text node\n");
    
    dom_text_release(text); // Release first reference
    printf("  ✓ Released first reference\n");
    
    // Still valid, has one reference
    data = dom_characterdata_get_data((DOMCharacterData*)text);
    assert(strcmp(data, "Shared") == 0);
    printf("  ✓ Node still valid with remaining reference\n");
    
    dom_text_release(text); // Release final reference
    printf("  ✓ Released final reference\n");
    printf("\n");

    // Cleanup
    dom_document_release(doc);

    printf("============================\n");
    printf("All tests passed! ✓\n");
    printf("\nPhase 3 Complete:\n");
    printf("- CharacterData interface ✓\n");
    printf("- Text interface ✓\n");
    printf("- Comment interface ✓\n");
    printf("- CDATASection interface ✓\n");
    printf("- ProcessingInstruction interface ✓\n");

    return 0;
}
