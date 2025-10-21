# Security Decisions for JS Bindings

## innerHTML and outerHTML - NOT IMPLEMENTED

**Decision**: innerHTML and outerHTML properties are **intentionally NOT implemented** in this C-ABI.

### Rationale

1. **Generic DOM Library, Not HTML-Specific**
   - This library implements generic XML/DOM (WHATWG DOM Standard)
   - innerHTML/outerHTML require HTML parsing/serialization
   - HTML-specific features are explicitly out of scope (see AGENTS.md)

2. **Severe XSS Security Risk**
   - Both properties are primary vectors for Cross-Site Scripting (XSS) attacks
   - MDN Warning: "potentially a vector for cross-site-scripting (XSS) attacks, if the input originally came from an attacker"
   - Example attack: `element.innerHTML = "<img src='x' onerror='alert(1)'>"` executes JavaScript

3. **Trusted Types API Not Available in C**
   - Modern browsers mitigate XSS via Trusted Types API (TrustedHTML objects)
   - Trusted Types API is JavaScript-only - cannot be used from C
   - C callers cannot benefit from browser security infrastructure
   - Content Security Policy (CSP) enforcement not applicable to C library

4. **No HTML Parser/Serializer in Codebase**
   - Would require implementing full HTML5 parsing algorithm
   - Would require HTML serialization with entity encoding
   - Massive scope increase for questionable security benefit

5. **Wrong Layer for Sanitization**
   - Content sanitization must happen at application layer
   - Libraries like DOMPurify work in JavaScript context
   - C library cannot make security decisions about content

### Recommended Alternatives

#### For Content Manipulation (Safe Methods)

Instead of innerHTML, use safe DOM construction APIs:

```c
// ❌ UNSAFE: innerHTML (not provided)
// element.innerHTML = user_input; // XSS RISK!

// ✅ SAFE: Manual DOM construction
DOMElement* container = dom_document_createelement(doc, "container");

DOMElement* child = dom_document_createelement(doc, "item");
dom_element_set_attribute(child, "class", "item-class");

DOMText* text = dom_document_createtextnode(doc, user_input); // Safe - text only
dom_node_appendchild((DOMNode*)child, (DOMNode*)text);

dom_node_appendchild((DOMNode*)container, (DOMNode*)child);
```

#### For Reading Content (Safe Methods)

```c
// ❌ AVOID: outerHTML (not provided)
// const char* html = element.outerHTML;

// ✅ SAFE: Use textContent for plain text
const char* text = dom_node_get_textcontent((DOMNode*)element);
printf("Content: %s\n", text); // No HTML, just text

// ✅ SAFE: Traverse DOM tree manually
DOMElement* first_child = dom_element_get_firstelementchild(element);
while (first_child != NULL) {
    const char* tag = dom_element_get_tagname(first_child);
    const char* content = dom_node_get_textcontent((DOMNode*)first_child);
    printf("<%s>%s</%s>\n", tag, content, tag);
    first_child = dom_element_get_nextelementsibling(first_child);
}
```

### Security Best Practices for C Callers

1. **Never Trust User Input**
   - Always validate and sanitize user input before creating DOM nodes
   - Use `dom_document_createtextnode()` for user-provided strings (auto-escapes)
   - Never directly interpolate user strings into attribute values without validation

2. **Prefer Explicit DOM Construction**
   - Build DOM trees using createElement(), createTextNode(), appendChild()
   - Explicit construction prevents injection attacks
   - Clear separation between structure and content

3. **Validate Attribute Values**
   - Check attribute values match expected patterns
   - For URLs: validate scheme (http/https only, no javascript:)
   - For IDs/classes: validate character set (alphanumeric, hyphen, underscore)

4. **Use Content Security Policy (Application Layer)**
   - If embedding in web context, use CSP headers
   - Restrict script-src, object-src, etc.
   - Use nonces or hashes for inline scripts

### Example: Safe User Content Rendering

```c
// User provides potentially unsafe content
const char* user_name = get_user_input(); // e.g., "<script>alert(1)</script>"
const char* user_bio = get_user_bio();     // e.g., "Hello <b>world</b>"

// ❌ UNSAFE (if innerHTML existed):
// element.innerHTML = user_bio; // XSS ATTACK!

// ✅ SAFE: Use textContent (auto-escapes)
DOMElement* name_elem = dom_document_createelement(doc, "name");
DOMText* name_text = dom_document_createtextnode(doc, user_name);
// user_name "<script>alert(1)</script>" becomes text, not executed
dom_node_appendchild((DOMNode*)name_elem, (DOMNode*)name_text);

DOMElement* bio_elem = dom_document_createelement(doc, "bio");
DOMText* bio_text = dom_document_createtextnode(doc, user_bio);
// user_bio "Hello <b>world</b>" renders as literal text, <b> not parsed
dom_node_appendchild((DOMNode*)bio_elem, (DOMNode*)bio_text);
```

### If You Absolutely Need HTML Parsing

If your application requires HTML parsing, do it **outside this library**:

1. **Use a Dedicated HTML Parser** (Application Layer)
   - [html5ever](https://github.com/servo/html5ever) (Rust)
   - [gumbo-parser](https://github.com/google/gumbo-parser) (C)
   - [lexbor](https://github.com/lexbor/lexbor) (C)

2. **Sanitize First** (Application Layer)
   - Use DOMPurify (JavaScript) or equivalent
   - Strip dangerous elements: `<script>`, `<iframe>`, `<object>`
   - Strip dangerous attributes: `onerror`, `onload`, `onclick`, etc.
   - Whitelist safe elements and attributes only

3. **Then Build DOM Manually** (This Library)
   - Parse sanitized HTML with external parser
   - Build DOM tree using this library's safe APIs
   - Never directly inject unsanitized strings

### References

- MDN innerHTML Security Warning: https://developer.mozilla.org/en-US/docs/Web/API/Element/innerHTML#security_considerations
- MDN outerHTML Security Warning: https://developer.mozilla.org/en-US/docs/Web/API/Element/outerHTML#security_considerations
- OWASP XSS Prevention: https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
- Trusted Types API: https://developer.mozilla.org/en-US/docs/Web/API/Trusted_Types_API
- Content Security Policy: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP

---

## Summary

**innerHTML and outerHTML are NOT implemented** because:
1. Out of scope for generic XML/DOM library
2. Severe XSS risk without browser security infrastructure
3. Trusted Types API not available in C
4. Better alternatives exist (explicit DOM construction)

**Use safe APIs** provided by this library instead:
- `dom_document_createtextnode()` - Auto-escapes user content
- `dom_document_createelement()` - Explicit structure
- `dom_node_appendchild()` - Safe tree construction
- `dom_node_get_textcontent()` - Plain text extraction

**Security is the application's responsibility**, not the DOM library's responsibility.
