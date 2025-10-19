//! matcher Tests
//!
//! Tests for matcher functionality.

const std = @import("std");
const dom = @import("dom");

const testing = std.testing;
const Element = dom.Element;
const Tokenizer = dom.Tokenizer;
const Parser = dom.Parser;
const Matcher = dom.Matcher;
test "Matcher - type selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    var tokenizer = Tokenizer.init(allocator, "div");
    var p = try Parser.init(allocator, &tokenizer);
    defer p.deinit();
    var selector_list = try p.parse();
    defer selector_list.deinit();

    const matcher = Matcher.init(allocator);
    const result = try matcher.matches(elem, &selector_list);
    try testing.expect(result);
}

test "Matcher - class selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();
    try elem.setAttribute("class", "container");

    var tokenizer = Tokenizer.init(allocator, ".container");
    var p = try Parser.init(allocator, &tokenizer);
    defer p.deinit();
    var selector_list = try p.parse();
    defer selector_list.deinit();

    const matcher = Matcher.init(allocator);
    const result = try matcher.matches(elem, &selector_list);
    try testing.expect(result);
}

test "Matcher - compound selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();
    try elem.setAttribute("class", "container active");
    try elem.setAttribute("id", "main");

    var tokenizer = Tokenizer.init(allocator, "div.container#main");
    var p = try Parser.init(allocator, &tokenizer);
    defer p.deinit();
    var selector_list = try p.parse();
    defer selector_list.deinit();

    const matcher = Matcher.init(allocator);
    const result = try matcher.matches(elem, &selector_list);
    try testing.expect(result);
}

test "Matcher - child combinator" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.prototype.release();

    const child = try Element.create(allocator, "p");
    _ = try parent.prototype.appendChild(&child.prototype);

    var tokenizer = Tokenizer.init(allocator, "div > p");
    var p = try Parser.init(allocator, &tokenizer);
    defer p.deinit();
    var selector_list = try p.parse();
    defer selector_list.deinit();

    const matcher = Matcher.init(allocator);
    const result = try matcher.matches(child, &selector_list);
    try testing.expect(result);
}

test "Matcher - :first-child" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "ul");
    defer parent.prototype.release();

    const li1 = try Element.create(allocator, "li");
    const li2 = try Element.create(allocator, "li");
    _ = try parent.prototype.appendChild(&li1.prototype);
    _ = try parent.prototype.appendChild(&li2.prototype);

    var tokenizer = Tokenizer.init(allocator, "li:first-child");
    var p = try Parser.init(allocator, &tokenizer);
    defer p.deinit();
    var selector_list = try p.parse();
    defer selector_list.deinit();

    const matcher = Matcher.init(allocator);
    const matches_li1 = try matcher.matches(li1, &selector_list);
    const matches_li2 = try matcher.matches(li2, &selector_list);
    try testing.expect(matches_li1);
    try testing.expect(!matches_li2);
}
