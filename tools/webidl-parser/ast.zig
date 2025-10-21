//! Abstract Syntax Tree types for WebIDL
//!
//! Represents parsed WebIDL interfaces, methods, and attributes.

const std = @import("std");
const Allocator = std.mem.Allocator;

/// WebIDL type
pub const Type = struct {
    name: []const u8,
    nullable: bool = false,
    is_sequence: bool = false,
    is_promise: bool = false,

    pub fn fromString(allocator: Allocator, type_str: []const u8) !Type {
        var t = Type{
            .name = type_str,
            .nullable = false,
            .is_sequence = false,
            .is_promise = false,
        };

        // Parse nullable (Type?)
        if (std.mem.endsWith(u8, type_str, "?")) {
            t.nullable = true;
            t.name = try allocator.dupe(u8, type_str[0 .. type_str.len - 1]);
        }

        // Parse sequence (sequence<Type>)
        if (std.mem.startsWith(u8, type_str, "sequence<")) {
            t.is_sequence = true;
            const inner_start = "sequence<".len;
            const inner_end = type_str.len - 1; // Remove >
            t.name = try allocator.dupe(u8, type_str[inner_start..inner_end]);
        }

        return t;
    }

    /// Convert WebIDL type to Zig type
    pub fn toZigType(self: Type, allocator: Allocator) ![]const u8 {
        // Map WebIDL types to Zig types
        const base_type = if (std.mem.eql(u8, self.name, "DOMString"))
            "[]const u8"
        else if (std.mem.eql(u8, self.name, "boolean"))
            "bool"
        else if (std.mem.eql(u8, self.name, "undefined"))
            "void"
        else if (std.mem.eql(u8, self.name, "unsigned long"))
            "u32"
        else if (std.mem.eql(u8, self.name, "unsigned short"))
            "u16"
        else if (std.mem.eql(u8, self.name, "long"))
            "i32"
        else if (std.mem.eql(u8, self.name, "double"))
            "f64"
        else if (std.mem.eql(u8, self.name, "float"))
            "f32"
        else if (std.mem.eql(u8, self.name, "any"))
            "anytype"
        else
            self.name; // Assume it's a DOM type (Node, Element, etc)

        // Add pointer for DOM types
        const needs_ptr = !std.mem.eql(u8, base_type, "bool") and
            !std.mem.eql(u8, base_type, "void") and
            !std.mem.eql(u8, base_type, "[]const u8") and
            !std.mem.startsWith(u8, base_type, "u") and
            !std.mem.startsWith(u8, base_type, "i") and
            !std.mem.startsWith(u8, base_type, "f");

        if (self.nullable) {
            if (needs_ptr) {
                return std.fmt.allocPrint(allocator, "?*{s}", .{base_type});
            } else {
                return std.fmt.allocPrint(allocator, "?{s}", .{base_type});
            }
        } else {
            if (needs_ptr) {
                return std.fmt.allocPrint(allocator, "*{s}", .{base_type});
            } else {
                return allocator.dupe(u8, base_type);
            }
        }
    }
};

/// Method parameter
pub const Parameter = struct {
    name: []const u8,
    type: Type,
    optional: bool = false,
    variadic: bool = false,

    pub fn toZigParam(self: Parameter, allocator: Allocator) ![]const u8 {
        const zig_type = try self.type.toZigType(allocator);
        defer allocator.free(zig_type);
        return try std.fmt.allocPrint(allocator, "{s}: {s}", .{ self.name, zig_type });
    }
};

/// WebIDL method/operation
pub const Method = struct {
    name: []const u8,
    return_type: Type,
    parameters: []Parameter,
    is_static: bool = false,

    /// Spec URL for this method
    pub fn specUrl(self: Method, interface_name: []const u8, allocator: Allocator) ![]const u8 {
        // Convert to lowercase and create spec URL
        const lower_name = try std.ascii.allocLowerString(allocator, self.name);
        defer allocator.free(lower_name);

        const lower_interface = try std.ascii.allocLowerString(allocator, interface_name);
        defer allocator.free(lower_interface);

        return try std.fmt.allocPrint(allocator, "https://dom.spec.whatwg.org/#dom-{s}-{s}", .{ lower_interface, lower_name });
    }
};

/// WebIDL attribute
pub const Attribute = struct {
    name: []const u8,
    type: Type,
    readonly: bool = false,

    /// Spec URL for this attribute
    pub fn specUrl(self: Attribute, interface_name: []const u8, allocator: Allocator) ![]const u8 {
        const lower_name = try std.ascii.allocLowerString(allocator, self.name);
        defer allocator.free(lower_name);

        const lower_interface = try std.ascii.allocLowerString(allocator, interface_name);
        defer allocator.free(lower_interface);

        return try std.fmt.allocPrint(allocator, "https://dom.spec.whatwg.org/#dom-{s}-{s}", .{ lower_interface, lower_name });
    }
};

/// WebIDL interface
pub const Interface = struct {
    name: []const u8,
    parent: ?[]const u8,
    methods: []Method,
    attributes: []Attribute,

    /// Get all ancestors in order (nearest to furthest)
    pub fn getAncestors(self: Interface, interfaces: std.StringHashMap(Interface), allocator: Allocator) ![][]const u8 {
        var ancestors = std.ArrayList([]const u8){};

        var current_parent = self.parent;
        while (current_parent) |parent_name| {
            try ancestors.append(allocator, parent_name);

            if (interfaces.get(parent_name)) |parent_iface| {
                current_parent = parent_iface.parent;
            } else {
                break;
            }
        }

        return ancestors.toOwnedSlice(allocator);
    }

    /// Get depth of inheritance (0 = no parent, 1 = has parent, 2 = has grandparent, etc)
    pub fn inheritanceDepth(self: Interface, interfaces: std.StringHashMap(Interface)) usize {
        var depth: usize = 0;
        var current_parent = self.parent;

        while (current_parent) |parent_name| {
            depth += 1;
            if (interfaces.get(parent_name)) |parent_iface| {
                current_parent = parent_iface.parent;
            } else {
                break;
            }
        }

        return depth;
    }
};

/// Parsed WebIDL document
pub const Document = struct {
    interfaces: std.StringHashMap(Interface),
    allocator: Allocator,

    pub fn init(allocator: Allocator) Document {
        return .{
            .interfaces = std.StringHashMap(Interface).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Document) void {
        self.interfaces.deinit();
    }

    /// Get interface by name
    pub fn getInterface(self: *Document, name: []const u8) ?Interface {
        return self.interfaces.get(name);
    }

    /// Add interface to document
    pub fn addInterface(self: *Document, interface: Interface) !void {
        try self.interfaces.put(interface.name, interface);
    }
};
