# DOM - WHATWG DOM Standard Implementation in Zig

[![Zig](https://img.shields.io/badge/zig-0.15.1-orange.svg)](https://ziglang.org/)
[![Tests](https://img.shields.io/badge/tests-5,528%2B%20passing-brightgreen.svg)]()
[![Security](https://img.shields.io/badge/security-hardened-brightgreen.svg)](SECURITY_IMPLEMENTATION_COMPLETE.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Coverage](https://img.shields.io/badge/coverage-~95%25-brightgreen.svg)]()

A complete, production-ready implementation of the [WHATWG DOM Living Standard](https://dom.spec.whatwg.org/) in Zig, with ~95% spec coverage for non-XML features and comprehensive CSS4 selector support.

**Sponsored by [DockYard, Inc.](https://dockyard.com)** - DockYard supports open source software development and the advancement of web standards.

## Features

- ✅ **Spec Compliant** - Follows WHATWG DOM Living Standard (~95% coverage)
- ✅ **Memory Safe** - Zero memory leaks across 5,528+ tests
- ✅ **Production Hardened** - Comprehensive security protections against DoS, cycles, and resource exhaustion
- ✅ **Comprehensive** - All non-XML DOM features implemented
- ✅ **CSS4 Selectors** - Production-ready CSS3/CSS4 selector engine with ReDoS protection
- ✅ **Well Tested** - 5,528+ passing tests with comprehensive coverage
- ✅ **Well Documented** - Inline docs with spec references
- ✅ **Production Ready** - Clean APIs, robust error handling, battle-tested security

## Quick Start

Add to your `build.zig.zon`:
```zig
.dependencies = .{
    .dom = .{
        .url = "https://github.com/liveviewnative/dom/archive/main.tar.gz",
        .hash = "...",
    },
},
```

### Basic Usage

```zig
const std = @import("std");
const dom = @import("dom");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a document
    const doc = try dom.Document.init(allocator);
    defer doc.release();

    // Create an element
    const div = try dom.Element.create(allocator, "div");
    defer div.release();
    
    try dom.Element.setAttribute(div, "id", "my-div");
    try dom.Element.addClass(div, "container");

    // Create text
    const text = try dom.Text.init(allocator, "Hello, DOM!");
    defer text.release();

    // Build tree
    _ = try div.appendChild(text.character_data.node);
    _ = try doc.node.appendChild(div);

    // Query with CSS selectors
    const found = try dom.selector.querySelector(doc.node, "div.container");
    std.debug.print("Found: {}\n", .{found != null});
}
```

## Security

🟢 **Production Ready** - This implementation includes comprehensive security hardening for adversarial environments.

### Security Features

- ✅ **Cycle Detection** - Prevents circular DOM structures causing memory leaks
- ✅ **Recursion Depth Limits** - Stack overflow protection (1,000 level limit)
- ✅ **Reference Count Protection** - Overflow/underflow detection with panics
- ✅ **Resource Quotas** - Per-document node limits (100,000 nodes default)
- ✅ **Width Limits** - Children per node (10,000), attributes per element (1,000), listeners per target (1,000)
- ✅ **Input Validation** - XML naming validation, length limits, control character rejection
- ✅ **ReDoS Protection** - Selector complexity limits (10KB, 10 nesting levels, 20 parts)
- ✅ **Mutation Observer Limits** - Queue size limits with FIFO eviction (10,000 records)
- ✅ **Security Event Logging** - Comprehensive monitoring infrastructure

### Quick Security Setup

```zig
const std = @import("std");
const dom = @import("dom");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Optional: Set up security event logging
    dom.Node.security_event_callback = mySecurityLogger;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    // All operations now have automatic security checks:
    // - Cycle detection on appendChild/insertBefore/replaceChild
    // - Depth limits on cloneNode/normalize/querySelectorAll
    // - Input validation on createElement/setAttribute
    // - Resource quotas on node creation
}

fn mySecurityLogger(event: dom.Node.SecurityEvent) void {
    std.debug.print("[SECURITY] {s}: {s}\n", .{@tagName(event.event_type), event.message});
}
```

### Configuration

All security limits are configurable in `src/node.zig`:

```zig
pub const SecurityLimits = struct {
    pub const max_tree_depth: usize = 1000;
    pub const max_children_per_node: usize = 10_000;
    pub const max_nodes_per_document: usize = 100_000;
    pub const max_attributes_per_element: usize = 1_000;
    pub const max_listeners_per_target: usize = 1_000;
    pub const max_tag_name_length: usize = 256;
    pub const max_attribute_name_length: usize = 256;
    pub const max_attribute_value_length: usize = 65536;  // 64KB
    pub const max_selector_length: usize = 10240;         // 10KB
    pub const max_selector_nesting: usize = 10;
    pub const max_selector_parts: usize = 20;
};
```

### Breaking Changes

This version introduces new error types for security violations. Applications **must** handle:

```zig
// New SecurityError types
SecurityError.TooManyChildren        // Exceeded max_children_per_node
SecurityError.TooManyNodes           // Exceeded max_nodes_per_document
SecurityError.TooManyAttributes      // Exceeded max_attributes_per_element
SecurityError.TooManyListeners       // Exceeded max_listeners_per_target
SecurityError.CircularReferenceDetected  // Cycle detected
SecurityError.MaxTreeDepthExceeded   // Recursion limit hit

// Validation errors
DOMError.InvalidCharacterError       // Invalid XML name
DOMError.InvalidStateError           // Empty tag/attribute name
DOMError.SyntaxError                 // Malformed selector
```

**Migration Guide:**

```zig
// Before (v1.0):
const elem = try dom.Element.create(allocator, "");  // Was accepted

// After (v1.1+):
const elem = try dom.Element.create(allocator, "");  // Returns InvalidStateError

// Handle errors:
const elem = dom.Element.create(allocator, tagName) catch |err| switch (err) {
    error.TooManyNodes => {
        // Handle quota exceeded
        return error.ResourceExhausted;
    },
    error.InvalidCharacterError => {
        // Handle invalid tag name
        return error.InvalidInput;
    },
    else => return err,
};
```

### Security Documentation

For comprehensive security information, see:
- [SECURITY_IMPLEMENTATION_COMPLETE.md](SECURITY_IMPLEMENTATION_COMPLETE.md) - Complete security implementation summary
- [CHANGELOG.md](CHANGELOG.md) - Version 1.1.0 security improvements and breaking changes

### Security Status

**Risk Level:** 🟢 **LOW** (Production Ready)

- 12 vulnerabilities fixed (3 critical, 5 high, 4 medium)
- 732/732 tests passing (100%)
- Zero memory leaks
- Ready for adversarial environments
- 8 remaining "very low" severity edge cases (all acceptable)

## CSS Selector Engine

This implementation includes a **production-ready CSS3/CSS4 selector engine** with comprehensive feature support:

### Fully Supported Features ✅

**CSS Level 1-2:**
- Type selectors: `div`, `p`, `span`
- Class selectors: `.class`, `.multiple.classes`
- ID selectors: `#id`
- Universal selector: `*`
- Attribute selectors: `[attr]`, `[attr="value"]`
- Descendant combinator: `div p`
- Child combinator: `div > p`

**CSS Level 3:**
- Adjacent sibling: `h1 + p`
- General sibling: `h1 ~ p`
- Attribute operators: `[attr^="val"]`, `[attr$="val"]`, `[attr*="val"]`, `[attr~="val"]`, `[attr|="val"]`
- Structural pseudo-classes: `:first-child`, `:last-child`, `:only-child`, `:nth-child(n)`, `:nth-of-type(n)`
- Negation: `:not(.class)`, `:not([attr])` - supports complex selectors recursively
- Other pseudo-classes: `:empty`, `:root`, `:first-of-type`, `:last-of-type`, `:only-of-type`
- Form pseudo-classes: `:enabled`, `:disabled`, `:checked`, `:required`, `:optional`

**CSS Level 4:**
- Case-insensitive attributes: `[attr="value" i]`
- `:is()` pseudo-class: `:is(h1, h2, h3)`
- `:where()` pseudo-class: `:where(.class1, .class2)`
- `:has()` pseudo-class: `div:has(> p)` (relational selectors)
- Link pseudo-classes: `:any-link`, `:link`, `:visited`, `:local-link`
- User action pseudo-classes: `:hover`, `:active`, `:focus`, `:target`
- `:focus-visible` - Keyboard focus indication
- `:defined` - Defined custom elements
- Form enhancements: `:read-write`, `:read-only`, `:placeholder-shown`, `:default`, `:valid`, `:invalid`, `:in-range`, `:out-of-range`
- Language pseudo-class: `:lang(en)`, `:lang(en-US)` with prefix matching
- Multiple selector lists: `:not(div, span)`, `:is(.class1, .class2, .class3)`

**Pseudo-Elements:**
- `::before`, `::after`, `::first-line`, `::first-letter`
- Legacy single-colon syntax: `:before`, `:after`, `:first-line`, `:first-letter`

**Complex Selectors:**
- Compound selectors: `div.class#id[attr]:not(.other)`
- Chained pseudo-classes: `:first-child:not(.special):enabled`
- Multi-combinator: `#main > article.featured + article ~ .widget`

### Examples

```zig
// Simple selectors
const elem = try querySelector(root, "div.container");
const links = try querySelectorAll(root, "a[href^='https://']");

// Structural pseudo-classes
const firstPara = try querySelector(root, "article > p:first-child");
const oddItems = try querySelectorAll(root, "li:nth-child(odd)");

// Complex selectors with :not()
const items = try querySelectorAll(root, ".widget:not(.special)");
const paras = try querySelectorAll(root, "p:first-child:not(.intro)");

// CSS4 features
const navs = try querySelectorAll(root, "[data-type='NAVIGATION' i]");
const headers = try querySelectorAll(root, ":is(h1, h2, h3).title");
const containers = try querySelectorAll(root, "div:has(> .important)");

// Link and user action pseudo-classes
const unvisitedLinks = try querySelectorAll(root, "a:link");
const hoveredButtons = try querySelectorAll(root, "button:hover");
const focusedInputs = try querySelectorAll(root, "input:focus");

// Form pseudo-classes
const requiredInputs = try querySelectorAll(root, "input:required:invalid");
const optionalFields = try querySelectorAll(root, ":read-write:optional");
const validForm = try querySelector(root, "form:has(:invalid)");

// Language matching
const frenchContent = try querySelectorAll(root, ":lang(fr)");
const enUsContent = try querySelectorAll(root, "p:lang(en-US)");
```

See `examples/query_selectors_demo.zig` for 30+ working examples!

### Performance

The selector engine is optimized for production use:
- Single-pass parsing with minimal allocations
- Efficient matching with early exit conditions
- Compound selector support without backtracking
- Recursive `:not()`, `:is()`, `:where()`, and `:has()` matching
- Smart caching for complex queries
- ReDoS protection with complexity limits

**Benchmark Results** (vs. browser JavaScript engines):
- CSS selectors: 2-10x faster
- Element creation: 2-3x faster
- Batch operations: 10-70x faster
- Zero memory overhead from JS engine/GC

See [PERFORMANCE_ANALYSIS.md](PERFORMANCE_ANALYSIS.md) for detailed benchmarks.

## API Documentation

### Core Concepts

#### Memory Management

The library uses two cleanup patterns:

1. **Reference Counted Objects** (Node-based):
   ```zig
   const doc = try dom.Document.init(allocator);
   defer doc.release();  // Decrements ref count
   ```

2. **Simple Objects**:
   ```zig
   const range = try dom.Range.init(allocator);
   defer range.deinit();  // Direct cleanup
   ```

#### Error Handling

All operations that can fail return Zig errors:

```zig
const node = try element.appendChild(child);  // Returns *Node or error
try dom.Element.setAttribute(elem, "id", "test");  // Can throw InvalidCharacterError
```

### Event System

Events support bubbling and capturing phases:

```zig
// Add capturing listener
try target.addEventListener("click", handler, .{ .capture = true });

// Add bubbling listener (default)
try target.addEventListener("click", handler, .{});

// Dispatch event
const event = try dom.Event.init(allocator, "custom", .{
    .bubbles = true,
    .cancelable = true,
});
defer event.deinit();

const not_cancelled = try target.dispatchEvent(event);
```

### Node Tree Operations

```zig
// Insert nodes
_ = try parent.appendChild(child);
_ = try parent.insertBefore(new_child, reference_child);

// Remove nodes
_ = try parent.removeChild(child);
child.remove();  // Remove from parent

// Replace nodes
_ = try parent.replaceChild(new_child, old_child);
```

### Element Operations

```zig
// Attributes
try dom.Element.setAttribute(elem, "class", "active");
const value = dom.Element.getAttribute(elem, "id");
try dom.Element.removeAttribute(elem, "disabled");
const has = dom.Element.hasAttribute(elem, "required");

// Class list
try dom.Element.addClass(elem, "highlight");
try dom.Element.removeClass(elem, "hidden");
try dom.Element.toggleClass(elem, "active");
const has_class = dom.Element.hasClass(elem, "container");

// Queries (CSS3/CSS4 selectors)
const elem = dom.Element.getElementById(doc.node, "my-id");
const first = try dom.selector.querySelector(root, "div.class:not(.disabled)");
const all = try dom.selector.querySelectorAll(root, "p:is(.intro, .summary)");
```

## Features Overview

### Events (§2)

```zig
// Event handling
var target = try dom.EventTarget.init(allocator);
defer target.deinit();

const listener = try target.addEventListener("click", callback);

// Custom events with data
const event = try dom.CustomEvent.init(allocator, "custom", .{
    .detail = .{ .count = 42 },
});
defer event.deinit();
```

**Implemented:**
- `Event` - Base event interface with bubbling/capturing
- `EventTarget` - Event dispatch and listener management
- `CustomEvent` - Events with custom data payloads

### Aborting Operations (§3)

```zig
// Abort controller for async operations
const controller = try dom.AbortController.init(allocator);
defer controller.deinit();

// Pass signal to operations
try fetchData(controller.signal);

// Abort when needed
controller.abort();
```

**Implemented:**
- `AbortController` - Control ongoing operations
- `AbortSignal` - Signal for abort notifications
  - Static methods: `AbortSignal.abort()`, `AbortSignal.timeout()`, `AbortSignal.any()`

### Nodes (§4)

```zig
// Create document
const doc = try dom.Document.init(allocator);
defer doc.release();

// Create elements
const html = try dom.Element.create(allocator, "html");
const body = try dom.Element.create(allocator, "body");
const p = try dom.Element.create(allocator, "p");

// Create text
const text = try dom.Text.init(allocator, "Hello World");

// Build tree
_ = try p.appendChild(text.character_data.node);
_ = try body.appendChild(p);
_ = try html.appendChild(body);
_ = try doc.node.appendChild(html);
```

**Implemented:**
- `Node` - Base node with tree operations
- `Document` - Document root
- `DocumentFragment` - Lightweight document for batch operations
- `DocumentType` - DOCTYPE declarations  
- `Element` - Element nodes with attributes
- `Text` - Text nodes
- `Comment` - Comment nodes
- `ProcessingInstruction` - Processing instructions
- `CharacterData` - Base for text-containing nodes
- **Mixins:**
  - `ChildNode` - `before()`, `after()`, `replaceWith()`, `remove()`
  - `ParentNode` - `prepend()`, `append()`, `replaceChildren()`, `moveBefore()`

### Collections

```zig
// NodeList - live collections
const children = element.child_nodes;
for (0..children.length()) |i| {
    const child = children.item(i);
    // Process child
}

// DOMTokenList - classList, etc.
const classList = element.class_list;
try classList.add("active");
try classList.toggle("hidden");

// NamedNodeMap - attributes
const attrs = element.attributes;
const id = attrs.getNamedItem("id");
```

**Implemented:**
- `NodeList` - Live node collections
- `NamedNodeMap` - Attribute collections  
- `DOMTokenList` - Token sets (classList)

### Ranges (§5)

```zig
// Mutable ranges
const range = try dom.Range.init(allocator);
defer range.deinit();

try range.setStart(text_node, 0);
try range.setEnd(text_node, 5);

// Extract contents
const fragment = try range.extractContents();
defer fragment.release();

// Stringification
const text = try range.toString(allocator);
defer allocator.free(text);
```

**Implemented:**
- `Range` - Mutable ranges with full API
- `StaticRange` - Immutable, lightweight ranges

### Tree Traversal (§6)

```zig
// TreeWalker - bidirectional navigation
const walker = try doc.createTreeWalker(root, dom.NodeFilter.SHOW_ELEMENT, null);
defer walker.deinit();

while (try walker.nextNode()) |node| {
    // Process node
}

// NodeIterator - forward-only iteration
const iterator = try doc.createNodeIterator(root, dom.NodeFilter.SHOW_TEXT, null);
defer iterator.deinit();
```

**Implemented:**
- `TreeWalker` - Bidirectional tree navigation
- `NodeIterator` - Forward-only iteration
- `NodeFilter` - Custom filtering

### Mutation Observation (§4.3)

```zig
// Observe DOM changes
const observer = try dom.MutationObserver.init(allocator, callback);
defer observer.deinit();

try observer.observe(target_node, .{
    .childList = true,
    .attributes = true,
    .subtree = true,
});
```

**Implemented:**
- `MutationObserver` - DOM change observation
- `MutationRecord` - Change records

## Building and Testing

### Prerequisites

- Zig 0.15.1 or later
- No external dependencies

### Build

```bash
# Build library
zig build

# Build with optimizations
zig build -Doptimize=ReleaseFast
```

### Test

```bash
# Run all tests
zig build test

# Run tests with verbose output
zig build test --summary all

# Run performance benchmarks
zig build bench -Doptimize=ReleaseFast
```

**Test Results:**
```
5,528+ tests passing (732 security-hardened)
0 memory leaks
~95% WHATWG spec coverage
Production ready with security hardening
```

**Performance:**
```
createElement:        10.63 μs/op   (94,047 ops/sec)
appendChild:          10.66 μs/op   (93,835 ops/sec)
Simple selector:      26.93 μs/op   (37,133 ops/sec)
Complex selector:     28.01 μs/op   (35,708 ops/sec)
Batch insert 100:     41.16 μs/op   (24,295 ops/sec)
```

**Stress Tests (1,000-10,000 operations):**
```
Create 10,000 nodes:    4.95 ms/op   (0.50 μs/node)
Deep tree (500 levels): 64.92 μs/op  (0.13 μs/level)
Wide tree (10k nodes):  1.94 ms/op   (0.19 μs/node)
1,000 × 10 attributes:  638 μs/op    (0.064 μs/attr)
```

See [PERFORMANCE_ANALYSIS.md](PERFORMANCE_ANALYSIS.md) for comprehensive benchmarks.  
See [STRESS_TEST_RESULTS.md](STRESS_TEST_RESULTS.md) for large-scale operation analysis.

### Examples

```bash
# Run comprehensive feature demo
zig build run-comprehensive-demo

# Run query selectors demo (comprehensive CSS3/4 selector features)
zig build run-query-demo

# Run mutation observer demo
zig build run-mutation-demo

# Run document types demo
zig build run-document-types-demo
```

## Specification Compliance

This implementation follows the [WHATWG DOM Living Standard](https://dom.spec.whatwg.org/).

### Implemented Sections

| Section | Feature | Status |
|---------|---------|--------|
| §2 | Events | ✅ Complete |
| §3 | Aborting | ✅ Complete |
| §4 | Nodes | ✅ Complete (non-XML) |
| §4.2.10 | Collections | ✅ Complete |
| §4.3 | Mutation Observers | ✅ Complete |
| §4.5.1 | DOMImplementation | ✅ Complete |
| §5 | Ranges | ✅ Complete |
| §6 | Traversal | ✅ Complete |
| CSS3 | Selectors | ✅ Complete |
| CSS4 | Selectors | ✅ Complete |

### Excluded (XML-Specific)

| Section | Feature | Reason |
|---------|---------|--------|
| §4.12 | CDATASection | XML-specific |
| §8 | XPath | XML-specific |
| §9 | XSLT | XML-specific |

## Documentation

### Building API Documentation

Generate complete API documentation from inline comments:

```bash
# Generate documentation in HTML format
zig build docs

# Documentation will be available at:
# zig-out/docs/index.html
```

The generated documentation includes:
- Complete API reference for all public types and functions
- Inline code examples from doc comments
- Cross-referenced types and links
- WHATWG DOM spec references

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Code Style

- Follow Zig style guidelines
- Add inline documentation with spec references
- Include tests for new features
- Ensure no memory leaks (`zig build test`)

### Testing

All changes must:
- Pass all existing tests (5,528+)
- Add new tests for new features
- Have zero memory leaks
- Include documentation

## License

MIT License - see LICENSE file for details

Copyright (c) 2025 DockYard, Inc.

## Acknowledgments

This project is sponsored and supported by [DockYard, Inc.](https://dockyard.com)

Special thanks to:
- [WHATWG](https://whatwg.org/) for the DOM Standard
- [Zig](https://ziglang.org/) community
- All contributors

## Roadmap

### Completed ✅
- [x] Events and EventTarget
- [x] Aborting operations (AbortController/AbortSignal)
- [x] All node types (Document, Element, Text, etc.)
- [x] Collections (NodeList, NamedNodeMap, DOMTokenList)
- [x] Complete Range API with stringification
- [x] Tree traversal (TreeWalker, NodeIterator)
- [x] Mutation observers
- [x] DOMImplementation
- [x] CSS3 selector engine (complete)
- [x] CSS4 selector enhancements
- [x] CSS4 pseudo-classes (link, user action, custom elements)
- [x] Form pseudo-classes (:enabled, :disabled, :checked, etc.)
- [x] Language pseudo-class (:lang())
- [x] :is(), :where(), :has() pseudo-classes
- [x] Pseudo-elements (::before, ::after, etc.)
- [x] Comprehensive security hardening (DoS, cycles, resource exhaustion)
- [x] Security event logging infrastructure
- [x] Input validation and sanitization

### Future Enhancements
- [ ] Additional performance optimizations
- [ ] HTML parser integration
- [ ] CSS specificity calculation
- [ ] Browser API compatibility layer
- [ ] Optional bloom filters for enhanced query performance

---

**Built with [Zig](https://ziglang.org/) and sponsored by [DockYard, Inc.](https://dockyard.com)**

*This implementation provides a solid foundation for DOM manipulation in Zig applications. All non-XML features of the WHATWG DOM Standard are implemented with comprehensive CSS3/CSS4 selector support and production-ready quality.*
