//! JavaScript Bindings Generator
//!
//! Generates C-ABI compatible bindings for JavaScript engines from WebIDL interfaces.

const std = @import("std");
const webidl = @import("webidl-parser");
const Parser = webidl.Parser;
const Interface = webidl.Interface;
const Attribute = webidl.Attribute;
const Method = webidl.Method;

const Generator = struct {
    allocator: std.mem.Allocator,
    output: std.ArrayList(u8),
    interface: Interface,

    pub fn init(allocator: std.mem.Allocator, interface: Interface) Generator {
        return .{
            .allocator = allocator,
            .output = std.ArrayList(u8){},
            .interface = interface,
        };
    }

    pub fn generate(self: *Generator) ![]const u8 {
        try self.writeHeader();
        try self.writeOpaqueTypes();
        try self.writeAttributes();
        try self.writeMethods();
        try self.writeRefCounting();

        return self.output.toOwnedSlice(self.allocator);
    }

    fn writeHeader(self: *Generator) !void {
        const name = self.interface.name;
        const writer = self.output.writer(self.allocator);

        // Header comment
        try writer.writeAll("//! JavaScript Bindings for ");
        try writer.writeAll(name);
        try writer.writeAll("\n//!\n");
        try writer.writeAll("//! This file provides C-ABI compatible bindings.\n\n");

        // Imports
        try writer.writeAll("const std = @import(\"std\");\n");
        try writer.writeAll("const DOMErrorCode = @import(\"dom_types.zig\").DOMErrorCode;\n");
        try writer.writeAll("const zigErrorToDOMError = @import(\"dom_types.zig\").zigErrorToDOMError;\n\n");
    }

    fn writeOpaqueTypes(self: *Generator) !void {
        const name = self.interface.name;
        const writer = self.output.writer(self.allocator);

        try writer.writeAll("/// Opaque handle to ");
        try writer.writeAll(name);
        try writer.writeAll("\npub const DOM");
        try writer.writeAll(name);
        try writer.writeAll(" = opaque {};\n\n");

        // Also declare forward declarations for types referenced by this interface
        var referenced_types = std.StringHashMap(void).init(self.allocator);
        defer referenced_types.deinit();

        // Collect types from attributes
        for (self.interface.attributes) |attr| {
            const type_name = attr.type.name;
            // Skip primitives
            if (!self.isPrimitive(type_name)) {
                try referenced_types.put(type_name, {});
            }
        }

        // Collect types from methods
        for (self.interface.methods) |method| {
            // Return type
            if (!self.isPrimitive(method.return_type.name)) {
                try referenced_types.put(method.return_type.name, {});
            }
            // Parameter types
            for (method.parameters) |param| {
                if (!self.isPrimitive(param.type.name)) {
                    try referenced_types.put(param.type.name, {});
                }
            }
        }

        // Write forward declarations
        var it = referenced_types.keyIterator();
        while (it.next()) |type_name| {
            // Skip the interface itself
            if (std.mem.eql(u8, type_name.*, name)) continue;

            // Skip complex types that won't be generated
            if (std.mem.indexOf(u8, type_name.*, " or ") != null) continue;
            if (std.mem.indexOf(u8, type_name.*, "(") != null) continue;

            try writer.writeAll("/// Forward declaration for ");
            try writer.writeAll(type_name.*);
            try writer.writeAll("\npub const DOM");
            try writer.writeAll(type_name.*);
            try writer.writeAll(" = opaque {};\n");
        }

        try writer.writeAll("\n");
    }

    fn isPrimitive(self: *Generator, type_name: []const u8) bool {
        _ = self;

        const primitives = [_][]const u8{
            "DOMString",          "USVString",           "ByteString",
            "boolean",            "undefined",           "byte",
            "octet",              "short",               "unsigned short",
            "long",               "unsigned long",       "long long",
            "unsigned long long", "float",               "unrestricted float",
            "double",             "unrestricted double",
        };

        for (primitives) |prim| {
            if (std.mem.eql(u8, type_name, prim)) return true;
        }

        return false;
    }

    fn writeAttributes(self: *Generator) !void {
        for (self.interface.attributes) |attr| {
            try self.writeAttributeGetter(attr);
            if (!attr.readonly) {
                try self.writeAttributeSetter(attr);
            }
        }
    }

    fn writeAttributeGetter(self: *Generator, attr: Attribute) !void {
        const writer = self.output.writer(self.allocator);
        const name = self.interface.name;

        // Create lowercase names
        var lower_interface = std.ArrayList(u8){};
        defer lower_interface.deinit(self.allocator);
        for (name) |c| {
            try lower_interface.append(self.allocator, std.ascii.toLower(c));
        }

        var lower_attr = std.ArrayList(u8){};
        defer lower_attr.deinit(self.allocator);
        for (attr.name) |c| {
            try lower_attr.append(self.allocator, std.ascii.toLower(c));
        }

        // Map type to C-ABI
        const c_type = try self.typeToCType(attr.type);
        defer self.allocator.free(c_type);

        // Documentation
        try writer.writeAll("\n/// Get ");
        try writer.writeAll(attr.name);
        try writer.writeAll(" attribute\n///\n/// WebIDL: `");
        if (attr.readonly) try writer.writeAll("readonly ");
        try writer.writeAll("attribute ");
        try writer.writeAll(attr.type.name);
        if (attr.type.nullable) try writer.writeAll("?");
        try writer.writeAll(" ");
        try writer.writeAll(attr.name);
        try writer.writeAll(";`\n");

        // Function signature
        try writer.writeAll("export fn dom_");
        try writer.writeAll(lower_interface.items);
        try writer.writeAll("_get_");
        try writer.writeAll(lower_attr.items);
        try writer.writeAll("(handle: *DOM");
        try writer.writeAll(name);
        try writer.writeAll(") ");
        try writer.writeAll(c_type);
        try writer.writeAll(" {\n");

        // Stub implementation
        try writer.writeAll("    _ = handle;\n");
        try writer.writeAll("    // TODO: Implement getter\n");

        // Return appropriate default based on type
        if (std.mem.eql(u8, c_type, "void")) {
            // No return needed
        } else if (std.mem.startsWith(u8, c_type, "?")) {
            try writer.writeAll("    return null;\n");
        } else if (std.mem.indexOf(u8, c_type, "[*:0]const u8") != null) {
            try writer.writeAll("    return \"\";\n");
        } else if (std.mem.startsWith(u8, c_type, "u") or std.mem.startsWith(u8, c_type, "i")) {
            try writer.writeAll("    return 0;\n");
        } else if (std.mem.startsWith(u8, c_type, "f")) {
            try writer.writeAll("    return 0.0;\n");
        } else if (std.mem.startsWith(u8, c_type, "*DOM")) {
            try writer.writeAll("    @panic(\"TODO: Non-nullable pointer return not yet implemented\");\n");
        } else {
            try writer.writeAll("    @panic(\"TODO: Unknown return type\");\n");
        }

        try writer.writeAll("}\n");
    }

    fn writeAttributeSetter(self: *Generator, attr: Attribute) !void {
        const writer = self.output.writer(self.allocator);
        const name = self.interface.name;

        // Create lowercase names
        var lower_interface = std.ArrayList(u8){};
        defer lower_interface.deinit(self.allocator);
        for (name) |c| {
            try lower_interface.append(self.allocator, std.ascii.toLower(c));
        }

        var lower_attr = std.ArrayList(u8){};
        defer lower_attr.deinit(self.allocator);
        for (attr.name) |c| {
            try lower_attr.append(self.allocator, std.ascii.toLower(c));
        }

        // Map type to C-ABI
        const c_type = try self.typeToCType(attr.type);
        defer self.allocator.free(c_type);

        // Documentation
        try writer.writeAll("\n/// Set ");
        try writer.writeAll(attr.name);
        try writer.writeAll(" attribute\n///\n/// WebIDL: `attribute ");
        try writer.writeAll(attr.type.name);
        if (attr.type.nullable) try writer.writeAll("?");
        try writer.writeAll(" ");
        try writer.writeAll(attr.name);
        try writer.writeAll(";`\n");

        // Function signature
        try writer.writeAll("export fn dom_");
        try writer.writeAll(lower_interface.items);
        try writer.writeAll("_set_");
        try writer.writeAll(lower_attr.items);
        try writer.writeAll("(handle: *DOM");
        try writer.writeAll(name);
        try writer.writeAll(", value: ");
        try writer.writeAll(c_type);
        try writer.writeAll(") c_int {\n");

        // Stub implementation
        try writer.writeAll("    _ = handle;\n");
        try writer.writeAll("    _ = value;\n");
        try writer.writeAll("    // TODO: Implement setter\n");
        try writer.writeAll("    return 0; // Success\n");
        try writer.writeAll("}\n");
    }

    fn writeMethods(self: *Generator) !void {
        for (self.interface.methods) |method| {
            // Check if method has complex types we can't handle yet
            if (try self.hasComplexTypes(method)) {
                try self.writeSkippedMethod(method);
                continue;
            }
            try self.writeMethod(method);
        }
    }

    fn hasComplexTypes(self: *Generator, method: Method) !bool {
        _ = self;

        // Check parameters for unions or callbacks
        for (method.parameters) |param| {
            const type_name = param.type.name;

            // Union types contain "or"
            if (std.mem.indexOf(u8, type_name, " or ") != null) {
                return true;
            }

            // Callback types end with "Listener" or "Callback"
            if (std.mem.endsWith(u8, type_name, "Listener") or
                std.mem.endsWith(u8, type_name, "Callback"))
            {
                return true;
            }

            // Dictionary types (would need struct handling)
            if (std.mem.endsWith(u8, type_name, "Init") or
                std.mem.endsWith(u8, type_name, "Options") or
                std.mem.endsWith(u8, type_name, "Dictionary"))
            {
                return true;
            }
        }

        return false;
    }

    fn writeSkippedMethod(self: *Generator, method: Method) !void {
        const writer = self.output.writer(self.allocator);

        try writer.writeAll("\n// SKIPPED: ");
        try writer.writeAll(method.name);
        try writer.writeAll("() - Contains complex types not supported in C-ABI v1\n");
        try writer.writeAll("// WebIDL: ");
        try writer.writeAll(method.return_type.name);
        try writer.writeAll(" ");
        try writer.writeAll(method.name);
        try writer.writeAll("(");

        for (method.parameters, 0..) |param, i| {
            if (i > 0) try writer.writeAll(", ");
            try writer.writeAll(param.type.name);
            try writer.writeAll(" ");
            try writer.writeAll(param.name);
        }

        try writer.writeAll(");\n");
        try writer.writeAll("// Reason: ");

        // Explain why it was skipped
        var found_reason = false;
        for (method.parameters) |param| {
            const type_name = param.type.name;
            if (std.mem.indexOf(u8, type_name, " or ") != null) {
                if (found_reason) try writer.writeAll(", ");
                try writer.writeAll("Union type '");
                try writer.writeAll(type_name);
                try writer.writeAll("'");
                found_reason = true;
            } else if (std.mem.endsWith(u8, type_name, "Listener") or
                std.mem.endsWith(u8, type_name, "Callback"))
            {
                if (found_reason) try writer.writeAll(", ");
                try writer.writeAll("Callback type '");
                try writer.writeAll(type_name);
                try writer.writeAll("'");
                found_reason = true;
            } else if (std.mem.endsWith(u8, type_name, "Init") or
                std.mem.endsWith(u8, type_name, "Options") or
                std.mem.endsWith(u8, type_name, "Dictionary"))
            {
                if (found_reason) try writer.writeAll(", ");
                try writer.writeAll("Dictionary type '");
                try writer.writeAll(type_name);
                try writer.writeAll("'");
                found_reason = true;
            }
        }

        try writer.writeAll("\n");
    }

    fn writeMethod(self: *Generator, method: Method) !void {
        const writer = self.output.writer(self.allocator);
        const name = self.interface.name;

        // Create lowercase names
        var lower_interface = std.ArrayList(u8){};
        defer lower_interface.deinit(self.allocator);
        for (name) |c| {
            try lower_interface.append(self.allocator, std.ascii.toLower(c));
        }

        var lower_method = std.ArrayList(u8){};
        defer lower_method.deinit(self.allocator);
        for (method.name) |c| {
            try lower_method.append(self.allocator, std.ascii.toLower(c));
        }

        // Map return type
        const return_type = if (std.mem.eql(u8, method.return_type.name, "undefined"))
            try self.allocator.dupe(u8, "c_int") // void methods return error code
        else
            try self.typeToCType(method.return_type);
        defer self.allocator.free(return_type);

        // Documentation
        try writer.writeAll("\n/// ");
        try writer.writeAll(method.name);
        try writer.writeAll(" method\n///\n/// WebIDL: `");
        try writer.writeAll(method.return_type.name);
        try writer.writeAll(" ");
        try writer.writeAll(method.name);
        try writer.writeAll("(");

        // Document parameters
        for (method.parameters, 0..) |param, i| {
            if (i > 0) try writer.writeAll(", ");
            try writer.writeAll(param.type.name);
            try writer.writeAll(" ");
            try writer.writeAll(param.name);
        }
        try writer.writeAll(");`\n");

        // Function signature
        try writer.writeAll("export fn dom_");
        try writer.writeAll(lower_interface.items);
        try writer.writeAll("_");
        try writer.writeAll(lower_method.items);
        try writer.writeAll("(handle: *DOM");
        try writer.writeAll(name);

        // Add parameters
        for (method.parameters) |param| {
            try writer.writeAll(", ");
            try writer.writeAll(param.name);
            try writer.writeAll(": ");
            const param_type = try self.typeToCType(param.type);
            defer self.allocator.free(param_type);
            try writer.writeAll(param_type);
        }

        try writer.writeAll(") ");
        try writer.writeAll(return_type);
        try writer.writeAll(" {\n");

        // Stub implementation
        try writer.writeAll("    _ = handle;\n");
        for (method.parameters) |param| {
            try writer.writeAll("    _ = ");
            try writer.writeAll(param.name);
            try writer.writeAll(";\n");
        }
        try writer.writeAll("    // TODO: Implement method\n");

        // Return appropriate value
        if (std.mem.eql(u8, return_type, "c_int")) {
            try writer.writeAll("    return 0; // Success\n");
        } else if (std.mem.eql(u8, return_type, "void")) {
            // No return
        } else if (std.mem.startsWith(u8, return_type, "?")) {
            try writer.writeAll("    return null;\n");
        } else if (std.mem.indexOf(u8, return_type, "[*:0]const u8") != null) {
            try writer.writeAll("    return \"\";\n");
        } else if (std.mem.startsWith(u8, return_type, "u") or std.mem.startsWith(u8, return_type, "i")) {
            try writer.writeAll("    return 0;\n");
        } else if (std.mem.startsWith(u8, return_type, "f")) {
            try writer.writeAll("    return 0.0;\n");
        } else if (std.mem.startsWith(u8, return_type, "*DOM")) {
            try writer.writeAll("    @panic(\"TODO: Non-nullable pointer return\");\n");
        } else {
            try writer.writeAll("    return 0;\n");
        }

        try writer.writeAll("}\n");
    }

    /// Convert WebIDL type to C-ABI type
    fn typeToCType(self: *Generator, webidl_type: webidl.Type) ![]const u8 {
        const base = webidl_type.name;

        // String types
        if (std.mem.eql(u8, base, "DOMString") or
            std.mem.eql(u8, base, "USVString") or
            std.mem.eql(u8, base, "ByteString"))
        {
            if (webidl_type.nullable) {
                return self.allocator.dupe(u8, "?[*:0]const u8");
            } else {
                return self.allocator.dupe(u8, "[*:0]const u8");
            }
        }

        // Boolean
        if (std.mem.eql(u8, base, "boolean")) {
            return self.allocator.dupe(u8, "u8");
        }

        // Void
        if (std.mem.eql(u8, base, "undefined")) {
            return self.allocator.dupe(u8, "void");
        }

        // Integer types
        if (std.mem.eql(u8, base, "byte")) return self.allocator.dupe(u8, "i8");
        if (std.mem.eql(u8, base, "octet")) return self.allocator.dupe(u8, "u8");
        if (std.mem.eql(u8, base, "short")) return self.allocator.dupe(u8, "i16");
        if (std.mem.eql(u8, base, "unsigned short")) return self.allocator.dupe(u8, "u16");
        if (std.mem.eql(u8, base, "long")) return self.allocator.dupe(u8, "i32");
        if (std.mem.eql(u8, base, "unsigned long")) return self.allocator.dupe(u8, "u32");
        if (std.mem.eql(u8, base, "long long")) return self.allocator.dupe(u8, "i64");
        if (std.mem.eql(u8, base, "unsigned long long")) return self.allocator.dupe(u8, "u64");

        // Float types
        if (std.mem.eql(u8, base, "float") or std.mem.eql(u8, base, "unrestricted float")) {
            return self.allocator.dupe(u8, "f32");
        }
        if (std.mem.eql(u8, base, "double") or std.mem.eql(u8, base, "unrestricted double")) {
            return self.allocator.dupe(u8, "f64");
        }

        // Interface types - opaque pointers
        if (webidl_type.nullable) {
            return std.fmt.allocPrint(self.allocator, "?*DOM{s}", .{base});
        } else {
            return std.fmt.allocPrint(self.allocator, "*DOM{s}", .{base});
        }
    }

    fn writeRefCounting(self: *Generator) !void {
        const name = self.interface.name;
        const writer = self.output.writer(self.allocator);

        // Create lowercase name
        var lower_name = std.ArrayList(u8){};
        defer lower_name.deinit(self.allocator);

        for (name) |c| {
            try lower_name.append(self.allocator, std.ascii.toLower(c));
        }

        try writer.writeAll("/// Increase reference count\n");
        try writer.writeAll("export fn dom_");
        try writer.writeAll(lower_name.items);
        try writer.writeAll("_addref(handle: *DOM");
        try writer.writeAll(name);
        try writer.writeAll(") void {\n");
        try writer.writeAll("    _ = handle;\n");
        try writer.writeAll("    // TODO: Implement\n");
        try writer.writeAll("}\n\n");

        try writer.writeAll("/// Decrease reference count\n");
        try writer.writeAll("export fn dom_");
        try writer.writeAll(lower_name.items);
        try writer.writeAll("_release(handle: *DOM");
        try writer.writeAll(name);
        try writer.writeAll(") void {\n");
        try writer.writeAll("    _ = handle;\n");
        try writer.writeAll("    // TODO: Implement\n");
        try writer.writeAll("}\n");
    }
};

pub fn generateBindings(
    allocator: std.mem.Allocator,
    interface_name: []const u8,
    webidl_source: []const u8,
) ![]const u8 {
    var parser = Parser.init(allocator, webidl_source);
    var doc = try parser.parse();
    defer doc.deinit();

    // Find the requested interface in HashMap
    if (doc.interfaces.get(interface_name)) |interface| {
        var generator = Generator.init(allocator, interface);
        return try generator.generate();
    }

    return error.InterfaceNotFound;
}

test "generate simple bindings" {
    const allocator = std.testing.allocator;

    const webidl_source =
        \\interface EventTarget {
        \\};
    ;

    const bindings = try generateBindings(allocator, "EventTarget", webidl_source);
    defer allocator.free(bindings);

    // Verify it contains expected content
    try std.testing.expect(std.mem.indexOf(u8, bindings, "DOMEventTarget") != null);
    try std.testing.expect(std.mem.indexOf(u8, bindings, "dom_event_target_addref") != null);
}
