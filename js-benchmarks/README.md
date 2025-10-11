# JavaScript DOM Benchmarks for Chrome

This directory contains JavaScript versions of all Zig DOM benchmarks, designed to run in Chrome's DevTools Console for direct performance comparison.

## Quick Start

### Option 1: Load Individual Files (Recommended for Development)

1. Open Chrome DevTools (F12 or Cmd+Option+I on Mac)
2. Go to the **Console** tab
3. Copy and paste the files in this order:

```javascript
// 1. Load the benchmark runner (required)
// Copy contents of: benchmark-runner.js

// 2. Load the benchmark suites you want to run
// Copy contents of: selector-benchmarks.js
// Copy contents of: crud-benchmarks.js
// Copy contents of: traversal-benchmarks.js
// Copy contents of: batch-benchmarks.js
// Copy contents of: event-benchmarks.js
// Copy contents of: observer-benchmarks.js
// Copy contents of: range-benchmarks.js
// Copy contents of: stress-benchmarks.js

// 3. Load and run
// Copy contents of: run-all.js

// 4. Execute benchmarks
await runAllBenchmarks()
```

### Option 2: Load Bundled Version (Fastest)

1. Open Chrome DevTools Console
2. Copy and paste entire contents of `bundle.js`
3. Run: `await runAllBenchmarks()`

## Individual Benchmark Suites

After loading the scripts, you can run individual suites:

```javascript
// CSS Selectors (3 benchmarks)
await runSelectorBenchmarks()

// DOM CRUD (9 benchmarks)
await runCrudBenchmarks()

// Tree Traversal (2 benchmarks)
await runTraversalBenchmarks()

// Batch Operations (1 benchmark)
await runBatchBenchmarks()

// Event System (9 benchmarks)
await runEventBenchmarks()

// MutationObserver (7 benchmarks)
await runObserverBenchmarks()

// Range Operations (12 benchmarks)
await runRangeBenchmarks()

// Stress Tests (5 benchmarks)
await runStressBenchmarks()
```

## Custom Benchmarks

Run your own benchmarks:

```javascript
await quickBench("My Custom Test", 1000, () => {
  // Your code here
  const elem = document.createElement('div');
  elem.textContent = 'test';
});
```

## Benchmark Coverage

### CSS Selector Queries (3 tests)
- Simple selector (`.class`)
- Complex selector (`article.post > p.content`)
- querySelectorAll (10 elements)

### DOM CRUD Operations (9 tests)
- createElement
- createElement + 3 attributes
- createTextNode
- appendChild (single)
- appendChild (10 children)
- removeChild
- setAttribute
- getAttribute
- className operations

### Tree Traversal (2 tests)
- Tree traversal (5 levels, 3 children/node)
- Deep tree traversal (50 levels)

### Batch Operations (1 test)
- Batch insert 100 elements

### Event System (9 tests)
- Create Event
- Create CustomEvent
- addEventListener
- removeEventListener
- dispatchEvent (single listener)
- Event propagation (2 levels)
- Event capture
- Multiple listeners (3)
- stopPropagation

### MutationObserver (7 tests)
- Create observer
- Observe childList
- Observe attributes
- Observe subtree
- Disconnect observer
- takeRecords
- Multiple observers

### Range Operations (12 tests)
- Create Range
- setStart
- setEnd
- selectNode
- selectNodeContents
- collapse
- cloneRange
- extractContents
- cloneContents
- deleteContents
- insertNode
- compareBoundaryPoints

### Stress Tests (5 tests)
- Create 10,000 nodes
- Deep tree (500 levels)
- Complex query over 10k nodes
- 1,000 elements × 10 attributes
- Wide tree (100×100 = 10k nodes)

## Performance Comparison

Run these benchmarks and compare with the Zig implementation results:

```bash
# In terminal (Zig benchmarks)
cd /path/to/dom
zig build bench -Doptimize=ReleaseFast
```

```javascript
// In Chrome Console (JS benchmarks)
await runAllBenchmarks()
```

### Expected Performance Characteristics

**Zig advantages:**
- 2-10x faster on selector queries
- 2-3x faster on element creation
- 10-70x faster on batch operations
- Zero GC overhead
- Consistent performance (no GC pauses)

**JavaScript advantages:**
- Highly optimized for specific patterns
- JIT compilation for hot paths
- Native browser integration

## Files

- `benchmark-runner.js` - Core benchmark infrastructure
- `selector-benchmarks.js` - CSS selector tests
- `crud-benchmarks.js` - DOM CRUD operation tests
- `traversal-benchmarks.js` - Tree traversal tests
- `batch-benchmarks.js` - Batch operation tests
- `event-benchmarks.js` - Event system tests
- `observer-benchmarks.js` - MutationObserver tests
- `range-benchmarks.js` - Range API tests
- `stress-benchmarks.js` - Large-scale stress tests
- `run-all.js` - Main runner and instructions
- `bundle.js` - All files combined (convenience)
- `README.md` - This file

## Tips for Accurate Benchmarks

1. **Close other tabs** - Reduce browser resource contention
2. **Disable extensions** - Some extensions interfere with timing
3. **Run multiple times** - First run includes warmup, subsequent runs more accurate
4. **Use Incognito mode** - Clean environment without extensions
5. **Check Task Manager** - Ensure Chrome isn't throttled
6. **Enable V8 flags** (optional, for more accurate results):
   - Start Chrome with: `--js-flags="--expose-gc"`
   - This allows manual garbage collection between benchmarks
   - Benchmarks work fine without this flag, but may show more variance

## Example Output

```
═══════════════════════════════════════════════════════════════════════
 DOM PERFORMANCE BENCHMARKS - JavaScript (Chrome)
═══════════════════════════════════════════════════════════════════════

📊 CSS SELECTOR QUERIES
────────────────────────────────────────────────────────────────────────
  Simple selector (.class)                            45.23 μs/op     22,108 ops/sec
  Complex selector (article.post > p.content)         52.18 μs/op     19,164 ops/sec
  querySelectorAll (10 elements)                      89.45 μs/op     11,179 ops/sec

📊 DOM CRUD OPERATIONS
────────────────────────────────────────────────────────────────────────
  createElement                                        18.32 μs/op     54,583 ops/sec
  createElement + 3 attributes                         42.15 μs/op     23,724 ops/sec
  ...
```

## Comparing Results

To compare Zig vs JavaScript performance:

1. Run Zig benchmarks: `zig build bench -Doptimize=ReleaseFast`
2. Run JS benchmarks: `await runAllBenchmarks()`
3. Compare μs/op (lower is better) or ops/sec (higher is better)

### Sample Comparison

| Operation | Zig (μs/op) | JS (μs/op) | Zig Speedup |
|-----------|-------------|------------|-------------|
| createElement | 14.5 | 18.3 | 1.26x faster |
| Simple selector | 34.9 | 45.2 | 1.30x faster |
| Batch insert 100 | 43.1 | 156.8 | 3.64x faster |

## Troubleshooting

**"runAllBenchmarks is not defined"**
- Make sure you loaded all the required files in order
- Load `benchmark-runner.js` first

**Benchmarks run very slowly**
- Close other tabs and applications
- Try Incognito mode
- Check if Chrome is throttled in Activity Monitor/Task Manager

**Results are inconsistent**
- Normal for JS due to GC and JIT compilation
- Run multiple times and average the results
- First run includes warmup overhead

## Contributing

When adding new benchmarks:

1. Add Zig version to `benchmarks/` directory
2. Add JavaScript version to `js-benchmarks/` directory
3. Ensure both test the same operation
4. Update both README files
5. Rebuild `bundle.js` if providing bundled version

## License

MIT License - Same as parent project

Copyright (c) 2025 DockYard, Inc.
