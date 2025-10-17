# Benchmark Parity Skill

## When to use this skill

Load this skill whenever:
- Adding new benchmarks to the Zig benchmark suite
- Modifying existing benchmark implementations
- Adding new DOM features that should be benchmarked
- Updating performance-critical code paths

## What this skill provides

Ensures that JavaScript and Zig benchmarks remain in sync, providing accurate cross-platform performance comparisons.

---

## Critical Rule: Maintain Benchmark Parity

**Whenever Zig benchmarks change, JavaScript benchmarks MUST be updated to match.**

This ensures:
- Fair comparisons between implementations
- Consistent test coverage across platforms
- Accurate performance regression detection
- Meaningful benchmark reports

---

## Benchmark File Locations

### Zig Benchmarks
- **Main suite**: `benchmarks/zig/benchmark.zig`
- **Runner**: `benchmarks/zig/benchmark_runner.zig`
- **Results**: `benchmark_results/phase4_release_fast.txt`

### JavaScript Benchmarks
- **Main suite**: `benchmarks/js/benchmark.js`
- **Playwright runner**: `benchmarks/js/playwright-runner.js`
- **Results**: `benchmark_results/browser_benchmarks_latest.json`

### Visualization
- **Generator**: `benchmarks/visualize.js`
- **Report**: `benchmark_results/benchmark_report.html`

---

## Benchmark Structure Pattern

Both Zig and JavaScript benchmarks follow the same structure:

### 1. Setup Functions

Create DOM structure once, measure queries multiple times:

**Zig Pattern:**
```zig
fn setupSmallDom(allocator: Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();
    
    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);
    
    // Build DOM structure
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const div = try doc.createElement("div");
        if (i == 50) try div.setAttribute("id", "target");
        _ = try root.node.appendChild(&div.node);
    }
    
    return doc;
}
```

**JavaScript Pattern:**
```javascript
function setupSmallDom() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    
    // Build DOM structure
    for (let i = 0; i < 100; i++) {
        const div = document.createElement('div');
        if (i === 50) div.id = 'target';
        container.appendChild(div);
    }
    
    return {
        container,
        cleanup: () => document.body.removeChild(container)
    };
}
```

### 2. Query Functions

Measure specific operations:

**Zig Pattern:**
```zig
fn benchQuerySelectorId(doc: *Document) !void {
    const result = try doc.querySelector("#target");
    _ = result;
}
```

**JavaScript Pattern:**
```javascript
function benchQuerySelectorId(context) {
    const result = context.container.querySelector('#target');
}
```

### 3. Benchmark Registration

Register benchmarks with consistent names:

**Zig Pattern:**
```zig
try results.append(allocator, try benchmarkWithSetup(
    allocator, 
    "Pure query: querySelector #id (100 elem)", 
    100000, 
    setupSmallDom, 
    benchQuerySelectorId
));
```

**JavaScript Pattern:**
```javascript
results.push(benchmarkWithSetup(
    'Pure query: querySelector #id (100 elem)', 
    100000, 
    setupSmallDom, 
    benchQuerySelectorId
));
```

---

## Adding a New Benchmark

### Step 1: Add to Zig Benchmarks

1. **Create setup function** (if needed):
```zig
fn setupNewFeature(allocator: Allocator) !*Document {
    const doc = try Document.init(allocator);
    // ... build DOM
    return doc;
}
```

2. **Create query function**:
```zig
fn benchNewFeature(doc: *Document) !void {
    const result = try doc.someNewMethod();
    _ = result;
}
```

3. **Register benchmark**:
```zig
try results.append(allocator, try benchmarkWithSetup(
    allocator, 
    "Pure query: newFeature (100 elem)", 
    100000, 
    setupNewFeature, 
    benchNewFeature
));
```

### Step 2: Add to JavaScript Benchmarks

1. **Create setup function**:
```javascript
function setupNewFeature() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    // ... build DOM (match Zig structure exactly)
    return {
        container,
        cleanup: () => document.body.removeChild(container)
    };
}
```

2. **Create query function**:
```javascript
function benchNewFeature(context) {
    const result = context.container.someNewMethod();
}
```

3. **Register benchmark**:
```javascript
results.push(benchmarkWithSetup(
    'Pure query: newFeature (100 elem)', 
    100000, 
    setupNewFeature, 
    benchNewFeature
));
```

### Step 3: Verify Parity

Run both benchmarks and verify they appear in the report:

```bash
zig build benchmark-all
```

Check:
- ✅ Same benchmark names appear in both Zig and browser results
- ✅ DOM structures are identical (same element counts, same attributes)
- ✅ Operations measure the same functionality
- ✅ Results appear in visualization report

---

## Benchmark Naming Convention

Use consistent, descriptive names:

```
[Category]: [Operation] ([Size])

Examples:
- "Pure query: getElementById (100 elem)"
- "Pure query: querySelector #id (1000 elem)"
- "Pure query: getElementsByTagName (10000 elem)"
- "Pure query: querySelector .class (100 elem)"
```

**Categories:**
- `Pure query:` - DOM pre-built, measuring query only
- `querySelector:` - DOM build + query (legacy tests)
- `SPA:` - Simulates single-page app patterns

**Sizes:**
- Small: 100 elements
- Medium: 1000 elements
- Large: 10000 elements

---

## DOM Structure Patterns

### ID Query Benchmarks

**Structure:**
- N div elements
- One element at position N/2 has `id="target"`

**Example:**
```zig
// Zig
while (i < 100) : (i += 1) {
    const div = try doc.createElement("div");
    if (i == 50) try div.setAttribute("id", "target");
    _ = try root.node.appendChild(&div.node);
}
```

```javascript
// JavaScript
for (let i = 0; i < 100; i++) {
    const div = document.createElement('div');
    if (i === 50) div.id = 'target';
    container.appendChild(div);
}
```

### Tag Query Benchmarks

**Structure:**
- N/2 div elements
- N/2 button elements

**Example:**
```zig
// Zig
i = 0;
while (i < 50) : (i += 1) {
    const div = try doc.createElement("div");
    _ = try root.node.appendChild(&div.node);
}
i = 0;
while (i < 50) : (i += 1) {
    const button = try doc.createElement("button");
    _ = try root.node.appendChild(&button.node);
}
```

```javascript
// JavaScript
for (let i = 0; i < 50; i++) {
    const div = document.createElement('div');
    container.appendChild(div);
}
for (let i = 0; i < 50; i++) {
    const button = document.createElement('button');
    container.appendChild(button);
}
```

### Class Query Benchmarks

**Structure:**
- N/2 button elements with `class="btn primary"`
- N/2 div elements with `class="container"`

**Example:**
```zig
// Zig
i = 0;
while (i < 50) : (i += 1) {
    const button = try doc.createElement("button");
    try button.setAttribute("class", "btn primary");
    _ = try root.node.appendChild(&button.node);
}
i = 0;
while (i < 50) : (i += 1) {
    const div = try doc.createElement("div");
    try div.setAttribute("class", "container");
    _ = try root.node.appendChild(&div.node);
}
```

```javascript
// JavaScript
for (let i = 0; i < 50; i++) {
    const button = document.createElement('button');
    button.className = 'btn primary';
    container.appendChild(button);
}
for (let i = 0; i < 50; i++) {
    const div = document.createElement('div');
    div.className = 'container';
    container.appendChild(div);
}
```

---

## Running Benchmarks

### Zig Only
```bash
zig build bench -Doptimize=ReleaseFast
```

### Browsers Only
```bash
cd benchmarks/js
npm install  # First time only
npx playwright install  # First time only
node playwright-runner.js
```

### All + Visualization
```bash
zig build benchmark-all
```

This runs:
1. Zig benchmarks (ReleaseFast)
2. Browser benchmarks (Chromium, Firefox, WebKit)
3. Generates HTML visualization report

**Output:**
- `benchmark_results/phase4_release_fast.txt` - Zig results
- `benchmark_results/browser_benchmarks_latest.json` - Browser results
- `benchmark_results/benchmark_report.html` - Interactive report

---

## Verification Checklist

When adding/modifying benchmarks, verify:

- [ ] Zig benchmark added/updated in `benchmarks/zig/benchmark.zig`
- [ ] JavaScript benchmark added/updated in `benchmarks/js/benchmark.js`
- [ ] Benchmark names match exactly (case-sensitive)
- [ ] DOM structures are identical (element counts, types, attributes)
- [ ] Both measure the same operation
- [ ] Both use same iteration counts
- [ ] Run `zig build benchmark-all` successfully
- [ ] New benchmarks appear in HTML report
- [ ] Results make sense (no unexpected 0s or infinities)

---

## Troubleshooting

### Benchmark doesn't appear in report

**Cause:** Name mismatch between Zig and JavaScript

**Fix:** Ensure names are **exactly** the same:
```zig
"Pure query: getElementById (100 elem)"  // Zig
```
```javascript
'Pure query: getElementById (100 elem)'  // JavaScript - must match exactly
```

### Results are wildly different

**Cause:** DOM structures don't match

**Fix:** Verify element counts and structure match:
- Same number of elements
- Same element types
- Same attributes and values
- Same parent/child relationships

### Playwright fails to run

**Cause:** Browsers not installed

**Fix:**
```bash
cd benchmarks/js
npx playwright install
```

### Chart doesn't display correctly

**Cause:** Missing or invalid data

**Fix:**
- Verify JSON results are valid
- Check browser console for errors
- Ensure at least one implementation has results

---

## Integration with Other Skills

This skill coordinates with:
- **performance_optimization** - Benchmarks verify optimizations
- **testing_requirements** - Benchmarks complement tests
- **documentation_standards** - Document benchmark results

---

## Examples

### Example: Adding Attribute Selector Benchmark

**1. Zig Benchmark (`benchmarks/zig/benchmark.zig`):**

```zig
fn setupAttrSmall(allocator: Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();
    
    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);
    
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const link = try doc.createElement("a");
        if (i % 10 == 0) {
            try link.setAttribute("href", "https://example.com");
        }
        _ = try root.node.appendChild(&link.node);
    }
    
    return doc;
}

fn benchQuerySelectorAttr(doc: *Document) !void {
    const result = try doc.querySelector("[href^='https']");
    _ = result;
}
```

Register:
```zig
try results.append(allocator, try benchmarkWithSetup(
    allocator,
    "Pure query: querySelector [attr^=] (100 elem)",
    100000,
    setupAttrSmall,
    benchQuerySelectorAttr
));
```

**2. JavaScript Benchmark (`benchmarks/js/benchmark.js`):**

```javascript
function setupAttrSmall() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    
    for (let i = 0; i < 100; i++) {
        const link = document.createElement('a');
        if (i % 10 === 0) {
            link.href = 'https://example.com';
        }
        container.appendChild(link);
    }
    
    return {
        container,
        cleanup: () => document.body.removeChild(container)
    };
}

function benchQuerySelectorAttr(context) {
    const result = context.container.querySelector("[href^='https']");
}
```

Register:
```javascript
results.push(benchmarkWithSetup(
    'Pure query: querySelector [attr^=] (100 elem)',
    100000,
    setupAttrSmall,
    benchQuerySelectorAttr
));
```

**3. Verify:**
```bash
zig build benchmark-all
# Check HTML report - should show new benchmark across all implementations
```

---

## Key Takeaways

1. **Always update both** Zig and JavaScript benchmarks together
2. **Match names exactly** - visualization depends on it
3. **Match DOM structures exactly** - ensures fair comparison
4. **Test the pipeline** - run `zig build benchmark-all` to verify
5. **Document changes** - note what you're measuring and why

---

**Remember:** Benchmark parity is not optional. It's essential for meaningful performance comparisons and regression detection.
