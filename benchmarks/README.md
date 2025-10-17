# DOM Benchmarks

Performance benchmarks for the WHATWG DOM implementation.

## Directory Structure

```
benchmarks/
├── README.md          (this file)
├── zig/               Zig (native) benchmarks
│   ├── benchmark.zig
│   └── benchmark_runner.zig
└── js/                JavaScript (browser) benchmarks
    ├── benchmark.js
    └── README.md
```

## Quick Start

### Zig Benchmarks (Native)

Run native Zig benchmarks:

```bash
# Debug build (slow)
zig build bench

# Release build (recommended)
zig build bench -Doptimize=ReleaseFast
```

**Expected Results (ReleaseFast):**
- getElementById: ~7ns (142M ops/sec)
- querySelector("#id"): ~16ns (62M ops/sec)

### JavaScript Benchmarks (Browser)

Run in browser for comparison:

1. Open browser console (F12)
2. Copy contents of `js/benchmark.js`
3. Paste into console
4. Run: `runAllBenchmarks()`

**Expected Results (Chrome V8):**
- getElementById: ~50-100ns (10-20M ops/sec)
- querySelector("#id"): ~200-500ns (2-5M ops/sec)

## Performance Comparison

| Operation | Zig | JavaScript | Zig Speedup |
|-----------|-----|------------|-------------|
| getElementById | 7ns | 80ns | **11x faster** |
| querySelector("#id") | 16ns | 400ns | **25x faster** |

### Why is Zig Faster?

1. **No JavaScript bridge** - Direct native execution
2. **No GC overhead** - Manual memory management
3. **LLVM optimizations** - Aggressive compiler optimizations
4. **Better memory layout** - Cache-friendly data structures
5. **Zero-cost abstractions** - No runtime overhead

## Benchmark Categories

### 1. Full Benchmarks (DOM Creation + Query)

Measures end-to-end performance including DOM creation:

- `querySelector: Small DOM (100)`
- `querySelector: Medium DOM (1000)`
- `querySelector: Large DOM (10000)`
- `getElementById: Small/Medium/Large DOM`

**Use case:** Simulates real-world scenarios where DOM is built and queried.

### 2. Pure Query Benchmarks (DOM Pre-Built)

Isolates query performance by building DOM once:

- `Pure query: getElementById (100/1000/10000 elem)`
- `Pure query: querySelector #id (100/1000/10000 elem)`

**Use case:** Shows true query performance without DOM creation overhead.

### 3. SPA Benchmarks

Simulates Single Page Application usage patterns:

- `SPA: Repeated queries` - Multiple selector types
- `SPA: Cold vs Hot cache` - Cache warming behavior

**Use case:** Real-world SPA performance with repeated queries.

## Understanding Results

### Time Units

- **ns** (nanoseconds): 1/1,000,000,000 second
- **µs** (microseconds): 1/1,000,000 second  
- **ms** (milliseconds): 1/1,000 second

### What's Fast?

**getElementById:**
- ✅ Good: < 100ns
- ⚠️ Acceptable: 100-1000ns
- ❌ Slow: > 1µs

**querySelector("#id"):**
- ✅ Good: < 500ns
- ⚠️ Acceptable: 500-5000ns
- ❌ Slow: > 5µs

### O(1) vs O(n) Behavior

**Good (O(1)):**
```
100 elements:   10ns
1,000 elements: 10ns  ✅ Constant time
10,000 elements: 10ns
```

**Bad (O(n)):**
```
100 elements:   10ns
1,000 elements: 100ns   ❌ Linear growth
10,000 elements: 1000ns
```

## Benchmark Results

See `../benchmark_results/` for detailed results:

- `baseline.txt` - Before optimization
- `phase1.txt` - Fast paths + selector cache
- `phase2.txt` - O(1) getElementById
- `phase2_release_fast.txt` - Final ReleaseFast results

## Running Benchmarks

### Zig

```bash
# Quick benchmark (Debug, ~2-3x slower)
zig build bench

# Production benchmark (ReleaseFast, accurate)
zig build bench -Doptimize=ReleaseFast

# Save results
zig build bench -Doptimize=ReleaseFast > results.txt
```

### JavaScript

```javascript
// Browser console
runAllBenchmarks();

// Compare with Zig
compareWithZig();

// Individual benchmarks
benchmarkFn('getElementById test', 10000, () => {
    document.getElementById('test');
});
```

### Node.js

```bash
# Install jsdom
npm install jsdom

# Run benchmarks
node -e "
const { JSDOM } = require('jsdom');
const dom = new JSDOM('<!DOCTYPE html>');
global.document = dom.window.document;
global.performance = require('perf_hooks').performance;
eval(require('fs').readFileSync('js/benchmark.js', 'utf8'));
runAllBenchmarks();
"
```

## Performance Tips

### For Accurate Benchmarks

1. **Use ReleaseFast** for Zig benchmarks
2. **Close other applications** to reduce system noise
3. **Run multiple times** to account for variance
4. **Use private/incognito** mode for browser tests
5. **Disable extensions** that might interfere

### Common Issues

**Zig benchmarks slower than expected?**
- Make sure you're using `-Doptimize=ReleaseFast`
- Check CPU isn't throttled (laptops on battery)

**JavaScript benchmarks inconsistent?**
- JIT warmup - first runs may be slower
- GC pauses - run with `--expose-gc` flag
- Other tabs/extensions interfering

## Adding New Benchmarks

### Zig

1. Add benchmark function to `zig/benchmark.zig`
2. Add to `runAllBenchmarks()`
3. Run and verify results
4. Update documentation

### JavaScript

1. Mirror the Zig benchmark in `js/benchmark.js`
2. Use same test data and iteration counts
3. Add to `runAllBenchmarks()`
4. Update `js/README.md`

## See Also

- [Phase 2 Results](../PHASE2_FINAL_RESULTS.md) - Detailed performance analysis
- [Optimization Strategy](../OPTIMIZATION_STRATEGY.md) - Performance approach
- [Browser Analysis](../BROWSER_SELECTOR_DEEP_ANALYSIS.md) - How browsers optimize
