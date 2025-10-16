//! DOM - WHATWG DOM Core implementation in Zig
//!
//! This library provides a production-ready implementation of the WHATWG DOM
//! specification for use in headless browsers and JavaScript engines.
//!
//! ## Features
//! - WebKit-style reference counting with weak parent pointers
//! - Packed ref_count + has_parent in single u32 (saves 12 bytes/node)
//! - Vtable-based polymorphism for extensibility
//! - Target: ≤96 bytes per node
//!
//! ## Usage
//! ```zig
//! const dom = @import("dom");
//!
//! const node = try dom.Node.init(allocator, vtable, .element);
//! defer node.release();
//! ```

const std = @import("std");

// Export core node modules
pub const Node = @import("node.zig").Node;
pub const NodeType = @import("node.zig").NodeType;
pub const NodeVTable = @import("node.zig").NodeVTable;

// Export element modules
pub const Element = @import("element.zig").Element;
pub const BloomFilter = @import("element.zig").BloomFilter;
pub const AttributeMap = @import("element.zig").AttributeMap;

// Export text and comment modules
pub const Text = @import("text.zig").Text;
pub const Comment = @import("comment.zig").Comment;

// Export document modules
pub const Document = @import("document.zig").Document;
pub const StringPool = @import("document.zig").StringPool;
pub const DocumentFragment = @import("document_fragment.zig").DocumentFragment;

// Export rare data modules
pub const NodeRareData = @import("rare_data.zig").NodeRareData;
pub const EventListener = @import("rare_data.zig").EventListener;
pub const MutationObserver = @import("rare_data.zig").MutationObserver;
pub const EventCallback = @import("rare_data.zig").EventCallback;
pub const MutationCallback = @import("rare_data.zig").MutationCallback;

// Export NodeList collection
pub const NodeList = @import("node_list.zig").NodeList;

// Export validation and helpers (internal)
pub const validation = @import("validation.zig");
pub const tree_helpers = @import("tree_helpers.zig");

test {
    // Run tests from all modules
    std.testing.refAllDecls(@This());
    _ = @import("node.zig");
    _ = @import("element.zig");
    _ = @import("text.zig");
    _ = @import("comment.zig");
    _ = @import("document.zig");
    _ = @import("document_fragment.zig");
    _ = @import("rare_data.zig");
    _ = @import("node_list.zig");
    _ = @import("validation.zig");
    _ = @import("tree_helpers.zig");
}
