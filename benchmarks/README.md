# DOM Performance Benchmarks

## Overview

This document describes the comprehensive benchmark suite for the Zig DOM implementation, covering 48 different operations across 8 categories.

## Running Benchmarks

```bash
# Run with optimizations (recommended for accurate results)
zig build bench -Doptimize=ReleaseFast

# Run with debug mode (slower but includes more checks)
zig build bench
```

**Note:** Always use `-Doptimize=ReleaseFast` for performance testing. Debug builds are ~10-20x slower.

## Benchmark Categories

### 1. CSS Selector Queries (3 benchmarks)
Tests the performance of CSS selector matching and querying operations.

- **Simple selector (.class)** - Basic class selector matching
- **Complex selector (article.post > p.content)** - Multi-level descendant selectors
- **querySelectorAll (10 elements)** - Bulk element selection

**Typical Performance (ReleaseFast):**
- Simple selector: ~40 μs/op (25,000 ops/sec)
- Complex selector: ~45 μs/op (22,000 ops/sec)
- querySelectorAll: ~75 μs/op (13,000 ops/sec)

### 2. DOM CRUD Operations (9 benchmarks)
Tests fundamental DOM creation, manipulation, and destruction operations.

- **createElement** - Basic element creation
- **createElement + 3 attributes** - Element creation with attribute initialization
- **createTextNode** - Text node creation
- **appendChild (single)** - Single child insertion
- **appendChild (10 children)** - Batch child insertion
- **removeChild** - Child removal
- **setAttribute** - Attribute modification
- **getAttribute** - Attribute retrieval
- **className operations** - CSS class manipulation

**Typical Performance (ReleaseFast):**
- createElement: ~15 μs/op (65,000 ops/sec)
- createTextNode: ~14 μs/op (70,000 ops/sec)
- appendChild: ~14-15 μs/op (68,000 ops/sec)
- setAttribute/getAttribute: ~21-22 μs/op (46,000 ops/sec)

### 3. Tree Traversal (2 benchmarks)
Tests performance of tree navigation and traversal operations.

- **Tree traversal (5 levels, 3 children/node)** - Balanced tree traversal
- **Deep tree traversal (50 levels)** - Deep linear tree navigation

**Typical Performance (ReleaseFast):**
- Balanced tree: ~29 μs/op (34,000 ops/sec)
- Deep tree: ~30 μs/op (33,000 ops/sec)

### 4. Batch Operations (1 benchmark)
Tests bulk insertion performance.

- **Batch insert 100 elements** - Inserting 100 elements in one operation

**Typical Performance (ReleaseFast):**
- ~49 μs/op (20,000 ops/sec)

### 5. Event System (9 benchmarks) ✨ NEW
Tests event creation, listener management, and event dispatching.

- **Create Event** - Standard event object creation
- **Create CustomEvent** - Custom event creation with data payload
- **addEventListener** - Registering event listeners
- **removeEventListener** - Unregistering event listeners
- **dispatchEvent (single listener)** - Dispatching to one listener
- **Event propagation (2 levels)** - Bubbling through parent hierarchy
- **Event capture** - Capture phase event handling
- **Multiple listeners (3)** - Dispatching to multiple listeners
- **stopPropagation** - Testing propagation control

**Typical Performance (ReleaseFast):**
- Create Event: ~12 μs/op (83,000 ops/sec)
- Create CustomEvent: ~15 μs/op (66,000 ops/sec)
- addEventListener/removeEventListener: ~18 μs/op (55,000 ops/sec)
- dispatchEvent: ~18-19 μs/op (53,000 ops/sec)
- Event propagation: ~24-27 μs/op (36,000-40,000 ops/sec)

### 6. Mutation Observer (7 benchmarks) ✨ NEW
Tests the MutationObserver API for monitoring DOM changes.

- **Create observer** - Observer instantiation
- **Observe childList** - Watching child node changes
- **Observe attributes** - Watching attribute modifications
- **Observe subtree** - Recursive observation of descendants
- **Disconnect observer** - Stopping observation
- **takeRecords** - Retrieving pending mutation records
- **Multiple observers** - Multiple observers on same target

**Typical Performance (ReleaseFast):**
- Create observer: ~6.7 μs/op (149,000 ops/sec)
- Observe operations: ~20-23 μs/op (43,000-49,000 ops/sec)
- takeRecords: ~22.6 μs/op (44,000 ops/sec)

### 7. Range Operations (12 benchmarks) ✨ NEW
Tests DOM Range API for text selection and manipulation.

- **Create Range** - Range object creation
- **setStart** - Setting range start boundary
- **setEnd** - Setting range end boundary
- **selectNode** - Selecting an entire node
- **selectNodeContents** - Selecting node's contents only
- **collapse** - Collapsing range to a point
- **cloneRange** - Duplicating a range
- **extractContents** - Moving range contents to fragment
- **cloneContents** - Copying range contents to fragment
- **deleteContents** - Removing range contents from DOM
- **insertNode** - Inserting node at range position
- **compareBoundaryPoints** - Comparing range boundaries

**Typical Performance (ReleaseFast):**
- Create Range: ~6.6 μs/op (151,000 ops/sec)
- setStart/setEnd: ~22-23 μs/op (44,000 ops/sec)
- selectNode operations: ~27-28 μs/op (36,000 ops/sec)
- Content operations: ~27-28 μs/op (35,000-36,000 ops/sec)
- compareBoundaryPoints: ~24 μs/op (41,000 ops/sec)

### 8. Stress Tests (5 benchmarks)
Expensive operations involving thousands of elements to test scalability.

- **Create 10,000 nodes** - Mass node creation
- **Deep tree (500 levels)** - Extremely deep tree operations
- **Complex query over 10k nodes** - Selector query on large tree
- **1,000 elements × 10 attributes** - Mass attribute operations
- **Wide tree (100×100 = 10k nodes)** - Very wide tree structure

**Typical Performance (ReleaseFast):**
- Create 10k nodes: ~8.3 ms/op (120 ops/sec)
- Deep tree 500: ~96 μs/op (10,400 ops/sec)
- Complex query 10k: ~228 ms/op (4 ops/sec)
- Mass attributes: ~825 μs/op (1,200 ops/sec)
- Wide tree: ~2.3 ms/op (441 ops/sec)

## Implementation Details

### Event Benchmarks

The event benchmarks test the complete event system including:
- Event object lifecycle (creation, dispatch, cleanup)
- Event listener registration/removal
- Event propagation (bubbling and capture phases)
- Multiple listener coordination
- Propagation control (stopPropagation)

**Key Implementation Notes:**
- Events use `defer event.deinit()` for cleanup
- CustomEvents use `defer event.release()` instead
- `removeEventListener` requires 3 parameters: type, callback, and capture flag
- Event listeners are stored per-element in an event listener map

### MutationObserver Benchmarks

Tests the observer pattern for DOM change detection:
- Observer creation and configuration
- Different observation modes (childList, attributes, subtree)
- Record retrieval and cleanup
- Multiple observers on same target

**Key Implementation Notes:**
- Observers use `defer observer.deinit()` for cleanup
- Callbacks receive `[]const *MutationRecord` and an opaque context pointer
- Records must be manually freed after `takeRecords()`
- Each observer maintains its own record queue

### Range Benchmarks

Tests text selection and manipulation APIs:
- Range creation and boundary management
- Node and content selection
- Range cloning and comparison
- Content extraction, deletion, and insertion

**Key Implementation Notes:**
- Ranges use `defer range.deinit()` for cleanup
- Text nodes must be accessed via `.character_data.node` when passing to Node APIs
- Range constants like `START_TO_START` are module-level, not struct methods
- Content operations return DocumentFragments that need cleanup

## Benchmark Architecture

### Structure

```
benchmarks/
├── main.zig                    # Main benchmark runner
├── benchmark_runner.zig        # Benchmark timing infrastructure
├── selector_benchmarks.zig     # CSS selector tests
├── crud_benchmarks.zig         # CRUD operation tests
├── traversal_benchmarks.zig    # Tree traversal tests
├── batch_benchmarks.zig        # Batch operation tests
├── event_benchmarks.zig        # Event system tests (NEW)
├── observer_benchmarks.zig     # MutationObserver tests (NEW)
├── range_benchmarks.zig        # Range API tests (NEW)
└── stress_benchmarks.zig       # Scalability tests
```

### Benchmark Function Pattern

Each benchmark follows this pattern:

```zig
pub fn benchOperationName(allocator: std.mem.Allocator) !void {
    // Setup
    const obj = try SomeType.init(allocator);
    defer obj.release(); // or deinit()
    
    // Operation being benchmarked
    try obj.someOperation();
    
    // Cleanup happens via defer
}
```

### Runner Infrastructure

The benchmark runner (`benchmark_runner.zig`) provides:
- High-resolution timing using `std.time.Timer`
- Configurable iteration counts per benchmark
- Statistical reporting (min, max, average, total time)
- Memory allocation tracking via provided allocator

## Performance Expectations

### Fast Operations (< 20 μs)
- Basic object creation (Event, Range, Observer)
- Simple DOM node creation
- Direct child manipulation
- Basic attribute operations

### Medium Operations (20-50 μs)
- Event dispatching and propagation
- Observer configuration
- Range boundary operations
- Attribute and class manipulation

### Slow Operations (> 50 μs)
- Complex CSS selectors
- Deep content cloning
- Batch operations
- Query operations over large trees

### Stress Tests (milliseconds)
- Operations on 1,000+ nodes
- Deep tree navigation (500+ levels)
- Complex queries on 10,000+ nodes

## Interpreting Results

### ops/sec (Operations Per Second)
Higher is better. Indicates throughput for the operation.

### μs/op (Microseconds Per Operation)
Lower is better. Indicates latency for single operation.

### Debug vs ReleaseFast Comparison
- Debug builds: Includes bounds checking, slower allocations
- ReleaseFast: Optimized machine code, ~10-20x faster
- Always benchmark in ReleaseFast for realistic performance

## Future Improvements

Potential areas for benchmark expansion:

1. **XPath Benchmarks** - Once XPath implementation is complete
2. **TreeWalker/NodeIterator** - Tree traversal APIs
3. **Shadow DOM** - ShadowRoot and slot operations
4. **Async Operations** - If DOM gains async APIs
5. **Memory Pressure** - Benchmarks under constrained memory
6. **Concurrent Access** - If DOM becomes thread-safe

## Contributing

When adding new benchmarks:

1. Create or update a category file in `benchmarks/`
2. Follow the established function signature pattern
3. Use appropriate defer patterns for cleanup
4. Add benchmark calls to `main.zig`
5. Choose iteration counts based on operation cost:
   - Fast ops (< 20μs): 50,000-100,000 iterations
   - Medium ops (20-50μs): 10,000-50,000 iterations
   - Slow ops (> 50μs): 1,000-10,000 iterations
   - Stress tests: 5-100 iterations
6. Update this documentation with performance expectations

## Benchmark Results Archive

### Session 12 - Initial Complete Benchmark Suite
**Date:** October 11, 2025  
**Zig Version:** 0.15.1  
**Platform:** macOS (Apple Silicon)  
**Build:** ReleaseFast  
**Total Benchmarks:** 48

All benchmarks completed successfully in ~36 seconds with ReleaseFast optimization.
See "Typical Performance" sections above for detailed results.
