//! Zig Code Generator
//!
//! Generates Zig delegation methods from WebIDL AST.

const std = @import("std");
const Allocator = std.mem.Allocator;

// Import standalone WebIDL parser library
const webidl = @import("webidl-parser");

pub const Generator = struct {
    allocator: Allocator,
    output: std.ArrayList(u8),
    overrides: std.StringHashMap(std.StringHashMap([]const u8)), // interface -> method -> reason

    pub fn init(allocator: Allocator) Generator {
        return .{
            .allocator = allocator,
            .output = std.ArrayList(u8){},
            .overrides = std.StringHashMap(std.StringHashMap([]const u8)).init(allocator),
        };
    }

    /// Load overrides from overrides.json
    pub fn loadOverrides(self: *Generator) !void {
        // For now, hardcode known overrides
        // TODO: Parse JSON file

        var node_overrides = std.StringHashMap([]const u8).init(self.allocator);
        try node_overrides.put("dispatchEvent", "Full DOM event propagation with capture/target/bubble phases");
        try self.overrides.put("Node", node_overrides);
    }

    fn getWriter(self: *Generator) std.ArrayList(u8).Writer {
        return self.output.writer(self.allocator);
    }

    pub fn deinit(self: *Generator) void {
        self.output.deinit(self.allocator);

        // Clean up overrides map
        var it = self.overrides.valueIterator();
        while (it.next()) |methods_map| {
            methods_map.deinit();
        }
        self.overrides.deinit();
    }

    pub fn getOutput(self: *Generator) []const u8 {
        return self.output.items;
    }

    /// Generate delegation code for an interface
    pub fn generate(self: *Generator, interface: webidl.Interface, doc: *webidl.Document) !void {

        // Get ancestors
        const ancestors = try interface.getAncestors(doc.interfaces, self.allocator);
        defer self.allocator.free(ancestors);

        if (ancestors.len == 0) {
            // No ancestors, no delegation needed
            return;
        }

        // Write header
        try self.writeHeader(interface, ancestors);

        // Generate delegation for each ancestor (reverse order - furthest first)
        var i = ancestors.len;
        while (i > 0) {
            i -= 1;
            const ancestor_name = ancestors[i];
            const depth = ancestors.len - i; // Depth from current interface

            if (doc.getInterface(ancestor_name)) |ancestor| {
                try self.generateAncestorDelegation(interface, ancestor, depth);
            }
        }

        // Write footer
        try self.writeFooter();
    }

    fn writeHeader(self: *Generator, interface: webidl.Interface, ancestors: [][]const u8) !void {
        try self.getWriter().writeAll(
            \\    // ========================================================================
            \\    // GENERATED CODE - DO NOT EDIT
            \\    // Generated from: skills/whatwg_compliance/dom.idl
            \\
        );

        // Write inheritance chain
        try self.getWriter().print("    // Interface: {s}", .{interface.name});
        for (ancestors) |ancestor| {
            try self.getWriter().print(" : {s}", .{ancestor});
        }
        try self.getWriter().writeAll("\n");

        const ts = std.time.timestamp();
        try self.getWriter().print("    // Generated: {d}\n", .{ts});
        try self.getWriter().writeAll(
            \\    // ========================================================================
            \\
            \\
        );
    }

    fn generateAncestorDelegation(self: *Generator, current_interface: webidl.Interface, ancestor: webidl.Interface, depth: usize) !void {
        try self.getWriter().print(
            \\    // ========================================================================
            \\    // GENERATED: {s} methods delegation (depth: {d})
            \\    // Source: {s} interface
            \\    // ========================================================================
            \\
            \\
        , .{ ancestor.name, depth, ancestor.name });

        // Generate method delegations (skip if overridden by current interface)
        for (ancestor.methods) |method| {
            const is_overridden_webidl = self.isMethodOverridden(current_interface, method.name);
            const is_overridden_custom = self.isCustomOverride(current_interface.name, method.name);
            const can_generate = self.canGenerateMethod(method);

            if (is_overridden_custom) {
                // Custom implementation in overrides.json
                const reason = self.getOverrideReason(current_interface.name, method.name) orelse "Custom implementation";
                try self.getWriter().print(
                    \\    // NOTE: {s}.{s}() has custom implementation - not generated
                    \\    // Reason: {s}
                    \\    // See: overrides.json
                    \\
                    \\
                , .{ ancestor.name, method.name, reason });
            } else if (is_overridden_webidl) {
                // Overridden in WebIDL
                try self.getWriter().print(
                    \\    // NOTE: {s}.{s}() is overridden by {s} - not delegated
                    \\
                    \\
                , .{ ancestor.name, method.name, current_interface.name });
            } else if (!can_generate) {
                // Complex types
                try self.getWriter().print(
                    \\    // NOTE: {s}.{s}() has complex types (union/callback) - requires manual implementation
                    \\
                    \\
                , .{ ancestor.name, method.name });
            } else {
                // Generate delegation
                try self.generateMethodDelegation(method, ancestor.name, depth, false);
            }
        }

        // Generate attribute delegations (skip if overridden)
        for (ancestor.attributes) |attribute| {
            const is_overridden = self.isAttributeOverridden(current_interface, attribute.name);
            if (!is_overridden) {
                try self.generateAttributeDelegation(attribute, ancestor.name, depth, false);
            } else {
                // Generate a comment noting this attribute is overridden
                try self.getWriter().print(
                    \\    // NOTE: {s}.{s} is overridden by {s} - not delegated
                    \\
                    \\
                , .{ ancestor.name, attribute.name, current_interface.name });
            }
        }

        try self.getWriter().writeAll("\n");
    }

    /// Check if a method is overridden by the current interface
    fn isMethodOverridden(self: *Generator, interface: webidl.Interface, method_name: []const u8) bool {
        _ = self;
        for (interface.methods) |method| {
            if (std.mem.eql(u8, method.name, method_name)) {
                return true;
            }
        }
        return false;
    }

    /// Check if an attribute is overridden by the current interface
    fn isAttributeOverridden(self: *Generator, interface: webidl.Interface, attr_name: []const u8) bool {
        _ = self;
        for (interface.attributes) |attribute| {
            if (std.mem.eql(u8, attribute.name, attr_name)) {
                return true;
            }
        }
        return false;
    }

    /// Check if we can generate delegation for a method (skip complex types)
    fn canGenerateMethod(self: *Generator, method: webidl.Method) bool {
        _ = self;

        // Check for union types (contains " or ")
        for (method.parameters) |param| {
            if (std.mem.indexOf(u8, param.type.name, " or ") != null) {
                return false; // Union type - too complex
            }
            // Check for callback types (EventListener, etc)
            if (std.mem.indexOf(u8, param.type.name, "Listener") != null or
                std.mem.indexOf(u8, param.type.name, "Callback") != null)
            {
                return false; // Callback type - too complex
            }
        }

        return true;
    }

    /// Check if a method has a custom override in overrides.json
    fn isCustomOverride(self: *Generator, interface_name: []const u8, method_name: []const u8) bool {
        if (self.overrides.get(interface_name)) |methods| {
            return methods.contains(method_name);
        }
        return false;
    }

    /// Get override reason from overrides.json
    fn getOverrideReason(self: *Generator, interface_name: []const u8, method_name: []const u8) ?[]const u8 {
        if (self.overrides.get(interface_name)) |methods| {
            return methods.get(method_name);
        }
        return null;
    }

    fn generateMethodDelegation(self: *Generator, method: webidl.Method, interface_name: []const u8, depth: usize, is_overridden: bool) !void {
        _ = is_overridden; // Reserved for future use
        const spec_url = try method.specUrl(interface_name, self.allocator);
        defer self.allocator.free(spec_url);

        const prototype_chain = try self.getPrototypeChain(depth);
        defer self.allocator.free(prototype_chain);

        // Write comprehensive documentation comment
        try self.getWriter().print(
            \\    /// {s}() - Delegated from {s} interface
            \\    ///
            \\    /// This method is inherited from the {s} interface and automatically
            \\    /// delegated to the prototype chain for spec compliance.
            \\    ///
            \\    /// **WebIDL Signature**:
            \\    /// ```webidl
            \\    /// {s} {s}(
        , .{ method.name, interface_name, interface_name, method.return_type.name, method.name });

        // Write WebIDL parameters
        for (method.parameters, 0..) |param, i| {
            if (i > 0) try self.getWriter().writeAll(", ");
            if (param.optional) try self.getWriter().writeAll("optional ");
            try self.getWriter().print("{s} {s}", .{ param.type.name, param.name });
        }
        try self.getWriter().writeAll(
            \\);
            \\    /// ```
            \\    ///
        );

        try self.getWriter().print(
            \\    /// **Specification**: {s}
            \\    ///
            \\    /// **Source**: `{s}` interface (depth: {d} in inheritance chain)
            \\    ///
            \\    /// *This is auto-generated delegation code. Do not edit manually.*
            \\
        , .{ spec_url, interface_name, depth });

        // Write method signature
        try self.getWriter().print("    pub inline fn {s}(self: anytype", .{method.name});

        // Write parameters
        for (method.parameters) |param| {
            const zig_param = try param.toZigParam(self.allocator);
            defer self.allocator.free(zig_param);
            try self.getWriter().print(", {s}", .{zig_param});
        }

        // Write return type
        const return_type = try method.return_type.toZigType(self.allocator);
        defer self.allocator.free(return_type);
        if (std.mem.eql(u8, return_type, "void")) {
            try self.getWriter().writeAll(") ");
        } else {
            try self.getWriter().print(") {s} ", .{return_type});
        }

        // For delegation, always use 'try' to be safe - propagates errors if any
        try self.getWriter().writeAll("{\n        ");
        if (!std.mem.eql(u8, return_type, "void")) {
            try self.getWriter().writeAll("return try ");
        } else {
            try self.getWriter().writeAll("try ");
        }

        // Write delegation call
        try self.getWriter().print("self.{s}.{s}(", .{ prototype_chain, method.name });

        // Pass parameters
        for (method.parameters, 0..) |param, i| {
            if (i > 0) try self.getWriter().writeAll(", ");
            try self.getWriter().print("{s}", .{param.name});
        }

        try self.getWriter().writeAll(");\n    }\n\n");
    }

    fn generateAttributeDelegation(self: *Generator, attribute: webidl.Attribute, interface_name: []const u8, depth: usize, is_overridden: bool) !void {
        _ = is_overridden; // Reserved for future use
        const spec_url = try attribute.specUrl(interface_name, self.allocator);
        defer self.allocator.free(spec_url);

        const prototype_chain = try self.getPrototypeChain(depth);
        defer self.allocator.free(prototype_chain);

        const zig_type = try attribute.type.toZigType(self.allocator);
        defer self.allocator.free(zig_type);

        // Generate getter with comprehensive documentation
        try self.getWriter().print(
            \\    /// {s}() - Getter for {s} attribute (delegated from {s} interface)
            \\    ///
            \\    /// This attribute is inherited from the {s} interface and automatically
            \\    /// delegated to the prototype chain for spec compliance.
            \\    ///
            \\    /// **WebIDL Signature**:
            \\    /// ```webidl
            \\    /// {s}attribute {s} {s};
            \\    /// ```
            \\    ///
            \\    /// **Specification**: {s}
            \\    ///
            \\    /// **Source**: `{s}` interface (depth: {d} in inheritance chain)
            \\    ///
            \\    /// *This is auto-generated delegation code. Do not edit manually.*
            \\    pub inline fn {s}(self: anytype) {s} {{
            \\        return self.{s}.{s};
            \\    }}
            \\
            \\
        , .{
            attribute.name,
            attribute.name,
            interface_name,
            interface_name,
            if (attribute.readonly) "readonly " else "",
            attribute.type.name,
            attribute.name,
            spec_url,
            interface_name,
            depth,
            attribute.name,
            zig_type,
            prototype_chain,
            attribute.name,
        });

        // Generate setter if not readonly (with comprehensive documentation)
        if (!attribute.readonly) {
            const capital_name = try self.capitalizeFirst(attribute.name);
            defer self.allocator.free(capital_name);

            try self.getWriter().print(
                \\    /// set{s}() - Setter for {s} attribute (delegated from {s} interface)
                \\    ///
                \\    /// This attribute setter is inherited from the {s} interface and automatically
                \\    /// delegated to the prototype chain for spec compliance.
                \\    ///
                \\    /// **WebIDL Signature**:
                \\    /// ```webidl
                \\    /// attribute {s} {s};
                \\    /// ```
                \\    ///
                \\    /// **Specification**: {s}
                \\    ///
                \\    /// **Source**: `{s}` interface (depth: {d} in inheritance chain)
                \\    ///
                \\    /// *This is auto-generated delegation code. Do not edit manually.*
                \\    pub inline fn set{s}(self: anytype, value: {s}) void {{
                \\        self.{s}.{s} = value;
                \\    }}
                \\
                \\
            , .{
                capital_name,
                attribute.name,
                interface_name,
                interface_name,
                attribute.type.name,
                attribute.name,
                spec_url,
                interface_name,
                depth,
                capital_name,
                zig_type,
                prototype_chain,
                attribute.name,
            });
        }
    }

    fn getPrototypeChain(self: *Generator, depth: usize) ![]const u8 {
        var chain = std.ArrayList(u8){};
        const writer = chain.writer(self.allocator);

        try writer.writeAll("prototype");

        var i: usize = 1;
        while (i < depth) : (i += 1) {
            try writer.writeAll(".prototype");
        }

        return chain.toOwnedSlice(self.allocator);
    }

    fn capitalizeFirst(self: *Generator, s: []const u8) ![]const u8 {
        if (s.len == 0) return try self.allocator.dupe(u8, s);

        var result = try self.allocator.alloc(u8, s.len);
        result[0] = std.ascii.toUpper(s[0]);
        @memcpy(result[1..], s[1..]);

        return result;
    }

    fn writeFooter(self: *Generator) !void {
        try self.getWriter().writeAll(
            \\    // ========================================================================
            \\    // END GENERATED CODE
            \\    // ========================================================================
            \\
        );
    }
};
