# Contributing to WHATWG DOM Implementation

Thank you for your interest in contributing to the WHATWG DOM implementation in Zig! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Coding Guidelines](#coding-guidelines)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Spec Compliance](#spec-compliance)
- [Questions](#questions)

## Getting Started

### Prerequisites

- **Zig 0.15.1 or later** - [Installation Guide](https://ziglang.org/download/)
- **Git** - For version control
- **A text editor** - VS Code with Zig extension recommended

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/dom.git
   cd dom
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/dom.git
   ```

## Development Setup

### Build the Project

```bash
zig build
```

### Run Tests

```bash
# Run all tests
zig build test --summary all

# Check for memory leaks
zig build test 2>&1 | grep -i leak
```

### Format Code

```bash
# Format all Zig files
zig fmt src/

# Check formatting without modifying
zig fmt --check src/
```

## How to Contribute

### Important: Issue and PR Policy

**Issues:**
- **Only organization members can open issues**
- If you've found a bug or want to suggest a feature:
  1. Open a [Discussion](../../discussions) describing the problem or idea
  2. An organization member will review it
  3. If appropriate, a member will create an issue referencing your discussion

**Pull Requests:**
- **Pull requests can only be opened if they fix an existing issue**
- Each PR must reference the issue it fixes (e.g., "Fixes #123")
- PRs without a linked issue will be closed
- Workflow:
  1. Find an open issue or start a discussion to get one created
  2. Comment on the issue to express interest in working on it
  3. Wait for assignment or approval from maintainers
  4. Create your PR that references the issue

### Starting a Discussion

To report bugs, suggest features, or ask questions:

1. Go to the [Discussions](../../discussions) tab
2. Click "New discussion"
3. Choose the appropriate category:
   - **Bug Reports** - For reporting bugs
   - **Feature Requests** - For suggesting new features
   - **Q&A** - For questions about usage or implementation
4. Provide detailed information:
   - **For bugs:**
     - Clear description of the bug
     - Steps to reproduce
     - Expected vs actual behavior
     - Zig version and OS
     - Minimal reproduction code
     - WHATWG spec reference (if applicable)
   - **For features:**
     - Clear description of the feature
     - Use case and motivation
     - WHATWG spec reference (if applicable)
     - Proposed API
   - **For questions:**
     - What you're trying to accomplish
     - What you've already tried
     - Relevant code samples
5. A maintainer will review and create an issue if needed

## Coding Guidelines

### Zig Style

Follow standard Zig conventions:

```zig
// Good: snake_case for functions and variables
pub fn appendChild(parent: *Node, child: *Node) !void {
    const result = try insertNode(parent, child);
    return result;
}

// Good: PascalCase for types
pub const Element = struct {
    node: *Node,
    attributes: AttributeList,
};

// Good: SCREAMING_CASE for constants
const MAX_DEPTH: usize = 1000;
```

### Documentation

All public APIs must be documented:

```zig
/// Creates a new element with the specified tag name.
/// 
/// Follows WHATWG DOM §4.9 Element creation algorithm.
/// https://dom.spec.whatwg.org/#dom-document-createelement
///
/// Memory: Caller must call element.release() when done.
/// Returns: A new Element node with ref_count = 1
/// Errors: OutOfMemory if allocation fails
pub fn createElement(allocator: Allocator, tag_name: []const u8) !*Element {
    // Implementation
}
```

### Memory Management

Follow these patterns:

```zig
// Reference counted objects (nodes)
const node = try Node.init(allocator, .element, "div");
defer node.release(); // Automatic cleanup

// Simple objects
const range = try Range.init(allocator);
defer range.deinit();

// Owned return values
const str = try node.toString(allocator);
defer allocator.free(str); // Caller owns result
```

### Error Handling

Use Zig's error handling:

```zig
// Define specific errors
pub const DOMError = error{
    InvalidNodeType,
    HierarchyRequest,
    NotFound,
    IndexSize,
};

// Return errors
pub fn setStart(self: *Range, node: *Node, offset: usize) DOMError!void {
    if (offset > getNodeLength(node)) {
        return error.IndexSize;
    }
    // ...
}

// Handle errors
const result = range.setStart(node, 5) catch |err| {
    std.debug.print("Error: {}\n", .{err});
    return err;
};
```

## Testing Guidelines

### Test Structure

```zig
test "Feature name - specific scenario" {
    const allocator = std.testing.allocator;
    
    // Setup
    const doc = try Document.init(allocator);
    defer doc.release();
    
    // Execute
    const elem = try Element.create(allocator, "div");
    defer elem.release();
    
    // Assert
    try std.testing.expectEqualStrings("div", elem.tag_name);
    
    // Cleanup happens via defer
}
```

### Test Coverage

All new features must include:

- ✅ **Happy path tests** - Normal usage scenarios
- ✅ **Edge case tests** - Boundary conditions
- ✅ **Error tests** - Invalid inputs and error conditions
- ✅ **Memory tests** - No leaks via `defer` patterns
- ✅ **Spec compliance** - Matches WHATWG behavior

### Test Naming

Use descriptive test names:

```zig
// Good
test "Element.appendChild - adds child to empty parent" { }
test "Element.appendChild - maintains tree order with multiple children" { }
test "Element.appendChild - throws on DocumentType child" { }

// Bad
test "appendChild test" { }
test "test1" { }
```

## Pull Request Process

### Before Starting

1. **Find or create an issue**
   - Browse [open issues](../../issues)
   - Or start a [discussion](../../discussions) to get an issue created by a maintainer
   - Comment on the issue to express interest
   - Wait for maintainer approval/assignment before starting work

2. **Create a feature branch**
   ```bash
   git checkout -b fix/123-issue-description
   # Example: git checkout -b fix/123-memory-leak-in-element
   ```

3. **Make your changes**
   - Follow coding guidelines above
   - Add tests for new features or fixes
   - Update documentation as needed

4. **Run quality checks**
   ```bash
   # Format code
   zig fmt src/
   
   # Run all tests
   zig build test --summary all
   
   # Verify no memory leaks
   zig build test 2>&1 | grep -i leak
   
   # Build in release mode
   zig build -Doptimize=ReleaseFast
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "fix: resolve memory leak in Element.closest() (fixes #123)"
   ```
   
   Use conventional commits:
   - `fix:` - Bug fix (most common for PRs)
   - `feat:` - New feature
   - `docs:` - Documentation only
   - `test:` - Adding tests
   - `refactor:` - Code refactoring
   - `perf:` - Performance improvement

6. **Push to your fork**
   ```bash
   git push origin fix/123-issue-description
   ```

### Creating the PR

1. Go to GitHub and create a Pull Request
2. **REQUIRED:** Reference the issue in the title or description
   - Use "Fixes #123" or "Closes #123" in the PR description
   - This will automatically close the issue when merged
   - Example title: "fix: resolve memory leak in Element.closest()"
   - Example description: "Fixes #123 by ensuring proper cleanup..."
3. Fill out the PR template completely
4. Ensure all CI checks pass
5. Wait for maintainer review

**⚠️ PRs without a linked issue will be closed immediately.**

### PR Review Process

- Maintainers will review your PR within a few days
- Address feedback by pushing new commits to the same branch
- Once approved, maintainers will merge your PR
- Your contribution will be credited in release notes

## Spec Compliance

### WHATWG DOM Standard

All implementations must follow the [WHATWG DOM Living Standard](https://dom.spec.whatwg.org/):

1. **Reference the spec** - Include spec section in code:
   ```zig
   /// Implements WHATWG DOM §4.2.3 Pre-insert algorithm
   /// https://dom.spec.whatwg.org/#concept-node-pre-insert
   ```

2. **Follow algorithms exactly** - Match spec steps:
   ```zig
   // 1. If parent is not a Document, DocumentFragment, or Element node,
   //    then throw a "HierarchyRequestError" DOMException.
   if (parent.node_type != .document and 
       parent.node_type != .document_fragment and 
       parent.node_type != .element) {
       return error.HierarchyRequest;
   }
   ```

3. **Test spec behavior** - Verify compliance:
   ```zig
   test "appendChild - throws HierarchyRequestError per spec §4.2.3" {
       // Test matches spec requirement
   }
   ```

### Spec Coverage

Check current coverage in `PROJECT_COMPLETE.md` before implementing:

- ✅ Events (§2) - 100%
- ✅ Aborting (§3) - 100%
- ✅ Nodes (§4) - ~98%
- ✅ Ranges (§5) - 100%
- ✅ Traversal (§6) - 100%
- ❌ XPath (§8) - Excluded
- ❌ XSLT (§9) - Excluded

## Questions?

- **All questions, bugs, and feature ideas** - Start a [Discussion](../../discussions)
- **Contributing to an existing issue** - Comment on the issue
- **General help** - Use the Q&A category in Discussions

**Remember:** Only organization members can open issues. Always start with a discussion!

## Recognition

Contributors will be:

- Listed in release notes
- Credited in `CONTRIBUTORS.md` (for significant contributions)
- Thanked in the project README

## License

By contributing, you agree that your contributions will be licensed under the same MIT License that covers the project. See the [LICENSE](LICENSE) file for details.

---

**Thank you for contributing to the WHATWG DOM implementation in Zig!** 🎉

Your contributions help make web standards accessible in Zig and advance the ecosystem.

**Questions?** Start a discussion - we're here to help! 🙏
