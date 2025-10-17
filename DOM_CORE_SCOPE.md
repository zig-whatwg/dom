# DOM Core Scope Definition

**Library:** dom2 (WHATWG DOM Core Implementation in Zig)  
**Scope:** DOM Core only - language-agnostic features  
**Excludes:** HTML-specific, XML-specific, SVG-specific features

---

## What is DOM Core?

**DOM Core** = Features that work for **any** markup language (HTML, XML, SVG, MathML, custom)

### ✅ IN SCOPE (DOM Core - Language Agnostic)

**Tree Structure:**
- Node (base interface)
- Element (generic elements)
- Document (generic document)
- DocumentFragment
- Text, Comment, ProcessingInstruction
- DocumentType
- Attr (attribute nodes)

**Tree Manipulation:**
- appendChild, insertBefore, removeChild, replaceChild
- before, after, replaceWith, remove
- prepend, append, replaceChildren
- cloneNode, normalize

**Query/Selection (CSS Selectors work on any elements):**
- querySelector, querySelectorAll
- Element.matches, Element.closest
- NodeList (generic node collection)

**Attributes (generic attribute system):**
- getAttribute, setAttribute, removeAttribute, hasAttribute
- getAttributeNS, setAttributeNS (namespace support)
- attributes property

**Events (generic event system):**
- Event, EventTarget
- addEventListener, removeEventListener, dispatchEvent
- Event phases (capture, target, bubble)
- AbortController, AbortSignal

**Observation:**
- MutationObserver (detect tree changes)

**Traversal:**
- NodeIterator, TreeWalker
- Range, StaticRange

**Node Properties (generic):**
- nodeType, nodeName, nodeValue
- parentNode, childNodes, firstChild, lastChild
- previousSibling, nextSibling
- textContent

---

### ❌ OUT OF SCOPE (HTML/XML/SVG-Specific)

**HTML-Specific:**
- HTMLCollection (HTML document collections with named access)
- HTMLDocument, HTMLElement interfaces
- getElementsByTagName, getElementsByClassName (HTML document methods)
- DOMTokenList, Element.classList (HTML class attribute)
- innerHTML, outerHTML (HTML serialization)
- Special id attribute handling (getElementById is borderline)

**XML-Specific:**
- XML parsing/serialization
- XML namespaces (though namespace methods are in DOM Core)
- XML-specific node types

**SVG-Specific:**
- SVGElement interface
- SVG-specific properties

**HTML Parsing:**
- HTML5 parsing algorithm
- Template element
- Custom elements registry
- Shadow DOM (primarily for HTML web components)

---

## Borderline Cases

### getElementById - ⚠️ Optional

**Issue:** The "id" attribute has special meaning in HTML but is just another attribute in pure XML.

**Options:**
1. **Include it** - Treat "id" as a special attribute name generically. Useful for any DOM tree. ✅ Recommended
2. **Exclude it** - Strict DOM Core, require querySelector("[id='foo']") instead.

**Decision:** Include as **optional** - useful generically even if somewhat HTML-centric.

### Shadow DOM - ⚠️ Lower Priority

**Issue:** Appears in WHATWG DOM spec but primarily used for HTML web components.

**DOM Core aspects:**
- Tree isolation (generic)
- Event retargeting (generic)

**HTML-specific aspects:**
- Used with HTML custom elements
- Slot distribution for HTML

**Decision:** Lower priority - implement only if web components needed.

---

## Key Principle

> **If a feature requires knowledge of HTML/XML/SVG semantics, it's not DOM Core.**

**DOM Core = Generic tree manipulation that works for any markup language**

---

## Examples

### ✅ DOM Core Usage (Any Markup)

```zig
// Works for HTML, XML, SVG, MathML, custom markup
const doc = try Document.init(allocator);

// Create elements (generic)
const elem = try doc.createElement("myElement");
try elem.setAttribute("foo", "bar");

// Query with CSS selectors (generic)
const results = try doc.querySelectorAll("myElement[foo='bar']");

// Tree manipulation (generic)
_ = try doc.node.appendChild(&elem.node);

// Events (generic)
try elem.node.addEventListener("myEvent", handler, ctx, false, false, false, null);
```

### ❌ HTML-Specific Usage (Not in DOM Core)

```zig
// These require HTML library:
const collection = doc.getElementsByClassName("btn"); // HTML class attribute
const list = elem.classList; // HTML class manipulation
elem.innerHTML = "<div>foo</div>"; // HTML parsing/serialization
const customElem = doc.createElement("my-element"); // Custom elements
```

---

## Recommended Architecture

```
┌─────────────────────────────────────┐
│         Application Layer            │
└─────────────────────────────────────┘
                  │
┌─────────────────────────────────────┐
│         HTML Library (Future)        │
│  - HTMLCollection                    │
│  - HTMLDocument, HTMLElement         │
│  - innerHTML/outerHTML               │
│  - Custom elements                   │
│  - HTML parsing                      │
└─────────────────────────────────────┘
                  │
┌─────────────────────────────────────┐
│   DOM Core Library (This Project)   │ ✅ CURRENT SCOPE
│  - Node tree manipulation            │
│  - querySelector/querySelectorAll    │
│  - Event system                      │
│  - MutationObserver                  │
│  - Generic attributes                │
└─────────────────────────────────────┘
```

**This library** = DOM Core layer only
**Future work** = HTML library layer on top

---

## Benefits of DOM Core Only

1. **Language Agnostic** - Works with any markup (XML, SVG, HTML, MathML, custom)
2. **Smaller Scope** - Focused implementation, easier to maintain
3. **Clear Boundaries** - HTML features belong in HTML library
4. **Reusable** - XML processing, SVG manipulation, custom markup all work
5. **Standards Compliant** - Clean separation matches web standards architecture

---

## Migration Path

**Current:** Building DOM Core ✅  
**Future:** HTML library can layer on top:

```zig
// HTML library would extend DOM Core:
const HTMLDocument = struct {
    document: *Document,  // DOM Core document
    
    // HTML-specific additions:
    pub fn getElementsByClassName(self: *HTMLDocument, classes: []const u8) *HTMLCollection { }
    pub fn getElementById(self: *HTMLDocument, id: []const u8) ?*HTMLElement { }
};

const HTMLElement = struct {
    element: *Element,  // DOM Core element
    
    // HTML-specific additions:
    pub fn classList(self: *HTMLElement) *DOMTokenList { }
    pub fn innerHTML(self: *HTMLElement) []const u8 { }
};
```

**Benefit:** Clear separation, DOM Core remains pure and reusable.

---

*Last Updated: October 17, 2025*  
*Scope: DOM Core (language-agnostic) only*
