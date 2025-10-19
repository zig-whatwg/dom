const std = @import("std");
const dom = @import("dom");
const NamedNodeMap = dom.NamedNodeMap;
const Element = dom.Element;
const Attr = dom.Attr;
const DOMError = dom.validation.DOMError;

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectEqualStrings = testing.expectEqualStrings;

test "NamedNodeMap: length" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    try elem.setAttribute("id", "main");
    try elem.setAttribute("class", "container");

    var attrs = NamedNodeMap{ .element = elem };
    try expectEqual(@as(u32, 2), attrs.length());
}

test "NamedNodeMap: getNamedItem" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "input");
    defer elem.prototype.release();

    try elem.setAttribute("type", "text");
    try elem.setAttribute("name", "username");

    var attrs = NamedNodeMap{ .element = elem };

    const type_attr = try attrs.getNamedItem("type");
    try expect(type_attr != null);
    defer type_attr.?.node.release();
    try expectEqualStrings("type", type_attr.?.name());
    try expectEqualStrings("text", type_attr.?.value());
    try expect(type_attr.?.owner_element == elem);

    const missing = try attrs.getNamedItem("missing");
    try expect(missing == null);
}

test "NamedNodeMap: item" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    try elem.setAttribute("a", "1");
    try elem.setAttribute("b", "2");

    var attrs = NamedNodeMap{ .element = elem };

    const attr0 = try attrs.item(0);
    try expect(attr0 != null);
    defer if (attr0) |a| a.node.release();

    const attr1 = try attrs.item(1);
    try expect(attr1 != null);
    defer if (attr1) |a| a.node.release();

    const attr2 = try attrs.item(2);
    try expect(attr2 == null); // Out of bounds
}

test "NamedNodeMap: setNamedItem" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    const attr = try Attr.create(allocator, "title");
    defer attr.node.release();
    try attr.setValue("Hello World");

    var attrs = NamedNodeMap{ .element = elem };
    const old = try attrs.setNamedItem(attr);
    try expect(old == null);

    try expectEqualStrings("Hello World", elem.getAttribute("title").?);
    try expect(attr.owner_element == elem);
}

test "NamedNodeMap: setNamedItem replaces existing" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    try elem.setAttribute("id", "old");

    var attrs = NamedNodeMap{ .element = elem };

    const new_attr = try Attr.create(allocator, "id");
    defer new_attr.node.release();
    try new_attr.setValue("new");

    const old_attr = try attrs.setNamedItem(new_attr);
    try expect(old_attr != null);
    defer old_attr.?.node.release();
    try expectEqualStrings("old", old_attr.?.value());
    try expect(old_attr.?.owner_element == null); // Detached

    try expectEqualStrings("new", elem.getAttribute("id").?);
}

test "NamedNodeMap: removeNamedItem" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    try elem.setAttribute("class", "highlight");

    var attrs = NamedNodeMap{ .element = elem };

    const removed = try attrs.removeNamedItem("class");
    defer removed.node.release();

    try expectEqualStrings("highlight", removed.value());
    try expect(removed.owner_element == null); // Detached
    try expect(elem.getAttribute("class") == null);
}

test "NamedNodeMap: removeNamedItem not found" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    var attrs = NamedNodeMap{ .element = elem };

    const result = attrs.removeNamedItem("missing");
    try expect(result == DOMError.NotFoundError);
}

test "NamedNodeMap: memory leak check" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    try elem.setAttribute("a", "1");
    try elem.setAttribute("b", "2");
    try elem.setAttribute("c", "3");

    var attrs = NamedNodeMap{ .element = elem };

    const attr0 = try attrs.item(0);
    defer if (attr0) |a| a.node.release();

    const attr1 = try attrs.item(1);
    defer if (attr1) |a| a.node.release();

    const attr_c = try attrs.getNamedItem("c");
    defer if (attr_c) |a| a.node.release();

    // Verify no leaks via testing allocator
}

test "NamedNodeMap: getNamedItemNS with namespaces" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    // Add non-namespaced attributes
    try elem.setAttribute("data-lang", "en");
    try elem.setAttribute("id", "main");

    var attrs = NamedNodeMap{ .element = elem };

    // Get non-namespaced attribute by name
    const id_attr = try attrs.getNamedItemNS(null, "id");
    defer if (id_attr) |a| a.node.release();
    try expect(id_attr != null);
    try expectEqualStrings("main", id_attr.?.value());

    // Another non-namespaced attribute
    const lang_attr = try attrs.getNamedItemNS(null, "data-lang");
    defer if (lang_attr) |a| a.node.release();
    try expect(lang_attr != null);
    try expectEqualStrings("en", lang_attr.?.value());

    // Non-existent attribute returns null
    const missing = try attrs.getNamedItemNS(null, "missing");
    defer if (missing) |a| a.node.release();
    try expect(missing == null);
}

test "NamedNodeMap: setNamedItemNS and removeNamedItemNS" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    // Create a non-namespaced attribute (namespace support is limited in current implementation)
    const attr = try Attr.create(allocator, "data-test");
    defer attr.node.release();
    try attr.setValue("value1");

    var attrs = NamedNodeMap{ .element = elem };

    // Set attribute via setNamedItemNS (works with null namespace)
    const old = try attrs.setNamedItemNS(attr);
    defer if (old) |o| o.node.release();
    try expect(old == null);
    try expectEqualStrings("value1", elem.getAttribute("data-test").?);

    // Remove by null namespace and local name
    const removed = try attrs.removeNamedItemNS(null, "data-test");
    defer removed.node.release();
    try expectEqualStrings("value1", removed.value());
    try expect(elem.getAttribute("data-test") == null);
}
