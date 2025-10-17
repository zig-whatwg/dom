# WHATWG DOM Specification Interpretations

Document complex or ambiguous spec sections and how they were interpreted in this implementation.

## Purpose

The WHATWG DOM spec can be ambiguous or incomplete in edge cases. This file tracks how we interpreted and implemented those cases.

---

## Custom Element Reactions

**Spec Section**: §4.13 - Custom elements

**Ambiguity**: Exact timing of attribute changed callbacks relative to tree mutations.

**Our Interpretation**: 
- [To be populated when custom elements are implemented]

**Rationale**:
- [Why we chose this interpretation]

---

## Namespace Handling in XML vs HTML

**Spec Section**: §4.9 - Element interface

**Ambiguity**: Case normalization behavior differs between HTML and XML documents.

**Our Interpretation**:
- XML documents: Case-sensitive, no normalization
- HTML documents: ASCII lowercase for tag and attribute names
- This matches browser behavior

**Rationale**:
- Aligns with XML 1.1 §2.3 (case-sensitive)
- Aligns with HTML5 spec (ASCII lowercase)
- Tested against browser implementations

---

*Add new interpretations as complex spec sections are implemented. Reference spec section numbers and describe the ambiguity.*
