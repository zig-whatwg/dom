//! DOM Standard Library Root
//!
//! This module serves as the root import for the DOM Standard implementation.
//! It re-exports all public interfaces defined by the WHATWG DOM specification.
//!
//! ## WHATWG DOM Standard
//!
//! This library implements the DOM Standard as specified by WHATWG:
//! https://dom.spec.whatwg.org/
//!
//! ## Core Interfaces
//!
//! ### Events (§2)
//! - **Event**: Base event interface
//! - **EventTarget**: Event dispatch and listening
//! - **CustomEvent**: Events with custom data payload
//!
//! ### Aborting (§3)
//! - **AbortController**: Control for aborting operations
//! - **AbortSignal**: Signal for abort notifications
//! - **AbortError**: Error type for aborted operations
//!
//! ### Ranges (§5)
//! - **Range**: Fragment selection and manipulation
//! - **RangeError**: Error type for range operations
//!
//! ### Traversal (§6)
//! - **NodeFilter**: Filter interface for tree traversal
//! - **TreeWalker**: Bi-directional tree navigation with filtering
//! - **NodeIterator**: Forward-only tree iteration with filtering
//!
//! ### Nodes (§4)
//! - **Node**: Base node interface (abstract)
//! - **Document**: Document root
//! - **DocumentFragment**: Lightweight document for batch operations
//! - **DocumentType**: DOCTYPE declarations
//! - **Element**: Element nodes
//! - **CharacterData**: Character data (abstract)
//! - **Text**: Text nodes
//! - **Comment**: Comment nodes
//! - **ProcessingInstruction**: Processing instruction nodes
//!
//! ### Collections (§4.2.10, §4.9.1)
//! - **NodeList**: Node collections
//! - **NamedNodeMap**: Attribute collections
//! - **DOMTokenList**: Token sets (classList)
//!
//! ### Utilities
//! - **RefCounted**: Reference counting
//! - **Selector**: CSS selector matching
//!
//! ## Usage Example
//!
//! ```zig
//! const dom = @import("dom");
//!
//! // Create a document
//! const doc = try dom.Document.init(allocator);
//! defer doc.release();
//!
//! // Create an element
//! const elem = try dom.Element.init(allocator, "div");
//! defer elem.release();
//!
//! // Work with text
//! const text = try dom.Text.init(allocator, "Hello World");
//! defer text.release();
//!
//! // Event handling
//! var target = dom.EventTarget.init(allocator);
//! defer target.deinit();
//! ```
//!
//! ## Project Structure
//!
//! ```
//! src/
//!   ├── root.zig          (this file - exports)
//!   ├── event.zig         (Event interface)
//!   ├── event_target.zig  (EventTarget interface)
//!   ├── node.zig          (Node base)
//!   ├── document.zig      (Document)
//!   ├── element.zig       (Element)
//!   ├── character_data.zig (CharacterData base)
//!   ├── text.zig          (Text nodes)
//!   ├── comment.zig       (Comment nodes)
//!   ├── node_list.zig     (NodeList collection)
//!   ├── named_node_map.zig (Attribute map)
//!   ├── dom_token_list.zig (Token list)
//!   ├── selector.zig      (CSS selectors)
//!   └── ref_counted.zig   (Reference counting)
//! ```
//!
//! ## Memory Management
//!
//! All DOM objects use manual memory management:
//! - Call `release()` or `deinit()` when done
//! - Use `defer` for automatic cleanup
//! - Reference counting used internally for nodes
//!
//! ## Specification Compliance
//!
//! This implementation aims for high compliance with the WHATWG DOM Standard.
//! Each module includes references to relevant specification sections.

const std = @import("std");

// Utilities
pub const RefCounted = @import("ref_counted.zig").RefCounted;

// Events (§2)
pub const Event = @import("event.zig").Event;
pub const EventTarget = @import("event_target.zig").EventTarget;
pub const CustomEvent = @import("custom_event.zig").CustomEvent;
pub const CustomEventOptions = @import("custom_event.zig").CustomEventOptions;

// Aborting (§3)
pub const AbortController = @import("abort_controller.zig").AbortController;
pub const AbortSignal = @import("abort_signal.zig").AbortSignal;
pub const AbortError = @import("abort_signal.zig").AbortError;

// Nodes (§4)
pub const Node = @import("node.zig").Node;
pub const CharacterData = @import("character_data.zig").CharacterData;
pub const Text = @import("text.zig").Text;
pub const Comment = @import("comment.zig").Comment;
pub const Element = @import("element.zig").Element;
pub const Document = @import("document.zig").Document;
pub const DocumentFragment = @import("document_fragment.zig").DocumentFragment;
pub const DocumentType = @import("document_type.zig").DocumentType;
pub const ProcessingInstruction = @import("processing_instruction.zig").ProcessingInstruction;
pub const DOMImplementation = @import("dom_implementation.zig").DOMImplementation;
pub const DOMImplementationError = @import("dom_implementation.zig").DOMImplementationError;

// Mixins (§4.2)
pub const ChildNode = @import("child_node.zig").ChildNode;
pub const ParentNode = @import("parent_node.zig").ParentNode;

// Collections
pub const DOMTokenList = @import("dom_token_list.zig").DOMTokenList;
pub const NamedNodeMap = @import("named_node_map.zig").NamedNodeMap;
pub const NodeList = @import("node_list.zig").NodeList;

// Selectors
pub const Selector = @import("selector.zig").Selector;

// Ranges (§5)
pub const Range = @import("range.zig").Range;
pub const RangeError = @import("range.zig").RangeError;
pub const StaticRange = @import("static_range.zig").StaticRange;
pub const START_TO_START = @import("range.zig").START_TO_START;
pub const START_TO_END = @import("range.zig").START_TO_END;
pub const END_TO_END = @import("range.zig").END_TO_END;
pub const END_TO_START = @import("range.zig").END_TO_START;

// Traversal (§6)
pub const NodeFilter = @import("node_filter.zig");
pub const TreeWalker = @import("tree_walker.zig").TreeWalker;
pub const NodeIterator = @import("node_iterator.zig").NodeIterator;

// Mutation Observation (§4.3)
pub const MutationObserver = @import("mutation_observer.zig").MutationObserver;
pub const MutationObserverInit = @import("mutation_observer.zig").MutationObserverInit;
pub const MutationRecord = @import("mutation_record.zig").MutationRecord;

// Test that all declarations are properly referenced.
// This ensures no public API is accidentally broken.
test {
    std.testing.refAllDecls(@This());
}

test "root module imports" {
    // Verify all types are accessible
    _ = RefCounted(i32);
    _ = Event;
    _ = EventTarget;
    _ = CustomEvent;
    _ = CustomEventOptions;
    _ = AbortController;
    _ = AbortSignal;
    _ = AbortError;
    _ = Node;
    _ = CharacterData;
    _ = Text;
    _ = Comment;
    _ = Element;
    _ = Document;
    _ = DocumentFragment;
    _ = DocumentType;
    _ = ProcessingInstruction;
    _ = DOMImplementation;
    _ = DOMImplementationError;
    _ = ChildNode;
    _ = ParentNode;
    _ = DOMTokenList;
    _ = NamedNodeMap;
    _ = NodeList;
    _ = Selector;
    _ = Range;
    _ = RangeError;
    _ = StaticRange;
    _ = NodeFilter;
    _ = TreeWalker;
    _ = NodeIterator;
    _ = MutationObserver;
    _ = MutationObserverInit;
    _ = MutationRecord;
}
