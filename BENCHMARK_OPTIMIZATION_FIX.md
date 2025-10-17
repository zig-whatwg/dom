# Benchmark JIT Optimization Fix

## Problem

Firefox was reporting **0ns** (instant) results for several benchmarks:
- `Pure query: getElementById (100 elem)`: 0ns
- `Pure query: getElementById (1000 elem)`: 0ns  
- `Pure query: getElementById (10000 elem)`: 0ns
- `Pure query: getElementsByTagName (1000 elem)`: 0ns
- `Pure query: getElementsByClassName (10000 elem)`: 0ns

## Root Cause

JavaScript JIT compilers (especially Firefox's SpiderMonkey) were performing **dead code elimination** (DCE):

```javascript
// Original code
function benchGetElementById(context) {
    const result = document.getElementById('target');
    // ❌ result is never used - entire call can be optimized away!
}
```

The JIT compiler saw that:
1. We call `getElementById()`
2. We store the result in `result`
3. We never use `result`
4. Therefore, the entire operation can be eliminated

This caused:
- **0ns timings** - Operations completed "instantly" because they weren't actually running
- **Unfair comparison** - Couldn't compare Zig vs browsers accurately
- **Misleading results** - Made browsers look infinitely fast

## Solution

Added **anti-optimization techniques** to force evaluation:

### 1. Global Accumulator Pattern

```javascript
// Global variable that can't be optimized away
let globalAccumulator = 0;

function benchGetElementById(context) {
    const result = document.getElementById('target');
    // ✅ Use the result - forces evaluation
    if (result) globalAccumulator += 1;
}
```

### 2. Force Live Collection Evaluation

```javascript
function benchGetElementsByTagName(context) {
    const result = context.container.getElementsByTagName('button');
    // ✅ Access length property to force evaluation
    if (result && result.length > 0) globalAccumulator += 1;
}
```

### 3. Increase Iterations for Ultra-Fast Operations

```javascript
// Before: 100,000 iterations (too fast for Firefox)
results.push(benchmarkWithSetup(
    'Pure query: getElementById (100 elem)', 
    100000,  // ❌ Completes in < 1ms on Firefox
    setupSmallDom, 
    benchGetElementById
));

// After: 1,000,000 iterations (measurable even on Firefox)
results.push(benchmarkWithSetup(
    'Pure query: getElementById (100 elem)', 
    1000000,  // ✅ Takes several ms, measurable
    setupSmallDom, 
    benchGetElementById
));
```

### 4. Use Accumulator (Can't Be Optimized Away)

```javascript
function runAllBenchmarks() {
    // ... run all benchmarks ...
    
    // ✅ Use the accumulator so it can't be eliminated
    if (globalAccumulator < 0) {
        console.log('This should never print:', globalAccumulator);
    }
    
    return results;
}
```

## Results: Before vs After

### Firefox getElementById (10000 elem)

**Before:**
```
nsPerOp: 0
totalMs: 0
opsPerSec: 0
```

**After:**
```
nsPerOp: 4
totalMs: 4.0
opsPerSec: 250000000
```

### All Browsers getElementById (10000 elem)

**Before:**
- Chromium: 35ns
- Firefox: **0ns** ❌
- WebKit: 20ns

**After:**
- Chromium: 37ns ✅
- Firefox: 4ns ✅  
- WebKit: 17ns ✅

## Why This Works

1. **Side effects can't be eliminated**: Modifying a global variable is a side effect that JIT can't prove is unused

2. **Conditional branches**: The `if (result)` check creates a branch that depends on the query result

3. **More iterations**: Spreading computation over more iterations ensures measurable time

4. **Observable behavior**: Using `globalAccumulator` at the end makes it "observable", preventing elimination

## Comparison with Zig

Zig uses a similar pattern but with explicit syntax:

```zig
fn benchGetElementById(doc: *Document) !void {
    const result = doc.getElementById("target");
    _ = result;  // ✅ Explicitly tell compiler: evaluate but don't use
}
```

JavaScript doesn't have `_ = result`, so we use the accumulator pattern instead.

## Verification

Run benchmarks and check for zero results:

```bash
# Run benchmarks
zig build benchmark-all -Doptimize=ReleaseFast

# Check for zeros
cat benchmark_results/browser_benchmarks_latest.json | \
  jq '.[] | .results[] | select(.nsPerOp == 0) | {browser: .name, nsPerOp}'
```

Should return nothing if all benchmarks are working correctly.

## Technical Notes

### Why Firefox Was Most Affected

Firefox's SpiderMonkey JIT has particularly aggressive optimizations:
- **IonMonkey**: Aggressive optimizing compiler
- **Warp**: New baseline compiler with better optimization
- **Escape analysis**: Detects unused allocations
- **Dead code elimination**: Removes provably unused code

Chrome and WebKit also optimize, but Firefox was hitting 0ns most often.

### Live Collections

`getElementsByTagName()` and `getElementsByClassName()` return **live collections** that aren't materialized until accessed. We force materialization by accessing `.length`:

```javascript
const result = container.getElementsByTagName('button');
// ✅ This forces the collection to be evaluated
if (result && result.length > 0) globalAccumulator += 1;
```

## Commits

1. `950f4e4` - fix: prevent JIT from eliminating benchmark operations
2. `a2732c3` - docs: document anti-optimization techniques in benchmarks

## References

- [V8 Optimization Killers](https://github.com/petkaantonov/bluebird/wiki/Optimization-killers)
- [SpiderMonkey JIT](https://spidermonkey.dev/)
- [MDN: Performance.now() precision](https://developer.mozilla.org/en-US/docs/Web/API/Performance/now)
- [Benchmark.js anti-optimization](https://github.com/bestiejs/benchmark.js/blob/main/benchmark.js#L1324)

---

**Result**: Fair, accurate benchmarks across all browsers! 🎉
