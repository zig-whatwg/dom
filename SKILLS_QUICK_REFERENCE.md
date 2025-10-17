# Skills Quick Reference

## 🎯 What Are Skills?

**Skills are modular expertise packages that Claude loads automatically when relevant to your task.**

Instead of loading 42KB of guidelines for every task, Claude now loads only what's needed (typically 10-30KB).

---

## 📚 Available Skills

### 1. `whatwg_compliance`
**When**: Implementing DOM interfaces, checking WebIDL signatures, understanding WHATWG algorithms  
**Contains**: Complete WebIDL spec (dom.idl), type mappings, implementation workflow  
**Key Files**: 
- `skills/whatwg_compliance/SKILL.md` - Usage guide
- `skills/whatwg_compliance/dom.idl` - FULL WebIDL (23KB)
- `skills/whatwg_compliance/webidl_mapping.md` - Type reference

### 2. `zig_standards`
**When**: Writing Zig code, managing memory with Document/allocators, handling errors  
**Contains**: Naming conventions, memory patterns, reference counting, error handling  
**Key Files**:
- `skills/zig_standards/SKILL.md`

### 3. `testing_requirements`
**When**: Writing tests, ensuring coverage, verifying no leaks, TDD workflow  
**Contains**: Test patterns, memory leak testing, TDD workflow, refactoring rules  
**Key Files**:
- `skills/testing_requirements/SKILL.md`

### 4. `performance_optimization`
**When**: Optimizing hot paths, implementing selectors, minimizing allocations  
**Contains**: Fast paths, bloom filters, allocation patterns, benchmarking  
**Key Files**:
- `skills/performance_optimization/SKILL.md`

### 5. `documentation_standards`
**When**: Writing docs, updating README/CHANGELOG, documenting decisions  
**Contains**: Inline doc format, CHANGELOG rules, README workflow, doc organization  
**Key Files**:
- `skills/documentation_standards/SKILL.md`

---

## 🧠 Memory Tool

**Location**: `memory/` directory

**Purpose**: Persist knowledge across conversations

**Files**:
- `completed_features.json` - Track implementations
- `design_decisions.md` - Architectural rationale
- `performance_baselines.json` - Benchmark tracking
- `spec_interpretations.md` - Complex spec notes

Claude uses the memory tool automatically to maintain project context.

---

## 🚀 How Skills Work

### Automatic Loading

```
You: "Implement Element.setAttribute()"

Claude automatically loads:
✓ whatwg_compliance  → Reads FULL Element interface from dom.idl
✓ zig_standards      → Memory patterns, errors
✓ documentation_standards → Inline doc format

You don't need to do anything - it just works!
```

### Context Efficiency

**Old AGENTS.md**: 42KB always loaded  
**New Skills**: 8.3KB base + relevant skills (10-30KB typical)  
**Savings**: 80% reduction in baseline context usage

### Complete Spec Access

**Old**: Grep fragments of spec  
**New**: Read COMPLETE WebIDL interfaces and prose algorithms

```
skills/whatwg_compliance/dom.idl contains:
✓ All 23KB of WebIDL definitions
✓ Complete interfaces (Event, Node, Element, Document, etc.)
✓ Inheritance relationships
✓ Extended attributes ([CEReactions], [SameObject], etc.)
```

---

## 📖 Quick Reference

### Most Common Types

```zig
undefined → void                 // NOT bool!
DOMString → []const u8
DOMString? → ?[]const u8
unsigned long → u32
Node → *Node
Node? → ?*Node
[NewObject] Element → !*Element
[SameObject] NodeList → *NodeList
```

### Memory Management

```zig
// Pattern 1: Direct creation (simple)
const elem = try Element.create(allocator, "div");
defer elem.node.release();

// Pattern 2: Document factory (RECOMMENDED - with string interning)
const doc = try Document.init(allocator);
defer doc.release();
const elem = try doc.createElement("div");
defer elem.node.release();
```

### Error Handling

```zig
pub const DOMError = error{
    InvalidCharacterError,
    HierarchyRequestError,
    NotFoundError,
    InvalidStateError,
};
```

---

## 🎓 Learn More

- **Main guide**: `AGENTS.md` (307 lines, quick read)
- **Detailed skills**: `skills/*/SKILL.md` (load automatically)
- **Complete refactoring notes**: `summaries/completion/AGENTS_REFACTORING.md`
- **Anthropic Skills docs**: https://www.anthropic.com/news/skills
- **Context Management**: https://www.anthropic.com/news/context-management

---

## ✅ Benefits

### For You
- ✅ Complete spec understanding (no grep fragments)
- ✅ Efficient context usage (80% reduction)
- ✅ Better agent performance (39% improvement per Anthropic)
- ✅ Persistent knowledge across sessions
- ✅ Automatic skill coordination

### For Claude
- 🚀 Faster task completion
- 🎯 Higher accuracy
- 🔄 Better memory
- 📊 Performance tracking
- 🛡️ Fewer errors

---

**Quality over speed. Skills provide the expertise. Claude coordinates automatically.**
