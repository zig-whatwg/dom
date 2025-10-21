# WebIDL Implementation - Quick Start Guide

**5-minute guide to implementing WebIDL interfaces in Zig**

---

## Tools

```bash
# Analyze existing source for delegation patterns
zig build analyze -- InterfaceName

# Generate delegation code from WebIDL
zig build codegen -- InterfaceName
```

---

## Common Workflows

### 1. Implement New Interface

```bash
# Step 1: Check WebIDL
grep -A 20 "interface NewInterface" skills/whatwg_compliance/dom.idl

# Step 2: Create struct
# src/new_interface.zig
pub const NewInterface = struct {
    prototype: ParentInterface,  // MUST be first field
    // your fields here
};

# Step 3: Generate delegation
zig build codegen -- NewInterface > /tmp/delegation.zig

# Step 4: Review and integrate generated code

# Step 5: Implement interface-specific methods

# Step 6: Test
zig build test
```

### 2. Modernize Existing Delegation

```bash
# Step 1: Analyze current code
zig build analyze -- ExistingInterface

# Step 2: Update overrides.json for custom implementations

# Step 3: Replace old patterns
# OLD: const Mixin = EventTargetMixin(Type);
# NEW: return self.prototype.method(...);

# Step 4: Test
zig build test
```

---

## Patterns

### Pattern 1: Prototype Chain (Most Common)

```zig
pub const Child = struct {
    prototype: Parent,  // First field
    
    // Access parent methods through prototype
    // child.prototype.parentMethod()
};
```

### Pattern 2: Convenience Wrapper

```zig
pub inline fn commonMethod(self: *Child, ...) !void {
    return self.prototype.commonMethod(...);
}
```

### Pattern 3: Custom Override

```zig
// Different implementation than parent
pub fn overriddenMethod(self: *Child, ...) !void {
    // Custom logic here (NOT just delegation)
}

// Add to tools/codegen/overrides.json:
{
  "Child": {
    "overriddenMethod": {
      "reason": "Why custom implementation needed",
      "file": "src/child.zig"
    }
  }
}
```

---

## Type Mappings

```
WebIDL              → Zig
----------------------------
undefined           → void
boolean             → bool
unsigned short      → u16
unsigned long       → u32
DOMString           → []const u8
Node                → *Node
Node?               → ?*Node
sequence<Type>      → []Type
```

---

## Decision Tree

```
Need to call ancestor method?
│
├─ Frequently used?
│  ├─ YES → Add convenience wrapper
│  └─ NO  → Use prototype chain directly
│
└─ Need different implementation?
   └─ YES → Custom override + add to overrides.json
```

---

## Examples

### Access Inherited Method

```zig
// Element inherits from Node
const elem = try doc.createElement("div");
const child = try doc.createElement("span");

// Node.appendChild through prototype
_ = try elem.prototype.appendChild(&child.prototype);
```

### With Convenience Wrapper

```zig
// Element has wrapper
const elem = try doc.createElement("div");
var event = Event.init("click", .{});

// Clean syntax via wrapper
_ = try elem.dispatchEvent(&event);

// Actually calls: elem.prototype.prototype.dispatchEvent(&event)
```

### Custom Override

```zig
// Node overrides EventTarget.dispatchEvent
pub fn dispatchEvent(self: *Node, event: *Event) !bool {
    // Full DOM event flow with capture/bubble
    // NOT: return self.prototype.dispatchEvent(event);
}
```

---

## Troubleshooting

### "Method not found"

**Problem**: `element.appendChild(child)` fails

**Solution**: Access through prototype
```zig
element.prototype.appendChild(&child.prototype)
```

Or add convenience wrapper.

### "Duplicate method"

**Problem**: Generated code conflicts with existing

**Solution**: Add to `tools/codegen/overrides.json`

### Generated code won't compile

**Problem**: Type mismatch

**Solution**: Check WebIDL signature, update implementation or add to overrides

---

## Best Practices

✅ **DO**:
- Check WebIDL first
- Use code generator
- Track overrides in overrides.json
- Test inheritance

❌ **DON'T**:
- Duplicate code manually
- Ignore generated output
- Forget to document overrides
- Break prototype chain

---

## Learn More

See **`skills/webidl_implementation/SKILL.md`** for complete guide including:
- Detailed workflows
- Architecture patterns
- Override system documentation
- Type mapping reference
- Testing strategies
- Multiple examples
- Troubleshooting

---

**Quick Reference**:
- **WebIDL spec**: `skills/whatwg_compliance/dom.idl`
- **Overrides**: `tools/codegen/overrides.json`
- **Analyze**: `zig build analyze -- Interface`
- **Generate**: `zig build codegen -- Interface`
