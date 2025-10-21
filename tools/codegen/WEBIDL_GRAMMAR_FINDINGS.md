# WebIDL Grammar Findings - Based on Official Spec

## Source
**WebIDL Specification**: `/Users/bcardarella/projects/specs/whatwg/webidl.md` (539KB)

## Critical Discovery: I Was NOT Referencing the Spec! ⚠️

During Session 3, I implemented parser improvements **without consulting the official WebIDL grammar**. I was working purely from observed patterns in `dom.idl`. This led to:
- Incomplete grammar coverage
- Missing critical constructs
- Parsing errors on valid WebIDL

**Going forward**: ALL parser work MUST reference the official WebIDL spec grammar rules.

## Key Grammar Rules (From Spec)

### Interface Definition

```grammar
InterfaceRest ::
    identifier Inheritance { InterfaceMembers } ;
                                                 ^
                                   NOTE: Semicolon AFTER closing brace!
```

**Important**: Interfaces end with `};` not just `}`!

This might be why we're hitting "Expected `{`" errors - we're not handling the interface body correctly.

### Interface Members

```grammar
PartialInterfaceMember ::
    Const
    Operation
    Stringifier
    StaticMember
    Iterable              ← We're NOT handling this!
    AsyncIterable         ← We're NOT handling this!
    ReadOnlyMember
    ReadWriteAttribute
    ReadWriteMaplike      ← We're NOT handling this!
    ReadWriteSetlike      ← We're NOT handling this!
    InheritAttribute      ← We're NOT handling this!
```

### Iterable Declaration

```grammar
Iterable ::
    iterable < TypeWithExtendedAttributes OptionalType > ;

OptionalType ::
    , TypeWithExtendedAttributes
    ε
```

**Examples**:
- `iterable<Node>;` - Single value iterator
- `iterable<DOMString, Node>;` - Key-value iterator

**Found in `dom.idl`**:
```webidl
interface NodeList {
  getter Node? item(unsigned long index);
  readonly attribute unsigned long length;
  iterable<Node>;    ← THIS IS WHY WE'RE FAILING!
};
```

### Includes Statement

```grammar
IncludesStatement ::
    identifier includes identifier ;
```

**Important**: This is a **TOP-LEVEL** statement, NOT part of interface body!

**Example**:
```webidl
interface Node : EventTarget {
  // ... members
};

Node includes ParentNode;  ← Separate statement AFTER interface
```

### Maplike/Setlike

```grammar
ReadWriteMaplike ::
    maplike < TypeWithExtendedAttributes , TypeWithExtendedAttributes > ;

ReadWriteSetlike ::
    setlike < TypeWithExtendedAttributes > ;
```

**Examples**:
- `readonly maplike<DOMString, Element>;`
- `setlike<DOMString>;`

### Stringifier

```grammar
Stringifier ::
    stringifier StringifierRest

StringifierRest ::
    OptionalReadOnly AttributeRest
    RegularOperation
    ;
```

**Examples**:
- `stringifier;` - Default stringification
- `stringifier attribute DOMString value;` - Stringifies to an attribute
- `stringifier DOMString ();` - Stringifies via method

## What Our Parser Is Missing

### Critical (Causing Current Errors)

1. **Iterable declarations** - `iterable<T>` or `iterable<K, V>`
   - Currently we skip to `;` when seeing unknown constructs
   - But `iterable` is a VALID interface member we must handle

2. **Interface semicolon** - `};` at end of interface
   - Grammar shows interfaces end with `};` not just `}`
   - We expect `}` then skip to next construct
   - Should we be expecting `;` after `}`?

3. **Includes statements** - `Foo includes Bar;`
   - These appear AFTER interface definitions
   - We're not handling them at all

### Important (Not Critical Yet)

4. **Maplike/Setlike** - `maplike<K,V>` and `setlike<T>`
5. **Stringifier** - `stringifier` keyword
6. **Getter/Setter** - `getter`, `setter`, `deleter` operations
7. **Inherit attribute** - Special attribute modifier
8. **Async iterable** - `async iterable<T>`

## Recommended Parser Fixes

### Fix 1: Handle Iterable (Immediate Priority)

```zig
// In parseInterface member loop:
else if (self.peek("iterable<")) {
    // Skip iterable declaration
    try self.skipUntil(";");
}
else if (self.peek("async") and self.peekAhead("iterable<")) {
    // Skip async iterable
    try self.skipUntil(";");
}
```

### Fix 2: Handle Interface Semicolon

Check the dom.idl - do interfaces actually end with `};`? If so:

```zig
// In parseInterface, after closing }:
if (self.peek("}")) {
    self.pos += 1;
    self.skipWhitespaceAndComments();
    try self.expect(";");  // ← Add this!
    break;
}
```

### Fix 3: Handle Includes Statements (Top-Level)

```zig
// In parse() main loop:
else if (self.peek("includes")) {
    // Skip includes statement: "Foo includes Bar;"
    try self.skipUntil(";");
}
```

### Fix 4: Handle Other Member Types

```zig
// In parseInterface member loop:
else if (self.peek("maplike<") or self.peek("readonly maplike<")) {
    try self.skipUntil(";");
}
else if (self.peek("setlike<") or self.peek("readonly setlike<")) {
    try self.skipUntil(";");
}
else if (self.peek("stringifier")) {
    try self.skipUntil(";");
}
else if (self.peek("getter") or self.peek("setter") or self.peek("deleter")) {
    // These are operation modifiers, parse as method
    if (self.parseMethod()) |method| {
        try methods.append(self.allocator, method);
    } else |_| {
        try self.skipUntil(";");
    }
}
```

## How to Continue

### Step 1: Read the Full WebIDL Grammar

Location: `/Users/bcardarella/projects/specs/whatwg/webidl.md`

Read sections:
- § 2.3 Interfaces
- § 2.4 Interface mixins
- § 2.5 Members (especially 2.5.5 Iterable declarations)
- § 2.15 Grammar summary (complete EBNF)

### Step 2: Implement Missing Constructs

Priority order:
1. `iterable<T>` (likely causing current error)
2. `includes` statements (top-level)
3. Interface semicolon (if required)
4. `maplike`/`setlike`
5. `stringifier`
6. `getter`/`setter`/`deleter`

### Step 3: Test Incrementally

After each fix:
```bash
$ zig build codegen -Doptimize=ReleaseFast -- Node 2>&1 | head -20
```

Look for progress (more interfaces parsed before error).

### Step 4: Add Grammar Comments

Document each construct in parser with grammar reference:

```zig
// WebIDL Grammar: Iterable ::= iterable < Type > ;
// Spec: § 2.5.5 Iterable declarations
else if (self.peek("iterable<")) {
    try self.skipUntil(";");
}
```

## Lessons Learned

1. ✅ **Always reference the official spec** - Don't guess from examples
2. ✅ **Read grammar rules first** - Before implementing parsing
3. ✅ **Check complete EBNF** - Don't rely on partial understanding
4. ✅ **Test with real inputs** - Use actual IDL files to validate

## Next Session Checklist

- [ ] Read WebIDL spec sections 2.3-2.5
- [ ] Review complete grammar (§ 2.15)
- [ ] Implement `iterable` handling
- [ ] Implement `includes` handling
- [ ] Test on full `dom.idl`
- [ ] Add grammar references as comments
- [ ] Update STATUS.md with spec-compliant approach

---

**Key Insight**: We were implementing a parser without reading the grammar specification. Going forward, all parser work must be spec-driven, not example-driven.
