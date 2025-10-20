# WPT Test Priority Checklist

**Quick Reference**: What to implement/test next
**Last Updated**: 2025-10-20

---

## 🎯 IMMEDIATE: Quick Wins (1-2 weeks)

Add WPT tests for already-implemented features. Zero new implementation needed!

### CharacterData (2 tests - 1 day)
- [ ] Convert `CharacterData-insertData.html` to Zig ✅ IMPLEMENTED
- [ ] Convert `CharacterData-replaceData.html` to Zig ✅ IMPLEMENTED

### TreeWalker (5 tests - 2 days)
- [ ] `TreeWalker-basic.html` ✅ IMPLEMENTED
- [ ] `TreeWalker-currentNode.html` ✅ IMPLEMENTED
- [ ] `TreeWalker-traversal-reject.html` ✅ IMPLEMENTED
- [ ] `TreeWalker-traversal-skip.html` ✅ IMPLEMENTED
- [ ] `TreeWalker-acceptNode-filter.html` ✅ IMPLEMENTED

### Range API (5 tests - 2 days)
Pick 5 most representative from unit test coverage:
- [ ] `Range-constructor.html` ✅ IMPLEMENTED
- [ ] `Range-deleteContents.html` ✅ IMPLEMENTED
- [ ] `Range-extractContents.html` ✅ IMPLEMENTED
- [ ] `Range-insertNode.html` ✅ IMPLEMENTED
- [ ] `Range-compareBoundaryPoints.html` ✅ IMPLEMENTED

### DOMTokenList (4 tests - 2 days)
- [ ] `DOMTokenList-Iterable.html`
- [ ] `DOMTokenList-iteration.html`
- [ ] `DOMTokenList-stringifier.html`
- [ ] `DOMTokenList-value.html`

### HTMLCollection (5 tests - 2 days)
- [ ] `HTMLCollection-iterator.html`
- [ ] `HTMLCollection-live-mutations.window.js` ✅ IMPLEMENTED
- [ ] `HTMLCollection-supported-property-indices.html`
- [ ] `HTMLCollection-supported-property-names.html`
- [ ] `HTMLCollection-empty-name.html`

### AbortSignal (3 tests - 1 day)
- [ ] `AbortSignal.any.js` ✅ IMPLEMENTED
- [ ] `event.any.js` ✅ IMPLEMENTED
- [ ] `reason-constructor.html` ✅ IMPLEMENTED

### NodeIterator (5 tests - 2 days)
- [ ] `NodeIterator.html` ✅ IMPLEMENTED
- [ ] `NodeIterator-removal.html` ✅ IMPLEMENTED
- [ ] `NodeFilter-constants.html`

**Outcome**: 42 → 72 tests (71% increase!) in 1-2 weeks!

---

## 🔴 CRITICAL PRIORITY: Core DOM (Next 12 weeks)

User-facing features expected in any DOM library.

### ParentNode Mixin (13 tests - 2 weeks)
**Implementation Needed**: append(), prepend(), replaceChildren()

- [ ] Implement `ParentNode.append()` (accepts nodes and strings)
- [ ] Implement `ParentNode.prepend()` (accepts nodes and strings)
- [ ] Implement `ParentNode.replaceChildren()` (replaces all children)
- [ ] `ParentNode-append.html`
- [ ] `ParentNode-prepend.html`
- [ ] `ParentNode-replaceChildren.html`
- [ ] `append-on-Document.html`
- [ ] `prepend-on-Document.html`
- [ ] `ParentNode-children.html`

**querySelector Tests** (4 tests):
- [ ] `ParentNode-querySelector-All.html` + `.js`
- [ ] `ParentNode-querySelector-case-insensitive.html`
- [ ] `ParentNode-querySelector-escapes.html`
- [ ] `ParentNode-querySelector-scope.html`

### ChildNode Mixin (5 tests - 1 week)
**Implementation Needed**: after(), before(), replaceWith()

- [ ] Implement `ChildNode.after()` (accepts nodes and strings)
- [ ] Implement `ChildNode.before()` (accepts nodes and strings)
- [ ] Implement `ChildNode.replaceWith()` (accepts nodes and strings)
- [ ] `ChildNode-after.html`
- [ ] `ChildNode-before.html`
- [ ] `ChildNode-replaceWith.html`
- [ ] `ChildNode-remove.js` (shared tests)
- [ ] `CharacterData-remove.html`

### Element Operations (18 tests - 3 weeks)
**Implementation Needed**: closest(), matches(), getElementsBy*, removeAttribute(), insertAdjacent*

#### Selector Matching (5 tests)
- [ ] Implement `Element.closest()` (find ancestor matching selector)
- [ ] Implement `Element.matches()` (test if element matches selector)
- [ ] `Element-closest.html`
- [ ] `Element-matches.html` + `Element-matches.js`
- [ ] `Element-matches-namespaced-elements.html`

#### Element Queries (4 tests)
- [ ] Implement `Element.getElementsByTagName()`
- [ ] Implement `Element.getElementsByClassName()`
- [ ] `Element-getElementsByTagName.html`
- [ ] `Element-getElementsByClassName.html`

#### Element Manipulation (9 tests)
- [ ] Implement `Element.removeAttribute()`
- [ ] Implement `Element.insertAdjacentElement()`
- [ ] Implement `Element.insertAdjacentText()`
- [ ] `Element-removeAttribute.html`
- [ ] `Element-removeAttributeNS.html`
- [ ] `Element-insertAdjacentElement.html`
- [ ] `Element-insertAdjacentText.html`
- [ ] `insert-adjacent.html`
- [ ] `Element-remove.html`

### Document Operations (12 tests - 2 weeks)
**Implementation Needed**: getElementsBy*, adoptNode(), importNode()

#### Document Queries (4 tests)
- [ ] Implement `Document.getElementsByTagName()`
- [ ] Implement `Document.getElementsByClassName()`
- [ ] `Document-getElementsByTagName.html`
- [ ] `Document-getElementsByClassName.html`

#### Cross-Document Operations (8 tests)
- [ ] Implement `Document.adoptNode()` (move node to this document)
- [ ] Implement `Document.importNode()` (copy node to this document)
- [ ] `Document-adoptNode.html`
- [ ] `Document-importNode.html`
- [ ] `Node-mutation-adoptNode.html`
- [ ] `adoption.window.js`
- [ ] `remove-and-adopt-thcrash.html`
- [ ] `attributes-namednodemap-cross-document.window.js`

### Node Operations (8 tests - 1 week)
**Implementation Needed**: isEqualNode(), getRootNode(), edge cases

- [ ] Implement `Node.isEqualNode()` (deep equality)
- [ ] Implement `Node.getRootNode()` (find root of tree)
- [ ] `Node-isEqualNode.html`
- [ ] `rootNode.html`
- [ ] `Node-properties.html`
- [ ] `Node-constants.html`
- [ ] `Node-childNodes-cache.html`
- [ ] `Node-childNodes-cache-2.html`

### Event System Foundation (40 tests - 5 weeks)
**Implementation Needed**: Event constructor, dispatch, propagation

⚠️ **MAJOR GAP**: This is the biggest missing piece!

#### Event Construction (8 tests - 1 week)
- [ ] Implement `Event()` constructor
- [ ] Implement `CustomEvent()` constructor
- [ ] `Event-constructors.any.js`
- [ ] `CustomEvent.html`
- [ ] `Event-constants.html`
- [ ] `Event-isTrusted.any.js`
- [ ] `Event-timestamp-cross-realm-getter.html`
- [ ] `Event-subclasses-constructors.html`

#### Event Properties (8 tests - 1 week)
- [ ] Implement `Event.defaultPrevented`
- [ ] Implement `Event.returnValue` (legacy)
- [ ] Implement `Event.cancelBubble` (legacy)
- [ ] Implement global event object
- [ ] `Event-defaultPrevented.html`
- [ ] `Event-defaultPrevented-after-dispatch.html`
- [ ] `Event-returnValue.html`
- [ ] `Event-cancelBubble.html`

#### Event Dispatch (24 tests - 3 weeks)
- [ ] Implement capture phase
- [ ] Implement target phase
- [ ] Implement bubble phase
- [ ] Implement `stopPropagation()`
- [ ] Implement `stopImmediatePropagation()`
- [ ] Implement `preventDefault()`
- [ ] `Event-dispatch-bubbles-false.html`
- [ ] `Event-dispatch-bubbles-true.html`
- [ ] `Event-dispatch-order.html`
- [ ] `Event-dispatch-order-at-target.html`
- [ ] `Event-dispatch-listener-order.window.js`
- [ ] `Event-dispatch-handlers-changed.html`
- [ ] `Event-dispatch-omitted-capture.html`
- [ ] `Event-dispatch-propagation-stopped.html`
- [ ] `Event-dispatch-bubble-canceled.html`
- [ ] `Event-dispatch-multiple-stopPropagation.html`
- [ ] `Event-dispatch-multiple-cancelBubble.html`
- [ ] `Event-propagation.html`
- [ ] `Event-stopPropagation-cancel-bubbling.html`
- [ ] `Event-stopImmediatePropagation.html`
- [ ] `Event-dispatch-redispatch.html`
- [ ] `Event-dispatch-target-moved.html`
- [ ] `Event-dispatch-target-removed.html`
- [ ] `Event-dispatch-throwing.html`

**After Critical Priority**: 72 → 167 tests (30% coverage), v1.0 nearly complete!

---

## 🟠 HIGH PRIORITY: Full Spec Compliance (Next 8 weeks)

Features needed for complete WHATWG DOM Standard compliance.

### Advanced Selectors (10 tests - 2 weeks)
- [ ] `ParentNode-querySelector-All-content.html`
- [ ] `ParentNode-querySelectorAll-removed-elements.html`
- [ ] `ParentNode-querySelectors-exclusive.html`
- [ ] `ParentNode-querySelectors-namespaces.html`
- [ ] `ParentNode-querySelectors-space-and-dash-attribute-value.html`
- [ ] `getElementsByClassName-32.html`
- [ ] `getElementsByClassName-empty-set.html`
- [ ] `getElementsByClassName-whitespace-class-names.html`
- [ ] `selectors.js`
- [ ] `Element-matches-init.js`

### Text & DocumentFragment (5 tests - 1 week)
- [ ] Implement `Text.splitText()` (split text node at offset)
- [ ] `Text-splitText.html`
- [ ] `Text-wholeText.html`
- [ ] `DocumentFragment-getElementById.html`
- [ ] `DocumentFragment-querySelectorAll-after-modification.html`

### DOMImplementation (7 tests - 1 week)
- [ ] Implement `DOMImplementation.createDocument()`
- [ ] Implement `DOMImplementation.createDocumentType()`
- [ ] Implement `DOMImplementation.createHTMLDocument()`
- [ ] Implement `DOMImplementation.hasFeature()` (always true per spec)
- [ ] `Document-implementation.html`
- [ ] `DOMImplementation-createDocument.html`
- [ ] `DOMImplementation-createDocumentType.html`
- [ ] `DOMImplementation-createHTMLDocument.html` + `.js`
- [ ] `DOMImplementation-hasFeature.html`

### DocumentType (4 tests - 1 week)
- [ ] `Document-doctype.html`
- [ ] `DocumentType-literal.html`
- [ ] `DocumentType-remove.html`

### Event Listener Options (6 tests - 1 week)
- [ ] Implement `addEventListener` `once` option
- [ ] Implement `addEventListener` `passive` option
- [ ] Implement `addEventListener` `signal` option (AbortSignal)
- [ ] `AddEventListenerOptions-once.any.js`
- [ ] `AddEventListenerOptions-passive.any.js`
- [ ] `AddEventListenerOptions-signal.any.js`

### Advanced Event Dispatch (15 tests - 2 weeks)
- [ ] `Event-dispatch-reenter.html`
- [ ] `Event-dispatch-other-document.html`
- [ ] `Event-dispatch-click.html`
- [ ] `Event-dispatch-detached-click.html`
- [ ] `Event-init-while-dispatching.html`
- [ ] `Event-initEvent.html` (deprecated but still tested)
... (15 more advanced event tests)

### Namespaces (15 tests - 3 weeks)
- [ ] Implement `Document.createElementNS()`
- [ ] Implement `Element.setAttributeNS()`
- [ ] Implement `Element.getAttributeNS()`
- [ ] Implement `Element.removeAttributeNS()`
- [ ] Implement `Element.getElementsByTagNameNS()`
- [ ] `Document-createElementNS.html` + `.js`
- [ ] `Element-removeAttributeNS.html`
- [ ] `Element-getElementsByTagNameNS.html`
- [ ] `Document-getElementsByTagNameNS.html`
- [ ] `Document-Element-getElementsByTagNameNS.js`
- [ ] `Node-lookupNamespaceURI.html`
- [ ] `Element-matches-namespaced-elements.html`
- [ ] `ParentNode-querySelectors-namespaces.html`
- [ ] `Element-firstElementChild-namespace.html`

### Collections & Lists (13 tests - 2 weeks)
- [ ] `NodeList-Iterable.html`
- [ ] `NodeList-live-mutations.window.js`
- [ ] `NodeList-static-length-getter-tampered-1.html`
- [ ] `NodeList-static-length-getter-tampered-2.html`
- [ ] `NodeList-static-length-getter-tampered-3.html`
- [ ] `NodeList-static-length-getter-tampered-indexOf-1.html`
- [ ] `NodeList-static-length-getter-tampered-indexOf-2.html`
- [ ] `NodeList-static-length-getter-tampered-indexOf-3.html`
- [ ] `HTMLCollection-own-props.html`
- [ ] `HTMLCollection-delete.html`
- [ ] `HTMLCollection-as-prototype.html`
- [ ] `namednodemap-supported-property-names.html`
- [ ] `attributes-namednodemap.html`

### Range Mutations (11 tests - 2 weeks)
- [ ] Implement Range boundary auto-adjustment on mutations
- [ ] `Range-mutations-appendChild.html`
- [ ] `Range-mutations-appendData.html`
- [ ] `Range-mutations-dataChange.html`
- [ ] `Range-mutations-deleteData.html`
- [ ] `Range-mutations-insertBefore.html`
- [ ] `Range-mutations-insertData.html`
- [ ] `Range-mutations-removeChild.html`
- [ ] `Range-mutations-replaceChild.html`
- [ ] `Range-mutations-replaceData.html`
- [ ] `Range-mutations-splitText.html`
- [ ] `Range-mutations.js`

### AbortSignal Extensions (2 features, 5 tests - 1 week)
- [ ] Implement `AbortSignal.timeout()` (abort after timeout)
- [ ] Implement `AbortSignal.any()` (compose multiple signals)
- [ ] `timeout.any.js`
- [ ] `abort-signal-any.any.js`
- [ ] `abort-signal-any-crash.html`

**After High Priority**: 167 → 306 tests (55% coverage), v1.5 feature-complete!

---

## 🟡 MEDIUM PRIORITY: Advanced Features (Next 12 weeks)

Modern DOM features for advanced use cases.

### Shadow DOM Core (30 tests - 5 weeks)
- [ ] Complete `Element.attachShadow()` implementation
- [ ] Implement ShadowRoot modes (open, closed)
- [ ] Implement `HTMLSlotElement` interface
- [ ] Implement declarative slot assignment
- [ ] Implement imperative slot assignment
- [ ] Implement `slotchange` event
- [ ] Implement event retargeting in shadow trees
- [ ] Implement `Event.composedPath()`
- [ ] 30 core shadow DOM WPT tests

### Custom Elements Core (25 tests - 4 weeks)
- [ ] Complete `CustomElementRegistry.define()`
- [ ] Implement lifecycle callbacks (connectedCallback, disconnectedCallback, adoptedCallback, attributeChangedCallback)
- [ ] Implement custom element reactions
- [ ] Implement element upgrading
- [ ] 25 autonomous custom element WPT tests

### Advanced Node Operations (17 tests - 2 weeks)
- [ ] All Node edge cases
- [ ] Cross-document cloning edge cases
- [ ] Comment/Text constructor variations
- [ ] Processing instruction support (XML)
- [ ] CDATA section support (XML)

**After Medium Priority**: 306 → 378 tests (69% coverage), v2.0 nearly complete!

---

## 🟢 LOW PRIORITY: Polish & Future (As Needed)

Nice-to-have features and edge cases.

### Shadow DOM Advanced (40 tests)
- Focus delegation
- Declarative shadow DOM
- Complex slot scenarios

### Custom Elements Advanced (30 tests)
- Form-associated custom elements
- Element internals
- Scoped registries

### Edge Cases & Polish (30+ tests)
- Crash regression tests
- Unicode handling
- Legacy API support
- Browser-specific workarounds

**After Low Priority**: 378+ → 450+ tests (80%+ coverage), v2.5 complete!

---

## Progress Tracking

### Current Status (2025-10-20)
- [x] 42 WPT tests implemented (7.6%)
- [ ] Quick Wins (30 tests) - Target: Week of 2025-10-27
- [ ] ParentNode/ChildNode Mixins (18 tests) - Target: Mid November
- [ ] Element Operations (18 tests) - Target: Early December
- [ ] Event System (40 tests) - Target: End of Year
- [ ] Document Operations (12 tests) - Target: Mid January

### Milestone Targets
- **v0.9** (Current): 42 tests, core Node operations
- **v1.0** (Target: Q1 2026): 175+ tests, complete core DOM
- **v1.5** (Target: Q2 2026): 300+ tests, full WHATWG compliance
- **v2.0** (Target: Q3 2026): 378+ tests, Shadow DOM & Custom Elements

---

## Notes

### Test Conversion Guidelines
1. Always use generic element names (element, container, item, NOT div, span, p)
2. Preserve WPT test structure and assertions
3. Add memory leak verification (std.testing.allocator)
4. Document any deviations from WPT
5. Keep test names identical to WPT (with .zig extension)

### Implementation Guidelines
1. Read complete WHATWG spec section before implementing
2. Write tests first (TDD)
3. Use existing patterns from codebase
4. Document with WHATWG + MDN references
5. Verify zero memory leaks
6. Update CHANGELOG.md

### When to Skip a Test
- HTML-specific element behavior
- Browser rendering/layout requirements
- Resource loading (fetch, XHR)
- User interaction simulation
- CSS-specific behavior

---

**For detailed analysis**: See `WPT_GAP_ANALYSIS_COMPREHENSIVE.md`
**For executive summary**: See `WPT_GAP_ANALYSIS_EXECUTIVE_SUMMARY.md`
