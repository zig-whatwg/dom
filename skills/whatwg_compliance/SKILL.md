# WHATWG Specification Compliance Skill

## When to use this skill

Load this skill automatically when:
- Implementing any DOM interface or method
- Verifying WebIDL signatures and return types
- Understanding WHATWG algorithm specifications
- Checking spec compliance for features
- Looking up type mappings between WebIDL and Zig

## What this skill provides

This skill contains complete, authoritative WHATWG DOM and WebIDL specifications - NOT fragments or grep results. Read specifications holistically to understand:

- Complete interface definitions with inheritance relationships
- Full algorithm specifications with all steps
- Type system definitions and constraints
- Edge cases documented in related sections
- Cross-references between interfaces

## Files in this skill

### `dom.idl` (23KB)
Complete WebIDL interface definitions for the entire DOM Standard. Contains:
- All interface declarations (Event, EventTarget, Node, Element, Document, etc.)
- Method signatures with exact return types
- Attribute definitions with nullability markers
- Interface mixins and inheritance relationships
- Dictionary and enum definitions

**Usage**: Read complete interfaces, not individual methods. Understand inheritance chains.

### `dom_spec_complete.md` (Reference)
Full WHATWG DOM prose specification (301KB) located at:
`/Users/bcardarella/projects/specs/whatwg/dom.md`

Contains:
- Algorithm specifications with numbered steps
- Semantic descriptions and behavior
- Edge case handling
- Historical notes and compatibility requirements

**Usage**: Read entire algorithm sections to understand complete behavior.

### `webidl_spec_complete.md` (Reference)
Full WebIDL specification (552KB) located at:
`/Users/bcardarella/projects/specs/whatwg/webidl.md`

Contains:
- WebIDL grammar and syntax
- Type system definitions
- Extended attributes ([CEReactions], [SameObject], [NewObject], etc.)
- Binding behavior specifications

**Usage**: Understand extended attributes and type system rules.

## Critical Principles

### 1. Dual Specification Compliance

**BOTH WebIDL AND WHATWG prose MUST be consulted for every feature.**

```zig
// Step 1: Check WebIDL in dom.idl for EXACT signature
// Find: interface Element : Node {
//         undefined removeAttribute(DOMString qualifiedName);
//       }

// Step 2: Read complete algorithm from dom_spec_complete.md
// Find: § 4.9 "To remove an attribute by name..."
// Read: ENTIRE algorithm, not just first paragraph

// Step 3: Implement with correct signature + complete behavior
pub fn removeAttribute(self: *Element, qualified_name: []const u8) void {
    // Note: 'undefined' in WebIDL = 'void' in Zig (not bool!)
    // Implementation follows all algorithm steps
}
```

### 2. NO Grep-Based Workflow

**WRONG** ❌:
```bash
grep "removeAttribute" /Users/bcardarella/projects/webref/ed/idl/dom.idl
# Returns: undefined removeAttribute(DOMString qualifiedName);
# Missing: Interface context, inheritance, related methods
```

**CORRECT** ✅:
```bash
# Read complete Element interface from dom.idl
# Understand:
# - Element extends Node (inherits Node methods)
# - removeAttribute relates to setAttribute, getAttribute, etc.
# - [CEReactions] annotation on setAttribute affects tree mutation
# - Namespace variants (removeAttributeNS) exist
```

### 3. Read Complete Sections

When implementing a feature:
1. **Find the interface** in `dom.idl` - read the ENTIRE interface
2. **Read related mixins** - ParentNode, ChildNode, etc.
3. **Read the algorithm** in `dom_spec_complete.md` - read ALL steps
4. **Check inheritance** - read parent interface (e.g., Node for Element)
5. **Verify extended attributes** - [CEReactions], [SameObject], etc.

## WebIDL to Zig Type Mapping

| WebIDL Type | Zig Type | Notes |
|-------------|----------|-------|
| `undefined` | `void` | **CRITICAL**: Not `bool`! No return value |
| `DOMString` | `[]const u8` | UTF-8 string slice |
| `DOMString?` | `?[]const u8` | Nullable string |
| `USVString` | `[]const u8` | UTF-8, validated as Unicode scalar values |
| `boolean` | `bool` | true/false |
| `unsigned long` | `u32` | 32-bit unsigned integer |
| `unsigned short` | `u16` | 16-bit unsigned integer |
| `Node` | `*Node` | Non-null pointer |
| `Node?` | `?*Node` | Nullable pointer |
| `[NewObject] Element` | `!*Element` | Returns new object, may fail (allocation) |
| `[SameObject] NodeList` | `*NodeList` | Returns cached instance (never allocates) |
| `sequence<T>` | `[]T` or `ArrayList(T)` | Dynamic array |
| `any` | `anyopaque` or union | Context-dependent |

## Common Extended Attributes

### `[CEReactions]` - Custom Element Reactions
Methods that modify the tree and trigger custom element callbacks.

```zig
// WebIDL: [CEReactions] undefined setAttribute(DOMString name, DOMString value);
// Implementation must trigger custom element reactions if needed
pub fn setAttribute(self: *Element, name: []const u8, value: []const u8) void {
    // 1. Validate name
    // 2. Set attribute
    // 3. Trigger CE reactions (if custom element)
}
```

### `[SameObject]` - Cached Instance
Attribute must return THE SAME object instance every call (never create new).

```zig
// WebIDL: [SameObject] readonly attribute NodeList childNodes;
// MUST cache NodeList and return same instance
pub fn childNodes(self: *Node) *NodeList {
    // Return cached NodeList from rare data
    // Do NOT create new NodeList on each call
}
```

### `[NewObject]` - New Instance
Method returns a newly created object (requires allocation).

```zig
// WebIDL: [NewObject] Element createElement(DOMString localName);
pub fn createElement(self: *Document, local_name: []const u8) !*Element {
    // Returns new Element, caller owns first reference
    return try Element.create(self.context, local_name);
}
```

## Implementation Workflow

### Step 1: Read Complete WebIDL Interface

```zig
// From dom.idl, read ENTIRE Element interface (lines 410-475)
// Not just one method!

[Exposed=Window]
interface Element : Node {
  readonly attribute DOMString? namespaceURI;
  readonly attribute DOMString? prefix;
  readonly attribute DOMString localName;
  readonly attribute DOMString tagName;

  [CEReactions] attribute DOMString id;
  [CEReactions] attribute DOMString className;
  [SameObject, PutForwards=value] readonly attribute DOMTokenList classList;
  
  boolean hasAttributes();
  [SameObject] readonly attribute NamedNodeMap attributes;
  sequence<DOMString> getAttributeNames();
  
  DOMString? getAttribute(DOMString qualifiedName);
  [CEReactions] undefined setAttribute(DOMString qualifiedName, DOMString value);
  [CEReactions] undefined removeAttribute(DOMString qualifiedName);
  boolean hasAttribute(DOMString qualifiedName);
  
  // ... more methods
};
```

**Notice:**
- `Element extends Node` - inherits all Node methods
- `getAttribute` returns `DOMString?` (nullable)
- `setAttribute` returns `undefined` (void in Zig)
- `setAttribute` has `[CEReactions]` annotation
- `attributes` has `[SameObject]` - must cache

### Step 2: Read Complete Algorithm

From `dom_spec_complete.md`, find algorithm section and read **ALL steps**:

```markdown
## 4.9 Element interface

### setAttribute(qualifiedName, value)
The setAttribute(qualifiedName, value) method steps are:

1. If qualifiedName does not match the Name production, then throw an "InvalidCharacterError" DOMException.
2. If this is in the HTML namespace and its node document is an HTML document, then set qualifiedName to qualifiedName in ASCII lowercase.
3. Let attribute be the first attribute in this's attribute list whose qualified name is qualifiedName, and null otherwise.
4. If attribute is null, create an attribute whose local name is qualifiedName, value is value, and node document is this's node document, then append this attribute to this, and then return.
5. Change attribute to value.
```

**Read ALL steps**, not just step 1. Understanding complete behavior prevents bugs.

### Step 3: Check Inheritance and Mixins

```webidl
// Element extends Node
interface Element : Node { ... }

// Element includes mixins
Element includes ParentNode;
Element includes ChildNode;
Element includes NonDocumentTypeChildNode;
Element includes Slottable;

// Read ALL of these to understand complete Element API
```

### Step 4: Implement with Documentation

```zig
/// Sets an attribute on the element.
///
/// Implements WHATWG DOM Element.setAttribute() per §4.9.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] undefined setAttribute(DOMString qualifiedName, DOMString value);
/// ```
///
/// ## Algorithm (from spec § 4.9)
/// 1. Validate qualifiedName matches Name production (XML 1.1 §2.3)
/// 2. Lowercase if HTML namespace and HTML document
/// 3. Find existing attribute or create new
/// 4. Set attribute value
/// 5. Trigger custom element reactions ([CEReactions])
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-element-setattribute
/// - WebIDL: dom.idl:450
///
/// ## Parameters
/// - `qualified_name`: Attribute name (must be valid XML Name)
/// - `value`: Attribute value (any string)
///
/// ## Errors
/// - `error.InvalidCharacterError`: Invalid character in qualified_name
pub fn setAttribute(
    self: *Element,
    qualified_name: []const u8,
    value: []const u8,
) DOMError!void {
    // Implementation follows all algorithm steps from spec
}
```

## Verification Checklist

Before marking any implementation complete:

- [ ] Read **complete** WebIDL interface (not grep snippet)
- [ ] Read **complete** algorithm from spec (all steps)
- [ ] Verified return type from WebIDL (`undefined` → `void`)
- [ ] Checked nullability markers (`?` in WebIDL → optional in Zig)
- [ ] Reviewed extended attributes ([CEReactions], [SameObject], etc.)
- [ ] Understood inheritance relationships (extends, includes)
- [ ] Checked for namespace variants (e.g., setAttributeNS)
- [ ] Read related methods for context
- [ ] Documentation includes BOTH spec references (WebIDL + prose)
- [ ] Tests verify spec-compliant behavior (all algorithm steps)

## Common Mistakes to Avoid

### ❌ Mistake 1: Grep-Based Implementation
```bash
grep "getAttribute" dom.idl
# Returns: DOMString? getAttribute(DOMString qualifiedName);
# Implements just this one method, misses:
# - Related setAttribute, removeAttribute, hasAttribute
# - Namespace variants getAttributeNS
# - [SameObject] attributes accessor
# - Inheritance from Node
```

### ❌ Mistake 2: Wrong Return Type
```zig
// WebIDL: undefined removeAttribute(DOMString qualifiedName);

// WRONG:
pub fn removeAttribute(self: *Element, name: []const u8) bool {
    // 'undefined' is NOT bool!
}

// CORRECT:
pub fn removeAttribute(self: *Element, name: []const u8) void {
    // 'undefined' in WebIDL = 'void' in Zig
}
```

### ❌ Mistake 3: Incomplete Algorithm
```zig
// Reading only step 1 of setAttribute algorithm:
pub fn setAttribute(self: *Element, name: []const u8, value: []const u8) !void {
    try validateName(name); // Step 1 only!
    // Missing: Case normalization (step 2)
    // Missing: Attribute creation/update (steps 3-5)
    // Missing: CE reactions
}
```

### ❌ Mistake 4: Missing Extended Attributes
```zig
// WebIDL: [SameObject] readonly attribute NodeList childNodes;

// WRONG: Creates new NodeList each call
pub fn childNodes(self: *Node) *NodeList {
    return NodeList.fromChildren(self.children); // New allocation!
}

// CORRECT: Returns cached instance
pub fn childNodes(self: *Node) *NodeList {
    if (self.rare_data) |rare| {
        return rare.child_nodes_list; // Cached [SameObject]
    }
    // Initialize cache once
}
```

## Best Practices

1. **Always read complete interfaces** - Understanding related methods prevents design mistakes
2. **Read all algorithm steps** - Edge cases hide in later steps
3. **Check inheritance chains** - Parent interfaces provide context
4. **Verify extended attributes** - They affect memory management and behavior
5. **Read cross-referenced sections** - Specs reference each other extensively
6. **Use type mapping table** - Prevent type conversion errors
7. **Document both sources** - WebIDL signature + prose algorithm

## Quick Reference

### Finding Interfaces
```bash
# View complete Element interface
# Read lines 410-475 in dom.idl, don't grep individual methods
```

### Finding Algorithms
```bash
# Open dom_spec_complete.md
# Search for § section number
# Read complete section, not just algorithm title
```

### Understanding Extended Attributes
```bash
# Open webidl_spec_complete.md
# Search for [AttributeName]
# Understand binding behavior and constraints
```

## Integration with Other Skills

This skill coordinates with:
- **zig_standards** - Provides Zig idioms for implementing spec algorithms
- **testing_requirements** - Defines how to test spec compliance
- **documentation_standards** - Format for spec references in docs
- **performance_optimization** - When to optimize beyond spec requirements

Load all relevant skills together for complete implementation guidance.
