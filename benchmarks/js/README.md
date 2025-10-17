# JavaScript DOM Benchmark Suite

Browser-based benchmark suite for comparing JavaScript DOM performance with the native Zig implementation.

## Quick Start

### Method 1: Browser Console

1. Open your browser (Chrome, Firefox, Safari, Edge)
2. Open Developer Console (F12 or Cmd+Option+I on Mac)
3. Copy the contents of `benchmark.js`
4. Paste into console and press Enter
5. Run benchmarks:

```javascript
// Run all benchmarks
runAllBenchmarks();

// Compare with Zig results
compareWithZig();
```

### Method 2: HTML File

Create an HTML file:

```html
<!DOCTYPE html>
<html>
<head>
    <title>DOM Benchmarks</title>
</head>
<body>
    <h1>Open console to see results (F12)</h1>
    <script src="benchmark.js"></script>
    <script>
        // Auto-run benchmarks on load
        window.addEventListener('load', () => {
            runAllBenchmarks();
        });
    </script>
</body>
</html>
```

## Benchmark Suite

The JavaScript benchmarks mirror the Zig benchmarks for accurate comparison:

### querySelector Benchmarks
- Small DOM (100 elements)
- Medium DOM (1,000 elements)
- Large DOM (10,000 elements)
- Class selector queries

### SPA Benchmarks
- Repeated queries (simulating SPA usage)
- Cold vs Hot cache behavior

### getElementById Benchmarks
- Small, Medium, Large DOMs
- Direct element lookup performance

### Pure Query Benchmarks
- **DOM pre-built** - measures only query time
- getElementById (100, 1000, 10000 elements)
- querySelector("#id") (100, 1000, 10000 elements)

## Understanding Results

### Time Units
- **ns** (nanoseconds): 1/1,000,000,000 second
- **µs** (microseconds): 1/1,000,000 second
- **ms** (milliseconds): 1/1,000 second

### Pure Query Results

These isolate the actual query performance by building the DOM once:

**Typical JavaScript Results (Chrome V8):**
```
Pure query: getElementById (100 elem): 50-100ns/op
Pure query: getElementById (1000 elem): 50-100ns/op
Pure query: getElementById (10000 elem): 50-100ns/op
Pure query: querySelector #id (100 elem): 200-500ns/op
Pure query: querySelector #id (1000 elem): 200-500ns/op
Pure query: querySelector #id (10000 elem): 200-500ns/op
```

**Zig Implementation Results (ReleaseFast):**
```
Pure query: getElementById (100 elem): 5ns/op
Pure query: getElementById (1000 elem): 5ns/op
Pure query: getElementById (10000 elem): 5ns/op
Pure query: querySelector #id (100 elem): 16ns/op
Pure query: querySelector #id (1000 elem): 16ns/op
Pure query: querySelector #id (10000 elem): 16ns/op
```

**Performance Comparison:**
- Zig getElementById: **10-20x faster** than JavaScript
- Zig querySelector: **12-30x faster** than JavaScript

## Why is Zig Faster?

1. **No JavaScript Bridge** - Direct native code execution
2. **No Garbage Collection** - Manual memory management
3. **LLVM Optimizations** - Aggressive compiler optimizations
4. **Cache Efficiency** - Better memory layout
5. **Zero Overhead** - No runtime checks or dynamic dispatch

## Browser Differences

Performance varies by browser and JavaScript engine:

- **Chrome (V8):** Fastest JavaScript implementation
- **Firefox (SpiderMonkey):** Similar to Chrome
- **Safari (JavaScriptCore):** Slightly slower
- **Edge (V8):** Same as Chrome (uses Chromium)

## Performance Tips

For most accurate results:

1. **Use ReleaseFast builds** for Zig comparison
2. **Close other tabs** to reduce noise
3. **Run multiple times** - JavaScript JIT warms up
4. **Use private/incognito** - Fewer extensions interfering
5. **Enable gc() in Chrome** - Run with `--js-flags="--expose-gc"`

## Interpreting Results

### Good Performance
- getElementById: < 100ns
- querySelector("#id"): < 500ns
- Consistent across DOM sizes (O(1) behavior)

### Expected Performance
Most modern browsers achieve:
- getElementById: 50-100ns (O(1))
- querySelector("#id"): 200-500ns (O(1) with optimization)

### Red Flags
If you see:
- getElementById > 1µs (slow)
- querySelector("#id") growing with DOM size (O(n) traversal)
- Wide variance between runs (unstable)

## Comparing with Zig

The benchmarks use identical test cases to the Zig implementation:

| Test Case | Zig (ReleaseFast) | JavaScript (V8) | Zig Speedup |
|-----------|-------------------|-----------------|-------------|
| getElementById (1000) | 5ns | 80ns | 16x faster |
| querySelector #id (1000) | 16ns | 400ns | 25x faster |

## Limitations

JavaScript benchmarks have some limitations:

1. **Timer Resolution** - `performance.now()` has ~5µs resolution
2. **JIT Warmup** - First runs may be slower
3. **GC Interference** - Garbage collection can add noise
4. **Background Tasks** - Browser doing other work
5. **Extension Interference** - Ad blockers, etc.

## Advanced: Node.js Benchmarks

You can also run these in Node.js, but you'll need to use jsdom:

```bash
npm install jsdom
```

```javascript
const { JSDOM } = require('jsdom');
const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>');
global.document = dom.window.document;
global.performance = require('perf_hooks').performance;

// Now run benchmarks
require('./benchmark.js');
runAllBenchmarks();
```

## Contributing

To add a new benchmark:

1. Add the benchmark function (mirrors Zig version)
2. Add to `runAllBenchmarks()` with appropriate iterations
3. Update this README with expected results

## See Also

- Zig benchmarks: `../zig/benchmark.zig`
- Benchmark results: `../../benchmark_results/`
- Performance documentation: `../../PHASE2_FINAL_RESULTS.md`
