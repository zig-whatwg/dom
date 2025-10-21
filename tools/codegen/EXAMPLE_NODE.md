# Example: Node Delegation Generation

This document shows what the generator will produce for the Node interface.

## Current Status

Node **already has manually-written delegation** in `src/node.zig`:

```zig
pub const Node = struct {
    prototype: EventTarget,
    
    // Manual delegation (written by hand)
    pub inline fn addEventListener(...) !void {
        return try getEventTarget(self).addEventListener(...);
    }
    
    pub inline fn removeEventListener(...) void {
        self.prototype.removeEventListener(...);
    }
    
    pub inline fn dispatchEvent(self: *Self, event: *Event) !bool {
        return try self.prototype.dispatchEvent(event);
    }
};
```

These were written manually as part of the inline delegation effort.

## What the Generator Will Do

Once the generator is complete, it will **replace** manual delegation with **generated** delegation:

### Before (Manual)

```zig
// src/node.zig
pub const Node = struct {
    prototype: EventTarget,
    
    // Hand-written delegation (error-prone, tedious)
    pub inline fn addEventListener(...) !void {
        return try getEventTarget(self).addEventListener(...);
    }
    
    pub inline fn removeEventListener(...) void {
        self.prototype.removeEventListener(...);
    }
    
    pub inline fn dispatchEvent(...) !bool {
        return try self.prototype.dispatchEvent(...);
    }
    
    // If EventTarget adds new methods, must update manually!
};
```

### After (Generated)

```zig
// src/node.zig
pub const Node = struct {
    prototype: EventTarget,
    
    // ========================================================================
    // GENERATED CODE - DO NOT EDIT
    // Generated from: skills/whatwg_compliance/dom.idl
    // Interface: Node : EventTarget
    // Command: zig build codegen -- Node
    // ========================================================================
    
    // ========================================================================
    // GENERATED: EventTarget methods delegation (depth: 1)
    // ========================================================================
    
    /// GENERATED: Delegates to EventTarget.addEventListener
    /// WebIDL: undefined addEventListener(DOMString type, EventListener callback, ...);
    /// Spec: https://dom.spec.whatwg.org/#dom-eventtarget-addeventlistener
    pub inline fn addEventListener(
        self: *Node,
        event_type: []const u8,
        callback: EventCallback,
        context: *anyopaque,
        capture: bool,
        once: bool,
        passive: bool,
        signal: ?*anyopaque,
    ) !void {
        return try self.prototype.addEventListener(
            event_type,
            callback,
            context,
            capture,
            once,
            passive,
            signal,
        );
    }
    
    /// GENERATED: Delegates to EventTarget.removeEventListener
    /// WebIDL: undefined removeEventListener(DOMString type, EventListener callback, ...);
    /// Spec: https://dom.spec.whatwg.org/#dom-eventtarget-removeeventlistener
    pub inline fn removeEventListener(
        self: *Node,
        event_type: []const u8,
        callback: EventCallback,
        capture: bool,
    ) void {
        self.prototype.removeEventListener(event_type, callback, capture);
    }
    
    /// GENERATED: Delegates to EventTarget.dispatchEvent
    /// WebIDL: boolean dispatchEvent(Event event);
    /// Spec: https://dom.spec.whatwg.org/#dom-eventtarget-dispatchevent
    pub inline fn dispatchEvent(self: *Node, event: *Event) !bool {
        return try self.prototype.dispatchEvent(event);
    }
    
    // ========================================================================
    // END GENERATED CODE
    // ========================================================================
};
```

## Benefits of Generated Code

### 1. Automatic Updates
```bash
# If EventTarget spec adds new methods:
zig build codegen -- Node

# Delegation automatically updated!
```

### 2. Consistency
All delegation follows the same pattern:
- ✅ Same doc comment format
- ✅ Same parameter naming
- ✅ Same error handling
- ✅ Spec URLs included

### 3. Zero Human Error
- ✅ No typos in delegation
- ✅ No missing methods
- ✅ No wrong return types

### 4. Self-Documenting
```zig
/// GENERATED: Delegates to EventTarget.addEventListener
/// WebIDL: undefined addEventListener(DOMString type, EventListener callback, ...);
/// Spec: https://dom.spec.whatwg.org/#dom-eventtarget-addeventlistener
```

Every method includes:
- What it delegates to
- WebIDL signature
- WHATWG spec URL

### 5. Complete Coverage
```zig
// Current (manual): 3 methods
addEventListener, removeEventListener, dispatchEvent

// Generated (automatic): ALL EventTarget methods
// If EventTarget has 5 methods, all 5 are delegated automatically
```

## How to Run (Once Complete)

```bash
# Generate delegation for Node
zig build codegen -- Node

# Or regenerate all interfaces
zig build codegen
```

## Current vs. Generated Comparison

| Aspect | Manual (Current) | Generated (Future) |
|--------|------------------|-------------------|
| **Effort** | Write each method by hand | Run one command |
| **Errors** | Typos possible | Zero errors |
| **Updates** | Manual updates needed | Automatic |
| **Documentation** | May be inconsistent | Always complete |
| **Coverage** | May miss methods | 100% coverage |
| **Maintenance** | High effort | Zero effort |

## Example: Adding a New EventTarget Method

### Scenario: WHATWG adds `EventTarget.clearAllListeners()`

**Manual approach** (current):
1. See spec update
2. Remember to update Node
3. Remember to update Element
4. Remember to update Document
5. Remember to update Text
6. Remember to update Comment
7. ... for ALL 11 types!
8. Write delegation manually for each
9. Test each one
10. Hope you didn't miss any

**Generated approach** (future):
```bash
zig build codegen
```

Done. All 11 types updated automatically. ✅

## Why Node is a Good Test Case

1. **Simple hierarchy**: Node : EventTarget (1 level)
2. **Already has manual delegation**: Can compare output
3. **Important interface**: Used by many types
4. **Real-world**: From actual WHATWG spec

## Next Steps

1. ✅ Document example (this file)
2. ⏳ Fix parser ArrayList API (2-3 hours)
3. ⏳ Run generator on real dom.idl
4. ⏳ Compare output with manual delegation
5. ⏳ Integrate into build system

## See Also

- `STATUS.md` - Implementation status
- `../FUTURE_ARCHITECTURE.md` - Vision for multiple generators
- `../webidl-parser/README.md` - Parser documentation
