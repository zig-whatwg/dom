# Debugging Session Notes: getElementById Bug

**Session Date**: October 22, 2024  
**Issue**: `document.getElementById()` returns null in V8 JavaScript tests, but works in C tests

---

## Investigation Timeline

### 1. Initial Symptom
JavaScript test showed getElementById returning null:
```javascript
const div = document.createElement("div");
div.setAttribute("id", "test-id");
document.appendChild(div);
const found = document.getElementById("test-id");  // Returns null!
```

But element was confirmed to be in tree via `getElementsByTagName`.

### 2. First Hypothesis: V8 Binding Issue
Added debug logging to V8 C++ wrapper:
```cpp
[DEBUG] getElementById: doc=0x100a4c000, id='test-id'
[DEBUG] getElementById result: 0x0
```

Document pointer was consistent, but result was null. Suspicion: bug in V8 wrapper caching.

### 3. C Test Verification
Wrote C test to verify Zig DOM works directly:
```c
dom_element_setattribute(div, "id", "test-id");
dom_node_appendchild(doc_node, div_node);
DOMElement* found = dom_document_getelementbyid(doc, "test-id");
// Result: FOUND ✓
```

**Conclusion**: Zig DOM implementation is correct. Bug is in language bindings layer.

### 4. Property Access Mystery
Noticed strange behavior:
```javascript
div.setAttribute("id", "test123");
console.log(div.getAttribute("id"));  // "test123" ✓
console.log(div.id);                  // "" (empty!) ✗
```

getAttribute works, but .id property returns empty string!

### 5. V8 Property Setter Issue
Initially suspected V8 property shadowing (JavaScript creating own property on instance). Added debug to IdSetter - but it was NEVER called! This led to discovery that IdGetter was also never seeing the attribute value.

### 6. Breakthrough: getAttribute Works, get_id Doesn't
Realized two different code paths:
- `getAttribute("id")` from JavaScript → Works ✓
- `dom_element_get_id()` (calls `getAttribute("id")` internally) → Returns empty ✗

Same function, different results! This pointed to a string lifetime issue.

### 7. Debug Logging in Zig
Added debug to `dom_element_get_id()`:
```zig
std::debug.print("[ZIG] getAttribute returned: {?s}\n", .{value});
```

Output: `getAttribute returned: null`

So internal call to `getAttribute("id")` returns null, even though external call returns "test123".

### 8. Attribute Inspection
Listed all attributes stored in element:
```
[ZIG] Element has 2 attributes:
[ZIG]   'T2' = 'test123'
[ZIG]   'T2�L�^��' = 'value123'
```

**SMOKING GUN**: Attribute names are corrupted garbage! Keys are wrong, but values are correct.

### 9. Root Cause Analysis
Traced string flow from JavaScript through V8 → C API → Zig:

1. V8 creates temporary UTF-8 buffer for "id"
2. C API converts to Zig slice pointing to V8 buffer
3. `setAttributeImpl` interns VALUE but NOT NAME
4. Attribute stores name pointer directly
5. V8 frees its buffer
6. Name pointer now points to freed memory → garbage

### 10. Why Values Work
Values ARE interned:
```zig
const interned_value = try doc.string_pool.intern(value);
```

This creates a stable copy owned by Document. But names are NOT interned, so they point to temporary memory.

### 11. Browser Research Confirmation
Checked how browsers handle this:
- Chrome: AtomicString (all strings interned)
- Firefox: nsAtom (all strings interned)
- WebKit: AtomString (all strings interned)

Our implementation: Values interned, names NOT interned → BUG!

---

## Key Insights

1. **Symptom != Root Cause**: getElementById failing was a symptom; attribute name corruption was the root cause

2. **Different Code Paths Matter**: C test worked because C strings are stable; V8 test failed because V8 strings are temporary

3. **Memory Flow Tracing Critical**: Understanding the lifetime of each pointer through the call stack revealed the bug

4. **Debug Output Saves Time**: Adding strategic debug logging at key points (attribute storage, retrieval) pinpointed the exact issue

5. **Browser Research Validates**: All browsers intern strings for good reasons - following their patterns would have prevented this bug

---

## Debugging Techniques Used

1. **Comparative Testing**: C test vs V8 test isolated the problematic layer
2. **Strategic Debug Logging**: Added at V8 wrapper, C API, and Zig implementation layers
3. **Data Structure Inspection**: Listed stored attributes to see corruption
4. **Memory Flow Analysis**: Traced pointer lifetimes through the call stack
5. **Reference Implementation Research**: Checked how browsers solve the same problem

---

## Lessons Learned

### For Future Debugging

1. **Test at multiple layers**: C API, JS bindings, unit tests
2. **Log pointer values**: Helps identify when pointers become invalid
3. **Inspect data structures**: Don't assume contents are what you expect
4. **Question assumptions**: "getAttribute works" → which getAttribute?
5. **Check lifetimes**: Temporary vs stable pointers

### For Implementation

1. **Intern all strings at boundaries**: C API → Zig should intern immediately
2. **Be consistent**: If values are interned, names should be too
3. **Learn from browsers**: They've solved these problems already
4. **Document ownership**: Make clear who owns each pointer
5. **Add assertions**: Check for garbage data in debug builds

---

## Prevention Strategies

### Code Review Checklist

When reviewing string handling code:
- [ ] Are all strings that need to persist being interned/copied?
- [ ] Is there asymmetry (some strings interned, others not)?
- [ ] Are we storing pointers to temporary buffers?
- [ ] Do lifetimes match expectations?
- [ ] Do we have tests with temporary string sources?

### Testing Checklist

When testing C API or bindings:
- [ ] Test with temporary string buffers
- [ ] Overwrite source buffers after API calls
- [ ] Test getAttribute after setAttribute
- [ ] Test both direct attribute access and property access
- [ ] Verify attribute names aren't corrupted

### Documentation Checklist

When documenting string APIs:
- [ ] Document string ownership (who owns? when freed?)
- [ ] Document whether strings are interned
- [ ] Document lifetime requirements
- [ ] Provide example with temporary strings
- [ ] Explain why interning is necessary

---

## Tools & Commands Used

### Compilation
```bash
# V8 bindings (need pointer compression flags)
clang++ -std=c++20 -DV8_COMPRESS_POINTERS -DV8_31BIT_SMIS_ON_64BIT_ARCH \
  -DV8_ENABLE_SANDBOX wpt_test_runner.cpp -I./include -I../js-bindings \
  -I/opt/homebrew/Cellar/v8/13.5.212.10/libexec/include -L./lib -lv8dom \
  -L../zig-out/lib -ldom -L/opt/homebrew/lib -lv8 -lv8_libplatform -lpthread \
  -o wpt_test_runner

# Zig library
zig build
```

### Running Tests
```bash
# JavaScript test
./wpt_test_runner ../tests/wpt-v8/test_getelementbyid_debug.js

# C test
clang test_getelementbyid_bug.c -I. -L./zig-out/lib -ldom \
  -o test_getelementbyid_bug && ./test_getelementbyid_bug
```

### Debug Output Techniques
```cpp
// C++
std::fprintf(stderr, "[DEBUG] pointer=%p, value='%s'\n", ptr, str);
```

```zig
// Zig
std.debug.print("[ZIG] value: {?s}\n", .{optional_string});
std.debug.print("[ZIG] pointer: {*}\n", .{pointer});
```

---

## Outcome

**Bug Found**: Attribute names not interned (use-after-free)  
**Fix Designed**: Intern names alongside values in `setAttributeImpl()`  
**Impact**: Critical - affects all attribute operations via C API/bindings  
**Next Steps**: Implement fix, add regression tests, verify with WPT suite

---

## Related Documents

- `ATTRIBUTE_NAME_INTERNING_ANALYSIS.md` - Detailed technical analysis
- `/tmp/attribute_flow_analysis.md` - Memory flow diagrams
- `/tmp/fix_analysis.md` - Fix options comparison

