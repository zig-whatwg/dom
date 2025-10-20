# Next Session: Custom Elements Phase 4 - Lifecycle Callbacks Integration

**Status**: Phase 3 Complete ✅ | Ready to start Phase 4  
**Last Commit**: `510e251` - "Add Custom Elements Phase 3: Reaction Queue System"  
**Tests**: 46/46 custom element tests passing (1111/1112 full suite)

---

## Quick Recap: What's Done

### Phase 1: Registry Foundation ✅ (Commit `6ce7648`)
- `CustomElementRegistry` with define/get/isDefined
- `CustomElementDefinition` with callbacks and metadata
- `isValidCustomElementName()` validation
- 18 tests passing

### Phase 2: Element State Machine ✅ (Commit `f2a4be1`)
- `CustomElementState` enum (undefined/uncustomized/custom/failed)
- Element custom element fields (17 bytes)
- State transition methods on Element
- Registry upgrade operations
- 29 tests total (11 new)

### Phase 3: Reaction Queue System ✅ (Commit `510e251`)
- `CustomElementReaction` tagged union (72 bytes, 5 variants)
- `CustomElementReactionQueue` per-element lazy allocation
- `CEReactionsStack` per-document stack (~56 bytes)
- Helper functions: invokeReaction, invokeReactionsForElement
- Element/Document integration complete
- 46 tests total (17 new)

---

## Phase 4: Lifecycle Callbacks Integration (NEXT)

### Goal
Integrate lifecycle callbacks with DOM operations marked with `[CEReactions]` in WebIDL.

### Scope

**DOM Operations to Update** (from WebIDL with `[CEReactions]` attribute):

1. **Node Insertion** (enqueue `connected` reaction):
   - `appendChild(node)`
   - `insertBefore(node, child)`
   - `replaceChild(node, child)` (for new node)
   - `prepend(...nodes)` (ParentNode mixin)
   - `append(...nodes)` (ParentNode mixin)

2. **Node Removal** (enqueue `disconnected` reaction):
   - `removeChild(child)`
   - `replaceChild(node, child)` (for old node)
   - `remove()` (ChildNode mixin)

3. **Attribute Changes** (enqueue `attribute_changed` reaction):
   - `setAttribute(name, value)`
   - `setAttributeNS(namespace, name, value)`
   - `removeAttribute(name)`
   - `removeAttributeNS(namespace, name)`
   - `toggleAttribute(name, force?)`
   - `setAttributeNode(attr)`
   - `setAttributeNodeNS(attr)`
   - `removeAttributeNode(attr)`

4. **Node Adoption** (enqueue `adopted` reaction):
   - `adoptNode(node)`

5. **Text Content** (enqueue reactions for affected custom elements):
   - `textContent = value` (setter)
   - `normalize()`

### Implementation Pattern

```zig
pub fn appendChild(self: *Node, node: *Node) !*Node {
    const doc = self.getOwnerDocument() orelse return error.NoOwnerDocument;
    const stack = doc.getCEReactionsStack();
    
    try stack.enter(); // Push [CEReactions] scope
    defer stack.leave(); // Pop scope, invoke reactions
    
    // ... existing appendChild logic ...
    
    // Enqueue connected reaction if custom element
    if (node.node_type == .element) {
        const elem: *Element = @fieldParentPtr("prototype", node);
        if (elem.isCustomElement() and node.isConnected()) {
            const queue = try elem.getOrCreateReactionQueue();
            try queue.enqueue(.{ .connected = {} });
            try stack.enqueueElement(elem);
        }
    }
    
    return node;
}
```

### Key Considerations

1. **Connected State**: Only enqueue `connected` if element becomes connected (isConnected() == true after operation)
2. **Disconnected State**: Only enqueue `disconnected` if element was connected before removal
3. **Observed Attributes**: Only enqueue `attribute_changed` if attribute is in definition's observed_attributes set
4. **Tree Walking**: For operations affecting subtrees, must walk tree and enqueue for all custom elements
5. **Error Handling**: If enqueue fails (OOM), operation should still succeed but callback won't fire

---

## Implementation Steps (3-4 Days)

### Day 1: Node Insertion Operations
- [ ] Update `appendChild()` to enqueue `connected` reactions
- [ ] Update `insertBefore()` to enqueue `connected` reactions
- [ ] Update `replaceChild()` to enqueue both reactions
- [ ] Add helper: `enqueueConnectedReactionsForTree(root, stack)`
- [ ] Write 8-10 tests for insertion operations

### Day 2: Node Removal Operations
- [ ] Update `removeChild()` to enqueue `disconnected` reactions
- [ ] Update `remove()` to enqueue `disconnected` reactions
- [ ] Add helper: `enqueueDisconnectedReactionsForTree(root, stack)`
- [ ] Write 6-8 tests for removal operations

### Day 3: Attribute Operations
- [ ] Update `setAttribute()` to enqueue `attribute_changed` reactions
- [ ] Update `removeAttribute()` to enqueue `attribute_changed` reactions
- [ ] Update namespaced attribute methods
- [ ] Check observed_attributes before enqueueing
- [ ] Write 8-10 tests for attribute operations

### Day 4: adoptNode + Polish
- [ ] Update `adoptNode()` to enqueue `adopted` reactions
- [ ] Add helper: `enqueueAdoptedReactionsForTree(root, old_doc, new_doc, stack)`
- [ ] Write 4-6 tests for adoption
- [ ] Integration testing across all operations
- [ ] Documentation + CHANGELOG update

---

## Helper Functions to Implement

### 1. enqueueConnectedReactionsForTree()

```zig
/// Enqueues connected reactions for all custom elements in a tree.
///
/// Called after tree is inserted into document (becomes connected).
fn enqueueConnectedReactionsForTree(root: *Node, stack: *CEReactionsStack) !void {
    var node: ?*Node = root;
    while (node) |current| {
        if (current.node_type == .element) {
            const elem: *Element = @fieldParentPtr("prototype", current);
            if (elem.isCustomElement()) {
                const queue = try elem.getOrCreateReactionQueue();
                try queue.enqueue(.{ .connected = {} });
                try stack.enqueueElement(elem);
            }
        }
        
        // Depth-first traversal
        node = treeTraversalNext(current, root);
    }
}
```

### 2. enqueueDisconnectedReactionsForTree()

```zig
/// Enqueues disconnected reactions for all custom elements in a tree.
///
/// Called before tree is removed from document (becomes disconnected).
fn enqueueDisconnectedReactionsForTree(root: *Node, stack: *CEReactionsStack) !void {
    // Similar to connected, but enqueue .disconnected
}
```

### 3. enqueueAttributeChangedReaction()

```zig
/// Enqueues attribute_changed reaction if attribute is observed.
fn enqueueAttributeChangedReaction(
    elem: *Element,
    name: []const u8,
    old_value: ?[]const u8,
    new_value: ?[]const u8,
    namespace: ?[]const u8,
    stack: *CEReactionsStack,
) !void {
    if (!elem.isCustomElement()) return;
    
    const definition = elem.getCustomElementDefinition() orelse return;
    
    // Check if attribute is observed
    if (!definition.observed_attributes.contains(name)) return;
    
    const queue = try elem.getOrCreateReactionQueue();
    try queue.enqueue(.{
        .attribute_changed = .{
            .name = name,
            .old_value = old_value,
            .new_value = new_value,
            .namespace_uri = namespace,
        },
    });
    try stack.enqueueElement(elem);
}
```

### 4. enqueueAdoptedReactionsForTree()

```zig
/// Enqueues adopted reactions for all custom elements in a tree.
fn enqueueAdoptedReactionsForTree(
    root: *Node,
    old_document: *Document,
    new_document: *Document,
    stack: *CEReactionsStack,
) !void {
    // Walk tree, enqueue .adopted for all custom elements
}
```

---

## Test Plan (25-30 Tests)

### Connected Callback Tests (8-10)
1. ✅ appendChild enqueues connected
2. ✅ insertBefore enqueues connected
3. ✅ replaceChild enqueues connected for new node
4. ✅ Connected enqueued for entire subtree
5. ✅ Connected NOT enqueued if already connected
6. ✅ Multiple connected reactions processed in order
7. ✅ Connected fires after tree fully inserted
8. ✅ Nested appendChild operations
9. ✅ prepend() enqueues connected
10. ✅ append() enqueues connected

### Disconnected Callback Tests (6-8)
11. ✅ removeChild enqueues disconnected
12. ✅ replaceChild enqueues disconnected for old node
13. ✅ remove() enqueues disconnected
14. ✅ Disconnected enqueued for entire subtree
15. ✅ Disconnected NOT enqueued if not connected
16. ✅ Disconnected fires before tree removed
17. ✅ Multiple disconnected reactions processed in order
18. ✅ Nested removeChild operations

### Attribute Changed Tests (8-10)
19. ✅ setAttribute enqueues attribute_changed (if observed)
20. ✅ setAttribute NOT enqueued (if not observed)
21. ✅ removeAttribute enqueues attribute_changed
22. ✅ setAttributeNS enqueues with namespace
23. ✅ toggleAttribute enqueues attribute_changed
24. ✅ Multiple attribute changes processed in order
25. ✅ Old value captured correctly
26. ✅ New value captured correctly
27. ✅ Namespace preserved in reaction
28. ✅ setAttribute with same value still enqueues

### Adopted Callback Tests (4-6)
29. ✅ adoptNode enqueues adopted
30. ✅ Adopted enqueued for entire subtree
31. ✅ Old document and new document captured
32. ✅ Adopted fires during adoption
33. ✅ Multiple adoptions processed correctly
34. ✅ Cross-document element movement

---

## Success Criteria for Phase 4

- [ ] All DOM operations with `[CEReactions]` updated
- [ ] 25-30 new tests passing (71-76 total)
- [ ] Zero memory leaks
- [ ] Connected callback fires when element inserted
- [ ] Disconnected callback fires when element removed
- [ ] Attribute changed callback fires for observed attributes only
- [ ] Adopted callback fires during document adoption
- [ ] Nested operations handled correctly
- [ ] CHANGELOG.md updated
- [ ] Completion report written
- [ ] Committed to main branch

---

## Performance Expectations (Phase 4)

| Operation | Without Reactions | With Reactions | Overhead |
|-----------|-------------------|----------------|----------|
| appendChild | ~500 ns | ~1.2 μs | ~700 ns |
| removeChild | ~400 ns | ~1.0 μs | ~600 ns |
| setAttribute | ~800 ns | ~1.5 μs | ~700 ns |
| adoptNode | ~1 μs | ~2 μs | ~1 μs |

**Overhead**: ~600-1000 ns per operation (enqueue + stack operations)

---

## Current Repository State

**Branch**: main  
**Latest Commit**: `510e251`  
**Tests**: 46/46 custom element tests passing  
**Full Suite**: 1111/1112 tests passing (1 skipped)  
**Memory**: Zero leaks

---

## Files to Review Before Starting Phase 4

1. `src/node.zig` - Node operations (appendChild, removeChild, etc.)
2. `src/element.zig` - Element operations (setAttribute, etc.)
3. `src/parent_node.zig` - ParentNode mixin (append, prepend)
4. `src/child_node.zig` - ChildNode mixin (remove, etc.)
5. `src/custom_element_registry.zig` - Reaction types and helpers
6. `src/document.zig` - adoptNode operation
7. `skills/whatwg_compliance/dom.idl` - Check for `[CEReactions]` markers

---

## Quick Start Command

```bash
# Resume session with this command
cd /Users/bcardarella/projects/dom2
git status
zig build test --summary all

# Check which DOM operations need [CEReactions]
grep "\[CEReactions\]" skills/whatwg_compliance/dom.idl
```

---

**Ready to start Phase 4!** 🚀

Remember: Each DOM operation needs:
1. `stack.enter()` at the beginning
2. `defer stack.leave()` for cleanup
3. Enqueue reaction after operation succeeds
4. Check isConnected() / isCustomElement() before enqueueing
