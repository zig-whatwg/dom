//! JavaScript Bindings Root Module
//!
//! This module provides the entry point for compiling JavaScript bindings
//! as a C library that can be linked with JavaScript engines.
//!
//! ## Usage
//!
//! Build as static library:
//! ```bash
//! zig build lib-js-bindings
//! ```
//!
//! This creates `zig-out/lib/libdom.a` which can be linked with C programs.
//!
//! ## Exported Functions
//!
//! All exported functions use the C-ABI and are prefixed with `dom_`:
//! - `dom_document_*` - Document interface (factory methods, properties)
//! - `dom_element_*` - Element interface (attributes, queries)
//! - `dom_node_*` - Node interface (tree manipulation, navigation)
//! - `dom_error_code_*` - Error handling utilities
//!
//! ## Example C Usage
//!
//! ```c
//! #include <stdio.h>
//!
//! // Forward declarations
//! typedef struct DOMDocument DOMDocument;
//! typedef struct DOMElement DOMElement;
//!
//! extern DOMDocument* dom_document_new(void);
//! extern DOMElement* dom_document_createelement(DOMDocument* doc, const char* name);
//! extern void dom_element_release(DOMElement* elem);
//! extern void dom_document_release(DOMDocument* doc);
//!
//! int main(void) {
//!     DOMDocument* doc = dom_document_new();
//!     DOMElement* div = dom_document_createelement(doc, "div");
//!
//!     printf("Created element!\n");
//!
//!     dom_element_release(div);
//!     dom_document_release(doc);
//!     return 0;
//! }
//! ```
//!
//! Compile:
//! ```bash
//! gcc -o test test.c zig-out/lib/libdom.a -lpthread
//! ```

// Import all binding modules to force compilation of export functions
const dom_types = @import("dom_types.zig");
const document = @import("document.zig");
const node = @import("node.zig");
const element = @import("element.zig");
const eventtarget = @import("eventtarget.zig");
const nodelist = @import("nodelist.zig");
const htmlcollection = @import("htmlcollection.zig");
const domtokenlist = @import("domtokenlist.zig");
const namednodemap = @import("namednodemap.zig");
const attr = @import("attr.zig");
const documenttype = @import("documenttype.zig");
const documentfragment = @import("documentfragment.zig");
const domimplementation = @import("domimplementation.zig");
const characterdata = @import("characterdata.zig");
const text = @import("text.zig");
const comment = @import("comment.zig");
const cdatasection = @import("cdatasection.zig");
const processinginstruction = @import("processinginstruction.zig");
const event = @import("event.zig");
const customevent = @import("customevent.zig");
const range = @import("range.zig");

// Force export of all C-ABI functions by referencing them
// This ensures they are included in the static library

// Prevent compiler from optimizing these away
comptime {
    // Just referencing the modules ensures their export functions are compiled
    _ = dom_types;
    _ = document;
    _ = node;
    _ = element;
    _ = eventtarget;
    _ = nodelist;
    _ = htmlcollection;
    _ = domtokenlist;
    _ = namednodemap;
    _ = attr;
    _ = documenttype;
    _ = documentfragment;
    _ = domimplementation;
    _ = characterdata;
    _ = text;
    _ = comment;
    _ = cdatasection;
    _ = processinginstruction;
    _ = event;
    _ = customevent;
    _ = range;
}
