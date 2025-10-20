// META: title=DocumentType name, publicId, systemId

const std = @import("std");
const dom = @import("dom");

test "DocumentType.name property" {
    const allocator = std.testing.allocator;

    const doctype = try dom.DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("html", doctype.name);
}

test "DocumentType.publicId property" {
    const allocator = std.testing.allocator;

    const doctype = try dom.DocumentType.create(allocator, "html", "-//W3C//DTD HTML 4.01//EN", "");
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("-//W3C//DTD HTML 4.01//EN", doctype.publicId);
}

test "DocumentType.systemId property" {
    const allocator = std.testing.allocator;

    const doctype = try dom.DocumentType.create(allocator, "html", "", "http://www.w3.org/TR/html4/strict.dtd");
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("http://www.w3.org/TR/html4/strict.dtd", doctype.systemId);
}

test "DocumentType with all properties" {
    const allocator = std.testing.allocator;

    const doctype = try dom.DocumentType.create(
        allocator,
        "svg",
        "-//W3C//DTD SVG 1.1//EN",
        "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd",
    );
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("svg", doctype.name);
    try std.testing.expectEqualStrings("-//W3C//DTD SVG 1.1//EN", doctype.publicId);
    try std.testing.expectEqualStrings("http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd", doctype.systemId);
}
