# Benchmark Suite

This directory contains a comprehensive benchmark suite for measuring the performance of CSS selector parsing, element matching, and querySelector operations.

## Running Benchmarks

### Build and Run

```bash
# Run benchmarks with ReleaseFast optimization
zig build bench -Doptimize=ReleaseFast

# Results will be saved to:
# - benchmark_results/YYYY-MM-DD_HH-MM-SS.json (timestamped)
# - benchmark_results/latest.json (always latest)
```

### Benchmark Categories

1. **Tokenizer Benchmarks** - CSS selector tokenization performance
   - Simple ID (`#main`)
   - Simple class (`.button`)
   - Simple tag (`div`)
   - Complex selectors
   - Very complex selectors

2. **Parser Benchmarks** - CSS selector parsing performance
   - Simple selectors
   - Complex selectors with combinators
   - Very complex selectors with pseudo-classes

3. **Matcher Benchmarks** - Element matching performance
   - ID matching
   - Class matching
   - Complex selector matching

4. **querySelector Benchmarks** - Query performance with various DOM sizes
   - Small DOM (100 elements)
   - Medium DOM (1,000 elements)
   - Large DOM (10,000 elements)
   - Class selectors
   - Tag selectors
   - Complex selectors

5. **querySelectorAll Benchmarks** - Bulk query performance
   - All divs
   - All classes
   - Complex selectors returning multiple results

6. **SPA Benchmarks** - Real-world SPA usage patterns
   - Repeated queries with same selector
   - Framework patterns (React/Vue/Angular style)

## Visualizing Results

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Visualization Options

#### 1. View Latest Results

```bash
python visualize_benchmarks.py
```

This will display a bar chart of all benchmarks from the latest run, color-coded by performance:
- Green: < 1µs (excellent)
- Orange: 1-10µs (good)
- Red: 10-100µs (acceptable)
- Purple: > 100µs (needs optimization)

#### 2. Compare Two Runs (Before/After Optimization)

```bash
python visualize_benchmarks.py --compare \
    benchmark_results/2025-10-17_10-00-00.json \
    benchmark_results/2025-10-17_11-00-00.json
```

This shows:
- Side-by-side comparison of performance
- Improvement percentages
- Top 5 improvements
- Any regressions

#### 3. View Historical Trends

```bash
python visualize_benchmarks.py --history
```

This plots performance over time for key benchmarks, useful for tracking:
- Performance improvements from optimizations
- Performance regressions
- Long-term trends

#### 4. Save Charts

```bash
# Save single run chart
python visualize_benchmarks.py --output benchmark_chart.png

# Save comparison chart
python visualize_benchmarks.py --compare file1.json file2.json --output comparison.png

# Save history chart
python visualize_benchmarks.py --history --output history.png
```

## JSON Output Format

Each benchmark run produces a JSON file with this structure:

```json
{
  "timestamp": 1697558400,
  "git_commit": "a1b2c3d4...",
  "zig_version": "0.12.0",
  "optimize_mode": "ReleaseFast",
  "results": [
    {
      "name": "querySelector: Small DOM (100 elems, #target)",
      "operations": 1000,
      "total_ns": 500000,
      "ns_per_op": 500,
      "ops_per_sec": 2000000
    },
    ...
  ]
}
```

This format allows:
- Tracking performance over time
- Comparing before/after optimization
- Correlating with git commits
- Graphing trends

## Baseline Results

Run benchmarks BEFORE implementing optimizations:

```bash
zig build bench -Doptimize=ReleaseFast
cp benchmark_results/latest.json benchmark_results/baseline.json
```

After implementing optimizations, compare:

```bash
zig build bench -Doptimize=ReleaseFast
python visualize_benchmarks.py --compare \
    benchmark_results/baseline.json \
    benchmark_results/latest.json
```

## Continuous Integration

Add benchmarks to CI to catch performance regressions:

```yaml
# .github/workflows/benchmark.yml
name: Benchmark
on: [pull_request]

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: goto-bus-stop/setup-zig@v2
      - name: Run benchmarks
        run: zig build bench -Doptimize=ReleaseFast
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: benchmark-results
          path: benchmark_results/latest.json
```

## Performance Targets

After implementing Phase 1 optimizations, we expect:

| Benchmark | Baseline | Target | Improvement |
|-----------|----------|--------|-------------|
| querySelector("#id") | 500µs | 1µs | 500x |
| querySelector(".class") | 500µs | 50µs | 10x |
| querySelector("tag") | 500µs | 30µs | 15x |
| SPA repeated queries | 50ms | 150µs | 333x |

## Tips

### Consistent Environment

For accurate comparisons:
1. Close other applications
2. Disable CPU frequency scaling
3. Run multiple times and average
4. Use same optimization mode
5. Run on same hardware

### What to Benchmark

Before optimization:
- Run baseline benchmarks
- Identify bottlenecks
- Set performance targets

After optimization:
- Compare against baseline
- Verify no regressions
- Document improvements

### Interpreting Results

- **ns/op** - Nanoseconds per operation (lower is better)
- **ops/sec** - Operations per second (higher is better)
- **Green bars** - Excellent performance (< 1µs)
- **Red bars** - Needs optimization (> 10µs)

## Example Workflow

```bash
# 1. Run baseline benchmarks
git checkout main
zig build bench -Doptimize=ReleaseFast
cp benchmark_results/latest.json benchmark_results/baseline.json

# 2. Implement optimizations
git checkout feature/fast-paths
# ... make changes ...

# 3. Run benchmarks again
zig build bench -Doptimize=ReleaseFast

# 4. Compare results
python visualize_benchmarks.py --compare \
    benchmark_results/baseline.json \
    benchmark_results/latest.json \
    --output comparison.png

# 5. View improvement summary
# Check console output for detailed statistics
```

## Troubleshooting

### Benchmarks are slow

- Make sure you're using `-Doptimize=ReleaseFast`
- Close other applications
- Check CPU frequency scaling

### Results vary widely

- Run multiple times and average
- Check for background processes
- Ensure consistent environment

### Visualization fails

- Install matplotlib: `pip install matplotlib`
- Check Python version (>= 3.9)
- Verify benchmark results exist

## Questions?

See the main analysis documents:
- `BROWSER_SELECTOR_DEEP_ANALYSIS.md` - Technical details
- `OPTIMIZATION_STRATEGY.md` - Implementation plan
- `EXECUTIVE_SUMMARY.md` - Quick overview
