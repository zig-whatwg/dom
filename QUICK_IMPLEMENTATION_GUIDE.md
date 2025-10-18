# Quick Implementation Guide - Next Features

**Status**: ✅ 498 tests passing, 0 leaks, ~85% spec compliance

---

## Immediate Next Steps (Prioritized)

### 1️⃣ Node.normalize() - IMPLEMENT FIRST
**Time**: 4-6 hours | **Priority**: HIGH | **Complexity**: MEDIUM

```zig
// What it does: Remove empty Text nodes, merge adjacent Text nodes
// Spec: WHATWG DOM §4.4
// WebIDL: [CEReactions] undefined normalize();

// Example:
const parent = try doc.createElement("div");
const text1 = try doc.createTextNode("Hello");
const text2 = try doc.createTextNode(" ");
const text3 = try doc.createTextNode("World");
_ = try parent.node.appendChild(&text1.node);
_ = try parent.node.appendChild(&text2.node);
_ = try parent.node.appendChild(&text3.node);

try parent.node.normalize(); // Merges into single "Hello World" text node
```

**Implementation Steps**:
1. Add `normalize()` to Node (src/node.zig)
2. Traverse all descendants depth-first
3. Collect runs of adjacent Text nodes
4. Merge text data into first node
5. Remove subsequent nodes
6. Remove empty Text nodes
7. Write tests (co-locate in src/node.zig)

**Tests Needed**:
- Adjacent text merging
- Empty text removal
- Nested elements (don't cross boundaries)
- DocumentFragment handling
- Memory safety

---

### 2️⃣ Text.splitText() - IMPLEMENT SECOND
**Time**: 2-3 hours | **Priority**: HIGH | **Complexity**: LOW

```zig
// What it does: Split text node at offset, return new node
// Spec: WHATWG DOM §4.10.1
// WebIDL: [NewObject] Text splitText(unsigned long offset);

// Example:
const text = try doc.createTextNode("Hello World");
const newText = try text.splitText(6); // "Hello " | "World"
// text.data = "Hello "
// newText.data = "World"
// newText inserted after text in parent
```

**Implementation Steps**:
1. Add `splitText()` to Text (src/text.zig)
2. Validate offset (0 to data.len)
3. Create new Text with data[offset..]
4. Truncate self to data[0..offset]
5. If has parent, insert new node after self
6. Return new node
7. Tests

---

### 3️⃣ Text.wholeText - IMPLEMENT THIRD
**Time**: 1-2 hours | **Priority**: MEDIUM | **Complexity**: LOW

```zig
// What it does: Get all adjacent text concatenated
// Spec: WHATWG DOM §4.10.1
// WebIDL: readonly attribute DOMString wholeText;

// Example:
const text1 = try doc.createTextNode("Hello");
const text2 = try doc.createTextNode(" ");
const text3 = try doc.createTextNode("World");
// ... append to parent ...
const whole = try text2.wholeText(allocator); // "Hello World"
defer allocator.free(whole);
```

**Implementation Steps**:
1. Add `wholeText()` to Text (src/text.zig)
2. Traverse previous siblings (collect Text nodes)
3. Traverse next siblings (collect Text nodes)
4. Concatenate all data
5. Return owned string

---

### 4️⃣ DOMTokenList (Element.classList) - BIG WIN
**Time**: 8-12 hours | **Priority**: VERY HIGH | **Complexity**: HIGH

```zig
// What it does: Modern class manipulation API
// Spec: WHATWG DOM §4.9.1
// WebIDL: [SameObject, PutForwards=value] readonly attribute DOMTokenList classList;

// Example:
const elem = try doc.createElement("button");
try elem.classList.add(allocator, &.{"btn", "btn-primary"});
try elem.classList.toggle(allocator, "active", null);
const has_btn = elem.classList.contains("btn"); // true
```

**Implementation Steps**:
1. Create `src/dom_token_list.zig`
2. Struct with weak pointer to Element + attribute name
3. Implement: add, remove, toggle, contains, replace, length, item, value
4. Add classList cache to Element rare_data ([SameObject])
5. Parse tokens on-demand from attribute
6. Update attribute on modifications
7. Extensive tests

**Why High Priority**: Extremely common in modern web development

---

## Quick Wins (1-3 hours each)

### CustomEvent Interface
```zig
pub const CustomEvent = struct {
    event: Event,
    detail: ?*anyopaque, // User-defined data
};
```
**Time**: 2 hours

### Document Metadata Properties
```zig
pub fn getURL(self: *Document) []const u8 { return ""; }
pub fn getCharacterSet(self: *Document) []const u8 { return "UTF-8"; }
pub fn getContentType(self: *Document) []const u8 { return "application/xml"; }
```
**Time**: 2 hours

---

## Phase 2 Features (Future)

### Range Interface (20-30 hours)
Essential for text editors, selection, copy/paste. Complex boundary logic.

### HTMLCollection (6-8 hours)
Live element collection for `children` property and proper return types.

### NodeIterator/TreeWalker (6-10 hours)
Structured tree traversal APIs. Less urgent (manual traversal works).

---

## Testing Checklist

For each feature:
- [ ] Happy path test
- [ ] Edge cases (boundaries, empty, null)
- [ ] Error conditions
- [ ] Memory safety (std.testing.allocator, zero leaks)
- [ ] WPT test conversion (if applicable)
- [ ] Inline documentation with spec references
- [ ] CHANGELOG.md entry
- [ ] Benchmark (if performance-critical)

---

## How to Implement (General Pattern)

1. **Read the spec**: `skills/whatwg_compliance/dom.idl` + WHATWG prose
2. **Check WebIDL signature**: Get exact types, return values, errors
3. **Write tests FIRST** (TDD):
   ```zig
   test "Feature - basic usage" {
       const allocator = std.testing.allocator;
       // ... test code ...
   }
   ```
4. **Implement** with spec references:
   ```zig
   /// Brief description.
   ///
   /// ## WebIDL
   /// ```webidl
   /// [CEReactions] undefined method(DOMString arg);
   /// ```
   ///
   /// ## Spec References
   /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-method
   /// - WebIDL: dom.idl:LINE
   pub fn method(self: *Node, arg: []const u8) !void {
       // Step 1: ...
       // Step 2: ...
   }
   ```
5. **Verify**: All tests pass, zero leaks, benchmarks run
6. **Document**: Update CHANGELOG.md

---

## Example: normalize() Implementation Outline

```zig
// In src/node.zig

/// Removes empty Text nodes and merges adjacent Text nodes.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] undefined normalize();
/// ```
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-node-normalize
/// - WebIDL: dom.idl:260
pub fn normalize(self: *Node) !void {
    // Step 1: Let node be this's first child
    var current = self.first_child;
    
    while (current) |node| {
        const next = node.next_sibling;
        
        if (node.node_type == .text) {
            const text_node = @fieldParentPtr(Text, "node", node);
            
            // Step 2: Remove empty text nodes
            if (text_node.data.len == 0) {
                _ = try self.removeChild(node);
                current = next;
                continue;
            }
            
            // Step 3: Merge adjacent text nodes
            var adjacent = next;
            while (adjacent) |adj| {
                if (adj.node_type != .text) break;
                
                const adj_text = @fieldParentPtr(Text, "node", adj);
                
                // Merge data
                const new_data = try std.mem.concat(
                    self.allocator, 
                    u8, 
                    &.{text_node.data, adj_text.data}
                );
                self.allocator.free(text_node.data);
                text_node.data = new_data;
                
                // Remove merged node
                const adj_next = adj.next_sibling;
                _ = try self.removeChild(adj);
                adjacent = adj_next;
            }
        }
        
        // Step 4: Recursively normalize children
        if (node.node_type == .element or node.node_type == .document_fragment) {
            try node.normalize();
        }
        
        current = next;
    }
}

test "Node.normalize - merges adjacent text nodes" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;
    
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const parent = try doc.createElement("div");
    defer parent.node.release();
    
    const text1 = try doc.createTextNode("Hello");
    const text2 = try doc.createTextNode(" ");
    const text3 = try doc.createTextNode("World");
    
    _ = try parent.node.appendChild(&text1.node);
    _ = try parent.node.appendChild(&text2.node);
    _ = try parent.node.appendChild(&text3.node);
    
    // Before: 3 text nodes
    try std.testing.expectEqual(@as(u32, 3), parent.node.childNodes().items.len);
    
    try parent.node.normalize();
    
    // After: 1 text node with merged data
    try std.testing.expectEqual(@as(u32, 1), parent.node.childNodes().items.len);
    
    const merged = parent.node.first_child.?;
    const merged_text = @fieldParentPtr(Text, "node", merged);
    try std.testing.expectEqualStrings("Hello World", merged_text.data);
}
```

---

## Questions Before Starting?

1. **Which feature to start with?** → `Node.normalize()` (builds foundation)
2. **How to test?** → Co-locate in src/*.zig, use std.testing.allocator
3. **Where's the spec?** → `skills/whatwg_compliance/dom.idl` + https://dom.spec.whatwg.org/
4. **Memory management?** → Children owned by parent, use defer for orphans
5. **Need help?** → Check existing implementations (appendChild, cloneNode, etc.)

---

**Start with `Node.normalize()` and you'll have a solid foundation for the rest!**
