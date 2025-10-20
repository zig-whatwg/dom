# DOM2 Roadmap - Future Development

**Current Version**: Post-Phase 7 (Medium Priority Complete)  
**Overall Status**: 95-98% WHATWG Spec Compliant  
**Production Ready**: ✅ YES - **v1.0.0 READY**

---

## Phase History

### ✅ Phase 1: Registry Foundation (COMPLETE)
- CustomElementRegistry core
- define(), get(), whenDefined()
- Element name validation
- Constructor tracking

### ✅ Phase 2: Element State Machine (COMPLETE)
- CustomElementState enum (undefined, uncustomized, custom, failed)
- State transitions (undefined → custom/failed/uncustomized)
- is_value tracking for autonomous custom elements

### ✅ Phase 3: Reaction Queue System (COMPLETE)
- CustomElementReactionQueue per element
- CEReactionsStack global stack
- Reaction queueing/processing
- connectedCallback enqueuing

### ✅ Phase 4: Lifecycle Callbacks Integration (COMPLETE)
- Connected/disconnected callbacks
- Adopted callback
- AttributeChanged callback
- Custom element upgrade algorithm
- Integration with Node tree operations

### ✅ Phase 5: Complete [CEReactions] Coverage (COMPLETE)
- Batch 1: ParentNode mixin (prepend, append, replaceChildren, moveBefore)
- Batch 2: ChildNode mixin (before, after, replaceWith, remove)
- Batch 3: Element attributes (setAttributeNS, removeAttributeNS, toggleAttribute)
- Batch 4: Node text/clone (setNodeValue, setTextContent, normalize)
- Batch 5: NamedNodeMap (setNamedItem, setNamedItemNS, removeNamedItem, removeNamedItemNS)
- **Total**: 18 methods with full [CEReactions] scope
- **Tests**: 74 custom element tests, all passing ✅

### ✅ Phase 6: High Priority Gaps (COMPLETE - Already Implemented!)
- Text.wholeText property (`src/text.zig:716-743`)
- Node namespace methods: lookupPrefix(), lookupNamespaceURI(), isDefaultNamespace()
- ShadowRoot properties: clonable, serializable
- **Status**: All features discovered already implemented
- **Date Verified**: 2025-10-20

### ✅ Phase 7: Medium Priority Features (COMPLETE - Already Implemented!)
- DOMTokenList.supports() (`src/dom_token_list.zig:587`)
- Element.insertAdjacentElement() (`src/element.zig`)
- Element.insertAdjacentText() (`src/element.zig`)
- Element.webkitMatchesSelector() (`src/element.zig`)
- Slottable.assignedSlot (Element and Text)
- **Status**: All features discovered already implemented
- **Tests**: Comprehensive test coverage in slot_test.zig
- **Date Verified**: 2025-10-20

---

## 📋 Phase 6-7 Implementation Details (ARCHIVED - Already Complete)

**Goal**: Complete XML namespace support and Web Components

**Estimated Effort**: ~350 lines, 1 week

### 6.1 Text.wholeText Property
**Lines**: ~50  
**Priority**: High  
**Spec**: https://dom.spec.whatwg.org/#dom-text-wholetext

**Implementation**:
```zig
pub fn wholeText(self: *const Text, allocator: Allocator) ![]const u8 {
    var result = std.ArrayList(u8).init(allocator);
    
    // 1. Collect text from previous Text siblings
    var prev = self.node.previous_sibling;
    while (prev) |p| {
        if (p.node_type != .text) break;
        const text: *const Text = @fieldParentPtr("node", p);
        try result.insertSlice(0, text.data);
        prev = p.previous_sibling;
    }
    
    // 2. Append this node's text
    try result.appendSlice(self.data);
    
    // 3. Append text from next Text siblings
    var next = self.node.next_sibling;
    while (next) |n| {
        if (n.node_type != .text) break;
        const text: *const Text = @fieldParentPtr("node", n);
        try result.appendSlice(text.data);
        next = n.next_sibling;
    }
    
    return result.toOwnedSlice();
}
```

**Tests**:
- Adjacent text nodes concatenation
- Non-text siblings act as boundaries
- Empty text nodes included
- Single text node returns its data

---

### 6.2 Node Namespace Methods
**Lines**: ~200  
**Priority**: High  
**Spec**: https://dom.spec.whatwg.org/#dom-node-lookupprefix

**Implementation**:

#### lookupPrefix(namespace)
```zig
pub fn lookupPrefix(self: *const Node, namespace: ?[]const u8) ?[]const u8 {
    // Null or empty namespace → return null
    if (namespace == null or namespace.?.len == 0) return null;
    
    const ns = namespace.?;
    
    // DocumentType/DocumentFragment → null
    if (self.node_type == .document_type or 
        self.node_type == .document_fragment) return null;
    
    // Element: check if namespace matches
    if (self.node_type == .element) {
        const Element = @import("element.zig").Element;
        const elem: *const Element = @fieldParentPtr("node", self);
        
        if (elem.namespace_uri) |elem_ns| {
            if (std.mem.eql(u8, elem_ns, ns) and elem.prefix != null) {
                return elem.prefix;
            }
        }
        
        // Check attributes for xmlns:prefix declarations
        var iter = elem.attributes.iterator();
        while (iter.next()) |attr| {
            if (attr.namespace_uri) |attr_ns| {
                if (std.mem.eql(u8, attr_ns, "http://www.w3.org/2000/xmlns/") and
                    attr.value) |val| {
                    if (std.mem.eql(u8, val, ns)) {
                        return attr.local_name;
                    }
                }
            }
        }
    }
    
    // Walk up to parent (but not Document)
    if (self.parent_node) |parent| {
        if (parent.node_type != .document) {
            return parent.lookupPrefix(namespace);
        }
    }
    
    return null;
}
```

#### lookupNamespaceURI(prefix)
```zig
pub fn lookupNamespaceURI(self: *const Node, prefix: ?[]const u8) ?[]const u8 {
    // Special prefixes
    if (prefix) |p| {
        if (std.mem.eql(u8, p, "xml")) {
            return "http://www.w3.org/XML/1998/namespace";
        }
        if (std.mem.eql(u8, p, "xmlns")) {
            return "http://www.w3.org/2000/xmlns/";
        }
    }
    
    // Similar tree-walking logic...
}
```

#### isDefaultNamespace(namespace)
```zig
pub fn isDefaultNamespace(self: *const Node, namespace: ?[]const u8) bool {
    const default_ns = self.lookupNamespaceURI(null);
    
    if (namespace == null and default_ns == null) return true;
    if (namespace != null and default_ns != null) {
        return std.mem.eql(u8, namespace.?, default_ns.?);
    }
    
    return false;
}
```

**Tests**:
- XML namespace declarations (xmlns, xmlns:prefix)
- Namespace inheritance in tree
- Special prefixes (xml, xmlns)
- Default namespace (null prefix)
- Boundary cases (DocumentType, DocumentFragment, detached nodes)

---

### 6.3 ShadowRoot Completion
**Lines**: ~100  
**Priority**: High  
**Spec**: https://dom.spec.whatwg.org/#shadowroot

**Implementation**:

#### Add Properties to ShadowRoot
```zig
pub const ShadowRoot = struct {
    // Existing fields...
    mode: ShadowRootMode,
    delegates_focus: bool,
    slot_assignment: SlotAssignmentMode,
    host_element: *Element,
    
    // NEW: Declarative shadow DOM support
    clonable: bool = false,
    serializable: bool = false,
    
    // NEW: Slot change event handler
    onslotchange: ?EventHandler = null,
};
```

#### Update attachShadow()
```zig
pub fn attachShadow(self: *Element, init: ShadowRootInit) !*ShadowRoot {
    // Existing validation...
    
    const shadow = try ShadowRoot.init(
        self.node.allocator,
        init.mode,
        init.delegates_focus,
        init.slot_assignment,
        init.clonable,       // NEW
        init.serializable,   // NEW
        init.custom_element_registry,
    );
    
    // Rest of implementation...
}
```

#### Fire slotchange Event
```zig
fn fireSlotChangeEvent(slot: *Element) !void {
    const event = Event.init("slotchange", .{
        .bubbles = true,
        .cancelable = false,
        .composed = false,
    });
    
    _ = try slot.node.dispatchEvent(&event);
    
    // Also call onslotchange handler if set
    if (slot.shadow_root) |shadow| {
        if (shadow.onslotchange) |handler| {
            handler(&event);
        }
    }
}
```

**Tests**:
- ShadowRoot clonable/serializable properties
- attachShadow with clonable/serializable options
- slotchange event fires on slot assignment changes
- onslotchange handler invoked
- Declarative shadow DOM serialization

---

---

## 📋 Phase 8: Polish & Legacy (LOW PRIORITY)

**Goal**: Maximum compatibility with legacy APIs

**Estimated Effort**: ~200 lines, 2-3 days

### 8.1 Event Legacy Properties
- `srcElement` (alias of target)
- `cancelBubble` (writable, alias of stopPropagation)
- `returnValue` (writable, alias of preventDefault)
- `initEvent()` (legacy constructor)

### 8.2 Document Legacy Aliases
- `charset` (alias of characterSet)
- `inputEncoding` (alias of characterSet)
- `createEvent()` (legacy factory)

### 8.3 Miscellaneous
- `ProcessingInstruction.target` property
- `Range` stringifier (text extraction)

---

## 🎯 v1.0 Release Criteria

### Required (Before v1.0) ✅ ALL COMPLETE
- ✅ Phase 1-5 complete (Custom Elements)
- ✅ Phase 6 complete (XML/Web Components gaps)
- ✅ Phase 7 complete (Medium priority features)
- ✅ Zero memory leaks
- ✅ All tests passing (500+ tests)
- ✅ Documentation complete

### Optional (Can be v1.1+)
- Phase 8 (Legacy polish)
- Additional WPT test imports
- Performance optimizations

---

## 📈 Beyond v1.0

### Potential Future Features

#### Performance Enhancements
- Parallel selector matching (rayon/threads)
- JIT selector compilation for hot paths
- Memory pooling for frequently-allocated nodes
- SIMD-accelerated string operations

#### Extended APIs
- CSS Object Model (CSSOM) integration
- DOM Parsing and Serialization
- HTML Parser integration (external library)
- XML Parser integration (external library)

#### Tooling
- JavaScript bindings generator (WebIDL → JS glue)
- Benchmark suite expansion
- Fuzzing infrastructure
- Memory profiler integration

#### Documentation
- MDN-style API documentation
- Interactive examples
- Migration guide from other DOM libraries
- Performance tuning guide

---

## 🚀 Release Schedule (Updated)

### Immediate (Q4 2025)
- ✅ **Phases 6-7**: Complete (already implemented)
- 🎯 **v1.0.0**: Ready for release after documentation updates
- **v1.0.0 Target**: November 2025

### Future (2026+)
- **v1.1**: Phase 8 complete (Legacy compatibility)
- **v1.2**: Additional WPT test coverage
- **v2.0**: Major enhancements (parallel matching, SIMD, etc.)

---

## 📊 Metrics Tracking

### Code Quality Metrics
- Lines of code: ~37,500 (current)
- Test coverage: 95%+ (current)
- Memory leaks: 0 (current)
- Spec compliance: **95-98%** (Phases 1-7 complete)

### Performance Metrics
- Selector cache hit rate: 80-90%
- Bloom filter rejection rate: 85-95%
- Average allocation per element: ~200 bytes
- Tree traversal: O(n) with optimal cache locality

---

## 🤝 Contributing

### High-Value Contributions
1. **Phase 8 implementation** (Legacy compatibility features)
2. **WPT test imports** (convert more Web Platform Tests)
3. **Performance benchmarks** (real-world DOM usage patterns)
4. **Documentation improvements** (examples, guides, API docs)
5. **v1.0.0 release preparation** (final polish and testing)

### Process
1. Check roadmap and pick a feature
2. Create design document (for new phases)
3. Write tests first (TDD)
4. Implement feature
5. Update CHANGELOG.md
6. Submit PR with completion report

---

## 📚 References

- **Gap Analysis**: `WHATWG_SPEC_GAP_ANALYSIS.md`
- **Status Summary**: `GAP_ANALYSIS_SUMMARY.md`
- **Quick Reference**: `IMPLEMENTATION_STATUS.md`
- **WHATWG Spec**: https://dom.spec.whatwg.org/
- **WebIDL**: `skills/whatwg_compliance/dom.idl`

---

**Ready to contribute?** Help prepare v1.0.0 release or start Phase 8! 🎉

**v1.0.0 Status**: All required features complete. Ready for final polish and release!
