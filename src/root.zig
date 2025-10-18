//! DOM - WHATWG DOM Core Implementation in Zig
//!
//! Production-ready implementation of the WHATWG DOM Standard for headless browsers,
//! JavaScript engines, and server-side rendering. Provides complete DOM Core functionality
//! with WebKit-inspired optimizations for memory efficiency and performance.
//!
//! ## WHATWG Specification
//!
//! This library implements:
//! - **WHATWG DOM Standard**: https://dom.spec.whatwg.org/
//! - **§4 Nodes**: https://dom.spec.whatwg.org/#nodes
//! - **§2 Events**: https://dom.spec.whatwg.org/#events
//! - **§3 Aborting**: https://dom.spec.whatwg.org/#aborting-ongoing-activities
//!
//! ## Features
//!
//! ### Core DOM
//! - **Node tree structure** with parent/child/sibling relationships
//! - **Element nodes** with attributes and class management
//! - **Text and Comment** nodes for content
//! - **Document** with factory methods and string interning
//! - **DocumentFragment** for efficient batch operations
//!
//! ### Events
//! - **EventTarget** mixin for addEventListener/removeEventListener
//! - **Event** with capture/bubble phases and propagation control
//! - **Event flow** algorithm per WHATWG (capture → target → bubble)
//!
//! ### Cancellation
//! - **AbortSignal** for operation cancellation
//! - **AbortController** for signal management
//! - Integration with addEventListener (signal option)
//!
//! ### Memory Optimizations
//! - **Reference counting** with acquire/release semantics
//! - **RareData pattern** saves 40-50% memory on typical DOMs
//! - **String interning** via Document.string_pool
//! - **Target: ≤96 bytes per Node** (achieved!)
//! - **Bloom filters** for fast class matching
//!
//! ## Quick Start
//!
//! ### Creating a DOM Tree
//! ```zig
//! const std = @import("std");
//! const dom = @import("dom");
//!
//! pub fn main() !void {
//!     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//!     defer _ = gpa.deinit();
//!     const allocator = gpa.allocator();
//!
//!     // Create document
//!     const doc = try dom.Document.init(allocator);
//!     defer doc.release();
//!
//!     // Build DOM tree
//!     const html = try doc.createElement("html");
//!     _ = try doc.prototype.appendChild(&html.prototype);
//!
//!     const body = try doc.createElement("body");
//!     _ = try html.prototype.appendChild(&body.prototype);
//!
//!     const div = try doc.createElement("div");
//!     try div.setAttribute("class", "container");
//!     _ = try body.prototype.appendChild(&div.prototype);
//!
//!     const text = try doc.createTextNode("Hello, World!");
//!     _ = try div.prototype.appendChild(&text.prototype);
//! }
//! ```
//!
//! ### Event Handling
//! ```zig
//! fn handleClick(event: *dom.Event, context: *anyopaque) void {
//!     _ = context;
//!     std.debug.print("Clicked!\n", .{});
//!     event.preventDefault();
//! }
//!
//! const button = try doc.createElement("button");
//! try button.prototype.addEventListener("click", handleClick, null, .{});
//!
//! var event = dom.Event.init("click", .{ .bubbles = true, .cancelable = true, .composed = false });
//! _ = try button.prototype.dispatchEvent(&event);
//! ```
//!
//! ### Cancellation
//! ```zig
//! const controller = try dom.AbortController.init(allocator);
//! defer controller.deinit();
//!
//! // Pass signal to operation
//! try fetchData(url, controller.signal);
//!
//! // Cancel operation
//! try controller.abort(null);
//! ```
//!
//! ## Library Organization
//!
//! ### Core Types
//! - `Node` - Base node type with tree structure
//! - `Element` - Element nodes with attributes
//! - `Text` - Text content nodes
//! - `Comment` - Comment nodes
//! - `Document` - Document root with factory methods
//! - `DocumentFragment` - Lightweight container
//!
//! ### Collections
//! - `NodeList` - Live collection of nodes
//! - `ElementCollection` - Live collection of elements (excludes text/comment nodes)
//! - `AttributeMap` - Element attribute storage
//! - `StringPool` - String interning for memory savings
//!
//! ### Events
//! - `Event` - Event object with phases and propagation
//! - `EventTarget` - Mixin for event handling
//! - `EventListener` - Listener registration
//!
//! ### Cancellation
//! - `AbortSignal` - Signal for operation cancellation
//! - `AbortController` - Controller for signals
//!
//! ### Utilities
//! - `validation` - Tree mutation validation
//! - `tree_helpers` - Tree traversal utilities
//! - `selector.Tokenizer` - CSS selector tokenization
//!
//! ## Performance Characteristics
//!
//! ### Memory
//! - Node: 96 bytes (target achieved)
//! - Element: Node + 32 bytes
//! - Text/Comment: Node + 16 bytes
//! - Document: Node + string pool
//! - RareData: Allocated only when needed (40-50% savings)
//!
//! ### Time Complexity
//! - appendChild/removeChild: O(1)
//! - NodeList.length(): O(n)
//! - NodeList.item(): O(n)
//! - getAttribute/setAttribute: O(1) amortized
//! - String interning: O(1) amortized
//!
//! ## Thread Safety
//!
//! This library is **not thread-safe** by default. Use external synchronization
//! if accessing DOM from multiple threads.
//!
//! ## Testing
//!
//! ```bash
//! # Run all tests
//! zig build test
//!
//! # Run with memory leak detection
//! zig build test --summary all
//!
//! # Run specific test file
//! zig test src/node.zig
//! ```
//!
//! ## Documentation
//!
//! Each module contains comprehensive documentation including:
//! - WHATWG specification references
//! - MDN documentation links
//! - Complete usage examples
//! - Common patterns
//! - Performance tips
//! - Implementation notes

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

// Export collections
pub const NodeList = @import("node_list.zig").NodeList;
pub const HTMLCollection = @import("html_collection.zig").HTMLCollection;

// Export AbortSignal and AbortController
pub const AbortSignal = @import("abort_signal.zig").AbortSignal;
pub const AbortController = @import("abort_controller.zig").AbortController;
pub const AbortAlgorithm = @import("abort_signal.zig").AbortAlgorithm;
pub const SignalRareData = @import("abort_signal_rare_data.zig").SignalRareData;

// Export validation and helpers (internal)
pub const validation = @import("validation.zig");
pub const tree_helpers = @import("tree_helpers.zig");

// Export selector module (Phase 4 - querySelector)
pub const selector = struct {
    pub const Tokenizer = @import("selector/tokenizer.zig").Tokenizer;
    pub const Token = @import("selector/tokenizer.zig").Token;
    pub const Parser = @import("selector/parser.zig").Parser;
    pub const Matcher = @import("selector/matcher.zig").Matcher;
    pub const SelectorList = @import("selector/parser.zig").SelectorList;
    pub const ComplexSelector = @import("selector/parser.zig").ComplexSelector;
    pub const CompoundSelector = @import("selector/parser.zig").CompoundSelector;
    pub const SimpleSelector = @import("selector/parser.zig").SimpleSelector;
    pub const Combinator = @import("selector/parser.zig").Combinator;
};

// Export fast path optimization modules
pub const FastPathType = @import("fast_path.zig").FastPathType;
pub const detectFastPath = @import("fast_path.zig").detectFastPath;
pub const extractIdentifier = @import("fast_path.zig").extractIdentifier;
pub const ElementIterator = @import("element_iterator.zig").ElementIterator;

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
    _ = @import("html_collection.zig");
    _ = @import("validation.zig");
    _ = @import("tree_helpers.zig");
    _ = @import("abort_signal.zig");
    _ = @import("abort_signal_test.zig");
    _ = @import("abort_controller.zig");
    _ = @import("abort_signal_rare_data.zig");
    // Phase 4 - querySelector
    _ = @import("selector/tokenizer.zig");
    _ = @import("selector/parser.zig");
    _ = @import("selector/matcher.zig");
    _ = @import("query_selector_test.zig");
    // Fast path optimizations
    _ = @import("fast_path.zig");
    _ = @import("element_iterator.zig");
    // Phase 2 verification tests
    _ = @import("getElementsByTagName_test.zig");

    // Shadow DOM tests
    _ = @import("slot_test.zig");
}
