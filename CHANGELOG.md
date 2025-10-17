# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- addEventListener signal option support per WHATWG DOM §2.7.3 (Critical Issue #8 resolved)
- Automatic listener removal when AbortSignal aborts (spec step 6)
- Early return if signal already aborted (spec step 2)
- DOMException struct for spec-compliant abort reason representation
- Set semantics for abort_algorithms (prevents duplicate algorithm registration)
- Set semantics for source_signals and dependent_signals (prevents duplicate signal links)
- 7 comprehensive tests for addEventListener signal integration and duplicate prevention

### Changed
- **BREAKING:** AbortAlgorithm now struct with callback + context instead of bare function pointer
- Enables closure-like behavior for abort algorithms (required for addEventListener signal integration)
- All abort algorithm tests updated to use new struct-based API
- AbortSignal.abort() now creates proper DOMException("AbortError") instead of encoded error value
- AbortSignal.signalAbort() creates DOMException for default reason per spec §3.2.5

### Fixed
- addEventListener signal parameter now fully functional (was completely ignored before)
- AbortAlgorithm memory management improved with automatic cleanup on abort
- throwIfAborted() limitation documented (Zig can't throw arbitrary values like JavaScript)
- abort_algorithms now enforces set semantics (no duplicate algorithms)
- source_signals/dependent_signals now enforce set semantics (no duplicate signal links)
- DOMException memory properly managed with ownership tracking

### Added
- EventTarget mixin pattern for reusable event dispatching across any type
- Comptime validation ensures EventTarget interface compliance at compile time
- `src/event_target.zig` module with EventTargetMixin(comptime T) generic function
- 5 comprehensive EventTarget mixin tests with MockEventTarget validation

### Changed
- Node EventTarget methods now delegate to EventTargetMixin (zero code duplication)
- EventCallback and EventListener types moved from rare_data.zig to event_target.zig
- rare_data.zig re-exports EventTarget types for backward compatibility

### Added
- `Event` struct with spec-compliant flags and state management per WHATWG DOM §2.2
- `EventTarget.dispatchEvent()` - synchronous event dispatching with listener invocation per WHATWG DOM §2.9
- Support for passive event listeners (preventDefault blocked when passive=true)
- Support for "once" event listeners (auto-removed after first invocation)
- `stopImmediatePropagation()` prevents remaining listeners from executing
- EventCallback signature updated to pass mutable Event pointer for preventDefault support
- 8 comprehensive dispatchEvent tests covering dispatch flow, cancellation, passive/once listeners, and state management
- `Node.lookupPrefix(namespace)` - returns namespace prefix per WHATWG DOM §4.4
- `Node.lookupNamespaceURI(prefix)` - returns namespace URI per WHATWG DOM §4.4
- `Node.isDefaultNamespace(namespace)` - checks if namespace is default per WHATWG DOM §4.4
- 14 comprehensive namespace method tests covering null handling, empty strings, and node type behavior
- **Phase 2 Complete!** All tree manipulation APIs now implemented with spec-compliant behavior
- `Node.normalize()` - removes empty text nodes and merges adjacent text nodes per WHATWG DOM §4.4
- Tree traversal helpers: `getFirstDescendant()`, `getNextNodeInTree()` for depth-first traversal
- 8 comprehensive normalize() tests covering empty removal, merging, nested trees, and edge cases
- **Phase 1 Complete!** All 10 missing Phase 1 readonly/comparison APIs now implemented
- `Node.isSameNode()` - identity comparison (Phase 1 readonly API)
- `Node.getRootNode(composed)` - root node traversal with shadow DOM support
- `Node.contains(other)` - inclusive descendant check
- `Node.baseURI()` - base URI property (placeholder implementation)
- `Node.compareDocumentPosition(other)` - relative position comparison with bitmask flags
- `Node.isEqualNode(other)` - deep structural equality check
- `Element.localName` - local name property (same as tagName for non-namespaced elements)
- `Document.doctype()` - returns DocumentType node (placeholder until DocumentType implemented)
- `Document.createDocumentFragment()` - factory method for DocumentFragment nodes
- `Text.wholeText()` - concatenates contiguous text nodes
- `DocumentFragment` node type implementation with cloning support
- Document position constants: DISCONNECTED, PRECEDING, FOLLOWING, CONTAINS, CONTAINED_BY, IMPLEMENTATION_SPECIFIC
- 47 comprehensive tests (33 Node + 2 Element + 2 Document + 4 Text + 6 DocumentFragment)
- `textContent` property (getter/setter) on Node interface per WHATWG DOM §4.4
- 14 comprehensive tests for textContent covering all edge cases

### Fixed
- Critical infinite loop bugs in tree traversal (saved `next_sibling` before recursive operations)
- Document cleanup reentrant destruction issue (added `is_destroying` flag)
- Double-free crash during document destruction cascade
- Memory leaks in `setDescendantsConnected()` and `collectTextContent()` helper functions
- Infinite loop in `clearOwnerDocumentRecursive()` during document destruction
- Use-after-free in `Element.deinitImpl()` child release loop

### Changed
- Removed HTML-specific optimizations to keep library generic for XML/SVG use
- Test element names changed from HTML tags ("div", "span") to generic names ("element", "item")
- README updated to reflect Phase 2 partial completion status (tree mutation APIs complete)

### Added
- Comprehensive implementation status document (`summaries/plans/IMPLEMENTATION_STATUS.md`)
- Infinite loop fixes session report (`summaries/completion/INFINITE_LOOP_FIXES.md`)
- Core Node structure with WebKit-style reference counting (96 bytes exactly)
- Packed ref_count + has_parent in single atomic u32 (saves 12 bytes/node)
- NodeVTable for polymorphic behavior (enables extension by Browser/HTML projects)
- Weak parent/sibling pointers to prevent circular references
- Atomic acquire/release operations for thread-safe ref counting
- Node size compile-time assertion (≤96 bytes enforced)
- Element implementation with tag name and attribute support
- BloomFilter for fast class name matching in querySelector (8 bytes, 80-90% rejection rate)
- AttributeMap with O(1) average-case attribute access
- Text node with mutable character data and manipulation methods
- Comment node with character data operations
- Document node with dual reference counting (external + internal node refs)
- StringPool with hybrid interning (comptime common strings + runtime rare strings)
- Document factory methods: createElement, createTextNode, createComment
- Automatic string interning for tag names in createElement
- Owner document tracking for all nodes
- **NodeRareData pattern** for optional features (saves 40-80 bytes on 90% of nodes)
- Event listener management (addEventListener, removeEventListener, getEventListeners)
- Mutation observer management (addMutationObserver, removeMutationObserver)
- User data storage (setUserData, getUserData, removeUserData)
- Lazy allocation of rare features (only allocated when first used)
- **WHATWG-compliant event API** on Node (addEventListener, removeEventListener, hasEventListeners)
- **Node helper methods**: hasChildNodes(), parentElement()
- **Element convenience properties**: getId/setId, getClassName/setClassName
- **Element helper methods**: hasAttributes(), getAttributeNames()
- Character data methods: substringData, appendData, insertData, deleteData, replaceData
- **NodeList collection type** with live semantics and indexed access
- **Node.childNodes property** returning live NodeList per WebIDL spec
- **Node.getOwnerDocument()** typed accessor returning `?*Document`
- **Document.documentElement property** returning root element
- **Tree validation module** with WHATWG pre-insert/replace/remove validity checking
- **Tree helpers module** for traversal, text collection, and connected state propagation
- Circular reference detection for tree operations (prevents inserting ancestor into descendant)
- Document constraint validation for element/doctype insertion rules
- **Tree manipulation APIs**: appendChild(), insertBefore(), removeChild(), replaceChild() per WHATWG §4.2.4
- Automatic connected state propagation when nodes inserted/removed from tree
- Document node always marked as connected per WHATWG spec
- Children cleanup in Element.deinit() and Document.deinitInternal()
- 100 comprehensive tests (Phase 1 + 2A + 2B core APIs complete)
- Deep Phase 1 analysis vs WHATWG DOM spec in `summaries/analysis/PHASE1_DEEP_ANALYSIS.md`
- WebIDL compliance analysis in `summaries/analysis/PHASE1_WEBIDL_COMPLIANCE.md`
- Architecture documentation in `summaries/ARCHITECTURE.md`

### Changed
- **Element.removeAttribute()** now returns void instead of bool per WebIDL spec
- **Node.removeEventListener()** now returns void instead of bool per WebIDL spec
- **Project renamed** from `dom2` to `dom` (import as `@import("dom")`)

### Fixed
- Event listener API ergonomics - now WHATWG-compliant delegation from Node
- Empty event listener lists properly cleaned up after removing last listener
- Missing basic WHATWG DOM helper methods now implemented
- Return types for removeAttribute/removeEventListener now match WebIDL spec

[Unreleased]: https://github.com/user/dom/compare/HEAD...HEAD
