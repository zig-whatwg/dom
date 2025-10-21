//! WebIDL Parser
//!
//! Parses WHATWG DOM WebIDL files and builds an AST.
//!
//! This is a simplified parser focused on extracting:
//! - Interface names and inheritance
//! - Methods and their signatures
//! - Attributes and their types
//!
//! It does NOT parse the full WebIDL spec (callbacks, dictionaries, etc).

const std = @import("std");
const Allocator = std.mem.Allocator;
const ast = @import("ast.zig");

pub const Parser = struct {
    allocator: Allocator,
    source: []const u8,
    pos: usize,

    pub fn init(allocator: Allocator, source: []const u8) Parser {
        return .{
            .allocator = allocator,
            .source = source,
            .pos = 0,
        };
    }

    /// Parse WebIDL source into a Document
    pub fn parse(self: *Parser) !ast.Document {
        var doc = ast.Document.init(self.allocator);

        while (self.pos < self.source.len) {
            self.skipWhitespaceAndComments();
            if (self.pos >= self.source.len) break;

            // Skip extended attributes [...]
            if (self.peek("[")) {
                try self.skipExtendedAttributes();
                self.skipWhitespaceAndComments();
            }

            // Look for top-level constructs
            // WebIDL Grammar: Definition
            if (self.peek("interface mixin")) {
                // WebIDL Grammar: InterfaceOrMixin (mixin case)
                // interface mixin identifier { MixinMembers } ;
                // Spec: § 2.4 Interface mixins
                try self.skipUntil("};");
            } else if (self.peek("interface")) {
                // WebIDL: CallbackOrInterfaceOrMixin (interface case)
                const interface = try self.parseInterface();
                try doc.addInterface(interface);
            } else if (self.peek("dictionary")) {
                // WebIDL Grammar: Dictionary
                try self.skipUntil(";");
            } else if (self.peek("callback")) {
                // WebIDL Grammar: CallbackOrInterfaceOrMixin (callback case)
                try self.skipUntil(";");
            } else if (self.peek("partial")) {
                // WebIDL Grammar: Partial
                try self.skipUntil("};");
            } else if (self.peek("enum")) {
                // WebIDL Grammar: Enum
                try self.skipUntil(";");
            } else if (self.peek("typedef")) {
                // WebIDL Grammar: Typedef
                try self.skipUntil(";");
            } else if (self.peek("namespace")) {
                // WebIDL Grammar: Namespace
                try self.skipUntil("};");
            } else if (self.startsWithIdentifier() and self.peekAhead("includes")) {
                // WebIDL Grammar: IncludesStatement ::= identifier includes identifier ;
                // Example: "Node includes ParentNode;"
                // Spec: § 2.4 Interface mixins
                try self.skipUntil(";");
            } else {
                // Skip unknown construct
                self.pos += 1;
            }
        }

        return doc;
    }

    fn parseInterface(self: *Parser) !ast.Interface {
        // Skip "interface" keyword
        try self.expect("interface");
        self.skipWhitespace();

        // Parse interface name
        const name = try self.parseIdentifier();
        self.skipWhitespace();

        // Parse optional parent (: ParentName)
        var parent: ?[]const u8 = null;
        if (self.peek(":")) {
            self.pos += 1;
            self.skipWhitespace();
            parent = try self.parseIdentifier();
            self.skipWhitespaceAndComments();
        }

        // Parse interface body { ... }
        self.skipWhitespaceAndComments();
        try self.expect("{");

        var methods = std.ArrayList(ast.Method){};
        var attributes = std.ArrayList(ast.Attribute){};

        while (self.pos < self.source.len) {
            self.skipWhitespaceAndComments();
            if (self.pos >= self.source.len) break;

            // Check for end of interface
            // WebIDL Grammar: InterfaceRest ::= identifier Inheritance { InterfaceMembers } ;
            if (self.peek("}")) {
                self.pos += 1;
                self.skipWhitespaceAndComments();
                // Expect semicolon after closing brace
                try self.expect(";");
                break;
            }

            // Skip extended attributes on members
            if (self.peek("[")) {
                try self.skipExtendedAttributes();
                self.skipWhitespaceAndComments();
            }

            // Parse member (attribute, method, constructor, const, iterable, maplike, setlike, stringifier, getter/setter)
            // WebIDL Grammar: InterfaceMember and PartialInterfaceMember
            if (self.peek("constructor")) {
                // WebIDL: Constructor
                try self.skipUntil(";");
            } else if (self.peek("iterable<")) {
                // WebIDL Grammar: Iterable ::= iterable < TypeWithExtendedAttributes OptionalType > ;
                // Spec: § 2.5.5 Iterable declarations
                try self.skipUntil(";");
            } else if (self.peek("async") and self.pos + 20 < self.source.len and std.mem.indexOf(u8, self.source[self.pos .. self.pos + 20], "iterable") != null) {
                // WebIDL Grammar: AsyncIterable
                // Spec: § 2.5.6 Asynchronously iterable declarations
                try self.skipUntil(";");
            } else if (self.peek("maplike<") or self.peek("readonly maplike<")) {
                // WebIDL Grammar: ReadWriteMaplike / ReadOnlyMaplike
                // Spec: § 2.5.7 Maplike declarations
                try self.skipUntil(";");
            } else if (self.peek("setlike<") or self.peek("readonly setlike<")) {
                // WebIDL Grammar: ReadWriteSetlike / ReadOnlySetlike
                // Spec: § 2.5.8 Setlike declarations
                try self.skipUntil(";");
            } else if (self.peek("stringifier")) {
                // WebIDL Grammar: Stringifier
                // Spec: § 2.5.3 Stringifiers
                try self.skipUntil(";");
            } else if (self.peek("inherit")) {
                // WebIDL Grammar: InheritAttribute ::= inherit attribute AttributeRest
                // Skip for now
                try self.skipUntil(";");
            } else if (self.peek("static")) {
                // WebIDL Grammar: StaticMember
                self.pos += 6; // "static"
                self.skipWhitespace();
                if (self.parseMethod()) |method| {
                    try methods.append(self.allocator, method);
                } else |_| {
                    try self.skipUntil(";");
                }
            } else if (self.peek("readonly")) {
                // WebIDL Grammar: ReadOnlyMember
                try attributes.append(self.allocator, try self.parseAttribute(true));
            } else if (self.peek("attribute")) {
                // WebIDL Grammar: ReadWriteAttribute
                try attributes.append(self.allocator, try self.parseAttribute(false));
            } else if (self.peek("const")) {
                // WebIDL Grammar: Const
                try self.skipUntil(";");
            } else if (self.peek("getter") or self.peek("setter") or self.peek("deleter")) {
                // WebIDL Grammar: Special operations (getter, setter, deleter)
                // Try to parse as method (these are operation modifiers)
                if (self.parseMethod()) |method| {
                    try methods.append(self.allocator, method);
                } else |_| {
                    try self.skipUntil(";");
                }
            } else {
                // Try to parse as method
                if (self.parseMethod()) |method| {
                    try methods.append(self.allocator, method);
                } else |_| {
                    // Skip unrecognized member
                    try self.skipUntil(";");
                }
            }
        }

        return ast.Interface{
            .name = name,
            .parent = parent,
            .methods = try methods.toOwnedSlice(self.allocator),
            .attributes = try attributes.toOwnedSlice(self.allocator),
        };
    }

    fn parseAttribute(self: *Parser, readonly: bool) !ast.Attribute {
        if (readonly) {
            try self.expect("readonly");
            self.skipWhitespace();
        }

        try self.expect("attribute");
        self.skipWhitespaceAndComments();

        // WebIDL Grammar: AttributeRest ::= attribute TypeWithExtendedAttributes AttributeName ;
        // TypeWithExtendedAttributes ::= ExtendedAttributeList Type
        // Skip extended attributes on the type
        if (self.peek("[")) {
            try self.skipExtendedAttributes();
            self.skipWhitespaceAndComments();
        }

        // Parse type
        const type_str = try self.parseType();
        const attr_type = try ast.Type.fromString(self.allocator, type_str);
        self.skipWhitespace();

        // Parse name
        const name = try self.parseIdentifier();
        self.skipWhitespaceAndComments();

        try self.expect(";");

        return ast.Attribute{
            .name = name,
            .type = attr_type,
            .readonly = readonly,
        };
    }

    fn parseMethod(self: *Parser) !ast.Method {
        // Parse return type
        const return_type_str = try self.parseType();
        const return_type = try ast.Type.fromString(self.allocator, return_type_str);
        self.skipWhitespace();

        // Parse method name
        const name = try self.parseIdentifier();
        self.skipWhitespace();

        // Parse parameters
        try self.expect("(");
        var parameters = std.ArrayList(ast.Parameter){};

        while (self.pos < self.source.len) {
            self.skipWhitespaceAndComments();
            if (self.peek(")")) {
                self.pos += 1;
                break;
            }

            // Check for optional
            var optional = false;
            if (self.peek("optional")) {
                optional = true;
                try self.expect("optional");
                self.skipWhitespace();
            }

            // Parse parameter type
            const param_type_str = try self.parseType();
            const param_type = try ast.Type.fromString(self.allocator, param_type_str);
            self.skipWhitespace();

            // Parse parameter name
            const param_name = try self.parseIdentifier();
            self.skipWhitespace();

            // Skip default value if present: = value
            if (self.peek("=")) {
                self.pos += 1;
                self.skipWhitespace();
                // Skip default value (could be literal, {}, [], identifier, etc.)
                // We'll skip until we find comma or close paren
                var depth: usize = 0;
                while (self.pos < self.source.len) {
                    const ch = self.source[self.pos];
                    if (ch == '(' or ch == '{' or ch == '[') {
                        depth += 1;
                    } else if (ch == ')' or ch == '}' or ch == ']') {
                        if (depth == 0) break;
                        depth -= 1;
                    } else if (ch == ',' and depth == 0) {
                        break;
                    }
                    self.pos += 1;
                }
                self.skipWhitespace();
            }

            try parameters.append(self.allocator, ast.Parameter{
                .name = param_name,
                .type = param_type,
                .optional = optional,
            });

            self.skipWhitespace();

            // Check for comma or end
            if (self.peek(",")) {
                self.pos += 1;
            } else if (!self.peek(")")) {
                return error.ExpectedCommaOrCloseParen;
            }
        }

        self.skipWhitespaceAndComments();
        try self.expect(";");

        return ast.Method{
            .name = name,
            .return_type = return_type,
            .parameters = try parameters.toOwnedSlice(self.allocator),
        };
    }

    fn parseType(self: *Parser) ![]const u8 {
        const start = self.pos;

        // Handle union types (A or B)
        if (self.peek("(")) {
            var depth: usize = 1;
            self.pos += 1;
            while (self.pos < self.source.len and depth > 0) {
                const ch = self.source[self.pos];
                if (ch == '(') depth += 1;
                if (ch == ')') depth -= 1;
                self.pos += 1;
            }
        }
        // Handle Promise<T>
        else if (self.peek("Promise<")) {
            while (self.pos < self.source.len and self.source[self.pos] != '>') {
                self.pos += 1;
            }
            if (self.pos < self.source.len) self.pos += 1; // Include >
        }
        // Handle sequence<T>
        else if (self.peek("sequence<")) {
            while (self.pos < self.source.len and self.source[self.pos] != '>') {
                self.pos += 1;
            }
            if (self.pos < self.source.len) self.pos += 1; // Include >
        }
        // Handle record<K, V>
        else if (self.peek("record<")) {
            var depth: usize = 1;
            self.pos += 7; // "record<"
            while (self.pos < self.source.len and depth > 0) {
                const ch = self.source[self.pos];
                if (ch == '<') depth += 1;
                if (ch == '>') depth -= 1;
                self.pos += 1;
            }
        }
        // Handle multi-word primitive types
        else if (self.peek("unrestricted ")) {
            self.pos += 13; // "unrestricted "
            // Now get the rest (float or double)
            if (self.peek("float")) {
                self.pos += 5;
            } else if (self.peek("double")) {
                self.pos += 6;
            }
        } else if (self.peek("unsigned ")) {
            self.pos += 9; // "unsigned "
            // Now get the rest (short, long, or long long)
            if (self.peek("long long")) {
                self.pos += 9;
            } else if (self.peek("long")) {
                self.pos += 4;
            } else if (self.peek("short")) {
                self.pos += 5;
            }
        } else if (self.peek("long long")) {
            self.pos += 9;
        } else {
            // Simple type or identifier
            while (self.pos < self.source.len) {
                const ch = self.source[self.pos];
                if (ch == ' ' or ch == '\t' or ch == '\n' or ch == ',' or
                    ch == ';' or ch == ')' or ch == '?' or ch == '=')
                {
                    break;
                }
                self.pos += 1;
            }
        }

        // Check for nullable (?)
        if (self.pos < self.source.len and self.source[self.pos] == '?') {
            self.pos += 1;
        }

        const type_str = self.source[start..self.pos];
        return try self.allocator.dupe(u8, type_str);
    }

    fn parseIdentifier(self: *Parser) ![]const u8 {
        const start = self.pos;

        while (self.pos < self.source.len) {
            const ch = self.source[self.pos];
            if ((ch >= 'a' and ch <= 'z') or
                (ch >= 'A' and ch <= 'Z') or
                (ch >= '0' and ch <= '9') or
                ch == '_')
            {
                self.pos += 1;
            } else {
                break;
            }
        }

        if (self.pos == start) {
            return error.ExpectedIdentifier;
        }

        const id = self.source[start..self.pos];
        return try self.allocator.dupe(u8, id);
    }

    fn expect(self: *Parser, expected: []const u8) !void {
        if (!self.peek(expected)) {
            return error.UnexpectedToken;
        }
        self.pos += expected.len;
    }

    fn peek(self: *Parser, expected: []const u8) bool {
        if (self.pos + expected.len > self.source.len) {
            return false;
        }
        return std.mem.eql(u8, self.source[self.pos .. self.pos + expected.len], expected);
    }

    /// Check if current position starts with an identifier (letter or underscore)
    fn startsWithIdentifier(self: *Parser) bool {
        if (self.pos >= self.source.len) return false;
        const ch = self.source[self.pos];
        return (ch >= 'a' and ch <= 'z') or
            (ch >= 'A' and ch <= 'Z') or
            ch == '_';
    }

    /// Look ahead for a keyword after skipping whitespace and an identifier
    fn peekAhead(self: *Parser, keyword: []const u8) bool {
        var temp_pos = self.pos;

        // Skip the identifier at current position
        while (temp_pos < self.source.len) {
            const ch = self.source[temp_pos];
            if ((ch >= 'a' and ch <= 'z') or
                (ch >= 'A' and ch <= 'Z') or
                (ch >= '0' and ch <= '9') or
                ch == '_')
            {
                temp_pos += 1;
            } else {
                break;
            }
        }

        // Skip whitespace
        while (temp_pos < self.source.len) {
            const ch = self.source[temp_pos];
            if (ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r') {
                temp_pos += 1;
            } else {
                break;
            }
        }

        // Check for keyword
        if (temp_pos + keyword.len > self.source.len) {
            return false;
        }
        return std.mem.eql(u8, self.source[temp_pos .. temp_pos + keyword.len], keyword);
    }

    fn skipWhitespace(self: *Parser) void {
        while (self.pos < self.source.len) {
            const ch = self.source[self.pos];
            if (ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r') {
                self.pos += 1;
            } else {
                break;
            }
        }
    }

    fn skipWhitespaceAndComments(self: *Parser) void {
        while (self.pos < self.source.len) {
            self.skipWhitespace();

            // Skip // comments
            if (self.pos + 1 < self.source.len and
                self.source[self.pos] == '/' and
                self.source[self.pos + 1] == '/')
            {
                while (self.pos < self.source.len and self.source[self.pos] != '\n') {
                    self.pos += 1;
                }
                continue;
            }

            // Skip /* */ comments
            if (self.pos + 1 < self.source.len and
                self.source[self.pos] == '/' and
                self.source[self.pos + 1] == '*')
            {
                self.pos += 2;
                while (self.pos + 1 < self.source.len) {
                    if (self.source[self.pos] == '*' and self.source[self.pos + 1] == '/') {
                        self.pos += 2;
                        break;
                    }
                    self.pos += 1;
                }
                continue;
            }

            break;
        }
    }

    fn skipUntil(self: *Parser, until: []const u8) !void {
        while (self.pos < self.source.len) {
            if (self.peek(until)) {
                self.pos += until.len;
                return;
            }
            self.pos += 1;
        }
        return error.UnexpectedEndOfFile;
    }

    /// Skip extended attributes [...] including nested brackets
    fn skipExtendedAttributes(self: *Parser) !void {
        if (!self.peek("[")) return error.ExpectedOpenBracket;

        self.pos += 1; // Skip opening [
        var depth: usize = 1;

        while (self.pos < self.source.len and depth > 0) {
            const ch = self.source[self.pos];
            if (ch == '[') {
                depth += 1;
            } else if (ch == ']') {
                depth -= 1;
            }
            self.pos += 1;
        }

        if (depth != 0) {
            return error.UnmatchedBracket;
        }
    }
};
