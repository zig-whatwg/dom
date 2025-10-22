//! Source Code Parser
//!
//! Parses Zig source files to extract public method signatures for delegation generation.
//! This allows generating delegations from actual Zig parent implementations rather than WebIDL,
//! which ensures we respect custom overrides and see the complete API.
//!
//! ## Key Features
//!
//! - Extracts public method signatures from Zig source files
//! - Handles both `pub fn` and `pub inline fn` declarations
//! - Parses parameter lists with types
//! - Extracts return types (including error unions)
//! - Skips private methods and non-function declarations
//!
//! ## Usage Example
//!
//! ```zig
//! const parser = SourceParser.init(allocator);
//! defer parser.deinit();
//!
//! const methods = try parser.parseFile("src/node.zig", "Node");
//! defer methods.deinit();
//!
//! for (methods.items) |method| {
//!     std.debug.print("Method: {s}\n", .{method.name});
//!     std.debug.print("  Returns: {s}\n", .{method.return_type});
//!     for (method.parameters.items) |param| {
//!         std.debug.print("  Param: {s}: {s}\n", .{param.name, param.type});
//!     }
//! }
//! ```

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Parameter information
pub const Parameter = struct {
    name: []const u8,
    type: []const u8,
    is_anytype: bool = false,

    pub fn deinit(self: *Parameter, allocator: Allocator) void {
        allocator.free(self.name);
        allocator.free(self.type);
    }
};

/// Method signature extracted from source
pub const MethodSignature = struct {
    name: []const u8,
    parameters: std.ArrayList(Parameter),
    return_type: []const u8,
    is_inline: bool = false,
    is_error_union: bool = false,

    pub fn init(allocator: Allocator, name: []const u8) MethodSignature {
        _ = allocator;
        return .{
            .name = name,
            .parameters = std.ArrayList(Parameter){},
            .return_type = "",
            .is_inline = false,
            .is_error_union = false,
        };
    }

    pub fn deinit(self: *MethodSignature, allocator: Allocator) void {
        allocator.free(self.name);
        for (self.parameters.items) |*param| {
            param.deinit(allocator);
        }
        self.parameters.deinit(allocator);
        allocator.free(self.return_type);
    }
};

/// Source code parser
pub const SourceParser = struct {
    allocator: Allocator,

    pub fn init(allocator: Allocator) SourceParser {
        return .{ .allocator = allocator };
    }

    /// Parse a Zig source file and extract public method signatures
    pub fn parseFile(self: *SourceParser, file_path: []const u8, struct_name: []const u8) !std.ArrayList(MethodSignature) {
        // Read the file
        const file = try std.fs.cwd().openFile(file_path, .{});
        defer file.close();

        const source = try file.readToEndAlloc(self.allocator, 10 * 1024 * 1024); // 10MB max
        defer self.allocator.free(source);

        return try self.parseSource(source, struct_name);
    }

    /// Parse source code and extract public method signatures for a specific struct
    pub fn parseSource(self: *SourceParser, source: []const u8, struct_name: []const u8) !std.ArrayList(MethodSignature) {
        var methods = std.ArrayList(MethodSignature){};
        errdefer {
            for (methods.items) |*method| {
                method.deinit(self.allocator);
            }
            methods.deinit(self.allocator);
        }

        // Find the struct declaration
        const struct_decl = try std.fmt.allocPrint(self.allocator, "pub const {s} = struct {{", .{struct_name});
        defer self.allocator.free(struct_decl);

        const struct_start = std.mem.indexOf(u8, source, struct_decl) orelse {
            return error.StructNotFound;
        };

        // Find the end of the struct (matching closing brace)
        const struct_end = self.findMatchingBrace(source, struct_start + struct_decl.len) orelse {
            return error.StructEndNotFound;
        };

        const struct_body = source[struct_start..struct_end];

        // Parse all public methods in the struct body
        var pos: usize = 0;
        while (pos < struct_body.len) {
            // Look for "pub fn" or "pub inline fn"
            const pub_pos = std.mem.indexOfPos(u8, struct_body, pos, "pub ") orelse break;
            pos = pub_pos + 4;

            // Check if it's a function
            const after_pub = struct_body[pos..];
            const is_inline = std.mem.startsWith(u8, after_pub, "inline fn ");
            const is_fn = std.mem.startsWith(u8, after_pub, "fn ");

            if (!is_inline and !is_fn) continue;

            const fn_pos = if (is_inline) pos + 10 else pos + 3; // Skip "inline fn " or "fn "

            // Extract method name
            const name_start = fn_pos;
            const name_end = std.mem.indexOfPos(u8, struct_body, name_start, "(") orelse continue;
            const method_name = std.mem.trim(u8, struct_body[name_start..name_end], &std.ascii.whitespace);

            // Skip if empty name or contains invalid characters
            if (method_name.len == 0) continue;

            // Parse the method signature
            if (self.parseMethodSignature(struct_body, name_start, method_name, is_inline)) |method| {
                try methods.append(self.allocator, method);
                pos = name_end;
            } else |_| {
                pos = name_end;
                continue;
            }
        }

        return methods;
    }

    /// Parse a single method signature
    fn parseMethodSignature(
        self: *SourceParser,
        source: []const u8,
        name_start: usize,
        method_name: []const u8,
        is_inline: bool,
    ) !MethodSignature {
        var method = MethodSignature.init(self.allocator, try self.allocator.dupe(u8, method_name));
        errdefer method.deinit(self.allocator);

        method.is_inline = is_inline;

        // Find parameter list start
        const paren_start = std.mem.indexOfPos(u8, source, name_start, "(") orelse return error.NoParenthesis;
        const paren_end = self.findMatchingParen(source, paren_start) orelse return error.UnmatchedParenthesis;

        // Parse parameters
        const params_str = source[paren_start + 1 .. paren_end];
        try self.parseParameters(params_str, &method.parameters);

        // Parse return type
        var pos = paren_end + 1;
        while (pos < source.len and std.ascii.isWhitespace(source[pos])) : (pos += 1) {}

        // Check for return type
        if (pos < source.len and source[pos] != '{') {
            // There's a return type
            const body_start = std.mem.indexOfPos(u8, source, pos, "{") orelse return error.NoMethodBody;
            const return_type_str = std.mem.trim(u8, source[pos..body_start], &std.ascii.whitespace);

            // Check if it's an error union
            method.is_error_union = std.mem.indexOf(u8, return_type_str, "!") != null;
            method.return_type = try self.allocator.dupe(u8, return_type_str);
        } else {
            // No return type (void)
            method.return_type = try self.allocator.dupe(u8, "void");
        }

        return method;
    }

    /// Parse parameter list
    fn parseParameters(self: *SourceParser, params_str: []const u8, params: *std.ArrayList(Parameter)) !void {
        if (params_str.len == 0) return;

        var pos: usize = 0;
        var paren_depth: i32 = 0;
        var bracket_depth: i32 = 0;
        var param_start: usize = 0;

        while (pos <= params_str.len) : (pos += 1) {
            const is_end = pos == params_str.len;
            const ch = if (!is_end) params_str[pos] else 0;

            // Track nesting depth
            if (ch == '(') paren_depth += 1;
            if (ch == ')') paren_depth -= 1;
            if (ch == '[') bracket_depth += 1;
            if (ch == ']') bracket_depth -= 1;

            // Split on comma at depth 0, or at end
            if ((ch == ',' and paren_depth == 0 and bracket_depth == 0) or is_end) {
                const param_str = std.mem.trim(u8, params_str[param_start..pos], &std.ascii.whitespace);
                if (param_str.len > 0) {
                    if (try self.parseParameter(param_str)) |param| {
                        try params.append(self.allocator, param);
                    }
                }
                param_start = pos + 1;
            }
        }
    }

    /// Parse a single parameter "name: type"
    fn parseParameter(self: *SourceParser, param_str: []const u8) !?Parameter {
        // Split on colon
        const colon_pos = std.mem.indexOf(u8, param_str, ":") orelse return null;

        const name = std.mem.trim(u8, param_str[0..colon_pos], &std.ascii.whitespace);
        const type_str = std.mem.trim(u8, param_str[colon_pos + 1 ..], &std.ascii.whitespace);

        if (name.len == 0) return null;

        const is_anytype = std.mem.eql(u8, type_str, "anytype");

        return Parameter{
            .name = try self.allocator.dupe(u8, name),
            .type = try self.allocator.dupe(u8, type_str),
            .is_anytype = is_anytype,
        };
    }

    /// Find matching closing brace
    fn findMatchingBrace(_: *SourceParser, source: []const u8, start: usize) ?usize {
        var depth: i32 = 1; // Start at 1 because we're inside the opening brace
        var i = start;

        while (i < source.len) : (i += 1) {
            if (source[i] == '{') {
                depth += 1;
            } else if (source[i] == '}') {
                depth -= 1;
                if (depth == 0) {
                    return i;
                }
            }
        }

        return null;
    }

    /// Find matching closing parenthesis
    fn findMatchingParen(_: *SourceParser, source: []const u8, start: usize) ?usize {
        var depth: i32 = 1; // Start at 1 because we're at the opening paren
        var i = start + 1;

        while (i < source.len) : (i += 1) {
            if (source[i] == '(') {
                depth += 1;
            } else if (source[i] == ')') {
                depth -= 1;
                if (depth == 0) {
                    return i;
                }
            }
        }

        return null;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "SourceParser - parse simple method" {
    const allocator = std.testing.allocator;

    const source =
        \\pub const Node = struct {
        \\    pub fn foo(self: *Node, value: u32) !void {
        \\        _ = self;
        \\        _ = value;
        \\    }
        \\};
    ;

    var parser = SourceParser.init(allocator);
    var methods = try parser.parseSource(source, "Node");
    defer {
        for (methods.items) |*method| {
            method.deinit(allocator);
        }
        methods.deinit(allocator);
    }

    try std.testing.expectEqual(@as(usize, 1), methods.items.len);

    const method = methods.items[0];
    try std.testing.expectEqualStrings("foo", method.name);
    try std.testing.expectEqualStrings("!void", method.return_type);
    try std.testing.expect(method.is_error_union);
    try std.testing.expectEqual(@as(usize, 2), method.parameters.items.len);

    const param0 = method.parameters.items[0];
    try std.testing.expectEqualStrings("self", param0.name);
    try std.testing.expectEqualStrings("*Node", param0.type);

    const param1 = method.parameters.items[1];
    try std.testing.expectEqualStrings("value", param1.name);
    try std.testing.expectEqualStrings("u32", param1.type);
}

test "SourceParser - parse inline method" {
    const allocator = std.testing.allocator;

    const source =
        \\pub const Element = struct {
        \\    pub inline fn appendChild(self: anytype, child: *Node) !*Node {
        \\        return try self.prototype.appendChild(child);
        \\    }
        \\};
    ;

    var parser = SourceParser.init(allocator);
    var methods = try parser.parseSource(source, "Element");
    defer {
        for (methods.items) |*method| {
            method.deinit(allocator);
        }
        methods.deinit(allocator);
    }

    try std.testing.expectEqual(@as(usize, 1), methods.items.len);

    const method = methods.items[0];
    try std.testing.expectEqualStrings("appendChild", method.name);
    try std.testing.expect(method.is_inline);
    try std.testing.expectEqualStrings("!*Node", method.return_type);
    try std.testing.expect(method.is_error_union);
}

test "SourceParser - parse method with complex return type" {
    const allocator = std.testing.allocator;

    const source =
        \\pub const Node = struct {
        \\    pub fn getChildren(self: *const Node) ?*NodeList {
        \\        _ = self;
        \\        return null;
        \\    }
        \\};
    ;

    var parser = SourceParser.init(allocator);
    var methods = try parser.parseSource(source, "Node");
    defer {
        for (methods.items) |*method| {
            method.deinit(allocator);
        }
        methods.deinit(allocator);
    }

    try std.testing.expectEqual(@as(usize, 1), methods.items.len);

    const method = methods.items[0];
    try std.testing.expectEqualStrings("getChildren", method.name);
    try std.testing.expectEqualStrings("?*NodeList", method.return_type);
    try std.testing.expect(!method.is_error_union);
}

test "SourceParser - parse method with no return type (void)" {
    const allocator = std.testing.allocator;

    const source =
        \\pub const Node = struct {
        \\    pub fn doSomething(self: *Node) {
        \\        _ = self;
        \\    }
        \\};
    ;

    var parser = SourceParser.init(allocator);
    var methods = try parser.parseSource(source, "Node");
    defer {
        for (methods.items) |*method| {
            method.deinit(allocator);
        }
        methods.deinit(allocator);
    }

    try std.testing.expectEqual(@as(usize, 1), methods.items.len);

    const method = methods.items[0];
    try std.testing.expectEqualStrings("doSomething", method.name);
    try std.testing.expectEqualStrings("void", method.return_type);
    try std.testing.expect(!method.is_error_union);
}

test "SourceParser - parse multiple methods" {
    const allocator = std.testing.allocator;

    const source =
        \\pub const Node = struct {
        \\    pub fn first(self: *Node) void {
        \\        _ = self;
        \\    }
        \\    
        \\    pub inline fn second(self: anytype, arg: []const u8) !u32 {
        \\        _ = self;
        \\        _ = arg;
        \\        return 42;
        \\    }
        \\    
        \\    pub fn third(self: *const Node) ?*Node {
        \\        return self;
        \\    }
        \\};
    ;

    var parser = SourceParser.init(allocator);
    var methods = try parser.parseSource(source, "Node");
    defer {
        for (methods.items) |*method| {
            method.deinit(allocator);
        }
        methods.deinit(allocator);
    }

    try std.testing.expectEqual(@as(usize, 3), methods.items.len);

    try std.testing.expectEqualStrings("first", methods.items[0].name);
    try std.testing.expectEqualStrings("second", methods.items[1].name);
    try std.testing.expectEqualStrings("third", methods.items[2].name);

    try std.testing.expect(!methods.items[0].is_inline);
    try std.testing.expect(methods.items[1].is_inline);
    try std.testing.expect(!methods.items[2].is_inline);
}
