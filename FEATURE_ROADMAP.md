# WHATWG DOM Core Feature Roadmap

**Analysis Date:** October 17, 2025  
**Scope:** DOM Core (language-agnostic, works for XML, SVG, HTML, etc.)  
**Excludes:** HTML-specific features (HTMLCollection, HTMLDocument, etc.)  
**Current Status:** Core DOM implementation complete, query/traversal features in progress

---

## Scope Clarification

**This library implements DOM Core only:**
- ✅ Generic DOM tree (Node, Element, Document, Text, Comment)
- ✅ Works with any markup language (HTML, XML, SVG, MathML)
- ✅ Language-agnostic query/selection (querySelector works on any elements)
- ✅ Generic event system

**Not in scope (HTML-specific):**
- ❌ HTMLCollection (HTML-centric named access via id/name attributes)
- ❌ getElementsByTagName/ClassName (HTML document methods)
- ❌ HTMLDocument, HTMLElement interfaces
- ❌ HTML-specific attributes (id as special, class as special)
- ❌ HTML parsing/serialization

---

## Executive Summary

The library has a **solid foundation** with core DOM interfaces implemented:
- ✅ Node tree manipulation (appendChild, insertBefore, removeChild, replaceChild)
- ✅ Element attributes (getAttribute, setAttribute, removeAttribute, hasAttribute)
- ✅ Event system (Event, EventTarget, addEventListener, dispatchEvent)
- ✅ Text/Comment nodes with CharacterData interface
- ✅ Document factory methods (createElement, createTextNode, etc.)
- ✅ AbortController/AbortSignal for cancellation

**Next Priority:** Complete query/selection and tree traversal features to enable practical DOM usage.

---

## Implementation Status by Category

### ✅ COMPLETE - Core DOM Tree (Priority 0)

**Interfaces:**
- ✅ Node (base interface with tree manipulation)
- ✅ Element (attributes, tag names, class bloom filter)
- ✅ Document (factory methods)
- ✅ DocumentFragment (lightweight container)
- ✅ Text (CharacterData implementation)
- ✅ Comment (CharacterData implementation)
- ✅ NodeList (live collection)

**Key Methods:**
- ✅ `appendChild(node)` - Add child to end
- ✅ `insertBefore(node, child)` - Insert before reference
- ✅ `removeChild(child)` - Remove child from parent
- ✅ `replaceChild(node, child)` - Replace child with new node
- ✅ `hasChildNodes()` - Check for children
- ✅ `contains(other)` - Check if node is descendant
- ✅ `cloneNode(deep)` - Clone node (with vtable dispatch)
- ✅ `compareDocumentPosition(other)` - Compare node positions

---

### 🚧 IN PROGRESS - Query/Selection (Priority 1)

**Status:** Tokenizer complete, parser/executor needed

**Interfaces to Complete:**

#### 1. **ParentNode Mixin** (High Priority) 🔥
WebIDL interfaces that need ParentNode:
- Document ✅ (inherits, needs implementation)
- DocumentFragment ✅ (inherits, needs implementation)
- Element ✅ (inherits, needs implementation)

**Missing Methods (DOM Core only):**
```webidl
interface mixin ParentNode {
  // Query methods (HIGH PRIORITY) - DOM CORE ✅
  Element? querySelector(DOMString selectors);                    // ❌ MISSING
  [NewObject] NodeList querySelectorAll(DOMString selectors);    // ❌ MISSING
  
  // Element children (MEDIUM PRIORITY) - DOM CORE ✅
  readonly attribute Element? firstElementChild;                  // ❌ MISSING
  readonly attribute Element? lastElementChild;                   // ❌ MISSING
  readonly attribute unsigned long childElementCount;             // ❌ MISSING
  
  // Modern DOM manipulation (LOWER PRIORITY) - DOM CORE ✅
  [CEReactions] undefined prepend((Node or DOMString)... nodes); // ❌ MISSING
  [CEReactions] undefined append((Node or DOMString)... nodes);  // ❌ MISSING
  [CEReactions] undefined replaceChildren(...nodes);             // ❌ MISSING
  [CEReactions] undefined moveBefore(Node node, Node? child);    // ❌ MISSING
};
```

**Excluded (HTML-specific):**
```webidl
// NOT implementing - requires HTML library
[SameObject] readonly attribute HTMLCollection children;  // ❌ OUT OF SCOPE
```

**Note:** We can implement `children` as returning `NodeList` of element children instead of `HTMLCollection`. This is DOM Core compatible and more generic.

**Dependencies:**
- ✅ CSS Selector tokenizer (`src/selector/tokenizer.zig`) - DONE
- ❌ CSS Selector parser (convert tokens to AST)
- ❌ Selector matcher (evaluate AST against elements)
- ❌ Query executor (traverse tree, return matches)

**Impact:** 🔥 **CRITICAL** - querySelector/querySelectorAll are essential for practical DOM usage

---

#### 2. **NonElementParentNode Mixin** (High Priority) 🔥

**DOM Core Consideration:**

```webidl
interface mixin NonElementParentNode {
  Element? getElementById(DOMString elementId);  // ⚠️ DEBATABLE
};
Document includes NonElementParentNode;
DocumentFragment includes NonElementParentNode;
```

**Issue:** `getElementById` is technically in the spec, but:
- The "id" attribute has special meaning in HTML
- In pure XML/SVG, "id" is just another attribute (no special lookup)
- This is somewhat HTML-centric

**Options:**

**Option A: Implement with generic id attribute**
- Treat "id" as special attribute name
- Works for any markup language
- O(1) lookup via HashMap
- **Recommended:** Useful for any DOM tree

**Option B: Skip entirely**
- Require HTML library for getElementById
- Force users to use querySelector("[id='foo']")
- More strict DOM Core interpretation

**Recommendation:** Implement **Option A** - getElementById is useful generically and the "id" attribute concept exists in XML (xml:id), SVG, etc. The implementation doesn't require HTML-specific behavior.

**Implementation Plan:**
- Add id→element map to Document (HashMap<[]const u8, *Element>)
- Update Element.setAttribute() to register/unregister "id" attribute
- Implement getElementById() with O(1) lookup
- Handle id changes and element removal
- Document that this treats "id" attribute specially

**Impact:** 🔥 **HIGH** - Very useful for any DOM tree, even if somewhat HTML-centric

---

#### 3. **Element Query Methods** (High Priority)
```webidl
Element? closest(DOMString selectors);                    // ❌ MISSING
boolean matches(DOMString selectors);                     // ❌ MISSING
boolean webkitMatchesSelector(DOMString selectors);       // ❌ MISSING (legacy)
```

**Dependencies:** Same as querySelector (parser + matcher)

**Impact:** 🔥 **HIGH** - closest() is essential for event delegation

---

### ❌ MISSING - Tree Traversal/Manipulation (Priority 2)

#### 1. **ChildNode Mixin** (Medium Priority)
```webidl
interface mixin ChildNode {
  [CEReactions] undefined before((Node or DOMString)... nodes);      // ❌ MISSING
  [CEReactions] undefined after((Node or DOMString)... nodes);       // ❌ MISSING
  [CEReactions] undefined replaceWith((Node or DOMString)... nodes); // ❌ MISSING
  [CEReactions] undefined remove();                                  // ❌ MISSING
};
DocumentType includes ChildNode;
Element includes ChildNode;
CharacterData includes ChildNode;
```

**Why Important:** Modern DOM API for easier manipulation

---

#### 2. **NonDocumentTypeChildNode Mixin** (Medium Priority)
```webidl
interface mixin NonDocumentTypeChildNode {
  readonly attribute Element? previousElementSibling;  // ❌ MISSING
  readonly attribute Element? nextElementSibling;      // ❌ MISSING
};
Element includes NonDocumentTypeChildNode;
CharacterData includes NonDocumentTypeChildNode;
```

**Implementation:** Traverse siblings, skip non-element nodes

---

#### 3. **Node Methods** (Medium Priority)
```webidl
// Text content and normalization
[CEReactions] attribute DOMString? textContent;      // ❌ MISSING
[CEReactions] undefined normalize();                 // ❌ MISSING

// Namespace methods (lower priority)
DOMString? lookupPrefix(DOMString? namespace);       // ❌ MISSING
DOMString? lookupNamespaceURI(DOMString? prefix);    // ❌ MISSING
boolean isDefaultNamespace(DOMString? namespace);    // ❌ MISSING
```

**Note:** textContent is critical, namespace methods less so for basic usage

---

### ❌ OUT OF SCOPE - HTML-Specific Collections

#### HTMLCollection and getElementsBy* Methods

**Not implementing (HTML-specific):**

```webidl
// These are HTML document features, not DOM Core:
interface HTMLCollection { ... }                                      // ❌ OUT OF SCOPE
HTMLCollection getElementsByTagName(DOMString qualifiedName);         // ❌ OUT OF SCOPE  
HTMLCollection getElementsByTagNameNS(DOMString? ns, DOMString name); // ❌ OUT OF SCOPE
HTMLCollection getElementsByClassName(DOMString classNames);          // ❌ OUT OF SCOPE
[SameObject] readonly attribute HTMLCollection children;              // ❌ OUT OF SCOPE
```

**Reason:** These are primarily HTML document methods. They appear in WHATWG DOM spec for HTML compatibility, but are not core DOM features.

**Alternative (DOM Core):**
- Use `querySelectorAll()` instead:
  - `getElementsByTagName("div")` → `querySelectorAll("div")`
  - `getElementsByClassName("btn")` → `querySelectorAll(".btn")`
- For `ParentNode.children`, we can return a filtered `NodeList` of element children (DOM Core compatible)

**Impact:** No impact - querySelector is more powerful and generic

---

### ❌ MISSING - Advanced Features (Priority 3)

#### 1. **MutationObserver** (Medium Priority)
```webidl
[Exposed=Window]
interface MutationObserver {
  constructor(MutationCallback callback);
  undefined observe(Node target, optional MutationObserverInit options = {});
  undefined disconnect();
  sequence<MutationRecord> takeRecords();
};
```

**Status:** Placeholder structures exist in `rare_data.zig`

**Why Important:**
- Essential for reactive frameworks
- Detect DOM changes programmatically
- Required for custom elements

**Implementation Plan:**
1. Complete MutationRecord structure
2. Track mutations in rare data per-node
3. Implement observer registration/notification
4. Add [CEReactions] triggers to mutation methods

---

#### 2. **Range Interface** (Lower Priority)
```webidl
[Exposed=Window]
interface Range : AbstractRange {
  constructor();
  readonly attribute Node commonAncestorContainer;
  
  undefined setStart(Node node, unsigned long offset);
  undefined setEnd(Node node, unsigned long offset);
  // ... many more methods
};
```

**Why Important:** Text selection, content extraction, editing

**Status:** ❌ Not started

---

#### 3. **DOMTokenList** (Medium Priority)
```webidl
[Exposed=Window]
interface DOMTokenList {
  readonly attribute unsigned long length;
  getter DOMString? item(unsigned long index);
  boolean contains(DOMString token);
  undefined add(DOMString... tokens);
  undefined remove(DOMString... tokens);
  boolean toggle(DOMString token, optional boolean force);
  boolean replace(DOMString token, DOMString newToken);
  boolean supports(DOMString token);
  [CEReactions] stringifier attribute DOMString value;
  iterable<DOMString>;
};
```

**Why Important:**
- Element.classList (very commonly used)
- Cleaner API than manual class manipulation

**Current Status:** Bloom filter exists for classes, but no DOMTokenList wrapper

---

#### 4. **Shadow DOM** (Lower Priority)
```webidl
[Exposed=Window]
interface ShadowRoot : DocumentFragment {
  readonly attribute ShadowRootMode mode;
  readonly attribute boolean delegatesFocus;
  readonly attribute SlotAssignmentMode slotAssignment;
  readonly attribute Element host;
};
```

**Status:** ❌ Not started

**Why Lower Priority:** 
- Complex feature
- Requires slot distribution
- Less critical for basic DOM usage

---

#### 5. **Custom Elements** (Lower Priority)
```webidl
[Exposed=Window]
interface CustomElementRegistry {
  undefined define(DOMString name, CustomElementConstructor constructor, ...);
  (CustomElementConstructor or undefined) get(DOMString name);
  DOMString? getName(CustomElementConstructor constructor);
  Promise<CustomElementConstructor> whenDefined(DOMString name);
  undefined upgrade(Node root);
};
```

**Status:** ❌ Not started

**Dependencies:** Requires JavaScript integration

---

### ❌ MISSING - Additional Node Types (Priority 3)

#### 1. **Attr (Attribute Nodes)** (Lower Priority)
```webidl
[Exposed=Window]
interface Attr : Node {
  readonly attribute DOMString? namespaceURI;
  readonly attribute DOMString? prefix;
  readonly attribute DOMString localName;
  readonly attribute DOMString name;
  [CEReactions] attribute DOMString value;
  readonly attribute Element? ownerElement;
};
```

**Current Status:** Attributes stored as HashMap, no Attr nodes

**Why Lower Priority:** Modern DOM uses Element.getAttribute() instead

---

#### 2. **ProcessingInstruction** (Lower Priority)
```webidl
[Exposed=Window]
interface ProcessingInstruction : CharacterData {
  readonly attribute DOMString target;
};
```

**Use Case:** XML processing instructions (rare)

---

#### 3. **CDATASection** (Lower Priority)
```webidl
[Exposed=Window]
interface CDATASection : Text {};
```

**Use Case:** XML CDATA sections (rare in HTML)

---

#### 4. **DocumentType** (Lower Priority)
```webidl
[Exposed=Window]
interface DocumentType : Node {
  readonly attribute DOMString name;
  readonly attribute DOMString publicId;
  readonly attribute DOMString systemId;
};
```

**Use Case:** DOCTYPE declarations

---

## Recommended Implementation Order (DOM Core Only)

### 🔥 Phase 1: Query/Selection (1-2 weeks) - CRITICAL - DOM CORE

**Critical for usability** - Makes the DOM actually queryable

1. **getElementById (Optional)** (2-3 days)
   - Add id map to Document
   - Hook setAttribute/removeAttribute for "id" attribute
   - Implement O(1) lookup
   - Add tests (100+ test cases)
   - **Note:** Treats "id" attribute specially, somewhat HTML-centric but useful generically

2. **CSS Selector Parser** (3-4 days)
   - Parse token stream from tokenizer
   - Build selector AST
   - Handle all selector types (tag, class, id, attribute, pseudo)
   - Comprehensive parsing tests

3. **Selector Matcher** (3-4 days)
   - Evaluate selector AST against elements
   - Implement all combinators (>, +, ~, space)
   - Handle pseudo-classes (:first-child, :last-child, :nth-child, etc.)
   - Use bloom filter for class matching optimization
   - Comprehensive matching tests

4. **querySelector/querySelectorAll** (2-3 days)
   - Implement ParentNode mixin
   - Tree traversal with selector matching
   - Return first match (querySelector) or all matches (querySelectorAll)
   - Performance optimization (early exit, smart traversal)
   - Integration tests

5. **Element.matches/closest** (1-2 days)
   - matches(selector): test if element matches selector
   - closest(selector): find nearest ancestor matching selector
   - Reuse selector matcher infrastructure

**Deliverables:**
- ✅ querySelector/querySelectorAll with full CSS3+ selector support (DOM CORE)
- ✅ Element.matches() and Element.closest() (DOM CORE)
- ⚠️ getElementById (optional, treats "id" attribute specially)
- ✅ Comprehensive test coverage (400+ tests)

**Impact:** Unlocks practical DOM usage, essential for any real application

**Excluded:**
- ❌ HTMLCollection (HTML-specific)
- ❌ getElementsByTagName/ClassName (HTML document methods)

---

### 📦 Phase 2: ParentNode/ChildNode Properties (3-4 days) - DOM CORE

**Complete the ParentNode interface (DOM Core features only)**

1. **ParentNode Element Properties** (1-2 days)
   - firstElementChild, lastElementChild (traverse, skip non-elements)
   - childElementCount (count element children)
   - children as filtered NodeList (elements only) - **DOM Core alternative to HTMLCollection**

2. **NonDocumentTypeChildNode** (1-2 days)
   - previousElementSibling (traverse siblings, skip non-elements)
   - nextElementSibling (traverse siblings, skip non-elements)

**Deliverables:**
- ✅ Complete ParentNode implementation (DOM Core features)
- ✅ Element sibling navigation
- ✅ Element-only child access via filtered NodeList

**Excluded:**
- ❌ getElementsByTagName (HTML document method)
- ❌ getElementsByClassName (HTML document method)
- ❌ HTMLCollection (HTML-specific)

---

### 🔧 Phase 3: Modern DOM Manipulation (1 week) - DOM CORE

**ChildNode and ParentNode convenience methods**

1. **ChildNode Mixin** (2-3 days) - DOM CORE ✅
   - before(), after(), replaceWith(), remove()
   - Handle variadic (Node or DOMString) parameters
   - Proper text node creation for strings
   - [CEReactions] compliance

2. **ParentNode Manipulation** (2-3 days) - DOM CORE ✅
   - prepend(), append(), replaceChildren()
   - Variadic parameters
   - DocumentFragment optimization
   - [CEReactions] compliance

3. **Node.textContent** (1-2 days) - DOM CORE ✅
   - Getter: collect all descendant text
   - Setter: replace all children with text node
   - [CEReactions] compliance

**Deliverables:**
- ✅ Modern DOM API complete (DOM Core)
- ✅ Easier manipulation than appendChild/insertBefore
- ✅ String→TextNode automatic conversion
- ✅ All methods are language-agnostic

---

### 📊 Phase 4: MutationObserver (1-2 weeks) - DOM CORE ✅

**Detect and react to DOM changes**

1. **MutationRecord** (1-2 days) - DOM CORE ✅
   - Implement complete record structure
   - Track type, target, addedNodes, removedNodes, etc.
   - Language-agnostic mutation tracking

2. **Observer Registration** (2-3 days) - DOM CORE ✅
   - observe() with options
   - Store observers in rare data
   - Efficient observer lookup

3. **Mutation Tracking** (3-4 days) - DOM CORE ✅
   - Integrate with all [CEReactions] methods
   - Batch mutations in microtasks
   - Queue records per observer

4. **Notification** (1-2 days) - DOM CORE ✅
   - takeRecords(), disconnect()
   - Deliver mutations to callbacks
   - Handle recursive mutations

**Deliverables:**
- ✅ Complete MutationObserver implementation
- ✅ All mutation types (childList, attributes, characterData)
- ✅ Proper batching and delivery
- ✅ Works for any markup language (DOM Core)

**Note:** MutationObserver is fully DOM Core - no HTML-specific behavior

---

### ❌ SKIPPED: DOMTokenList (HTML-specific)

**Not implementing - HTML-specific**

DOMTokenList (Element.classList) is primarily for HTML class attribute manipulation:

```webidl
// NOT implementing - HTML-specific
[Exposed=Window]
interface DOMTokenList { ... }
```

**Reason:** 
- The "class" attribute is HTML-specific
- In pure XML/SVG, "class" is just another attribute
- DOMTokenList semantics (space-separated tokens, case-sensitivity) are HTML-centric

**Alternative (DOM Core):**
- Use `getAttribute("class")` and `setAttribute("class", value)`
- Parse/manipulate class strings manually
- The bloom filter for class matching still works with string-based classes

**Impact:** No impact for DOM Core - class manipulation can be done via standard attribute methods

---

### 🌲 Phase 5: Range API (1-2 weeks) - DOM CORE ✅

**Text selection and manipulation**

1. **AbstractRange** (1 day) - DOM CORE ✅
   - Base interface
   - Start/end containers and offsets
   - Language-agnostic

2. **Range** (4-5 days) - DOM CORE ✅
   - Full Range implementation
   - setStart, setEnd, collapse
   - extract, clone, insertNode
   - deleteContents, extractContents, cloneContents
   - Many methods to implement
   - Works for any markup language

3. **StaticRange** (1 day) - DOM CORE ✅
   - Immutable range variant

**Deliverables:**
- ✅ Range API for selections
- ✅ Content extraction and manipulation
- ✅ Fully language-agnostic

**Note:** Range API is fully DOM Core - works for any tree structure

---

### ❌ LOWER PRIORITY: Shadow DOM (HTML-centric)

**Shadow DOM - Mixed scope**

Shadow DOM appears in WHATWG DOM spec but is primarily used with HTML Web Components:

```webidl
interface ShadowRoot : DocumentFragment { ... }
```

**Considerations:**

**DOM Core aspects:**
- Tree isolation (generic concept)
- Event retargeting (generic concept)
- getRootNode({ composed }) (generic)

**HTML-specific aspects:**
- Primarily used with HTML Custom Elements
- Slot distribution tied to HTML elements
- Used for HTML web components encapsulation

**Decision:** **Lower priority** - While technically in DOM spec, Shadow DOM is primarily an HTML web components feature. Implement only if HTML web components support is needed.

**If implementing later:**
1. ShadowRoot interface (1 week)
2. Event retargeting (3-4 days)
3. Slot distribution (1 week)
4. Integration (3-4 days)

**For now:** Focus on core DOM query/manipulation features first

---

## Priority Justification

### Why Query/Selection First? 🔥

**Current State:** Can build DOM trees but can't query them efficiently

**With querySelector (DOM Core):**
```zig
// ✅ ENABLED - Query by selector (works for any markup)
const buttons = elem.querySelectorAll("button[type='submit']");

// ✅ ENABLED - Match testing
const isActive = elem.matches(".active");

// ✅ ENABLED - Find ancestor
const form = button.closest("form");

// ✅ ENABLED - Event delegation
elem.addEventListener("click", handleClick, ...);
fn handleClick(event: *Event, ctx: *anyopaque) void {
    const target = @ptrCast(*Element, event.target);
    if (target.matches("button[data-action]")) {
        // Handle button click
    }
}
```

**Optional: getElementById (treats "id" attribute specially):**
```zig
// ⚠️ OPTIONAL - Get element by id attribute
// Note: "id" is somewhat HTML-centric, but useful generically
const elem = doc.getElementById("main-content");
```

**Without these methods:**
- Must manually traverse entire tree
- No efficient element lookup
- Event delegation nearly impossible
- DOM is not practically usable

**Decision:** Query/selection is the **minimum viable feature set** for real DOM usage.

**Note:** querySelector is fully DOM Core (works for XML, SVG, HTML, MathML). getElementById is optional (treats "id" attribute specially, somewhat HTML-centric but useful).

---

## Testing Requirements

Each feature must have:

1. **Unit Tests** (100+ per major feature)
   - Happy path
   - Edge cases (null, empty, invalid)
   - Error conditions
   - Memory safety (no leaks)

2. **Spec Compliance Tests**
   - Cross-reference WHATWG spec algorithms
   - WebIDL signature verification
   - Behavior verification

3. **Performance Tests**
   - Benchmark critical paths
   - Verify O(n) complexity assumptions
   - Compare against baselines

4. **Integration Tests**
   - Real-world usage scenarios
   - Cross-feature interactions
   - Mutation observer integration

---

## Performance Targets

### Query Performance

- **getElementById:** O(1) lookup (HashMap)
- **querySelector:** O(n) worst case, O(log n) average with bloom filter
- **getElementsByClassName:** O(n) with bloom filter fast path
- **getElementsByTagName:** O(n) linear scan

### Memory Efficiency

- **HTMLCollection:** Lazy evaluation, no storage overhead
- **DOMTokenList:** Reuse class bloom filter
- **MutationObserver:** Store in rare data (allocated on demand)

---

## Dependencies and Blockers

### Selector Implementation Dependencies
1. ✅ Tokenizer (DONE)
2. ❌ Parser (NEEDED)
3. ❌ Matcher (NEEDED)
4. ❌ HTMLCollection (NEEDED for ParentNode)

### No External Blockers
- All features can be implemented with current codebase
- No missing infrastructure
- Zig 0.11+ provides all needed capabilities

---

## Success Criteria

### Phase 1 Complete When (DOM Core):
- [ ] `querySelector("element[attr='value']")` returns first matching element
- [ ] `querySelectorAll("element[attr='value']")` returns all matching elements
- [ ] `Element.matches("selector")` correctly identifies matches
- [ ] `Element.closest("selector")` finds nearest ancestor
- [ ] All selector types work (tag, class, id, attribute, pseudo-classes)
- [ ] All combinators work (>, +, ~, space)
- [ ] All tests pass with 0 memory leaks
- [ ] Documentation complete with JS bindings
- [ ] Benchmarks show acceptable performance

### Optional:
- [ ] `getElementById("foo")` returns element with id="foo" in O(1) (treats "id" attribute specially)

---

## Conclusion

**Current Status:** Core DOM tree manipulation is solid ✅

**Scope:** DOM Core only (language-agnostic, no HTML-specific features) ✅

**Critical Gap:** Query/selection features missing ❌

**Recommended Next Steps (DOM Core):**
1. 🔥 Complete CSS selector parser (3-4 days)
2. 🔥 Implement selector matcher (3-4 days)
3. 🔥 Add querySelector/querySelectorAll (2-3 days)
4. 🔥 Add Element.matches/closest (1-2 days)
5. ⚠️ Optional: getElementById (2-3 days) - treats "id" attribute specially

**Features Excluded (HTML-specific):**
- ❌ HTMLCollection (HTML document collections)
- ❌ getElementsByTagName/ClassName (HTML document methods)
- ❌ DOMTokenList (HTML class attribute manipulation)
- ❌ Special "id" attribute handling (optional for getElementById)

**Alternatives (DOM Core):**
- Use `querySelectorAll()` instead of getElementsBy* methods
- Use standard attribute methods instead of classList
- getElementById is optional if you want O(1) id lookup

**Total Time to Usable DOM:** ~1-2 weeks of focused work

**Impact:** Transforms library from "tree builder" to "practical DOM Core implementation"

**Key Principle:** This library implements **DOM Core** - features that work for **any** markup language (HTML, XML, SVG, MathML). HTML-specific features belong in an HTML library layer.

---

*Last Updated: October 17, 2025*  
*Based on: WHATWG DOM Living Standard (Core features only)*  
*Scope: DOM Core (language-agnostic)*  
*Excludes: HTML-specific features (HTMLCollection, HTMLDocument, etc.)*  
*WebIDL Reference: skills/whatwg_compliance/dom.idl*
