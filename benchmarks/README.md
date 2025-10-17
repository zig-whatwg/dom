# DOM Benchmarks

Cross-platform performance benchmarking suite comparing Zig DOM implementation with browser implementations.

## Quick Start

### First Time Setup

Install Playwright and browsers (one-time, ~500MB download):

```bash
# Easy way
./benchmarks/setup.sh

# Or manually
cd benchmarks/js
npm install
npx playwright install
cd ../..
```

### Run Benchmarks

Run all benchmarks with a single command:

```bash
zig build benchmark-all -Doptimize=ReleaseFast
```

**⚠️ IMPORTANT:** Always use `-Doptimize=ReleaseFast` for accurate performance measurements!

This will:
1. ✅ Run Zig benchmarks (ReleaseFast mode)
2. ✅ Run browser benchmarks (Chromium, Firefox, WebKit)
3. ✅ Generate interactive HTML visualization

**Time:** ~2-3 minutes per run.

---

## Output Files

After running, you'll find:

```
benchmark_results/
├── phase4_release_fast.txt           # Zig benchmark results (text)
├── browser_benchmarks_latest.json     # Browser results (JSON)
└── benchmark_report.html              # 🎨 Interactive visualization (OPEN THIS!)
```

**Open the HTML report:**
```bash
open benchmark_results/benchmark_report.html
```

---

## Individual Components

### 1. Zig Benchmarks Only

```bash
zig build bench -Doptimize=ReleaseFast
```

Runs 24 benchmarks:
- ID queries (`getElementById`, `querySelector("#id")`)
- Tag queries (`getElementsByTagName`, `querySelector("tag")`)
- Class queries (`getElementsByClassName`, `querySelector(".class")`)
- Other query patterns

**Output:** `benchmark_results/phase4_release_fast.txt`

### 2. Browser Benchmarks Only

**First time setup:**
```bash
cd benchmarks/js
npm install
npx playwright install
```

**Run benchmarks:**
```bash
cd benchmarks/js
node playwright-runner.js
```

Runs same 24 benchmarks in:
- Chromium (headless)
- Firefox (headless)
- WebKit (headless)

**Output:** `benchmark_results/browser_benchmarks_latest.json`

### 3. Visualization Only

```bash
cd benchmarks
node visualize.js
```

Generates HTML report from existing results.

**Output:** `benchmark_results/benchmark_report.html`

---

## Benchmark Categories

The suite measures performance across four categories:

### ID Queries (O(1) in Zig via hash map)
- `getElementById()`
- `querySelector("#id")`
- Sizes: 100, 1000, 10000 elements

### Tag Queries (O(1) first match in Zig via tag map)
- `getElementsByTagName()`
- `querySelector("tag")`
- Sizes: 100, 1000, 10000 elements

### Class Queries (O(1) first match in Zig via class map)
- `getElementsByClassName()`
- `querySelector(".class")`
- Sizes: 100, 1000, 10000 elements

### Complex Queries
- SPA patterns (repeated queries)
- Mixed selectors
- Cache behavior

---

## Visualization Features

The HTML report includes:

**📊 Interactive Charts**
- Logarithmic bar charts (handles ns to ms range)
- Grouped by category
- Color-coded by implementation
- Powered by Chart.js

**📈 Performance Tables**
- Raw numbers for each implementation
- Winner highlighted
- Speedup factors (e.g., "2.5x slower")

**🎨 Beautiful Design**
- Gradient purple background
- Clean white cards
- Responsive layout
- Implementation badges

---

## Adding New Benchmarks

**⚠️ IMPORTANT:** Zig and JavaScript benchmarks must stay synchronized!

See `skills/benchmark_parity/SKILL.md` for complete guide.

### Quick Steps:

1. **Add to Zig** (`zig/benchmark.zig`):
```zig
fn setupNewTest(allocator: Allocator) !*Document {
    // Setup DOM
}

fn benchNewTest(doc: *Document) !void {
    // Run query
}

// Register:
try results.append(allocator, try benchmarkWithSetup(
    allocator,
    "Pure query: newTest (100 elem)",  // Must match JS name exactly
    100000,
    setupNewTest,
    benchNewTest
));
```

2. **Add to JavaScript** (`js/benchmark.js`):
```javascript
function setupNewTest() {
    // Setup DOM (must match Zig structure)
    return { container, cleanup };
}

function benchNewTest(context) {
    // Run query (must match Zig operation)
}

// Register:
results.push(benchmarkWithSetup(
    'Pure query: newTest (100 elem)',  // Must match Zig name exactly
    100000,
    setupNewTest,
    benchNewTest
));
```

3. **Verify:**
```bash
zig build benchmark-all
# Check HTML report - new benchmark should appear across all implementations
```

---

## File Structure

```
benchmarks/
├── zig/
│   ├── benchmark.zig          # Zig benchmark suite
│   └── benchmark_runner.zig   # Runner that prints results
├── js/
│   ├── benchmark.js           # JavaScript benchmark suite
│   ├── playwright-runner.js   # Automated browser testing
│   ├── package.json           # Playwright dependency
│   └── node_modules/          # (created by npm install)
├── run-all.sh                 # Pipeline orchestration
├── visualize.js               # HTML report generator
└── README.md                  # This file
```

---

## Requirements

**System:**
- Zig 0.15.1+
- Node.js 18+
- Bash (for run-all.sh)
- Internet (first run, to download browsers)

**Disk Space:**
- ~500MB for Playwright browsers (first time only)

**Time:**
- First run: ~5 minutes (downloads + benchmarks)
- Subsequent runs: ~2-3 minutes (benchmarks only)

---

## Troubleshooting

### "command not found: node"

Install Node.js:
```bash
# macOS
brew install node

# Ubuntu/Debian
sudo apt install nodejs npm
```

### "Playwright browsers not installed"

```bash
cd benchmarks/js
npx playwright install
```

### "Benchmark names don't match"

Ensure Zig and JavaScript benchmark names are **exactly** the same (case-sensitive).

### "Results file not found"

Run Zig benchmarks first:
```bash
zig build bench -Doptimize=ReleaseFast
```

### "No chart displayed"

Check browser console for errors. Ensure:
- JSON files are valid
- At least one implementation has results

---

## CI/CD Integration

For automated testing:

```yaml
# .github/workflows/benchmarks.yml
- name: Run benchmarks
  run: |
    zig build benchmark-all
    
- name: Upload results
  uses: actions/upload-artifact@v3
  with:
    name: benchmark-report
    path: benchmark_results/benchmark_report.html
```

---

## Performance Notes

**Zig Implementation Optimizations:**
- **Phase 2:** O(1) getElementById via hash map
- **Phase 3:** O(1) querySelector("tag") via tag map
- **Phase 4:** O(1) querySelector(".class") via class map

**Browser Implementations:**
- Highly optimized native code
- JIT compiled JavaScript
- Decades of optimization work

**Expected Results:**
- Zig competitive with browsers for simple queries
- Browsers may be faster for complex selectors (more optimizations)
- Results vary by browser engine

---

## Contributing

When adding benchmarks:

1. ✅ Add to both Zig and JavaScript
2. ✅ Match DOM structures exactly
3. ✅ Use same benchmark names
4. ✅ Document what you're measuring
5. ✅ Run `zig build benchmark-all` to verify

See `skills/benchmark_parity/SKILL.md` for complete guidelines.

---

## License

Same as parent project.

---

**Happy benchmarking!** 🚀
