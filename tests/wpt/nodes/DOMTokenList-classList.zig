// META: title=Element.classList (DOMTokenList)
// META: link=https://dom.spec.whatwg.org/#dom-element-classlist
// META: link=https://dom.spec.whatwg.org/#domtokenlist

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const DOMTokenList = dom.DOMTokenList;

// ============================================================================
// Basic Properties
// ============================================================================

test "classList returns DOMTokenList" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectEqual(@as(usize, 0), classList.length());
}

test "classList is a live view of class attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();

    // Add via classList
    try classList.add(&[_][]const u8{"foo"});

    // Should be reflected in attribute
    const class_attr = elem.getAttribute("class");
    try std.testing.expect(class_attr != null);
    try std.testing.expectEqualStrings("foo", class_attr.?);

    // Modify attribute
    try elem.setAttribute("class", "bar baz");

    // Should be reflected in classList
    try std.testing.expect(classList.contains("bar"));
    try std.testing.expect(classList.contains("baz"));
    try std.testing.expect(!classList.contains("foo"));
    try std.testing.expectEqual(@as(usize, 2), classList.length());
}

// ============================================================================
// add() Method
// ============================================================================

test "add() adds single token" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{"foo"});

    try std.testing.expectEqual(@as(usize, 1), classList.length());
    try std.testing.expect(classList.contains("foo"));
}

test "add() adds multiple tokens" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{ "foo", "bar", "baz" });

    try std.testing.expectEqual(@as(usize, 3), classList.length());
    try std.testing.expect(classList.contains("foo"));
    try std.testing.expect(classList.contains("bar"));
    try std.testing.expect(classList.contains("baz"));
}

test "add() does not add duplicates" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{"foo"});
    try classList.add(&[_][]const u8{"foo"});

    try std.testing.expectEqual(@as(usize, 1), classList.length());
}

test "add() throws SyntaxError on empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectError(error.SyntaxError, classList.add(&[_][]const u8{""}));
}

test "add() throws InvalidCharacterError on whitespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectError(error.InvalidCharacterError, classList.add(&[_][]const u8{"foo bar"}));
    try std.testing.expectError(error.InvalidCharacterError, classList.add(&[_][]const u8{"foo\tbar"}));
    try std.testing.expectError(error.InvalidCharacterError, classList.add(&[_][]const u8{"foo\nbar"}));
    try std.testing.expectError(error.InvalidCharacterError, classList.add(&[_][]const u8{" foo"}));
}

// ============================================================================
// remove() Method
// ============================================================================

test "remove() removes single token" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{ "foo", "bar", "baz" });
    try classList.remove(&[_][]const u8{"bar"});

    try std.testing.expectEqual(@as(usize, 2), classList.length());
    try std.testing.expect(classList.contains("foo"));
    try std.testing.expect(!classList.contains("bar"));
    try std.testing.expect(classList.contains("baz"));
}

test "remove() removes multiple tokens" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{ "foo", "bar", "baz" });
    try classList.remove(&[_][]const u8{ "foo", "baz" });

    try std.testing.expectEqual(@as(usize, 1), classList.length());
    try std.testing.expect(!classList.contains("foo"));
    try std.testing.expect(classList.contains("bar"));
    try std.testing.expect(!classList.contains("baz"));
}

test "remove() is idempotent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{"foo"});
    try classList.remove(&[_][]const u8{"foo"});
    try classList.remove(&[_][]const u8{"foo"}); // Should not error

    try std.testing.expectEqual(@as(usize, 0), classList.length());
}

test "remove() throws SyntaxError on empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectError(error.SyntaxError, classList.remove(&[_][]const u8{""}));
}

test "remove() throws InvalidCharacterError on whitespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectError(error.InvalidCharacterError, classList.remove(&[_][]const u8{"foo bar"}));
}

// ============================================================================
// contains() Method
// ============================================================================

test "contains() returns true for present token" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{"foo"});

    try std.testing.expect(classList.contains("foo"));
}

test "contains() returns false for absent token" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();

    try std.testing.expect(!classList.contains("foo"));
}

test "contains() is case-sensitive" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{"Foo"});

    try std.testing.expect(classList.contains("Foo"));
    try std.testing.expect(!classList.contains("foo"));
    try std.testing.expect(!classList.contains("FOO"));
}

// ============================================================================
// toggle() Method
// ============================================================================

test "toggle() adds token when absent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    const result = try classList.toggle("foo", null);

    try std.testing.expect(result); // Returns true when added
    try std.testing.expect(classList.contains("foo"));
}

test "toggle() removes token when present" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{"foo"});
    const result = try classList.toggle("foo", null);

    try std.testing.expect(!result); // Returns false when removed
    try std.testing.expect(!classList.contains("foo"));
}

test "toggle() with force=true adds token" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    const result = try classList.toggle("foo", true);

    try std.testing.expect(result);
    try std.testing.expect(classList.contains("foo"));

    // Toggle again with force=true (should remain)
    const result2 = try classList.toggle("foo", true);
    try std.testing.expect(result2);
    try std.testing.expect(classList.contains("foo"));
}

test "toggle() with force=false removes token" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{"foo"});
    const result = try classList.toggle("foo", false);

    try std.testing.expect(!result);
    try std.testing.expect(!classList.contains("foo"));

    // Toggle again with force=false (should remain absent)
    const result2 = try classList.toggle("foo", false);
    try std.testing.expect(!result2);
    try std.testing.expect(!classList.contains("foo"));
}

test "toggle() throws SyntaxError on empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectError(error.SyntaxError, classList.toggle("", null));
}

test "toggle() throws InvalidCharacterError on whitespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectError(error.InvalidCharacterError, classList.toggle("foo bar", null));
}

// ============================================================================
// replace() Method
// ============================================================================

test "replace() replaces existing token" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{ "foo", "bar" });
    const result = try classList.replace("foo", "baz");

    try std.testing.expect(result); // Returns true when replaced
    try std.testing.expect(!classList.contains("foo"));
    try std.testing.expect(classList.contains("baz"));
    try std.testing.expect(classList.contains("bar"));
}

test "replace() returns false when token absent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    const result = try classList.replace("foo", "bar");

    try std.testing.expect(!result); // Returns false when not found
    try std.testing.expect(!classList.contains("foo"));
    try std.testing.expect(!classList.contains("bar"));
}

test "replace() preserves order" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{ "first", "second", "third" });
    _ = try classList.replace("second", "middle");

    // Check order is preserved
    const item0 = classList.item(0);
    const item1 = classList.item(1);
    const item2 = classList.item(2);

    try std.testing.expect(item0 != null);
    try std.testing.expect(item1 != null);
    try std.testing.expect(item2 != null);
    try std.testing.expectEqualStrings("first", item0.?);
    try std.testing.expectEqualStrings("middle", item1.?);
    try std.testing.expectEqualStrings("third", item2.?);
}

test "replace() throws SyntaxError on empty strings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectError(error.SyntaxError, classList.replace("", "bar"));
    try std.testing.expectError(error.SyntaxError, classList.replace("foo", ""));
}

test "replace() throws InvalidCharacterError on whitespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectError(error.InvalidCharacterError, classList.replace("foo bar", "baz"));
    try std.testing.expectError(error.InvalidCharacterError, classList.replace("foo", "bar baz"));
}

// ============================================================================
// item() Method
// ============================================================================

test "item() returns token at index" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{ "foo", "bar", "baz" });

    const item0 = classList.item(0);
    const item1 = classList.item(1);
    const item2 = classList.item(2);

    try std.testing.expect(item0 != null);
    try std.testing.expect(item1 != null);
    try std.testing.expect(item2 != null);
    try std.testing.expectEqualStrings("foo", item0.?);
    try std.testing.expectEqualStrings("bar", item1.?);
    try std.testing.expectEqualStrings("baz", item2.?);
}

test "item() returns null for out of bounds index" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{"foo"});

    try std.testing.expect(classList.item(0) != null);
    try std.testing.expect(classList.item(1) == null);
    try std.testing.expect(classList.item(999) == null);
}

// ============================================================================
// length Property
// ============================================================================

test "length is 0 for empty list" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectEqual(@as(usize, 0), classList.length());
}

test "length reflects token count" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectEqual(@as(usize, 0), classList.length());

    try classList.add(&[_][]const u8{"foo"});
    try std.testing.expectEqual(@as(usize, 1), classList.length());

    try classList.add(&[_][]const u8{ "bar", "baz" });
    try std.testing.expectEqual(@as(usize, 3), classList.length());

    try classList.remove(&[_][]const u8{"bar"});
    try std.testing.expectEqual(@as(usize, 2), classList.length());
}

// ============================================================================
// Iterator
// ============================================================================

test "iterator returns all tokens in order" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{ "first", "second", "third" });

    var iter = classList;
    const token1 = iter.next();
    const token2 = iter.next();
    const token3 = iter.next();
    const token4 = iter.next();

    try std.testing.expect(token1 != null);
    try std.testing.expect(token2 != null);
    try std.testing.expect(token3 != null);
    try std.testing.expect(token4 == null);

    try std.testing.expectEqualStrings("first", token1.?);
    try std.testing.expectEqualStrings("second", token2.?);
    try std.testing.expectEqualStrings("third", token3.?);
}

test "iterator with while loop" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{ "alpha", "beta", "gamma", "delta" });

    var iter = classList;
    var count: usize = 0;
    const expected = [_][]const u8{ "alpha", "beta", "gamma", "delta" };

    while (iter.next()) |token| {
        try std.testing.expect(count < expected.len);
        try std.testing.expectEqualStrings(expected[count], token);
        count += 1;
    }

    try std.testing.expectEqual(@as(usize, 4), count);
}

test "iterator on empty classList" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    var iter = elem.classList();
    const token = iter.next();

    try std.testing.expect(token == null);
}

// ============================================================================
// Edge Cases and Complex Scenarios
// ============================================================================

test "multiple spaces are normalized" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Set class with multiple spaces
    try elem.setAttribute("class", "foo  bar   baz");

    const classList = elem.classList();
    try std.testing.expectEqual(@as(usize, 3), classList.length());
    try std.testing.expect(classList.contains("foo"));
    try std.testing.expect(classList.contains("bar"));
    try std.testing.expect(classList.contains("baz"));
}

test "leading and trailing whitespace is ignored" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("class", "  foo bar  ");

    const classList = elem.classList();
    try std.testing.expectEqual(@as(usize, 2), classList.length());
    try std.testing.expect(classList.contains("foo"));
    try std.testing.expect(classList.contains("bar"));
}

test "tabs and newlines are treated as whitespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("class", "foo\tbar\nbaz");

    const classList = elem.classList();
    try std.testing.expectEqual(@as(usize, 3), classList.length());
    try std.testing.expect(classList.contains("foo"));
    try std.testing.expect(classList.contains("bar"));
    try std.testing.expect(classList.contains("baz"));
}

test "removing non-existent class attribute works" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();

    // Should not error when class attribute doesn't exist
    try classList.remove(&[_][]const u8{"foo"});
    try std.testing.expectEqual(@as(usize, 0), classList.length());
}

test "classList operations preserve document ownership" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.add(&[_][]const u8{ "foo", "bar" });

    // Verify element still has correct owner document
    try std.testing.expect(elem.prototype.owner_document == &doc.prototype);
}
