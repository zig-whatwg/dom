# Generic DOM Library Policy

**Date**: 2025-10-18  
**Status**: ✅ **ENFORCED** - Updated all skills and guidelines

---

## ⚠️ CRITICAL: This is a GENERIC DOM Library

This library implements the **WHATWG DOM Standard** for **ANY document type** (XML, custom formats, etc.), **NOT specifically for HTML**.

---

## Absolute Prohibitions

### ❌ NO HTML-Specific Features

**NEVER implement**:
- HTML element interfaces (HTMLDivElement, HTMLButtonElement, HTMLAnchorElement, etc.)
- HTML element semantics (button click behavior, form submission, link navigation)
- HTML-specific attribute handling (href navigation, src loading, action processing)
- HTML parsing rules (HTML namespace, ASCII case normalization for HTML context)
- HTML-only APIs (document.forms, document.images, document.scripts, etc.)
- HTML event specifics (submit events, load events, click events with HTML behavior)

### ❌ NO HTML Element Names in Code/Tests/Docs

**NEVER use these names**:
```
div, span, p, a, button, input, form, table, tr, td, th, tbody, thead,
ul, ol, li, dl, dt, dd, header, footer, section, article, nav, main,
aside, h1, h2, h3, h4, h5, h6, body, html, head, title, meta, link,
script, style, img, video, audio, canvas, svg, iframe, embed, object
```

**Why?** These names imply HTML-specific semantics and behavior that this library DOES NOT implement.

---

## What IS Allowed

### ✅ Generic DOM Features

**ONLY implement**:
- Generic Element interface (tag names are arbitrary strings)
- Generic attribute handling (key-value pairs, no semantic behavior)
- Generic tree manipulation (appendChild, removeChild, insertBefore, etc.)
- Generic query selectors (CSS selector matching, document-type agnostic)
- Generic event system (EventTarget, Event dispatch, no HTML-specific events)
- Generic node types (Element, Text, Comment, DocumentFragment, Document, DocumentType)
- Generic traversal (firstChild, nextSibling, parentNode, etc.)

### ✅ Generic Element Names

**USE these names in tests/examples/docs**:

#### General Purpose:
```
element, node, container, item, component, widget, panel, view, content,
wrapper, holder, box, frame, block, section
```

#### Hierarchical:
```
root, parent, child, grandchild, ancestor, descendant,
level1, level2, level3, top, middle, bottom
```

#### Functional:
```
source, target, placeholder, template, fragment, stub, mock, test
```

#### Custom Element Pattern:
```
my-component, custom-widget, x-panel, data-table, app-header, ui-button
(hyphenated names following custom element conventions)
```

### ✅ Generic Attribute Names

**USE these names**:
```
attr1, attr2, attr3, key, value, flag, data-id, data-name, data-value,
data-test, test-attr, custom-attr, prop1, prop2
```

---

## Implementation Guidelines

### When Reading WHATWG DOM Spec

The WHATWG DOM spec includes **HTML-specific steps** in some algorithms. When implementing:

1. **Read the FULL algorithm** (don't skip steps)
2. **Identify HTML-specific steps** (mention "HTML namespace", "HTML document", "HTML element")
3. **SKIP or stub out HTML-specific steps** with comments explaining why
4. **Implement generic behavior only**

#### Example: setAttribute() Algorithm

```zig
/// WHATWG DOM §4.9 Element.setAttribute(qualifiedName, value)
pub fn setAttribute(self: *Element, qualified_name: []const u8, value: []const u8) !void {
    // Step 1: Validate qualifiedName matches Name production
    if (!isValidName(qualified_name)) {
        return error.InvalidCharacterError;
    }
    
    // Step 2: If HTML namespace and HTML document, lowercase qualifiedName
    // ⚠️ SKIPPED: This library is document-type agnostic, no HTML-specific behavior
    
    // Step 3: Find existing attribute
    var attr = self.getAttributeNode(qualified_name);
    
    // Step 4-5: Create or update attribute
    if (attr == null) {
        try self.createAndAppendAttribute(qualified_name, value);
    } else {
        try self.changeAttribute(attr.?, value);
    }
}
```

### When Converting WPT Tests

Web Platform Tests often use HTML elements. When converting:

1. **ONLY convert generic DOM behavior tests** (tree manipulation, queries, events)
2. **SKIP HTML-specific test files** (form validation, link navigation, etc.)
3. **Replace ALL HTML element names** with generic names
4. **Replace ALL HTML attribute names** with generic names
5. **Remove HTML-specific assertions** (e.g., element.href behavior)
6. **Place in `wpt_tests/` directory**

#### Example Conversion

**Original WPT Test** (JavaScript):
```javascript
test(() => {
  const div = document.createElement('div');
  const span = document.createElement('span');
  div.appendChild(span);
  assert_equals(div.firstChild, span);
}, "appendChild adds child to div");
```

**Converted Test** (Zig):
```zig
test "appendChild adds child to parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const parent = try doc.createElement("parent");
    defer parent.node.release();
    const child = try doc.createElement("child");
    _ = try parent.node.appendChild(&child.node);
    
    try std.testing.expect(parent.node.first_child == &child.node);
}
```

---

## Why This Matters

### 1. **Scope Clarity**
HTML is ONE document type that uses DOM. This library implements the DOM interface for ANY document type.

### 2. **Maintainability**
HTML-specific features would create:
- Massive scope creep (100+ HTML element types, each with unique behavior)
- Browser compatibility issues (HTML rendering engine complexity)
- Security concerns (XSS, CSRF, CSP, etc.)

### 3. **Use Cases**
This library is suitable for:
- ✅ XML document manipulation
- ✅ Custom document formats (configuration, data structures)
- ✅ DOM-like APIs for non-HTML content
- ✅ Generic tree structures with query support
- ❌ Full HTML rendering (out of scope)

### 4. **Clarity for Users**
Using HTML element names misleads users into thinking HTML-specific features are supported.

---

## Enforcement

### Skills Updated (2025-10-18)

1. ✅ **whatwg_compliance/SKILL.md**
   - Added "NO HTML Specifics" section
   - Clarified generic vs HTML-specific implementation
   - Updated examples to use generic names

2. ✅ **testing_requirements/SKILL.md**
   - Added test naming rules
   - Prohibited HTML element/attribute names in tests
   - Updated examples to use generic names

3. ✅ **documentation_standards/SKILL.md**
   - Added documentation naming rules
   - Prohibited HTML names in examples
   - Required generic names in all documentation

4. ✅ **AGENTS.md**
   - Added critical prohibitions at top
   - Listed forbidden HTML element names
   - Specified generic alternatives

### Code Changes (2025-10-18)

1. ✅ **wpt_tests/nodes/Node-cloneNode.zig**
   - Removed ALL HTML element names
   - Replaced with generic names (element, container, item, etc.)
   - Updated test descriptions
   - All 24 tests pass with generic names

---

## Checklist for New Code

Before adding ANY new feature, verify:

- [ ] Feature is generic DOM, not HTML-specific
- [ ] No HTML element interfaces (HTMLDivElement, etc.)
- [ ] No HTML semantics (click behavior, form submission)
- [ ] Tests use generic element names (element, container, item)
- [ ] Tests use generic attribute names (attr1, data-id, key)
- [ ] Documentation examples use generic names
- [ ] No HTML-specific algorithm steps (or clearly marked as skipped)
- [ ] WHATWG spec steps marked clearly (generic vs HTML-specific)

---

## Examples of Correct Usage

### ✅ Creating Elements
```zig
const container = try doc.createElement("container");
const item = try doc.createElement("item");
_ = try container.node.appendChild(&item.node);
```

### ✅ Setting Attributes
```zig
try element.setAttribute("data-id", "123");
try element.setAttribute("key", "value");
try element.setAttribute("flag", "");
```

### ✅ Query Selectors
```zig
const result = try doc.querySelector("container > item");
const items = try doc.querySelectorAll("[data-id]");
```

### ✅ Custom Elements
```zig
const component = try doc.createElement("my-component");
const widget = try doc.createElement("custom-widget");
```

---

## Examples of PROHIBITED Usage

### ❌ HTML Element Names
```zig
// WRONG:
const div = try doc.createElement("div");
const button = try doc.createElement("button");
const input = try doc.createElement("input");
```

### ❌ HTML Attributes
```zig
// WRONG:
try element.setAttribute("href", "https://example.com");
try element.setAttribute("type", "submit");
try element.setAttribute("placeholder", "Enter name");
```

### ❌ HTML-Specific Behavior
```zig
// WRONG:
pub fn click(self: *Element) void {
    // Triggering HTML button click behavior
}

// WRONG:
pub fn submit(self: *Element) void {
    // Triggering HTML form submission
}
```

---

## Summary

| Aspect | Generic DOM (✅ Allowed) | HTML-Specific (❌ Prohibited) |
|--------|-------------------------|------------------------------|
| **Scope** | WHATWG DOM interfaces | HTML element semantics |
| **Element Names** | element, container, item | div, span, button, form |
| **Attributes** | attr1, data-id, key | href, src, type, action |
| **Behavior** | Tree manipulation, queries | Click handling, form submission |
| **Document Types** | Any (XML, custom) | HTML only |
| **Test Location** | src/, wpt_tests/ | wpt_tests/ only (converted) |

---

**Policy Status**: ✅ **ACTIVE AND ENFORCED**

All skills, guidelines, and code have been updated to enforce this policy. Future development MUST comply with these rules.

---

**Questions?** Refer to this document when in doubt. When converting WPT tests or implementing spec features, always replace HTML-specific names with generic alternatives.
