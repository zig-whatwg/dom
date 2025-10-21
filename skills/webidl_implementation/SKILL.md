# WebIDL Implementation Skill

**Purpose**: Guide for implementing WHATWG DOM interfaces in Zig using WebIDL specifications and code generation tools.

**When to use**: When implementing new DOM interfaces, adding methods to existing interfaces, or understanding the delegation/inheritance patterns.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Patterns](#architecture-patterns)
3. [Code Generation Tools](#code-generation-tools)
4. [Implementation Workflow](#implementation-workflow)
5. [Override System](#override-system)
6. [Type Mappings](#type-mappings)
7. [Testing](#testing)
8. [Examples](#examples)

---

## Overview

### WebIDL in WHATWG DOM

WebIDL (Web Interface Definition Language) is the specification language used by WHATWG to define DOM APIs. It describes:
- Interface inheritance hierarchies
- Method signatures and parameters
- Attribute types (readonly or writable)
- Extended attributes (behavioral modifiers)

**Source**: `skills/whatwg_compliance/dom.idl`

### Zig Implementation Strategy

Zig doesn't have inheritance, so we use **prototype chain delegation** to simulate it:

```zig
// WebIDL: interface Element : Node : EventTarget
pub const Element = struct {
    prototype: Node,  // First field - contains Node which contains EventTarget
    
    // Element-specific fields
    tag_name: []const u8,
    // ...
};
```

**Access pattern**:
```zig
element.prototype.appendChild(child);           // Node method
element.prototype.prototype.dispatchEvent(e);   // EventTarget method
```

---

## Architecture Patterns

### Pattern 1: Prototype Chain (Preferred)

**For**: Most interfaces inheriting from Node or EventTarget

**Structure**:
```zig
pub const ChildInterface = struct {
    prototype: ParentInterface,  // MUST be first field
    
    // Child-specific fields
    child_field: SomeType,
};
```

**Advantages**:
- ✅ Automatic inheritance of all ancestor methods
- ✅ Memory-efficient (no duplication)
- ✅ Type-safe at compile time
- ✅ Clear inheritance chain

**Disadvantages**:
- ⚠️ Verbose access: `self.prototype.prototype.method()`
- ⚠️ Must traverse chain for ancestor methods

### Pattern 2: Convenience Wrappers

**For**: Frequently-used ancestor methods that benefit from ergonomics

**Structure**:
```zig
pub const Element = struct {
    prototype: Node,
    // ... fields ...
    
    /// Convenience wrapper for EventTarget.addEventListener
    pub inline fn addEventListener(self: *Element, ...) !void {
        return self.prototype.prototype.addEventListener(...);
    }
    
    /// Convenience wrapper for EventTarget.dispatchEvent  
    pub inline fn dispatchEvent(self: *Element, event: *Event) !bool {
        return self.prototype.prototype.dispatchEvent(event);
    }
};
```

**When to use**:
- Method is called frequently in user code
- Ergonomics matter more than generated code size
- Method signature is simple (no complex types)

**Example**: Element provides wrappers for addEventListener/removeEventListener/dispatchEvent

### Pattern 3: Custom Override

**For**: Methods requiring different implementation than ancestor

**Structure**:
```zig
pub const Node = struct {
    prototype: EventTarget,
    // ... fields ...
    
    /// Custom implementation - NOT simple delegation
    /// EventTarget has simplified version, Node needs full DOM event propagation
    pub fn dispatchEvent(self: *Node, event: *Event) !bool {
        // 70+ lines of capture/target/bubble phase logic
        // NOT just: return self.prototype.dispatchEvent(event);
    }
};
```

**Registry**: Track in `tools/codegen/overrides.json`:
```json
{
  "Node": {
    "dispatchEvent": {
      "reason": "Full DOM event propagation with capture/target/bubble phases",
      "file": "src/node.zig",
      "lines": "2586-2656"
    }
  }
}
```

---

## Code Generation Tools

### Tool 1: Source Analyzer

**Purpose**: Analyze existing implementations to detect patterns

**Usage**:
```bash
zig build analyze -- InterfaceName
```

**Output**:
```
addEventListener():
  Status: simple_delegation
  Action: 🗑️  Remove (old EventTargetMixin pattern)
  
dispatchEvent():
  Status: custom_implementation
  Action: 📝 Add to overrides.json
  Reason: Custom implementation (44 lines)
```

**What it detects**:
1. **Simple delegation** - Wrapper calling ancestor (can remove/replace)
2. **Custom implementation** - Complex logic (add to overrides)
3. **Not found** - Method doesn't exist (can generate)

**Location**: `tools/codegen/analyze.zig`

### Tool 2: Code Generator

**Purpose**: Generate delegation methods from WebIDL

**Usage**:
```bash
zig build codegen -- InterfaceName
```

**Output**: Delegation code with comprehensive documentation

**What it generates**:
- Method delegation with `self.prototype.method()` calls
- Attribute getters/setters
- Full documentation with WebIDL signatures
- Spec URLs for each method
- Inheritance depth tracking

**What it skips**:
- Methods in `overrides.json` (custom implementations)
- Methods with complex types (union/callback)
- Methods the interface overrides in WebIDL

**Location**: `tools/codegen/generator.zig`

### Tool 3: Override Registry

**Purpose**: Track custom implementations that shouldn't be regenerated

**File**: `tools/codegen/overrides.json`

**Format**:
```json
{
  "overrides": {
    "InterfaceName": {
      "methodName": {
        "reason": "Why this is custom",
        "file": "src/interface.zig",
        "lines": "start-end",
        "detected": "2025-10-21"
      }
    }
  }
}
```

**When to add entry**:
1. You implement a method differently than simple delegation
2. Analyzer detects `custom_implementation`
3. Method has complex logic (>10 lines, non-trivial)

---

## Implementation Workflow

### Workflow 1: New Interface from Scratch

**Steps**:

1. **Read WebIDL**
   ```bash
   grep -A 50 "interface YourInterface" skills/whatwg_compliance/dom.idl
   ```

2. **Identify parent**
   ```
   interface YourInterface : ParentInterface {
                             ^^^^^^^^^^^^^^^^
   ```

3. **Create struct with prototype**
   ```zig
   pub const YourInterface = struct {
       prototype: ParentInterface,  // MUST be first field
       
       // Your fields based on WebIDL attributes
       your_field: YourType,
   };
   ```

4. **Generate delegation code**
   ```bash
   zig build codegen -- YourInterface > /tmp/your_interface_delegation.zig
   ```

5. **Review generated code**
   - Check which methods are generated
   - Note which are skipped (complex types, overrides)
   - Decide what to integrate

6. **Add generated methods** (if desired)
   ```zig
   pub const YourInterface = struct {
       prototype: ParentInterface,
       your_field: YourType,
       
       // Option A: No wrappers - use prototype.method() directly
       
       // Option B: Add convenience wrappers for common methods
       pub inline fn commonMethod(self: *YourInterface, ...) !void {
           return self.prototype.commonMethod(...);
       }
       
       // Option C: Copy all generated delegation code
   };
   ```

7. **Implement interface-specific methods**
   ```zig
   /// Methods unique to this interface (from WebIDL)
   pub fn yourUniqueMethod(self: *YourInterface, ...) !void {
       // Implementation
   }
   ```

8. **Test**
   ```bash
   zig build test
   ```

### Workflow 2: Modernize Existing Interface

**Steps**:

1. **Analyze current implementation**
   ```bash
   zig build analyze -- ExistingInterface
   ```

2. **Review analysis results**
   - Identify simple delegations (can modernize)
   - Identify custom implementations (add to overrides)
   - Check for old patterns (EventTargetMixin)

3. **Update overrides.json**
   ```json
   {
     "ExistingInterface": {
       "customMethod": {
         "reason": "From analyzer: Custom implementation (X lines)",
         "file": "src/existing_interface.zig",
         "lines": "start-end"
       }
     }
   }
   ```

4. **Remove old delegation patterns**
   ```zig
   // OLD (remove):
   const Mixin = EventTargetMixin(ExistingInterface);
   return Mixin.method(...);
   
   // NEW (replace with):
   return self.prototype.method(...);
   ```

5. **Generate fresh delegation**
   ```bash
   zig build codegen -- ExistingInterface
   ```
   Generator will respect overrides.json

6. **Test**
   ```bash
   zig build test
   ```

### Workflow 3: Add Method to Existing Interface

**Steps**:

1. **Check WebIDL**
   ```bash
   grep -A 5 "methodName" skills/whatwg_compliance/dom.idl
   ```

2. **Determine if it's custom or inherited**
   - **Custom**: Implement directly in interface
   - **Inherited**: Already available via prototype (test it)

3. **If custom implementation needed**:
   ```zig
   /// methodName() - Interface-specific implementation
   ///
   /// **WebIDL Signature**:
   /// ```webidl
   /// ReturnType methodName(ParamType param);
   /// ```
   ///
   /// **Specification**: https://dom.spec.whatwg.org/#dom-interface-methodname
   pub fn methodName(self: *YourInterface, param: ParamType) !ReturnType {
       // Implementation following WHATWG algorithm
   }
   ```

4. **If it's a custom override of inherited method**:
   - Implement method
   - Add to overrides.json
   - Document why it's custom

---

## Override System

### When to Override

**Override when**:
- ✅ Ancestor's implementation is insufficient for this interface
- ✅ Need different behavior (e.g., Node.dispatchEvent vs EventTarget.dispatchEvent)
- ✅ Performance optimization required
- ✅ Interface-specific side effects needed

**Don't override when**:
- ❌ Ancestor's implementation works correctly
- ❌ Just want convenience (use wrapper instead)
- ❌ Only changing parameter validation (extend ancestor instead)

### Override Registry Format

**File**: `tools/codegen/overrides.json`

**Entry format**:
```json
{
  "overrides": {
    "InterfaceName": {
      "methodName": {
        "reason": "Detailed explanation of why override is needed",
        "file": "src/interface_name.zig",
        "lines": "start-end",
        "detected": "YYYY-MM-DD"
      }
    }
  }
}
```

**Field descriptions**:
- `reason`: **Required**. Explain implementation difference from ancestor
- `file`: Source file with custom implementation
- `lines`: Line range of implementation
- `detected`: Date when override was added/detected

**Example**:
```json
{
  "Node": {
    "dispatchEvent": {
      "reason": "Full DOM event propagation with capture/target/bubble phases (44 lines). EventTarget has simplified version (target-only). Node's version handles tree traversal for capture and bubble propagation.",
      "file": "src/node.zig",
      "lines": "2586-2656",
      "detected": "2025-10-21"
    }
  }
}
```

### How Generator Uses Overrides

When generating delegation for an interface:

1. **Load overrides.json**
2. **For each ancestor method**:
   ```
   IF method in overrides for this interface:
     → Skip generation
     → Add comment: "Custom implementation - not generated"
     → Reference overrides.json
   
   ELSE IF method has complex types (union/callback):
     → Skip generation
     → Add comment: "Complex types - manual implementation needed"
   
   ELSE IF interface overrides in WebIDL:
     → Skip generation  
     → Add comment: "Overridden by Interface - not delegated"
   
   ELSE:
     → Generate delegation code
   ```

3. **Output includes helpful comments**:
   ```zig
   // NOTE: EventTarget.dispatchEvent() has custom implementation - not generated
   // Reason: Full DOM event propagation with capture/target/bubble phases
   // See: overrides.json
   ```

---

## Type Mappings

### WebIDL to Zig Type Conversion

**Primitive types**:
```
WebIDL                  → Zig
--------------------------------
undefined               → void
boolean                 → bool
byte                    → i8
octet                   → u8
short                   → i16
unsigned short          → u16
long                    → i32
unsigned long           → u32
long long               → i64
unsigned long long      → u64
float                   → f32
unrestricted float      → f32
double                  → f64
unrestricted double     → f64
```

**String types**:
```
WebIDL          → Zig
------------------------
DOMString       → []const u8
USVString       → []const u8 (UTF-8 validated)
ByteString      → []const u8 (ASCII only)
```

**Nullable types**:
```
WebIDL          → Zig
------------------------
Type?           → ?Type
DOMString?      → ?[]const u8
```

**DOM types**:
```
WebIDL          → Zig
------------------------
Node            → *Node
Element         → *Element
Node?           → ?*Node
[NewObject] Node → !*Node (can fail)
```

**Collection types**:
```
WebIDL              → Zig
--------------------------------
sequence<Type>      → []Type
FrozenArray<Type>   → []const Type
```

**Complex types** (NOT auto-generated):
```
WebIDL                              → Status
------------------------------------------------
(Type1 or Type2)                    → Skipped (union type)
EventListener?                      → Skipped (callback)
callback interface Type             → Skipped (callback)
```

### Optional Parameters

**WebIDL**:
```webidl
Node cloneNode(optional boolean deep = false);
```

**Current Zig mapping** (limitation):
```zig
// Generator produces (no default support):
pub fn cloneNode(self: anytype, deep: bool) *Node

// Caller must always provide:
element.cloneNode(true);  // Can't omit parameter
```

**Note**: Zig doesn't support default parameter values. Optional parameters become required in generated code.

### Extended Attributes

**Common extended attributes**:

- `[NewObject]` - Returns newly created object (ref_count=1)
  ```zig
  // Caller must release:
  const node = try elem.cloneNode(true);
  defer node.release();
  ```

- `[SameObject]` - Returns same instance each time
  ```zig
  // Don't call release - same object always returned
  const list = elem.childNodes();
  ```

- `[CEReactions]` - Triggers custom element reactions
  ```zig
  // Implementation must call enqueueCEReaction()
  ```

- `[Throws]` - Can throw exceptions
  ```zig
  // Maps to Zig error union: !ReturnType
  ```

---

## Testing

### Test Structure

**Unit tests**: Test interface-specific functionality
```zig
test "YourInterface.yourMethod works correctly" {
    const allocator = std.testing.allocator;
    
    // Setup
    const obj = try YourInterface.create(allocator, ...);
    defer obj.prototype.release();
    
    // Test
    try obj.yourMethod(...);
    
    // Verify
    try std.testing.expectEqual(...);
}
```

**Integration tests**: Test inheritance works
```zig
test "YourInterface inherits ParentInterface methods" {
    const allocator = std.testing.allocator;
    
    const obj = try YourInterface.create(allocator, ...);
    defer obj.prototype.release();
    
    // Test ancestor methods work through prototype
    try obj.prototype.parentMethod(...);
    try obj.prototype.prototype.grandparentMethod(...);
}
```

### Testing Delegation

**Pattern 1: Direct prototype access**:
```zig
test "Element inherits Node.appendChild" {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");
    
    // Access Node method through prototype
    _ = try parent.prototype.appendChild(&child.prototype);
    
    try std.testing.expectEqual(child.prototype.parent_node, &parent.prototype);
}
```

**Pattern 2: Convenience wrapper**:
```zig
test "Element.dispatchEvent convenience wrapper" {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const elem = try doc.createElement("div");
    var event = Event.init("click", .{});
    
    // Use convenience wrapper (delegates to prototype.prototype)
    _ = try elem.dispatchEvent(&event);
}
```

---

## Examples

### Example 1: Simple Interface with Prototype Inheritance

**WebIDL**:
```webidl
interface Text : CharacterData {
  Text splitText(unsigned long offset);
};

interface CharacterData : Node {
  attribute DOMString data;
  readonly attribute unsigned long length;
  // ... more methods
};
```

**Zig Implementation**:
```zig
pub const Text = struct {
    prototype: CharacterData,  // Inherits Node through CharacterData
    
    // Text-specific implementation
    pub fn splitText(self: *Text, offset: u32) !*Text {
        // Implementation
    }
    
    // CharacterData methods available via self.prototype.data
    // Node methods available via self.prototype.prototype.appendChild()
    // EventTarget methods via self.prototype.prototype.prototype.dispatchEvent()
};
```

**Usage**:
```zig
const text = try doc.createTextNode("Hello World");

// Text-specific method
const newText = try text.splitText(5);

// CharacterData method (depth 1)
const data = text.prototype.data;

// Node method (depth 2)
_ = try text.prototype.prototype.appendChild(...);

// EventTarget method (depth 3)
_ = try text.prototype.prototype.prototype.dispatchEvent(...);
```

### Example 2: Interface with Convenience Wrappers

**Zig Implementation**:
```zig
pub const Element = struct {
    prototype: Node,
    tag_name: []const u8,
    attributes: AttributeMap,
    
    // Convenience wrappers for frequently-used methods
    pub inline fn addEventListener(self: *Element, ...) !void {
        return self.prototype.prototype.addEventListener(...);
    }
    
    pub inline fn dispatchEvent(self: *Element, event: *Event) !bool {
        return self.prototype.prototype.dispatchEvent(event);
    }
    
    // Element-specific methods
    pub fn getAttribute(self: *Element, name: []const u8) ?[]const u8 {
        return self.attributes.get(name);
    }
};
```

**Usage**:
```zig
const elem = try doc.createElement("div");

// Convenience wrappers (clean syntax)
try elem.addEventListener("click", callback, ctx, false, false, false, null);
_ = try elem.dispatchEvent(&event);

// Element-specific methods
try elem.setAttribute("class", "container");
const class = elem.getAttribute("class");

// Node methods through prototype
_ = try elem.prototype.appendChild(&child.prototype);
```

### Example 3: Interface with Custom Override

**WebIDL**:
```webidl
interface Node : EventTarget {
  boolean dispatchEvent(Event event);  // Inherited, but overridden
  // ... other methods
};
```

**Zig Implementation**:
```zig
pub const Node = struct {
    prototype: EventTarget,
    parent_node: ?*Node,
    first_child: ?*Node,
    // ... fields
    
    /// Custom override - NOT simple delegation
    /// EventTarget.dispatchEvent is simple (target-only)
    /// Node.dispatchEvent implements full DOM event flow
    pub fn dispatchEvent(self: *Node, event: *Event) !bool {
        // Validate event state
        if (event.dispatch_flag) return error.InvalidStateError;
        
        // Build event path for capture/bubble
        try buildEventPath(self.allocator, self, event);
        defer event.clearEventPath(self.allocator);
        
        // Phase 1: CAPTURING_PHASE - walk down from root
        event.event_phase = .capturing_phase;
        // ... 20 lines of capture phase logic
        
        // Phase 2: AT_TARGET - fire on target
        event.event_phase = .at_target;
        // ... 15 lines of target phase logic
        
        // Phase 3: BUBBLING_PHASE - walk up to root
        event.event_phase = .bubbling_phase;
        // ... 25 lines of bubble phase logic
        
        return !event.canceled_flag;
    }
    
    // Other Node methods delegate normally
    pub inline fn addEventListener(self: *Node, ...) !void {
        return self.prototype.addEventListener(...);
    }
};
```

**overrides.json**:
```json
{
  "Node": {
    "dispatchEvent": {
      "reason": "Full DOM event propagation with capture/target/bubble phases. EventTarget has simplified version (target-only). Node needs tree traversal.",
      "file": "src/node.zig",
      "lines": "2586-2656"
    }
  }
}
```

### Example 4: Generated Delegation Code

**Generated by**: `zig build codegen -- Element`

**Output** (excerpt):
```zig
// ========================================================================
// GENERATED CODE - DO NOT EDIT
// Generated from: skills/whatwg_compliance/dom.idl
// Interface: Element : Node : EventTarget
// ========================================================================

// NOTE: EventTarget.addEventListener() has complex types (union/callback) - requires manual implementation

// NOTE: EventTarget.removeEventListener() has complex types (union/callback) - requires manual implementation

/// dispatchEvent() - Delegated from EventTarget interface
///
/// This method is inherited from the EventTarget interface and automatically
/// delegated to the prototype chain for spec compliance.
///
/// **WebIDL Signature**:
/// ```webidl
/// boolean dispatchEvent(Event event);
/// ```
///
/// **Specification**: https://dom.spec.whatwg.org/#dom-eventtarget-dispatchevent
///
/// **Source**: `EventTarget` interface (depth: 1 in inheritance chain)
///
/// *This is auto-generated delegation code. Do not edit manually.*
pub inline fn dispatchEvent(self: anytype, event: *Event) bool {
    return try self.prototype.dispatchEvent(event);
}

/// appendChild() - Delegated from Node interface
///
/// This method is inherited from the Node interface and automatically
/// delegated to the prototype chain for spec compliance.
///
/// **WebIDL Signature**:
/// ```webidl
/// Node appendChild(Node node);
/// ```
///
/// **Specification**: https://dom.spec.whatwg.org/#dom-node-appendchild
///
/// **Source**: `Node` interface (depth: 2 in inheritance chain)
///
/// *This is auto-generated delegation code. Do not edit manually.*
pub inline fn appendChild(self: anytype, node: *Node) *Node {
    return try self.prototype.prototype.appendChild(node);
}
```

---

## Quick Reference

### Commands
```bash
# Analyze source file for delegation patterns
zig build analyze -- InterfaceName

# Generate delegation code
zig build codegen -- InterfaceName

# Generate for all interfaces
zig build codegen -- all

# Test specific interface
zig build test -- InterfaceName
```

### File Locations
```
skills/whatwg_compliance/dom.idl     # WebIDL specifications
tools/codegen/overrides.json          # Custom implementation registry
tools/codegen/analyze.zig             # Source analyzer tool
tools/codegen/generator.zig           # Code generator
tools/codegen/main.zig                # CLI entry point
```

### Decision Tree

```
Need to implement interface method?
│
├─ Is it inherited from ancestor?
│  │
│  ├─ YES: Does ancestor's implementation work?
│  │  │
│  │  ├─ YES: Use prototype chain (self.prototype.method)
│  │  │      Add convenience wrapper if frequently used
│  │  │
│  │  └─ NO: Implement custom version
│  │         Add to overrides.json
│  │
│  └─ NO: Implement directly in interface
│
└─ Need to modernize existing delegation?
   │
   ├─ Analyze with: zig build analyze -- InterfaceName
   │
   ├─ If simple_delegation found:
   │  └─ Replace with prototype delegation
   │
   └─ If custom_implementation found:
      └─ Add to overrides.json
```

---

## Best Practices

### DO ✅

- ✅ **Read WebIDL first** - Understand the spec before implementing
- ✅ **Use code generator** - Let tools create boilerplate
- ✅ **Track overrides** - Document custom implementations in overrides.json
- ✅ **Prototype-first** - Default to prototype chain inheritance
- ✅ **Convenience when useful** - Wrap frequently-used methods
- ✅ **Test inheritance** - Verify prototype chain works
- ✅ **Document decisions** - Explain why custom implementations needed
- ✅ **Follow patterns** - Be consistent with existing code

### DON'T ❌

- ❌ **Don't duplicate code** - Use delegation instead
- ❌ **Don't ignore generator** - It knows the spec perfectly
- ❌ **Don't skip overrides.json** - Document custom implementations
- ❌ **Don't break prototype chain** - First field must be parent
- ❌ **Don't over-wrapper** - Only wrap what's frequently used
- ❌ **Don't modify generated code** - Regenerate instead
- ❌ **Don't assume types** - Check WebIDL for correct signature
- ❌ **Don't forget tests** - Test both interface and inherited methods

---

## Troubleshooting

### "Method not found" error

**Problem**: Trying to call inherited method directly
```zig
element.appendChild(child);  // ❌ Error: no method named 'appendChild'
```

**Solution**: Access through prototype chain
```zig
element.prototype.appendChild(&child.prototype);  // ✅ Works
```

Or add convenience wrapper:
```zig
pub inline fn appendChild(self: *Element, node: *Node) !*Node {
    return self.prototype.appendChild(node);
}
```

### "Duplicate method" error

**Problem**: Generated code conflicts with existing method
```zig
pub fn dispatchEvent(...) { }  // Existing
// Generated code also has dispatchEvent
```

**Solution**: Add to overrides.json
```json
{
  "YourInterface": {
    "dispatchEvent": {
      "reason": "Custom implementation exists",
      "file": "src/your_interface.zig"
    }
  }
}
```

Then regenerate - generator will skip it.

### Type mismatch errors

**Problem**: Generated type doesn't match actual implementation
```zig
// Generated expects:
pub fn method(self: anytype, param: *Type) !ReturnType

// But Node has:
pub fn method(self: *Node, param: *Type) !ReturnType
```

**Solution**: 
1. Check WebIDL for correct signature
2. Update implementation to match WebIDL
3. If intentionally different, add to overrides.json

### Generated code has wrong prototype depth

**Problem**: Generator produces `self.prototype.method()` but should be `self.prototype.prototype.method()`

**Cause**: Inheritance chain in WebIDL might be wrong

**Solution**:
1. Verify inheritance chain: `grep "interface YourInterface" skills/whatwg_compliance/dom.idl`
2. Check ancestor chain depth
3. Manually adjust if needed (rare)

---

## Related Skills

- **whatwg_compliance** - WebIDL specifications and type mappings
- **zig_standards** - Zig coding patterns and conventions
- **testing_requirements** - Test coverage and patterns
- **documentation_standards** - Documentation format
- **performance_optimization** - Optimization patterns for delegation

---

## Summary

**Key Concepts**:
1. **Prototype Chain** - Zig uses composition to simulate inheritance
2. **Code Generation** - Tools automate delegation boilerplate
3. **Override System** - Track custom implementations to prevent overwriting
4. **Convenience Wrappers** - Add ergonomics where useful
5. **WebIDL First** - Spec is source of truth for signatures

**Tools**:
- `zig build analyze` - Detect patterns in existing code
- `zig build codegen` - Generate delegation from WebIDL
- `overrides.json` - Registry of custom implementations

**Patterns**:
- Prototype inheritance (default)
- Convenience wrappers (ergonomics)
- Custom overrides (when needed)

**Workflow**:
1. Read WebIDL
2. Create struct with prototype
3. Generate delegation
4. Add interface-specific methods
5. Test

---

**This skill ensures consistent, spec-compliant implementation of WHATWG DOM interfaces in Zig.**
