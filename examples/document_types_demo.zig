//! DocumentType and ProcessingInstruction Demo
//!
//! This example demonstrates the usage of DocumentType and ProcessingInstruction nodes,
//! which are used to represent DOCTYPE declarations and processing instructions in XML/HTML documents.

const std = @import("std");
const dom = @import("dom");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== DocumentType & ProcessingInstruction Demo ===\n\n", .{});

    // ============================================================================
    // PART 1: DocumentType - HTML5
    // ============================================================================
    std.debug.print("1. HTML5 DOCTYPE\n", .{});
    std.debug.print("{s}\n", .{"-" ** 60});

    const html5_doctype = try dom.DocumentType.init(allocator, "html", "", "");
    defer html5_doctype.release();

    std.debug.print("<!DOCTYPE {s}>\n", .{html5_doctype.name()});
    std.debug.print("  Name:      \"{s}\"\n", .{html5_doctype.name()});
    std.debug.print("  Public ID: \"{s}\"\n", .{html5_doctype.publicId()});
    std.debug.print("  System ID: \"{s}\"\n", .{html5_doctype.systemId()});
    std.debug.print("  Node Type: {any}\n\n", .{html5_doctype.node.node_type});

    // ============================================================================
    // PART 2: DocumentType - XHTML
    // ============================================================================
    std.debug.print("2. XHTML DOCTYPE (with Public and System IDs)\n", .{});
    std.debug.print("{s}\n", .{"-" ** 60});

    const xhtml_doctype = try dom.DocumentType.init(
        allocator,
        "html",
        "-//W3C//DTD XHTML 1.0 Strict//EN",
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd",
    );
    defer xhtml_doctype.release();

    std.debug.print("<!DOCTYPE {s}\n", .{xhtml_doctype.name()});
    std.debug.print("  PUBLIC \"{s}\"\n", .{xhtml_doctype.publicId()});
    std.debug.print("  \"{s}\">\n", .{xhtml_doctype.systemId()});
    std.debug.print("\n", .{});

    // ============================================================================
    // PART 3: DocumentType - Custom XML
    // ============================================================================
    std.debug.print("3. Custom XML DOCTYPE\n", .{});
    std.debug.print("{s}\n", .{"-" ** 60});

    const xml_doctype = try dom.DocumentType.init(
        allocator,
        "book",
        "-//ACME//DTD Book 2.0//EN",
        "http://example.com/book.dtd",
    );
    defer xml_doctype.release();

    std.debug.print("<!DOCTYPE {s}\n", .{xml_doctype.name()});
    std.debug.print("  PUBLIC \"{s}\"\n", .{xml_doctype.publicId()});
    std.debug.print("  SYSTEM \"{s}\">\n", .{xml_doctype.systemId()});
    std.debug.print("\n", .{});

    // ============================================================================
    // PART 4: ProcessingInstruction - XML Declaration
    // ============================================================================
    std.debug.print("4. XML Declaration (Processing Instruction)\n", .{});
    std.debug.print("{s}\n", .{"-" ** 60});

    const xml_decl = try dom.ProcessingInstruction.init(
        allocator,
        "xml",
        "version=\"1.0\" encoding=\"UTF-8\"",
    );
    defer xml_decl.release();

    std.debug.print("<?{s} {s}?>\n", .{ xml_decl.target(), xml_decl.data() });
    std.debug.print("  Target:    \"{s}\"\n", .{xml_decl.target()});
    std.debug.print("  Data:      \"{s}\"\n", .{xml_decl.data()});
    std.debug.print("  Node Type: {any}\n\n", .{xml_decl.node.node_type});

    // ============================================================================
    // PART 5: ProcessingInstruction - Stylesheet
    // ============================================================================
    std.debug.print("5. XML Stylesheet Processing Instruction\n", .{});
    std.debug.print("{s}\n", .{"-" ** 60});

    const stylesheet = try dom.ProcessingInstruction.init(
        allocator,
        "xml-stylesheet",
        "type=\"text/css\" href=\"style.css\"",
    );
    defer stylesheet.release();

    std.debug.print("<?{s} {s}?>\n", .{ stylesheet.target(), stylesheet.data() });
    std.debug.print("\n", .{});

    // ============================================================================
    // PART 6: ProcessingInstruction - XSLT
    // ============================================================================
    std.debug.print("6. XSLT Processing Instruction\n", .{});
    std.debug.print("{s}\n", .{"-" ** 60});

    const xslt = try dom.ProcessingInstruction.init(
        allocator,
        "xml-stylesheet",
        "type=\"text/xsl\" href=\"transform.xsl\"",
    );
    defer xslt.release();

    std.debug.print("<?{s} {s}?>\n", .{ xslt.target(), xslt.data() });
    std.debug.print("\n", .{});

    // ============================================================================
    // PART 7: ProcessingInstruction - PHP (historical)
    // ============================================================================
    std.debug.print("7. PHP Processing Instruction (historical)\n", .{});
    std.debug.print("{s}\n", .{"-" ** 60});

    const php = try dom.ProcessingInstruction.init(
        allocator,
        "php",
        "echo 'Hello from PHP';",
    );
    defer php.release();

    std.debug.print("<?{s} {s}?>\n", .{ php.target(), php.data() });
    std.debug.print("\n", .{});

    // ============================================================================
    // PART 8: Modifying ProcessingInstruction Data
    // ============================================================================
    std.debug.print("8. Modifying Processing Instruction Data\n", .{});
    std.debug.print("{s}\n", .{"-" ** 60});

    const mutable_pi = try dom.ProcessingInstruction.init(
        allocator,
        "xml",
        "version=\"1.0\"",
    );
    defer mutable_pi.release();

    std.debug.print("Before: <?{s} {s}?>\n", .{ mutable_pi.target(), mutable_pi.data() });

    try mutable_pi.setData("version=\"1.1\" encoding=\"UTF-8\" standalone=\"yes\"");

    std.debug.print("After:  <?{s} {s}?>\n", .{ mutable_pi.target(), mutable_pi.data() });
    std.debug.print("\n", .{});

    // ============================================================================
    // PART 9: Complete XML Document Structure
    // ============================================================================
    std.debug.print("9. Complete XML Document with DOCTYPE and PIs\n", .{});
    std.debug.print("{s}\n", .{"-" ** 60});

    std.debug.print("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n", .{});
    std.debug.print("<?xml-stylesheet type=\"text/xsl\" href=\"book.xsl\"?>\n", .{});
    std.debug.print("<!DOCTYPE book\n", .{});
    std.debug.print("  PUBLIC \"-//ACME//DTD Book 2.0//EN\"\n", .{});
    std.debug.print("  \"http://example.com/book.dtd\">\n", .{});
    std.debug.print("<book>\n", .{});
    std.debug.print("  <title>DOM Implementation in Zig</title>\n", .{});
    std.debug.print("  <author>WHATWG Community</author>\n", .{});
    std.debug.print("</book>\n\n", .{});

    // ============================================================================
    // PART 10: Node Properties Comparison
    // ============================================================================
    std.debug.print("10. Node Properties Comparison\n", .{});
    std.debug.print("{s}\n", .{"-" ** 60});

    std.debug.print("DocumentType:\n", .{});
    std.debug.print("  - Can have children: No\n", .{});
    std.debug.print("  - Can have parent:   Yes (usually Document)\n", .{});
    std.debug.print("  - Node name:         Same as DOCTYPE name\n", .{});
    std.debug.print("  - Node value:        null\n\n", .{});

    std.debug.print("ProcessingInstruction:\n", .{});
    std.debug.print("  - Can have children: No\n", .{});
    std.debug.print("  - Can have parent:   Yes (any node)\n", .{});
    std.debug.print("  - Node name:         Same as target\n", .{});
    std.debug.print("  - Node value:        Same as data\n\n", .{});

    // ============================================================================
    // PART 11: Reference Counting Demo
    // ============================================================================
    std.debug.print("11. Reference Counting\n", .{});
    std.debug.print("{s}\n", .{"-" ** 60});

    const ref_doctype = try dom.DocumentType.init(allocator, "html", "", "");
    std.debug.print("Initial ref count:  {}\n", .{ref_doctype.node.ref_count});

    ref_doctype.node.retain();
    std.debug.print("After retain():     {}\n", .{ref_doctype.node.ref_count});

    ref_doctype.release();
    std.debug.print("After release():    {}\n", .{ref_doctype.node.ref_count});

    ref_doctype.release();
    std.debug.print("Final release() - node deallocated\n\n", .{});

    // ============================================================================
    std.debug.print("Demo completed successfully!\n\n", .{});
}
