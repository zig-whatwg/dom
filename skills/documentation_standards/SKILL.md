# Documentation Standards Skill

## ⚠️ CRITICAL: Generic DOM Library - Documentation Rules

**THIS IS A GENERIC DOM LIBRARY** - Documentation examples MUST use generic element/attribute names.

### Documentation Naming Rules

✅ **ALWAYS use in examples**:
- Elements: `element`, `container`, `item`, `node`, `component`, `widget`, `panel`, `view`, `content`, `wrapper`, `parent`, `child`, `root`
- Attributes: `attr1`, `attr2`, `data-id`, `data-name`, `key`, `value`, `flag`

❌ **NEVER use in examples**:
- NO HTML elements: `div`, `span`, `p`, `a`, `button`, `input`, `form`, `table`, `body`, `html`
- NO HTML attributes: `id`, `class`, `href`, `src`, `type`, `name`, `placeholder`

### Example Documentation Pattern

```zig
//! ## Usage Examples
//!
//! ### Creating Elements
//! ```zig
//! // ✅ CORRECT: Generic element names
//! const parent = try doc.createElement("container");
//! const child = try doc.createElement("item");
//! _ = try parent.node.appendChild(&child.node);
//! ```
//!
//! ❌ **WRONG**: Using HTML element names like "div", "span"
```

## When to use this skill

Load when:
- Writing inline documentation for public APIs
- Updating README.md
- Maintaining CHANGELOG.md
- Documenting design decisions
- Creating completion reports

## What this skill provides

Documentation standards for the project based on the reference `/Users/bcardarella/projects/dom` library:
- Module-level documentation format (`//!` comments)
- Function and type documentation (`///` comments)
- Specification references (WHATWG + MDN)
- Usage examples and common patterns
- Security annotations
- README.md update workflow
- CHANGELOG.md format (Keep a Changelog 1.1.0)

---

## Documentation Style (Based on Reference Library)

### Module-Level Documentation (`//!`)

**Every file MUST start with comprehensive module-level documentation using `//!` comments.**

#### Structure

```zig
//! [Title] - [Brief Description]
//!
//! [Detailed overview paragraph explaining what this module implements]
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§X.Y [Section Name]**: https://dom.spec.whatwg.org/#section
//! - **§X.Z [Related Section]**: https://dom.spec.whatwg.org/#related
//!
//! ## MDN Documentation
//!
//! - [Interface Name]: https://developer.mozilla.org/en-US/docs/Web/API/InterfaceName
//! - [Method Name]: https://developer.mozilla.org/en-US/docs/Web/API/Interface/method
//! - [Property Name]: https://developer.mozilla.org/en-US/docs/Web/API/Interface/property
//!
//! ## Core Features
//!
//! ### [Feature Category 1]
//! [Description of feature with code example]
//! ```zig
//! // ✅ CORRECT: Use generic element names in examples
//! const container = try doc.createElement("container");
//! const item = try doc.createElement("item");
//! _ = try container.node.appendChild(&item.node);
//! ```
//!
//! ### [Feature Category 2]
//! [Description with code example]
//!
//! ## [Additional Section - Architecture/Memory/etc.]
//!
//! [Details about internal structure, memory management, etc.]
//!
//! ## Usage Examples
//!
//! ### [Common Use Case 1]
//! ```zig
//! // Complete working example
//! ```
//!
//! ### [Common Use Case 2]
//! ```zig
//! // Another example
//! ```
//!
//! ## Performance Tips
//!
//! 1. **[Tip 1]** - explanation
//! 2. **[Tip 2]** - explanation
//!
//! ## JavaScript Bindings
//!
//! **REQUIRED for all public DOM API types (Node, Element, Document, Event, etc.)**
//! **SKIP for internal utilities (validation, tree_helpers, rare_data, etc.)**
//!
//! This section documents how JavaScript developers will interact with this DOM interface
//! when creating bindings. It shows the JavaScript API surface that maps to the Zig implementation.
//!
//! ### Instance Properties
//! ```javascript
//! // Example: Element.tagName (readonly)
//! Object.defineProperty(Element.prototype, 'tagName', {
//!   get: function() { return zig.element_get_tag_name(this._ptr); }
//! });
//!
//! // Example: Element.id (read-write)
//! Object.defineProperty(Element.prototype, 'id', {
//!   get: function() { return zig.element_get_id(this._ptr); },
//!   set: function(value) { zig.element_set_id(this._ptr, value); }
//! });
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // Example: Element.setAttribute()
//! Element.prototype.setAttribute = function(name, value) {
//!   return zig.element_setAttribute(this._ptr, name, value);
//! };
//!
//! // Example: Element.getAttribute()
//! Element.prototype.getAttribute = function(name) {
//!   return zig.element_getAttribute(this._ptr, name);
//! };
//! ```
//!
//! ### Static Methods (if applicable)
//! ```javascript
//! // Example: AbortSignal.abort()
//! AbortSignal.abort = function(reason) {
//!   return zig.abortsignal_abort(reason);
//! };
//! ```
//!
//! ### Constructor (if applicable)
//! ```javascript
//! // Example: Event constructor
//! function Event(type, eventInitDict) {
//!   const opts = eventInitDict || {};
//!   this._ptr = zig.event_init(
//!     type,
//!     opts.bubbles || false,
//!     opts.cancelable || false,
//!     opts.composed || false
//!   );
//! }
//! ```
//!
//! ### Usage Examples
//! ```javascript
//! // Show real JavaScript code using the API
//! const element = document.createElement('div');
//! element.tagName; // 'DIV'
//! element.setAttribute('id', 'main');
//! element.id; // 'main'
//! ```
//!
//! **Reference:** See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Security Notes (if applicable)
//!
//! Describe security considerations, limits, and best practices.
```

#### Real Example from Reference Library

```zig
//! Element Interface (§4.9)
//!
//! This module implements the Element interface as specified by the WHATWG DOM Standard.
//! Elements are the most commonly used nodes in the DOM tree and represent HTML/XML elements.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.9 Interface Element**: https://dom.spec.whatwg.org/#element
//! - **§4.9.1 Interface NamedNodeMap**: https://dom.spec.whatwg.org/#namednodemap
//! - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#parentnode
//!
//! ## MDN Documentation
//!
//! - Element: https://developer.mozilla.org/en-US/docs/Web/API/Element
//! - Element.attributes: https://developer.mozilla.org/en-US/docs/Web/API/Element/attributes
//! - Element.classList: https://developer.mozilla.org/en-US/docs/Web/API/Element/classList
//!
//! ## Core Features
//!
//! ### Attributes Management
//! Elements can have named attributes that provide metadata:
//! ```zig
//! const element = try Element.create(ctx, "input");
//! try Element.setAttribute(element, "type", "text");
//! const type_attr = Element.getAttribute(element, "type"); // "text"
//! ```
//!
//! ### Class List Management
//! The `class` attribute is special and gets automatic classList synchronization:
//! ```zig
//! try Element.setClassName(element, "btn btn-primary active");
//! // class_list contains: ["btn", "btn-primary", "active"]
//! ```
//!
//! ## Memory Management
//!
//! Elements use reference counting through the Node interface:
//! ```zig
//! const element = try Element.create(ctx, "div");
//! defer element.release(); // Decrements ref count, frees if 0
//! ```
//!
//! ## Common Patterns
//!
//! ### Building a DOM Tree
//! ```zig
//! const article = try Element.create(ctx, "article");
//! defer article.release();
//!
//! const header = try Element.create(ctx, "header");
//! _ = try article.appendChild(header);
//! ```
//!
//! ## Performance Tips
//!
//! 1. **getElementById** is faster than querySelector for single elements
//! 2. **querySelector** stops at first match (good for single elements)
//! 3. **Class list operations** are automatically synced with class attribute
```

### Key Principles for Module Documentation

1. **Start with spec section number** in title when applicable
2. **Always include WHATWG + MDN links** in separate sections
3. **Provide complete working examples** (not fragments)
4. **Show common patterns** section with real use cases
5. **Include performance tips** for hot paths
6. **Document memory management** explicitly
7. **JavaScript bindings** for all public DOM API (REQUIRED)
8. **Security notes** for security-critical code

---

## Type and Const Documentation (`///`)

### Structure Documentation

```zig
/// [Brief one-line description].
///
/// [Detailed explanation of purpose, behavior, and usage]
///
/// ## [Section if needed - Fields/Parameters/etc.]
///
/// [Details with bullet lists if helpful]
///
/// ## Reference (optional)
///
/// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#section
/// * MDN Web Docs: https://developer.mozilla.org/...
///
/// ## Security Note (if applicable)
///
/// **[Category]**: [Security consideration]
pub const TypeName = struct {
    // ...
};
```

### Real Examples

```zig
/// Represents an event listener with its configuration options.
///
/// An event listener consists of a callback function and various flags that control
/// how the listener behaves during event dispatch.
///
/// ## Specification
///
/// As defined in the DOM Standard (§2.7 Interface EventTarget):
/// "An event listener can be used to observe a specific event and consists of:
/// - type (a string)
/// - callback (null or an EventListener object)
/// - capture (a boolean, initially false)
/// - once (a boolean, initially false)"
///
/// ## Fields
///
/// - `callback`: The function to invoke when the event is dispatched
/// - `capture`: Whether this listener is for the capture phase
/// - `once`: Whether this listener should be removed after being invoked once
///
/// ## Reference
///
/// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#concept-event-listener
///
/// ## Security Note (P2)
///
/// **Callback Lifetime**: The callback function pointer must remain valid for the
/// lifetime of the listener. Failure to ensure this can lead to use-after-free.
pub const EventListener = struct {
    callback: *const fn (event: *Event) void,
    capture: bool,
    once: bool,
};
```

```zig
/// Security limits to prevent DoS attacks and resource exhaustion.
/// These limits can be adjusted based on application requirements.
pub const SecurityLimits = struct {
    /// Maximum DOM tree depth to prevent stack overflow attacks (P0)
    /// Default: 1000 levels
    pub const max_tree_depth: usize = 1000;

    /// Maximum reference count to prevent overflow (P0)
    /// Default: 1 million references
    pub const max_ref_count: usize = 1_000_000;
};
```

---

## Function Documentation

### Public Functions (`pub fn`)

**Every public function MUST have documentation.**

```zig
/// [Brief one-line description].
///
/// [Detailed explanation of what the function does, its purpose, and behavior]
///
/// ## Parameters
///
/// - `param1`: Description
/// - `param2`: Description
///
/// ## Returns
///
/// Description of return value
///
/// ## Errors (if applicable)
///
/// - `error.ErrorName`: When and why
///
/// ## Example (optional for complex functions)
///
/// ```zig
/// // Usage example
/// ```
///
/// ## Specification (if implements spec method)
///
/// See: https://dom.spec.whatwg.org/#dom-method-name
pub fn functionName(param1: Type1, param2: Type2) !ReturnType {
    // Implementation
}
```

### Private/Internal Functions

Private functions should have brief documentation:

```zig
/// Validates a tag name according to XML naming rules and security limits.
///
/// ## Security (P1)
///
/// Prevents:
/// - Memory exhaustion from extremely long tag names
/// - Injection attacks from special characters
///
/// ## Returns
///
/// error.TagNameTooLong if exceeds max length
/// error.InvalidCharacter if contains invalid characters
fn validateTagName(tag_name: []const u8) !void {
    // Implementation
}
```

---

## Field Documentation

### Struct Fields

```zig
pub const Element = struct {
    /// Base Node (MUST be first field for @fieldParentPtr to work)
    node: Node,

    /// Tag name (pointer to interned string, 8 bytes)
    /// e.g., "div", "span", "custom-element"
    tag_name: []const u8,

    /// Attribute map (16 bytes)
    /// Stores name→value pairs (both interned strings)
    attributes: AttributeMap,

    /// Bloom filter for fast class matching (8 bytes)
    /// Used by querySelector to quickly reject non-matching elements
    class_bloom: BloomFilter,
};
```

**Principles:**
- Include type size in bytes for memory-critical structs
- Explain purpose and usage
- Note any special requirements (like field ordering)
- Provide examples in comments for complex fields

---

## Code Comments

### When to Comment

```zig
// ✅ GOOD: Explain WHY, not WHAT
// Fast path: Skip UTF-8 decoding for pure ASCII (most common case)
// This provides 0% overhead for English element names.
if (is_pure_ascii) {
    return validateAsciiName(name);
}

// ✅ GOOD: Explain non-obvious behavior
// Note: We don't normalize case because XML is case-sensitive
// per XML 1.1 §2.3, unlike HTML5.
const name = tag_name; // No normalization

// ✅ GOOD: Mark security-critical sections
// Security (P1): Validate depth before recursion to prevent stack overflow
if (depth > SecurityLimits.max_tree_depth) {
    return SecurityError.MaxTreeDepthExceeded;
}

// ❌ BAD: Obvious comments
// Increment counter by 1
counter += 1;

// ❌ BAD: Outdated comments
// Returns null if not found (WRONG: now returns error)
pub fn find() !*Node { }
```

### Section Separators

Use comment separators for logical sections:

```zig
// ============================================================================
// Input Validation (P1 Security)
// ============================================================================

/// Validates input...
fn validateInput() !void {
    // ...
}

// ============================================================================
// Core DOM Operations
// ============================================================================

/// Creates element...
pub fn createElement() !*Element {
    // ...
}
```

---

## Security Annotations

### Priority Levels

- **(P0)**: Critical - memory safety, crashes
- **(P1)**: High - DoS, resource exhaustion
- **(P2)**: Medium - best practices, monitoring

### Documentation Style

```zig
/// ## Security (P1)
///
/// Prevents:
/// - Memory exhaustion from extremely long tag names
/// - Injection attacks from special characters
/// - Parser confusion from invalid characters
///
/// ## Security Note (P2)
///
/// **Callback Lifetime**: The callback function pointer must remain valid for the
/// lifetime of the listener. Failure to ensure this can lead to use-after-free.
///
/// **Best Practices**:
/// - Use static or global functions when possible
/// - Call removeEventListener() before freeing any callback context
```

---

## README.md Standards

### Update After Each Phase

1. Update "WHATWG DOM Compliance" section (mark ✅)
2. Update test count badge
3. Update phase status line
4. Move completed phase to "Complete"

### Example Phase Documentation

```markdown
### ✅ Phase 2 - Tree Manipulation (Complete)

**Node Interface** - Tree modification operations
- ✅ `appendChild(node)` - Append child to parent
- ✅ `insertBefore(node, child)` - Insert node before reference
- ✅ `removeChild(child)` - Remove child from parent
- ✅ `replaceChild(node, child)` - Replace child with new node
- ✅ `textContent` property - Get/set descendant text content
- ✅ `contains(other)` - Check if node is descendant
```

---

## CHANGELOG.md Standards

Follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).

### Categories

- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security fixes

### Writing Guidelines

**Keep entries concise (1-2 sentences max) but descriptive.**

✅ GOOD:

```markdown
### Added
- Unicode support for element/attribute names per XML 1.1 §2.3 with fast-path for ASCII
- CSS selector bytecode compiler with 2-3x performance improvement

### Fixed
- Memory leak in Element.closest() when parent chain contains null
- ReDoS vulnerability in CSS selector parser with complexity limits

### Security
- Added resource quotas to prevent DoS (max 100k nodes, 1k tree depth)
```

❌ BAD:

```markdown
### Added
- Added stuff (Too vague)
- Unicode (Not descriptive)
- Full Unicode support... (Too verbose, save for docs)
```

### Update Process

```bash
# 1. Make code changes
# 2. Add concise CHANGELOG entry (1-2 sentences)
# 3. Commit CHANGELOG with your changes
```

---

## JavaScript Bindings Documentation (Public DOM API)

### Purpose

JavaScript bindings documentation serves multiple critical purposes:

1. **Bindings Implementation Guide** - Shows developers how to create JavaScript wrappers around Zig code
2. **API Surface Documentation** - Documents the JavaScript-facing API (not just Zig internals)
3. **WebIDL Compliance** - Ensures the exposed API matches WHATWG and WebIDL specifications exactly
4. **Integration Testing** - Provides examples for validating bindings work correctly

### Critical: WHATWG & WebIDL Compliance

**JavaScript bindings MUST match the WebIDL specification EXACTLY.**

Before writing JS bindings:

1. ✅ **Check `dom.idl`** in `skills/whatwg_compliance/` for the exact WebIDL interface definition
2. ✅ **Verify property names** match WebIDL (case-sensitive: `tagName`, not `tag_name`)
3. ✅ **Verify method signatures** match WebIDL (parameters, return types, nullability)
4. ✅ **Check extended attributes** ([NewObject], [SameObject], [CEReactions], etc.)
5. ✅ **Verify readonly vs read-write** for properties
6. ✅ **Check for static methods** vs instance methods
7. ✅ **Verify constructor signature** if applicable

**Reference Documents:**
- `skills/whatwg_compliance/dom.idl` - Complete WebIDL definitions
- `skills/whatwg_compliance/webidl_mapping.md` - WebIDL→Zig→JavaScript type mappings

### When to Include

**✅ INCLUDE for:**
- All WHATWG DOM interfaces (Node, Element, Document, Event, EventTarget, etc.)
- All Web API types (AbortController, AbortSignal, NodeList, DOMTokenList, etc.)
- Any type that will be exposed to JavaScript

**❌ SKIP for:**
- Internal utilities (validation.zig, tree_helpers.zig, rare_data.zig)
- Implementation details not exposed to JavaScript
- Entry points (main.zig, root.zig)
- Internal data structures

### Structure and Placement

**Location:** Between "Performance Tips" and "Implementation Notes" sections

**Template:**
```zig
//! ## JavaScript Bindings
//!
//! [Brief note about the interface, e.g., "EventTarget is exposed as a mixin"]
//!
//! ### Static Methods (if applicable)
//! ```javascript
//! [JavaScript static method examples]
//! ```
//!
//! ### Constructor (if applicable)
//! ```javascript
//! [JavaScript constructor example]
//! ```
//!
//! ### Instance Properties
//! ```javascript
//! [JavaScript property definitions with Object.defineProperty]
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! [JavaScript method definitions on prototype]
//! ```
//!
//! ### Usage Examples (optional but recommended)
//! ```javascript
//! [Real JavaScript code showing how to use the API]
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
```

### Property Documentation Pattern

**CRITICAL: Property names MUST match WebIDL exactly (case-sensitive).**

Check `dom.idl` for exact property name. Common examples:
- ✅ `tagName` (not `tag_name`) 
- ✅ `nodeType` (not `node_type`)
- ✅ `childNodes` (not `child_nodes`)
- ✅ `firstChild` (not `first_child`)

**Readonly Properties:**
```javascript
// propertyName (readonly) - Per WebIDL: readonly attribute DOMString propertyName;
Object.defineProperty(TypeName.prototype, 'propertyName', {
  get: function() { return zig.typename_get_propertyname(this._ptr); }
});
```

**Read-Write Properties:**
```javascript
// propertyName (read-write) - Per WebIDL: attribute DOMString propertyName;
Object.defineProperty(TypeName.prototype, 'propertyName', {
  get: function() { return zig.typename_get_propertyname(this._ptr); },
  set: function(value) { zig.typename_set_propertyname(this._ptr, value); }
});
```

**Nullable Properties:**
```javascript
// parentNode (readonly, nullable) - Per WebIDL: readonly attribute Node? parentNode;
Object.defineProperty(Node.prototype, 'parentNode', {
  get: function() { 
    const ptr = zig.node_get_parent_node(this._ptr);
    return ptr ? wrapNode(ptr) : null; // Null check required
  }
});
```

**[SameObject] Properties (Always returns same reference):**
```javascript
// signal (readonly) - [SameObject] per WebIDL
Object.defineProperty(AbortController.prototype, 'signal', {
  get: function() { return zig.abortcontroller_get_signal(this._ptr); }
});
```

### Method Documentation Pattern

**CRITICAL: Method names MUST match WebIDL exactly (case-sensitive).**

Check `dom.idl` for exact method signature. Common patterns:
- ✅ `appendChild` (not `append_child`)
- ✅ `insertBefore` (not `insert_before`)
- ✅ `getAttribute` (not `get_attribute`)
- ✅ `addEventListener` (not `add_event_listener`)

**WebIDL Return Type Mapping:**
- `undefined` → `void` (no return statement needed)
- `Node` → return wrapped Node object
- `Node?` → return wrapped Node or null
- `boolean` → return boolean value
- `DOMString` → return string value

**Simple Methods:**
```javascript
// Per WebIDL: Node appendChild(Node node);
TypeName.prototype.appendChild = function(node) {
  return zig.typename_appendChild(this._ptr, node._ptr);
};

// Per WebIDL: undefined setAttribute(DOMString name, DOMString value);
Element.prototype.setAttribute = function(name, value) {
  zig.element_setAttribute(this._ptr, name, value);
  // No return - 'undefined' in WebIDL
};
```

**Methods with Optional/Nullable Arguments:**
```javascript
// Per WebIDL: Node insertBefore(Node node, Node? child);
//                                              ^^^ nullable parameter
Node.prototype.insertBefore = function(node, child) {
  return zig.node_insertBefore(
    this._ptr, 
    node._ptr, 
    child ? child._ptr : null  // Handle nullable argument
  );
};
```

**Methods with Options Dictionaries:**
```javascript
EventTarget.prototype.addEventListener = function(type, listener, options) {
  // Parse options (can be boolean for capture or object)
  const opts = typeof options === 'boolean' 
    ? { capture: options } 
    : (options || {});
  
  return zig.eventtarget_addEventListener(
    this._ptr,
    type,
    listener,
    opts.capture || false,
    opts.once || false,
    opts.passive || false,
    opts.signal || null
  );
};
```

**Static Methods:**
```javascript
// Static method on constructor
AbortSignal.abort = function(reason) {
  return zig.abortsignal_abort(reason);
};
```

### Constructor Documentation Pattern

**Simple Constructor:**
```javascript
function Event(type, eventInitDict) {
  const opts = eventInitDict || {};
  this._ptr = zig.event_init(
    type,
    opts.bubbles || false,
    opts.cancelable || false,
    opts.composed || false
  );
}
```

**Constructor with Defaults:**
```javascript
function Element(tagName) {
  // In bindings implementation:
  this._ptr = zig.element_create(tagName);
}
```

### Inheritance Documentation

When a type inherits methods/properties from a parent:

```javascript
// Text inherits all Node properties (nodeType, nodeName, nodeValue, etc.)
// Text inherits all Node methods (appendChild, insertBefore, etc.)
// Text inherits all EventTarget methods (addEventListener, etc.)
```

This reminds developers that the full API surface includes inherited members.

### Usage Examples

Include 1-3 practical JavaScript examples showing the API in action:

```javascript
// Create and configure element
const element = document.createElement('div');
element.id = 'main';
element.className = 'container active';

// Manipulate DOM
const child = document.createElement('span');
child.textContent = 'Hello';
element.appendChild(child);

// Event handling
element.addEventListener('click', (e) => {
  console.log('Clicked:', e.target);
});
```

### WebIDL Type Mapping (MUST Follow Exactly)

**Reference:** See `skills/whatwg_compliance/webidl_mapping.md` for complete type mappings.

Common WebIDL → JavaScript mappings to use in bindings:

| WebIDL Type | JavaScript Type | Binding Pattern | Notes |
|-------------|-----------------|-----------------|-------|
| `undefined` | `void` | No return statement | **CRITICAL: Not boolean!** |
| `DOMString` | `string` | Return string value | UTF-8 encoded |
| `DOMString?` | `string \| null` | Return string or null | Check for null |
| `boolean` | `boolean` | Return true/false | |
| `unsigned long` | `number` | Return number | 0 to 2³²-1 |
| `unsigned short` | `number` | Return number | 0 to 65535 |
| `Node` | `Node` | Return wrapped object | Non-null pointer |
| `Node?` | `Node \| null` | Return wrapped or null | Nullable pointer |
| `[NewObject] Element` | `Element` | Return new instance | Caller owns |
| `[SameObject] NodeList` | `NodeList` | Return cached instance | Always same ref |
| `sequence<Node>` | `Node[]` | Return array | Dynamic list |

**Extended Attribute Compliance:**

```javascript
// [NewObject] - Method returns newly allocated object
// Per WebIDL: [NewObject] Element createElement(DOMString localName);
Document.prototype.createElement = function(localName) {
  return zig.document_createElement(this._ptr, localName); // Returns new Element
};

// [SameObject] - Property returns THE SAME instance every time
// Per WebIDL: [SameObject] readonly attribute NodeList childNodes;
Object.defineProperty(Node.prototype, 'childNodes', {
  get: function() { 
    return zig.node_get_childNodes(this._ptr); // Always returns same NodeList
  }
});

// [CEReactions] - Method triggers custom element callbacks
// Per WebIDL: [CEReactions] undefined setAttribute(DOMString name, DOMString value);
Element.prototype.setAttribute = function(name, value) {
  zig.element_setAttribute(this._ptr, name, value); // Triggers CE reactions internally
};
```

### Constants Documentation

For enums and constants:

```javascript
// Event phase constants
Event.NONE = 0;
Event.CAPTURING_PHASE = 1;
Event.AT_TARGET = 2;
Event.BUBBLING_PHASE = 3;

// Node type constants
Node.ELEMENT_NODE = 1;
Node.TEXT_NODE = 3;
Node.COMMENT_NODE = 8;
// ...
```

### Mixin Documentation

For mixins (EventTarget, ParentNode, etc.):

```javascript
//! **Note:** EventTarget is a mixin in this implementation. In JavaScript, it's exposed as
//! instance methods on objects that implement EventTarget (Node, Element, Document, etc.).
//!
//! ### Instance Methods (Mixed into Node, Element, Document, etc.)
//! ```javascript
//! EventTarget.prototype.addEventListener = function(type, listener, options) {
//!   // ...
//! };
//! ```
```

### Reference to Complete Guide

Always end with:

```zig
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
```

This points to the comprehensive 715-line guide that covers:
- Memory management patterns
- Error handling
- Property descriptor patterns
- WebIDL extended attributes
- Complete implementation examples

### Real-World Example

See `src/element.zig`, `src/node.zig`, `src/event.zig`, or `src/abort_controller.zig` for complete examples of this pattern in practice.

### Verification Process

**After writing JS bindings documentation, verify accuracy:**

1. **Cross-check with dom.idl:**
   ```bash
   # Find interface definition
   grep -A 50 "interface Element" skills/whatwg_compliance/dom.idl
   ```

2. **Verify property names match:**
   - WebIDL: `readonly attribute DOMString tagName;`
   - JS Binding: `'tagName'` (not `'tag_name'`)

3. **Verify method signatures match:**
   - WebIDL: `undefined setAttribute(DOMString name, DOMString value);`
   - JS Binding: Two parameters, no return (undefined → void)

4. **Verify type mappings:**
   - `undefined` → void (no return statement)
   - `Node?` → null checks required
   - `[NewObject]` → returns new instance
   - `[SameObject]` → returns cached instance

5. **Check for completeness:**
   - All properties from WebIDL interface documented
   - All methods from WebIDL interface documented
   - Inherited members noted (e.g., "Node inherits from EventTarget")

**Common Verification Failures:**

```javascript
// ❌ WRONG: Zig naming convention
Element.prototype.tag_name // Should be 'tagName'

// ❌ WRONG: Returning boolean for undefined
Element.prototype.setAttribute = function(name, value) {
  return zig.element_setAttribute(this._ptr, name, value); // Should not return
};

// ❌ WRONG: Missing null check for nullable type
Node.prototype.insertBefore = function(node, child) {
  return zig.node_insertBefore(this._ptr, node._ptr, child._ptr); // child might be null!
};

// ✅ CORRECT: Proper null handling
Node.prototype.insertBefore = function(node, child) {
  return zig.node_insertBefore(this._ptr, node._ptr, child ? child._ptr : null);
};
```

---

## Examples Section Format

### In Module Documentation

```zig
//! ## Usage Examples
//!
//! ### [Use Case Title]
//! ```zig
//! // Complete, runnable example
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const elem = try doc.createElement("div");
//! try Element.setAttribute(elem, "id", "content");
//! _ = try doc.node.appendChild(elem);
//! ```
//!
//! ### [Another Use Case]
//! ```zig
//! // Another complete example
//! ```
```

**Principles:**
- Examples must be **complete and runnable**
- Include setup **and** cleanup (defer)
- Show real use cases, not toy examples
- Demonstrate best practices (memory management, error handling)

---

## Documentation Checklist

### Module-Level (`//!`)

- [ ] Title with spec section if applicable
- [ ] Detailed overview paragraph
- [ ] WHATWG Specification section with links
- [ ] MDN Documentation section with links
- [ ] Core Features section with examples
- [ ] Memory Management section
- [ ] Usage Examples section (2-3 common patterns)
- [ ] Performance Tips section (if performance-critical)
- [ ] **JavaScript Bindings section (REQUIRED for public DOM API)**
- [ ] Security Notes (if security-relevant)

### JavaScript Bindings Section (Public DOM API Only)

**Before Writing - WebIDL Verification:**
- [ ] Located exact interface in `skills/whatwg_compliance/dom.idl`
- [ ] Verified property names match WebIDL exactly (case-sensitive)
- [ ] Verified method names match WebIDL exactly (case-sensitive)
- [ ] Checked for extended attributes ([NewObject], [SameObject], [CEReactions])
- [ ] Verified readonly vs read-write for properties
- [ ] Verified parameter types and nullability (`Node?` vs `Node`)
- [ ] Verified return types (`undefined` vs `Node` vs `Node?`)
- [ ] Checked constructor signature if applicable
- [ ] Checked for static methods vs instance methods

**Documentation Content:**
- [ ] Instance properties with Object.defineProperty examples
- [ ] Instance methods with prototype assignments
- [ ] Static methods (if applicable)
- [ ] Constructor examples (if applicable)
- [ ] Usage examples in JavaScript
- [ ] WebIDL comments showing source (e.g., `// Per WebIDL: readonly attribute DOMString tagName;`)
- [ ] Correct type mappings (`undefined` → void, not bool!)
- [ ] Nullable type handling (`Node?` → null checks)
- [ ] Extended attribute handling ([SameObject], [NewObject])
- [ ] Reference to `JS_BINDINGS.md` for complete patterns

**When to include JS bindings:**
- ✅ Public DOM interfaces (Node, Element, Document, Event, Text, Comment, etc.)
- ✅ Public Web APIs (AbortController, AbortSignal, NodeList, etc.)
- ❌ Internal utilities (validation, tree_helpers, rare_data, etc.)
- ❌ Entry points (main.zig, root.zig)

**Common Errors to Avoid:**
- ❌ Using Zig naming (snake_case) instead of WebIDL naming (camelCase)
- ❌ Returning boolean for `undefined` return type
- ❌ Missing null checks for nullable types (`Node?`)
- ❌ Ignoring extended attributes ([SameObject], [NewObject])
- ❌ Wrong parameter order or types
- ❌ Missing readonly marker for readonly properties

### Type-Level (`///`)

- [ ] Brief one-line description
- [ ] Detailed explanation
- [ ] Spec reference if implements WHATWG type
- [ ] Security note if security-relevant
- [ ] Field documentation (purpose, size, constraints)

### Function-Level (`///`)

- [ ] Brief one-line description
- [ ] Detailed behavior explanation
- [ ] Parameters section
- [ ] Returns section
- [ ] Errors section (if fallible)
- [ ] Spec reference if implements WHATWG method
- [ ] Example (if complex)

---

## Integration with Other Skills

This skill coordinates with:
- **whatwg_compliance** - Reference spec URLs correctly, verify WebIDL signatures for JS bindings
- **zig_standards** - Format Zig doc comments properly
- **testing_requirements** - Document test coverage and purpose

**Critical for JS Bindings:**

When writing JavaScript bindings documentation, **ALWAYS load `whatwg_compliance` skill** to:
1. Check `dom.idl` for exact WebIDL interface definition
2. Verify property/method names (case-sensitive)
3. Verify type signatures and nullability
4. Check extended attributes ([NewObject], [SameObject], [CEReactions])
5. Reference `webidl_mapping.md` for type mappings

**Workflow:**
```
1. Load whatwg_compliance skill
2. Read complete interface from dom.idl
3. Write Zig implementation (zig_standards skill)
4. Document with JS bindings (this skill + whatwg_compliance)
5. Verify bindings match WebIDL exactly
6. Test bindings (testing_requirements skill)
```

Load all relevant skills for complete documentation guidance.
