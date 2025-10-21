# Delegation Debugging Skill

**Purpose**: Guide for debugging issues in delegated methods and determining whether bugs belong in the ancestor implementation or require interface-specific overrides.

**When to use**: When fixing bugs in methods that delegate to ancestor interfaces, determining root cause location, or deciding whether to create custom implementations.

---

## Table of Contents

1. [Overview](#overview)
2. [Debugging Workflow](#debugging-workflow)
3. [Root Cause Analysis](#root-cause-analysis)
4. [Decision Framework](#decision-framework)
5. [Creating Overrides](#creating-overrides)
6. [Testing Strategy](#testing-strategy)
7. [Examples](#examples)
8. [Common Patterns](#common-patterns)

---

## Overview

### The Delegation Chain Challenge

When a method delegates through the prototype chain, bugs can occur at multiple levels:

```zig
Element.method() → Node.method() → EventTarget.method()
     ↓                ↓                    ↓
   Bug here?      Bug here?          Bug here?
```

**Key Question**: Where should the fix be applied?

### Three Possible Outcomes

1. **Fix in Ancestor** - Bug affects all inheriting interfaces
2. **Override in Current Interface** - Bug is interface-specific behavior
3. **Fix in Both** - Ancestor fix + special case override

---

## Debugging Workflow

### Step 1: Reproduce the Bug

**Create minimal test case:**

```zig
test "Bug reproduction: methodName fails with specific input" {
    const allocator = std.testing.allocator;
    
    // Minimal setup to trigger bug
    const obj = try Interface.create(allocator, ...);
    defer obj.prototype.release();
    
    // This should pass but fails
    const result = try obj.methodName(problematic_input);
    
    try std.testing.expectEqual(expected, result);
    // Currently fails with: [error description]
}
```

**Document the failure:**
- What input triggers the bug?
- What's the expected behavior?
- What actually happens?
- Which interface is the entry point?

### Step 2: Trace the Delegation Chain

**Identify the call path:**

```bash
# Find the method in the source
grep -n "pub fn methodName" src/interface.zig

# Check if it's delegated
# Look for: return self.prototype.methodName(...)
```

**Map the chain:**
```
Interface.methodName (lines X-Y)
  ↓ delegates to
AncestorA.methodName (lines A-B)
  ↓ delegates to
AncestorB.methodName (lines M-N)
  ↓ actual implementation
```

### Step 3: Locate Implementation

**Find where the actual work happens:**

1. **Check current interface**:
   ```bash
   grep -A 30 "pub fn methodName" src/current_interface.zig
   ```

2. **If delegation, check ancestor**:
   ```bash
   # Interface delegates to prototype
   grep -A 30 "pub fn methodName" src/ancestor.zig
   ```

3. **Repeat until you find actual implementation** (not just delegation)

**Indicators of actual implementation:**
- Method body > 3 lines
- No `return self.prototype.method()` pattern
- Contains logic, not just forwarding
- Has local variables, conditionals, loops

### Step 4: Understand the Implementation

**Read the implementation thoroughly:**

```zig
pub fn methodName(self: *ActualImplementor, params...) !ReturnType {
    // What does this code do?
    // What assumptions does it make?
    // What edge cases does it handle?
    // What WebIDL spec section does it implement?
}
```

**Check the WebIDL:**
```bash
grep -A 10 "methodName" skills/whatwg_compliance/dom.idl
```

**Check the WHATWG spec:**
- Look up the specification URL
- Read the algorithm completely
- Understand intended behavior
- Check if there are interface-specific notes

### Step 5: Test at Each Level

**Test the actual implementation directly:**

```zig
test "Bug in ActualImplementor.methodName" {
    const allocator = std.testing.allocator;
    
    // Test the ancestor that has the implementation
    const ancestor = try ActualImplementor.create(allocator, ...);
    defer ancestor.release();
    
    // Does the bug exist at this level?
    const result = try ancestor.methodName(problematic_input);
    
    try std.testing.expectEqual(expected, result);
}
```

**If test fails**: Bug is in ancestor implementation.

**If test passes**: Bug is in delegation or interface-specific behavior.

---

## Root Cause Analysis

### Question 1: Does the Bug Affect All Users?

**Test with multiple interface types:**

```zig
test "methodName bug affects Element" {
    const elem = try doc.createElement("div");
    const result = try elem.methodName(input);
    // Fails
}

test "methodName bug affects Text" {
    const text = try doc.createTextNode("text");
    const result = try text.prototype.methodName(input);
    // Also fails? → Ancestor bug
    // Passes? → Element-specific bug
}

test "methodName bug affects Document" {
    const result = try doc.methodName(input);
    // Also fails? → Ancestor bug
    // Passes? → Element-specific bug
}
```

**Decision Matrix:**

| Element | Text | Document | Root Cause |
|---------|------|----------|------------|
| ❌ Fails | ❌ Fails | ❌ Fails | **Ancestor bug** |
| ❌ Fails | ✅ Pass | ✅ Pass | **Element-specific** |
| ❌ Fails | ❌ Fails | ✅ Pass | **Node-level issue** |
| ❌ Fails | ✅ Pass | ❌ Fails | **Mixed issue** |

### Question 2: Does the Spec Indicate Interface-Specific Behavior?

**Check WebIDL for notes:**

```webidl
interface Element : Node {
  // Special behavior for Element
  DOMString methodName(DOMString param);
};

interface Node : EventTarget {
  // General behavior for all nodes
  DOMString methodName(DOMString param);
};
```

**Check WHATWG prose for conditions:**
- Look for "If this is an Element node..."
- Check for "When called on Element..."
- Search for interface-specific algorithm steps

**Example spec patterns indicating override needed:**

```
❌ Ancestor implementation:
"The methodName() method must..."

✅ Interface-specific:
"When called on Element, the methodName() method must first..."
"If the context object is Element, then..."
"Element nodes handle this differently by..."
```

### Question 3: Is It a Delegation Signature Issue?

**Check parameter transformations:**

```zig
// Interface A delegates:
pub fn method(self: *A, param: TypeX) !Result {
    return self.prototype.method(param);  // ← Type mismatch?
}

// Ancestor B expects:
pub fn method(self: *B, param: TypeY) !Result {
    // TypeX != TypeY causes issues
}
```

**Common signature mismatches:**
- Pointer depth: `*Node` vs `Node`
- Nullability: `?*Type` vs `*Type`
- Const qualifiers: `[]const u8` vs `[]u8`
- Node vs specific type: `*Node` vs `*Element`

**Fix approach:**
- If ancestor signature is wrong → Fix ancestor
- If delegation needs conversion → Override with conversion logic

### Question 4: Is It State-Related?

**Does the bug depend on interface-specific state?**

```zig
// Example: Method needs Element's attributes
pub fn methodName(self: *Element, ...) !void {
    // Needs access to self.attributes
    // But ancestor doesn't have attributes field
    
    // → Requires Element-specific override
}
```

**Indicators of state dependency:**
- Method needs fields that only exist in current interface
- Behavior depends on interface type (Element vs Text)
- Side effects differ based on interface specifics

---

## Decision Framework

### Decision Tree

```
Bug found in delegated method
│
├─ Step 1: Test ancestor directly
│  │
│  ├─ Ancestor fails with same input?
│  │  ├─ YES → Go to Step 2
│  │  └─ NO → DECISION: Interface-specific override needed
│  │
├─ Step 2: Test other interfaces using same ancestor
│  │
│  ├─ All fail with same input?
│  │  ├─ YES → DECISION: Fix in ancestor
│  │  └─ NO → Go to Step 3
│  │
├─ Step 3: Check WHATWG spec
│  │
│  ├─ Spec has interface-specific notes?
│  │  ├─ YES → DECISION: Interface-specific override
│  │  └─ NO → Go to Step 4
│  │
└─ Step 4: Analyze root cause
   │
   ├─ State dependency on interface-specific fields?
   │  └─ YES → DECISION: Interface-specific override
   │
   ├─ Type conversion needed for this interface?
   │  └─ YES → DECISION: Interface-specific override
   │
   └─ General algorithmic bug?
      └─ YES → DECISION: Fix in ancestor
```

### Decision: Fix in Ancestor

**When to fix in ancestor:**
- ✅ Bug affects all inheriting interfaces equally
- ✅ No interface-specific behavior in spec
- ✅ Algorithmic error or logic bug
- ✅ Type mapping error affecting all users
- ✅ Edge case not handled correctly

**How to fix:**
1. Create test in ancestor's test file
2. Fix the ancestor implementation
3. Verify all inheriting interfaces pass
4. Document the fix in CHANGELOG.md
5. No changes to overrides.json needed

**Example:**
```zig
// Bug: Node.appendChild doesn't validate input correctly
// Fix: Update Node.appendChild implementation
// Result: Element, Document, DocumentFragment all benefit
```

### Decision: Interface-Specific Override

**When to create override:**
- ✅ Spec indicates interface-specific behavior
- ✅ Only affects one interface type
- ✅ Needs access to interface-specific state
- ✅ Requires type conversion for this interface
- ✅ Performance optimization for specific case

**How to create override:**
1. Remove delegation from current interface
2. Implement custom version
3. Add to overrides.json with detailed reason
4. Test thoroughly
5. Document in CHANGELOG.md

**Process:** See "Creating Overrides" section below.

### Decision: Fix Both

**When to fix both:**
- ⚠️ Ancestor has general bug + interface needs special case
- ⚠️ Ancestor algorithm is mostly correct but interface has edge case
- ⚠️ Need to fix ancestor AND optimize for specific interface

**How to fix both:**
1. Fix ancestor implementation (benefits all)
2. Create override for special case (benefits one)
3. Document relationship between fixes
4. Add override to overrides.json
5. Update both test suites

---

## Creating Overrides

### Step-by-Step Process

#### 1. Remove Generated Delegation

**Before:**
```zig
/// methodName() - Delegated from Ancestor interface
pub inline fn methodName(self: anytype, params...) !ReturnType {
    return try self.prototype.methodName(params...);
}
```

**After:**
```zig
// Remove the generated delegation completely
// Will be replaced with custom implementation
```

#### 2. Implement Custom Version

**Template:**
```zig
/// methodName() - Custom implementation for Interface
///
/// **Why Custom**:
/// [Explain why this interface needs different implementation]
/// 
/// **WebIDL Signature**:
/// ```webidl
/// ReturnType methodName(ParamType param);
/// ```
///
/// **Specification**: https://dom.spec.whatwg.org/#dom-interface-methodname
///
/// **Differences from Ancestor**:
/// - [Difference 1]
/// - [Difference 2]
///
/// **See**: tools/codegen/overrides.json for override reasoning
pub fn methodName(self: *Interface, params: ParamTypes) !ReturnType {
    // Custom implementation here
    
    // Option A: Completely different algorithm
    // ... custom logic ...
    
    // Option B: Call ancestor with modifications
    // ... pre-processing ...
    const result = try self.prototype.methodName(modified_params);
    // ... post-processing ...
    return result;
    
    // Option C: Conditional delegation
    if (special_case) {
        // Handle special case
        return special_result;
    } else {
        // Delegate to ancestor
        return try self.prototype.methodName(params);
    }
}
```

#### 3. Add to Overrides Registry

**Edit `tools/codegen/overrides.json`:**

```json
{
  "overrides": {
    "InterfaceName": {
      "methodName": {
        "reason": "Detailed explanation of why override is needed. Include: (1) What bug was fixed, (2) Why it's interface-specific, (3) How it differs from ancestor, (4) Spec references if applicable.",
        "file": "src/interface_name.zig",
        "lines": "start-end",
        "created": "YYYY-MM-DD",
        "bug_reference": "Issue #123 or test name"
      }
    }
  }
}
```

**Required fields:**
- `reason`: **Critical**. Explain the "why" thoroughly
- `file`: Source file location
- `lines`: Line range of implementation
- `created`: Date when override was created
- `bug_reference`: Link to bug report or failing test

#### 4. Verify Generator Respects Override

**Test the generator:**
```bash
# Generate delegation code
zig build codegen -- InterfaceName

# Check output includes skip comment
# Should see: "NOTE: methodName has custom implementation - not generated"
```

**Expected output:**
```zig
// NOTE: Interface.methodName() has custom implementation - not generated
// Reason: [Your reason from overrides.json]
// See: tools/codegen/overrides.json
```

#### 5. Test Thoroughly

**Test the override:**
```zig
test "Interface.methodName custom implementation" {
    const allocator = std.testing.allocator;
    
    // Test the specific behavior that required override
    const obj = try Interface.create(allocator, ...);
    defer obj.prototype.release();
    
    // Test case that failed before override
    const result = try obj.methodName(problematic_input);
    try std.testing.expectEqual(expected, result);
    
    // Test that normal cases still work
    const normal_result = try obj.methodName(normal_input);
    try std.testing.expectEqual(normal_expected, normal_result);
}

test "Interface.methodName differs from ancestor" {
    // Document how it differs
    const obj = try Interface.create(allocator, ...);
    defer obj.prototype.release();
    
    const ancestor = try Ancestor.create(allocator, ...);
    defer ancestor.release();
    
    // Same input, different output
    const obj_result = try obj.methodName(input);
    const ancestor_result = try ancestor.methodName(input);
    
    try std.testing.expect(obj_result != ancestor_result);
    // Document why they should differ
}
```

#### 6. Document in CHANGELOG

**Add to CHANGELOG.md:**
```markdown
### Fixed

- **Interface.methodName override** 🐛→✅
  - Created custom implementation for Interface-specific behavior
  - Bug: [Description of what was broken]
  - Root cause: [Why ancestor implementation wasn't sufficient]
  - Fix: [What the override does differently]
  - Added to overrides.json: Interface.methodName
  - Tests: [Test names that verify the fix]
  - Spec: [Relevant WHATWG spec sections]
```

---

## Testing Strategy

### Test Suite for Overrides

**Create comprehensive test coverage:**

```zig
// ============================================================================
// OVERRIDE TESTING: Interface.methodName
// Reason: [Brief reason from overrides.json]
// ============================================================================

test "methodName - original bug case" {
    // The test case that revealed the need for override
    // This MUST pass with override, MUST fail with ancestor delegation
}

test "methodName - interface-specific behavior" {
    // Test the behavior that's unique to this interface
    // Should differ from ancestor behavior
}

test "methodName - edge cases" {
    // Test edge cases specific to this interface
}

test "methodName - normal cases still work" {
    // Ensure override doesn't break normal functionality
}

test "methodName - compared to ancestor" {
    // Document how this differs from ancestor
    // May intentionally have different results
}

test "methodName - spec compliance" {
    // Test against WHATWG spec requirements
    // Especially interface-specific spec notes
}
```

### Regression Testing

**Ensure override doesn't break other interfaces:**

```bash
# Run full test suite
zig build test

# Check that other interfaces still work
grep -r "methodName" tests/

# Verify no unexpected test failures
```

### Integration Testing

**Test with real-world usage:**

```zig
test "methodName in realistic scenario" {
    // Create realistic DOM structure
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const parent = try doc.createElement("parent");
    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);
    
    // Test override in realistic context
    const result = try parent.methodName(...);
    
    // Verify behavior matches expectations
}
```

---

## Examples

### Example 1: Bug in Ancestor (Fix Ancestor)

**Scenario**: Element.normalize() fails with certain text node configurations

**Investigation:**

```zig
test "Element.normalize fails with empty text nodes" {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const elem = try doc.createElement("div");
    const text1 = try doc.createTextNode("");
    const text2 = try doc.createTextNode("text");
    
    _ = try elem.prototype.appendChild(&text1.prototype);
    _ = try elem.prototype.appendChild(&text2.prototype);
    
    try elem.prototype.normalize();  // Crashes!
}
```

**Step 1: Check delegation chain**
```bash
$ grep -A 5 "pub fn normalize" src/element.zig
# Not found - Element doesn't override

$ grep -A 5 "pub fn normalize" src/node.zig
pub fn normalize(self: *Node) !void {
    // Implementation here - THIS is where the bug is
}
```

**Step 2: Test Node directly**
```zig
test "Node.normalize fails with empty text nodes" {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const parent = &doc.prototype;  // Document is a Node
    const text1 = try doc.createTextNode("");
    const text2 = try doc.createTextNode("text");
    
    _ = try parent.appendChild(&text1.prototype);
    _ = try parent.appendChild(&text2.prototype);
    
    try parent.normalize();  // Also crashes!
}
```

**Step 3: Test other interfaces**
```zig
test "DocumentFragment.normalize has same bug" {
    // Also crashes - confirms it's Node-level bug
}
```

**Decision**: ✅ Fix in Node (ancestor)

**Fix:**
```zig
// src/node.zig
pub fn normalize(self: *Node) !void {
    // Bug was here: didn't check for empty text nodes
    var current = self.first_child;
    while (current) |node| {
        if (node.node_type == .text) {
            const text = @as(*Text, @ptrCast(@alignCast(node)));
            // FIX: Skip empty text nodes
            if (text.data.len == 0) {
                current = node.next_sibling;
                _ = try self.removeChild(node);
                continue;
            }
            // ... rest of normalize logic
        }
        current = node.next_sibling;
    }
}
```

**Result**: 
- ✅ Fixed in Node
- ✅ All interfaces benefit
- ✅ No override needed
- ✅ No changes to overrides.json

### Example 2: Interface-Specific Behavior (Create Override)

**Scenario**: Element.cloneNode() needs to copy attributes, but Text.cloneNode() doesn't

**Investigation:**

```zig
test "Element.cloneNode should copy attributes" {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const elem = try doc.createElement("div");
    try elem.setAttribute("data-id", "123");
    
    const clone = try elem.prototype.cloneNode(false);
    const clone_elem = @as(*Element, @ptrCast(@alignCast(clone)));
    
    // BUG: Attributes not copied!
    const value = clone_elem.getAttribute("data-id");
    try std.testing.expect(value != null);  // FAILS
}
```

**Step 1: Check Node.cloneNode()**
```zig
// src/node.zig
pub fn cloneNode(self: *Node, deep: bool) !*Node {
    // Creates new node of same type
    // Copies basic node properties
    // Does NOT copy attributes (Node doesn't have attributes!)
}
```

**Step 2: Test Text.cloneNode()**
```zig
test "Text.cloneNode works correctly" {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const text = try doc.createTextNode("hello");
    const clone = try text.prototype.cloneNode(false);
    
    // Works fine - Text doesn't need attributes
    try std.testing.expectEqualStrings("hello", clone.data);
}
```

**Step 3: Check WHATWG spec**
```
WebIDL spec for Element:
"When cloneNode() is called on Element, 
the attributes must be copied to the clone."

This is Element-specific behavior!
```

**Decision**: ✅ Element-specific override needed

**Implementation:**

```zig
// src/element.zig

/// cloneNode() - Custom implementation for Element
///
/// **Why Custom**:
/// Element needs to copy attributes to the clone, which is Element-specific
/// behavior not handled by Node.cloneNode(). Per WHATWG DOM §4.10, when
/// cloneNode() is invoked on Element, all attributes must be copied.
///
/// **WebIDL Signature**:
/// ```webidl
/// [NewObject] Node cloneNode(optional boolean deep = false);
/// ```
///
/// **Specification**: https://dom.spec.whatwg.org/#dom-node-clonenode
///
/// **Differences from Node.cloneNode()**:
/// - Copies all attributes to the clone
/// - Maintains attribute order and namespace
/// - Then delegates to Node.cloneNode() for deep cloning children
///
/// **See**: tools/codegen/overrides.json for full reasoning
pub fn cloneNode(self: *Element, deep: bool) !*Node {
    // Step 1: Create basic node clone via Node.cloneNode
    const clone_node = try self.prototype.cloneNode(false);
    const clone_elem = @as(*Element, @ptrCast(@alignCast(clone_node)));
    
    // Step 2: Copy Element-specific data (attributes)
    var it = self.attributes.iterator();
    while (it.next()) |entry| {
        try clone_elem.setAttribute(entry.key_ptr.*, entry.value_ptr.*);
    }
    
    // Step 3: If deep, clone children (let Node handle this)
    if (deep) {
        var child = self.prototype.first_child;
        while (child) |child_node| {
            const child_clone = try child_node.cloneNode(true);
            _ = try clone_node.appendChild(child_clone);
            child = child_node.next_sibling;
        }
    }
    
    return clone_node;
}
```

**Add to overrides.json:**
```json
{
  "Element": {
    "cloneNode": {
      "reason": "Element.cloneNode must copy attributes to the clone per WHATWG DOM §4.10. Node.cloneNode doesn't handle attributes because Node doesn't have attributes. This is interface-specific behavior documented in the spec.",
      "file": "src/element.zig",
      "lines": "1234-1267",
      "created": "2025-10-21",
      "bug_reference": "test: Element.cloneNode should copy attributes"
    }
  }
}
```

**Result**:
- ✅ Element has custom cloneNode
- ✅ Text still uses Node.cloneNode (works correctly)
- ✅ Override tracked in registry
- ✅ Generator will skip Element.cloneNode

### Example 3: Type Conversion Needed (Create Override)

**Scenario**: Element.appendChild() should return *Element not *Node for convenience

**Investigation:**

```zig
test "Element.appendChild should return Element for chaining" {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");
    
    // BUG: Returns *Node, but user wants *Element
    const returned = try parent.prototype.appendChild(&child.prototype);
    // returned is *Node, can't access Element methods directly
    
    // User wants to do:
    // const returned = try parent.appendChild(child);
    // try returned.setAttribute("class", "added");
    // But returned is *Node, not *Element!
}
```

**Step 1: Check Node.appendChild()**
```zig
// src/node.zig
pub fn appendChild(self: *Node, child: *Node) !*Node {
    // Returns *Node (generic)
    // This is correct for Node level
}
```

**Step 2: Decide if override needed**

This is **ergonomics/convenience**, not a bug. But it's a common pattern.

**Decision**: ⚠️ Optional - Create convenience override

**Implementation:**

```zig
// src/element.zig

/// appendChild() - Convenience override returning *Element
///
/// **Why Custom**:
/// Provides better ergonomics by returning *Element instead of *Node,
/// allowing direct access to Element methods without casting.
/// This is a convenience wrapper, not a behavioral difference.
///
/// **WebIDL Signature**:
/// ```webidl
/// Node appendChild(Node node);
/// ```
///
/// **Differences from Node.appendChild()**:
/// - Returns *Element instead of *Node for convenience
/// - Otherwise identical behavior
/// - Still delegates to Node.appendChild for actual work
///
/// **See**: tools/codegen/overrides.json
pub fn appendChild(self: *Element, child: *Node) !*Element {
    const result = try self.prototype.appendChild(child);
    return @as(*Element, @ptrCast(@alignCast(result)));
}
```

**Add to overrides.json:**
```json
{
  "Element": {
    "appendChild": {
      "reason": "Convenience wrapper that returns *Element instead of *Node for better ergonomics. Allows method chaining with Element-specific methods. Behavior is identical to Node.appendChild, just type conversion for return value.",
      "file": "src/element.zig",
      "lines": "890-894",
      "created": "2025-10-21",
      "bug_reference": "Ergonomics improvement for Element API"
    }
  }
}
```

**Alternative**: Don't override, just cast when needed:
```zig
const returned_node = try parent.prototype.appendChild(&child.prototype);
const returned_elem = @as(*Element, @ptrCast(@alignCast(returned_node)));
```

---

## Common Patterns

### Pattern 1: Validation Error in Ancestor

**Symptom**: Method rejects valid input for specific interface

**Example**:
```zig
// Node.insertBefore validates that new_child isn't parent
// But for DocumentFragment, this check is too strict
```

**Solution**: Fix validation in ancestor to handle all cases correctly

### Pattern 2: Missing Interface-Specific Side Effect

**Symptom**: Method works but doesn't trigger interface-specific behavior

**Example**:
```zig
// Element.setAttribute should trigger custom element reactions
// But base implementation doesn't know about custom elements
```

**Solution**: Override in Element to add CE reaction triggers

### Pattern 3: State Access Needed

**Symptom**: Method needs fields that don't exist in ancestor

**Example**:
```zig
// Element.method needs self.attributes
// But Node doesn't have attributes field
```

**Solution**: Override in Element to access Element-specific state

### Pattern 4: Performance Optimization

**Symptom**: Ancestor implementation correct but slow for specific interface

**Example**:
```zig
// Node.querySelector traverses entire tree
// Document.querySelector can use indexed structures
```

**Solution**: Override in Document with optimized implementation

### Pattern 5: Type-Specific Algorithm

**Symptom**: Same method name but fundamentally different algorithm per spec

**Example**:
```zig
// Node.textContent concatenates all descendant text
// Element.textContent might need HTML parsing considerations
```

**Solution**: Override with interface-specific algorithm

---

## Checklist

### Before Creating Override

- [ ] Reproduced bug with minimal test case
- [ ] Traced delegation chain to find implementation
- [ ] Tested ancestor implementation directly
- [ ] Tested other interfaces using same ancestor
- [ ] Read WHATWG spec completely for this method
- [ ] Checked for interface-specific spec notes
- [ ] Determined root cause (ancestor vs interface-specific)
- [ ] Confirmed override is necessary

### When Creating Override

- [ ] Removed delegated version (if exists)
- [ ] Implemented custom version with full documentation
- [ ] Added detailed entry to overrides.json
- [ ] Created comprehensive test suite
- [ ] Verified generator skips this method
- [ ] Tested all edge cases
- [ ] Compared behavior to ancestor (document differences)
- [ ] Updated CHANGELOG.md

### After Creating Override

- [ ] Full test suite passes
- [ ] Override is documented in three places:
  - [ ] overrides.json (registry)
  - [ ] Inline documentation (code)
  - [ ] CHANGELOG.md (user-facing)
- [ ] Generator produces correct skip comment
- [ ] Other interfaces still work correctly
- [ ] No regression in existing tests

---

## Quick Reference

### Debugging Commands

```bash
# Find method location
grep -n "pub fn methodName" src/*.zig

# Check if delegated
grep -A 3 "pub fn methodName" src/interface.zig | grep "prototype"

# Check WebIDL
grep -A 10 "methodName" skills/whatwg_compliance/dom.idl

# Test generator
zig build codegen -- InterfaceName | grep methodName

# Run specific test
zig build test -- "test name"
```

### Decision Quick Check

```
Bug in delegated method?
│
├─ Ancestor fails same test? → Fix ancestor
├─ Only this interface fails? → Check spec
│  ├─ Spec has interface notes? → Override
│  └─ No interface notes? → Fix ancestor
├─ Needs interface-specific state? → Override
└─ Type conversion only? → Optional override (ergonomics)
```

### Override Registry Template

```json
{
  "InterfaceName": {
    "methodName": {
      "reason": "Why override needed (be detailed)",
      "file": "src/interface_name.zig",
      "lines": "start-end",
      "created": "YYYY-MM-DD",
      "bug_reference": "Test name or issue #"
    }
  }
}
```

---

## Related Skills

- **webidl_implementation** - How to implement WebIDL interfaces
- **testing_requirements** - Test coverage and patterns
- **whatwg_compliance** - Reading specifications
- **zig_standards** - Zig coding patterns

---

## Summary

**Key Principles:**

1. **Test the ancestor first** - Determine if bug is at ancestor level
2. **Test all interfaces** - See if bug affects multiple inheritors
3. **Read the spec** - Check for interface-specific notes
4. **Fix in ancestor when possible** - Benefits all interfaces
5. **Override when necessary** - Track in registry with detailed reasoning
6. **Document thoroughly** - Three places: registry, code, changelog

**Common Mistakes:**

- ❌ Creating override without testing ancestor
- ❌ Fixing ancestor when interface-specific behavior needed
- ❌ Not checking spec for interface-specific notes
- ❌ Forgetting to add to overrides.json
- ❌ Insufficient documentation of override reasoning

**Remember:**

The delegation chain is a powerful pattern, but requires careful debugging to determine where fixes belong. When in doubt, test at each level and consult the spec.

**This skill ensures bugs are fixed at the right level and overrides are properly tracked.**
