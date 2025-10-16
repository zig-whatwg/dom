# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
- 72 comprehensive tests with zero memory leaks across all node types
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
