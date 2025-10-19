//! parser Tests
//!
//! Tests for parser functionality.

const std = @import("std");
const dom = @import("dom");

const testing = std.testing;
const Parser = dom.Parser;
const Tokenizer = dom.Tokenizer;
const Combinator = dom.Combinator;
test "Parser - simple type selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    try testing.expectEqual(@as(usize, 1), selector_list.selectors.len);

    const complex = selector_list.selectors[0];
    try testing.expectEqual(@as(usize, 1), complex.compound.simple_selectors.len);

    const simple = complex.compound.simple_selectors[0];
    try testing.expect(simple == .Type);
    try testing.expectEqualStrings("div", simple.Type.tag_name);
}

test "Parser - class selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, ".container");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    const simple = selector_list.selectors[0].compound.simple_selectors[0];
    try testing.expect(simple == .Class);
    try testing.expectEqualStrings("container", simple.Class.class_name);
}

test "Parser - ID selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "#main");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    const simple = selector_list.selectors[0].compound.simple_selectors[0];
    try testing.expect(simple == .Id);
    try testing.expectEqualStrings("main", simple.Id.id);
}

test "Parser - compound selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div.container#main");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    const compound = selector_list.selectors[0].compound;
    try testing.expectEqual(@as(usize, 3), compound.simple_selectors.len);

    try testing.expect(compound.simple_selectors[0] == .Type);
    try testing.expectEqualStrings("div", compound.simple_selectors[0].Type.tag_name);

    try testing.expect(compound.simple_selectors[1] == .Class);
    try testing.expectEqualStrings("container", compound.simple_selectors[1].Class.class_name);

    try testing.expect(compound.simple_selectors[2] == .Id);
    try testing.expectEqualStrings("main", compound.simple_selectors[2].Id.id);
}

test "Parser - child combinator" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div > p");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    const complex = selector_list.selectors[0];
    try testing.expectEqual(@as(usize, 1), complex.combinators.len);
    try testing.expectEqual(Combinator.Child, complex.combinators[0].combinator);
}

test "Parser - descendant combinator" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div p");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    const complex = selector_list.selectors[0];
    try testing.expectEqual(@as(usize, 1), complex.combinators.len);
    try testing.expectEqual(Combinator.Descendant, complex.combinators[0].combinator);
}

test "Parser - attribute presence" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[href]");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    const simple = selector_list.selectors[0].compound.simple_selectors[0];
    try testing.expect(simple == .Attribute);
    try testing.expectEqualStrings("href", simple.Attribute.name);
    try testing.expect(simple.Attribute.matcher == .Presence);
}

test "Parser - attribute exact match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[type=\"text\"]");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    const simple = selector_list.selectors[0].compound.simple_selectors[0];
    try testing.expect(simple == .Attribute);
    try testing.expectEqualStrings("type", simple.Attribute.name);
    try testing.expect(simple.Attribute.matcher == .Exact);
    try testing.expectEqualStrings("text", simple.Attribute.matcher.Exact.value);
}

test "Parser - pseudo-class" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, ":first-child");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    const simple = selector_list.selectors[0].compound.simple_selectors[0];
    try testing.expect(simple == .PseudoClass);
    try testing.expect(simple.PseudoClass.kind == .FirstChild);
}

test "Parser - nth-child with odd" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, ":nth-child(odd)");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    const simple = selector_list.selectors[0].compound.simple_selectors[0];
    try testing.expect(simple == .PseudoClass);
    try testing.expect(simple.PseudoClass.kind == .NthChild);
    try testing.expectEqual(@as(i32, 2), simple.PseudoClass.kind.NthChild.a);
    try testing.expectEqual(@as(i32, 1), simple.PseudoClass.kind.NthChild.b);
}

test "Parser - multiple selectors" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div, span, p");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    try testing.expectEqual(@as(usize, 3), selector_list.selectors.len);
}

test "Parser - complex selector chain" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "article > header h1.title");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();

    var selector_list = try parser.parse();
    defer selector_list.deinit();

    const complex = selector_list.selectors[0];
    try testing.expectEqual(@as(usize, 2), complex.combinators.len);
    try testing.expectEqual(Combinator.Child, complex.combinators[0].combinator);
    try testing.expectEqual(Combinator.Descendant, complex.combinators[1].combinator);
}

