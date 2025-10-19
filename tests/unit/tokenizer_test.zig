//! tokenizer Tests
//!
//! Tests for tokenizer functionality.

const std = @import("std");
const dom = @import("dom");

const testing = std.testing;
const Tokenizer = dom.Tokenizer;
const TokenType = dom.TokenType;
const Token = dom.Token;
test "Tokenizer - simple type selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 2), tokens.len); // ident + eof
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqualStrings("div", tokens[0].value);
    try testing.expectEqual(Token.Tag.eof, tokens[1].tag);
}

test "Tokenizer - class selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, ".foo");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 3), tokens.len); // dot + ident + eof
    try testing.expectEqual(Token.Tag.dot, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqualStrings("foo", tokens[1].value);
}

test "Tokenizer - ID selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "#myid");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 2), tokens.len); // hash + eof
    try testing.expectEqual(Token.Tag.hash, tokens[0].tag);
    try testing.expectEqualStrings("myid", tokens[0].value);
}

test "Tokenizer - compound selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div.foo#bar");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div . foo # bar eof
    try testing.expectEqual(@as(usize, 5), tokens.len);
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqualStrings("div", tokens[0].value);
    try testing.expectEqual(Token.Tag.dot, tokens[1].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[2].tag);
    try testing.expectEqualStrings("foo", tokens[2].value);
    try testing.expectEqual(Token.Tag.hash, tokens[3].tag);
    try testing.expectEqualStrings("bar", tokens[3].value);
}

test "Tokenizer - child combinator" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div > p");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div whitespace > whitespace p eof
    try testing.expectEqual(@as(usize, 6), tokens.len);
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqual(Token.Tag.whitespace, tokens[1].tag);
    try testing.expectEqual(Token.Tag.gt, tokens[2].tag);
    try testing.expectEqual(Token.Tag.whitespace, tokens[3].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[4].tag);
}

test "Tokenizer - adjacent sibling combinator" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div+p");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div + p eof
    try testing.expectEqual(@as(usize, 4), tokens.len);
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqual(Token.Tag.plus, tokens[1].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[2].tag);
}

test "Tokenizer - general sibling combinator" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div~p");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div ~ p eof
    try testing.expectEqual(@as(usize, 4), tokens.len);
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqual(Token.Tag.tilde, tokens[1].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[2].tag);
}

test "Tokenizer - attribute selector with presence" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[href]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // [ href ] eof
    try testing.expectEqual(@as(usize, 4), tokens.len);
    try testing.expectEqual(Token.Tag.lbracket, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqualStrings("href", tokens[1].value);
    try testing.expectEqual(Token.Tag.rbracket, tokens[2].tag);
}

test "Tokenizer - attribute selector with exact match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[type=\"text\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // [ type = "text" ] eof
    try testing.expectEqual(@as(usize, 6), tokens.len);
    try testing.expectEqual(Token.Tag.lbracket, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqualStrings("type", tokens[1].value);
    try testing.expectEqual(Token.Tag.equals, tokens[2].tag);
    try testing.expectEqual(Token.Tag.string, tokens[3].tag);
    try testing.expectEqualStrings("text", tokens[3].value);
    try testing.expectEqual(Token.Tag.rbracket, tokens[4].tag);
}

test "Tokenizer - attribute selector with prefix match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[href^=\"http\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // [ href ^= "http" ] eof
    try testing.expectEqual(@as(usize, 6), tokens.len);
    try testing.expectEqual(Token.Tag.lbracket, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqual(Token.Tag.prefix_match, tokens[2].tag);
    try testing.expectEqual(Token.Tag.string, tokens[3].tag);
    try testing.expectEqualStrings("http", tokens[3].value);
}

test "Tokenizer - attribute selector with suffix match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[href$=\".pdf\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(Token.Tag.suffix_match, tokens[2].tag);
    try testing.expectEqualStrings(".pdf", tokens[3].value);
}

test "Tokenizer - attribute selector with substring match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[href*=\"example\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(Token.Tag.substring_match, tokens[2].tag);
    try testing.expectEqualStrings("example", tokens[3].value);
}

test "Tokenizer - attribute selector with includes match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[class~=\"foo\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(Token.Tag.includes_match, tokens[2].tag);
}

test "Tokenizer - attribute selector with dash match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[lang|=\"en\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(Token.Tag.dash_match, tokens[2].tag);
}

test "Tokenizer - pseudo-class" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, ":first-child");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // : first-child eof
    try testing.expectEqual(@as(usize, 3), tokens.len);
    try testing.expectEqual(Token.Tag.colon, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqualStrings("first-child", tokens[1].value);
}

test "Tokenizer - pseudo-class with parentheses" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, ":nth-child(2n+1)");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // : nth-child ( 2n + 1 ) eof
    // Tokens: colon, ident(nth-child), lparen, ident(2n), plus, ident(1), rparen, eof
    try testing.expectEqual(Token.Tag.colon, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqualStrings("nth-child", tokens[1].value);
    try testing.expectEqual(Token.Tag.lparen, tokens[2].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[3].tag);
    try testing.expectEqualStrings("2n", tokens[3].value);
    try testing.expectEqual(Token.Tag.plus, tokens[4].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[5].tag);
    try testing.expectEqualStrings("1", tokens[5].value);
    try testing.expectEqual(Token.Tag.rparen, tokens[6].tag);
}

test "Tokenizer - universal selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "*");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 2), tokens.len);
    try testing.expectEqual(Token.Tag.asterisk, tokens[0].tag);
}

test "Tokenizer - multiple selectors" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div, span");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div , whitespace span eof
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqual(Token.Tag.comma, tokens[1].tag);
    try testing.expectEqual(Token.Tag.whitespace, tokens[2].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[3].tag);
}

test "Tokenizer - complex selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div.foo > p:first-child");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div . foo whitespace > whitespace p : first-child eof
    try testing.expect(tokens.len > 0);
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqualStrings("div", tokens[0].value);
}

test "Tokenizer - string with single quotes" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[title='hello']");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(Token.Tag.string, tokens[3].tag);
    try testing.expectEqualStrings("hello", tokens[3].value);
}

test "Tokenizer - unclosed string error" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[title=\"hello");
    try testing.expectError(error.UnexpectedEOF, tokenizer.tokenize());
}

test "Tokenizer - invalid token error" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div ^");
    try testing.expectError(error.UnexpectedToken, tokenizer.tokenize());
}

test "Tokenizer - empty input" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 1), tokens.len);
    try testing.expectEqual(Token.Tag.eof, tokens[0].tag);
}

test "Tokenizer - whitespace only" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "   ");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 2), tokens.len);
    try testing.expectEqual(Token.Tag.whitespace, tokens[0].tag);
    try testing.expectEqual(Token.Tag.eof, tokens[1].tag);
}

