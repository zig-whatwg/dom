// Test C API string handling directly
#include <iostream>
#include <iomanip>
#include <cstring>
#include "dom.h"

void print_hex(const char* label, const char* str) {
    if (!str) {
        std::cout << label << ": (null)" << std::endl;
        return;
    }
    
    size_t len = strlen(str);
    std::cout << label << ": [" << str << "]" << std::endl;
    std::cout << "  Length: " << len << " bytes" << std::endl;
    std::cout << "  Hex: ";
    for (size_t i = 0; i < len && i < 20; i++) {
        std::cout << std::hex << std::setfill('0') << std::setw(2) 
                  << (int)(unsigned char)str[i] << " ";
    }
    std::cout << std::dec << std::endl;
}

int main() {
    std::cout << "Creating document..." << std::endl;
    DOMDocument* doc = dom_document_new();
    
    std::cout << "\nCreating element..." << std::endl;
    DOMElement* elem = dom_document_createelement(doc, "test");
    
    std::cout << "\nSetting attribute..." << std::endl;
    int result = dom_element_setattribute(elem, "id", "test123");
    std::cout << "  Result: " << result << std::endl;
    
    std::cout << "\nGetting attribute..." << std::endl;
    const char* value = dom_element_getattribute(elem, "id");
    print_hex("  Value", value);
    
    std::cout << "\nGetting non-existent attribute..." << std::endl;
    const char* missing = dom_element_getattribute(elem, "missing");
    print_hex("  Missing", missing);
    
    dom_element_release(elem);
    dom_document_release(doc);
    
    return 0;
}
