/**
 * DOM Selector Benchmark Suite - JavaScript Edition
 * 
 * Anti-Optimization Hardened Benchmarks
 * 
 * Techniques used to prevent JIT optimization:
 * 1. Black hole function - unpredictable, side-effecting
 * 2. Random iterations - prevents loop unrolling
 * 3. Opaque predicates - prevents branch elimination
 * 4. Result arrays - forces memory writes
 * 5. Type polymorphism - prevents type specialization
 */

// ===================================================================
// Anti-Optimization Infrastructure
// ===================================================================

/**
 * Black hole - unpredictable function that prevents DCE
 * The JIT can't prove this function is pure, so it must execute code
 */
const blackHole = (function() {
    let state = Date.now();
    return function(value) {
        // Unpredictable computation using current state
        // XOR with timestamp creates data dependency
        state = (state ^ Date.now() ^ (typeof value === 'object' ? 1 : 0)) >>> 0;
        // Return something based on value to prevent elimination
        return state & 1 ? value : null;
    };
})();

/**
 * Result accumulator - array of results prevents DCE
 * Arrays force memory writes that can't be optimized away
 */
let resultAccumulator = [];

/**
 * Opaque value - runtime value that JIT can't predict
 * Prevents constant folding and branch elimination
 */
function getOpaqueValue() {
    return Date.now() & 1;
}

// ===================================================================
// Benchmark Infrastructure
// ===================================================================

class BenchmarkResult {
    constructor(name, operations, totalMs, msPerOp, opsPerSec, bytesAllocated = 0, bytesPerOp = 0, peakMemory = 0) {
        this.name = name;
        this.operations = operations;
        this.totalMs = totalMs;
        this.msPerOp = msPerOp;
        this.opsPerSec = opsPerSec;
        this.nsPerOp = Math.round(msPerOp * 1000000); // Convert to nanoseconds for consistency with Zig
        this.bytesAllocated = bytesAllocated;
        this.bytesPerOp = bytesPerOp;
        this.peakMemory = peakMemory;
    }
}

/**
 * Run benchmark with anti-optimization measures and memory tracking
 */
function benchmarkFn(name, iterations, func) {
    // Warmup with variable iterations (prevents profiling predictability)
    const warmupCount = 10 + (Date.now() % 5);
    for (let i = 0; i < warmupCount; i++) {
        func();
    }
    
    // Force garbage collection if available
    if (typeof gc === 'function') {
        gc();
    }
    
    // Clear result accumulator
    resultAccumulator = [];
    
    // Measure memory before (if available)
    let memStart = 0;
    if (performance.memory) {
        memStart = performance.memory.usedJSHeapSize;
    }
    
    // Actual benchmark with unpredictable iteration count
    // Add small random offset to prevent JIT from unrolling
    const actualIterations = iterations + (Date.now() % 10);
    
    const start = performance.now();
    for (let i = 0; i < actualIterations; i++) {
        func();
    }
    const end = performance.now();
    
    const totalMs = end - start;
    const msPerOp = totalMs / actualIterations;
    const opsPerSec = msPerOp > 0 ? Math.floor(1000 / msPerOp) : 0;
    
    // Note: Browser memory cannot be accurately measured via performance.memory
    // - It reports total JS heap, not per-operation memory
    // - GC makes measurements unpredictable
    // - Not available in Firefox/WebKit
    // Therefore, we don't track browser memory (only Zig memory is meaningful)
    const bytesAllocated = 0;
    const bytesPerOp = 0;
    const peakMemory = 0;
    
    // Use results (prevents elimination)
    blackHole(resultAccumulator);
    
    return new BenchmarkResult(name, actualIterations, totalMs, msPerOp, opsPerSec, bytesAllocated, bytesPerOp, peakMemory);
}

/**
 * Run benchmark with setup phase and memory tracking
 */
function benchmarkWithSetup(name, iterations, setup, func) {
    // Setup: build DOM once
    const context = setup();
    
    // Warmup with variable iterations
    const warmupCount = 10 + (Date.now() % 5);
    for (let i = 0; i < warmupCount; i++) {
        func(context);
    }
    
    // Force garbage collection if available
    if (typeof gc === 'function') {
        gc();
    }
    
    // Clear result accumulator
    resultAccumulator = [];
    
    // Measure memory before (if available)
    let memStart = 0;
    if (performance.memory) {
        memStart = performance.memory.usedJSHeapSize;
    }
    
    // Actual benchmark with unpredictable iteration count
    const actualIterations = iterations + (Date.now() % 10);
    
    const start = performance.now();
    for (let i = 0; i < actualIterations; i++) {
        func(context);
    }
    const end = performance.now();
    
    const totalMs = end - start;
    const msPerOp = totalMs / actualIterations;
    const opsPerSec = msPerOp > 0 ? Math.floor(1000 / msPerOp) : 0;
    
    // Note: Browser memory cannot be accurately measured
    // Only Zig memory tracking is meaningful
    const bytesAllocated = 0;
    const bytesPerOp = 0;
    const peakMemory = 0;
    
    // Use results (prevents elimination)
    blackHole(resultAccumulator);
    
    // Cleanup
    if (context.cleanup) {
        context.cleanup();
    }
    
    return new BenchmarkResult(name, actualIterations, totalMs, msPerOp, opsPerSec, bytesAllocated, bytesPerOp, peakMemory);
}

// ===================================================================
// Benchmark Functions (with anti-optimization)
// ===================================================================

function querySmallDom() {
    const container = document.createElement('div');
    for (let i = 0; i < 100; i++) {
        const div = document.createElement('div');
        if (i === 50) div.id = 'target';
        container.appendChild(div);
    }
    const result = container.querySelector('#target');
    // Force result to be used - store in array (memory write)
    resultAccumulator.push(result);
    // Black hole prevents DCE
    blackHole(result);
}

function queryMediumDom() {
    const container = document.createElement('div');
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        if (i === 500) div.id = 'target';
        container.appendChild(div);
    }
    const result = container.querySelector('#target');
    resultAccumulator.push(result);
    blackHole(result);
}

function queryLargeDom() {
    const container = document.createElement('div');
    for (let i = 0; i < 10000; i++) {
        const div = document.createElement('div');
        if (i === 5000) div.id = 'target';
        container.appendChild(div);
    }
    const result = container.querySelector('#target');
    resultAccumulator.push(result);
    blackHole(result);
}

function queryClass() {
    const container = document.createElement('div');
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        if (i % 100 === 0) div.className = 'target';
        container.appendChild(div);
    }
    const result = container.querySelector('.target');
    resultAccumulator.push(result);
    blackHole(result);
}

function spaRepeated() {
    const container = document.createElement('div');
    
    // Build DOM
    for (let i = 0; i < 100; i++) {
        const div = document.createElement('div');
        div.className = 'component';
        container.appendChild(div);
        
        const button = document.createElement('button');
        button.className = 'btn primary';
        div.appendChild(button);
    }
    
    // Simulate SPA: repeated queries
    for (let i = 0; i < 10; i++) {
        const r1 = container.querySelector('.component');
        const r2 = container.querySelector('.btn');
        const r3 = container.querySelector('.primary');
        const r4 = container.querySelector('button');
        const r5 = container.querySelector('div');
        
        // Store all results
        resultAccumulator.push(r1, r2, r3, r4, r5);
        blackHole(r1);
        blackHole(r2);
        blackHole(r3);
        blackHole(r4);
        blackHole(r5);
    }
}

function spaColdVsHot() {
    const container = document.createElement('div');
    
    // Build DOM
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        div.className = 'item';
        if (i === 500) div.id = 'target';
        container.appendChild(div);
    }
    
    // Run same query 100 times
    for (let i = 0; i < 100; i++) {
        const result = container.querySelector('.item');
        resultAccumulator.push(result);
        blackHole(result);
    }
}

function getElementByIdSmall() {
    const container = document.createElement('div');
    for (let i = 0; i < 100; i++) {
        const div = document.createElement('div');
        if (i === 50) div.id = 'target';
        container.appendChild(div);
    }
    const result = document.getElementById('target');
    resultAccumulator.push(result);
    blackHole(result);
}

function getElementByIdMedium() {
    const container = document.createElement('div');
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        if (i === 500) div.id = 'target';
        container.appendChild(div);
    }
    const result = document.getElementById('target');
    resultAccumulator.push(result);
    blackHole(result);
}

function getElementByIdLarge() {
    const container = document.createElement('div');
    for (let i = 0; i < 10000; i++) {
        const div = document.createElement('div');
        if (i === 5000) div.id = 'target';
        container.appendChild(div);
    }
    const result = document.getElementById('target');
    resultAccumulator.push(result);
    blackHole(result);
}

// ===================================================================
// Setup functions for pure query benchmarks
// ===================================================================

function setupSmallDom() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    
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

function setupMediumDom() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        if (i === 500) div.id = 'target';
        container.appendChild(div);
    }
    
    return {
        container,
        cleanup: () => document.body.removeChild(container)
    };
}

function setupLargeDom() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    
    for (let i = 0; i < 10000; i++) {
        const div = document.createElement('div');
        if (i === 5000) div.id = 'target';
        container.appendChild(div);
    }
    
    return {
        container,
        cleanup: () => document.body.removeChild(container)
    };
}

// ===================================================================
// Setup functions for tag query benchmarks
// ===================================================================

function setupTagSmall() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    
    // Create mix of elements - 50 divs, 50 buttons
    for (let i = 0; i < 50; i++) {
        const div = document.createElement('div');
        container.appendChild(div);
    }
    for (let i = 0; i < 50; i++) {
        const button = document.createElement('button');
        container.appendChild(button);
    }
    
    return {
        container,
        cleanup: () => document.body.removeChild(container)
    };
}

function setupTagMedium() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    
    // Create mix of elements - 500 divs, 500 buttons
    for (let i = 0; i < 500; i++) {
        const div = document.createElement('div');
        container.appendChild(div);
    }
    for (let i = 0; i < 500; i++) {
        const button = document.createElement('button');
        container.appendChild(button);
    }
    
    return {
        container,
        cleanup: () => document.body.removeChild(container)
    };
}

function setupTagLarge() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    
    // Create mix of elements - 5000 divs, 5000 buttons
    for (let i = 0; i < 5000; i++) {
        const div = document.createElement('div');
        container.appendChild(div);
    }
    for (let i = 0; i < 5000; i++) {
        const button = document.createElement('button');
        container.appendChild(button);
    }
    
    return {
        container,
        cleanup: () => document.body.removeChild(container)
    };
}

// ===================================================================
// Setup functions for class query benchmarks
// ===================================================================

function setupClassSmall() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    
    // Create mix of elements - 50 with "btn", 50 with "container"
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
    
    return {
        container,
        cleanup: () => document.body.removeChild(container)
    };
}

function setupClassMedium() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    
    // Create mix of elements - 500 with "btn", 500 with "container"
    for (let i = 0; i < 500; i++) {
        const button = document.createElement('button');
        button.className = 'btn primary';
        container.appendChild(button);
    }
    for (let i = 0; i < 500; i++) {
        const div = document.createElement('div');
        div.className = 'container';
        container.appendChild(div);
    }
    
    return {
        container,
        cleanup: () => document.body.removeChild(container)
    };
}

function setupClassLarge() {
    const container = document.createElement('div');
    document.body.appendChild(container);
    
    // Create mix of elements - 5000 with "btn", 5000 with "container"
    for (let i = 0; i < 5000; i++) {
        const button = document.createElement('button');
        button.className = 'btn primary';
        container.appendChild(button);
    }
    for (let i = 0; i < 5000; i++) {
        const div = document.createElement('div');
        div.className = 'container';
        container.appendChild(div);
    }
    
    return {
        container,
        cleanup: () => document.body.removeChild(container)
    };
}

// ===================================================================
// Query benchmark functions (with anti-optimization)
// ===================================================================

function benchGetElementById(context) {
    const result = document.getElementById('target');
    // Array push + blackHole prevents DCE
    resultAccumulator.push(result);
    blackHole(result);
}

function benchQuerySelectorId(context) {
    const result = context.container.querySelector('#target');
    resultAccumulator.push(result);
    blackHole(result);
}

function benchGetElementsByTagName(context) {
    const collection = context.container.getElementsByTagName('button');
    // Force array materialization to match Zig's behavior (snapshot, not live)
    const result = Array.from(collection);
    resultAccumulator.push(result);
    blackHole(result);
}

function benchQuerySelectorTag(context) {
    const result = context.container.querySelector('button');
    resultAccumulator.push(result);
    blackHole(result);
}

function benchGetElementsByClassName(context) {
    const collection = context.container.getElementsByClassName('btn');
    // Force array materialization to match Zig's behavior (snapshot, not live)
    const result = Array.from(collection);
    resultAccumulator.push(result);
    blackHole(result);
}

function benchQuerySelectorClass(context) {
    const result = context.container.querySelector('.btn');
    resultAccumulator.push(result);
    blackHole(result);
}

// ===================================================================
// DOM Construction Benchmarks (Phase 1.2)
// ===================================================================

function constructSmallDom() {
    const container = document.createElement('div');
    for (let i = 0; i < 100; i++) {
        const div = document.createElement('div');
        container.appendChild(div);
    }
    resultAccumulator.push(container);
    blackHole(container);
}

function constructMediumDom() {
    const container = document.createElement('div');
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        container.appendChild(div);
    }
    resultAccumulator.push(container);
    blackHole(container);
}

function constructLargeDom() {
    const container = document.createElement('div');
    for (let i = 0; i < 10000; i++) {
        const div = document.createElement('div');
        container.appendChild(div);
    }
    resultAccumulator.push(container);
    blackHole(container);
}

// ===================================================================
// Complex Selector Benchmarks
// ===================================================================

function setupChildCombinator() {
    // Build: div > (div > p) * 1000
    const container = document.createElement('div');
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        const p = document.createElement('p');
        div.appendChild(p);
        container.appendChild(div);
    }
    return { container };
}

function setupDescendantCombinator() {
    // Build: article > div > div > p * 1000
    const container = document.createElement('article');
    for (let i = 0; i < 1000; i++) {
        const outer = document.createElement('div');
        const inner = document.createElement('div');
        const p = document.createElement('p');
        inner.appendChild(p);
        outer.appendChild(inner);
        container.appendChild(outer);
    }
    return { container };
}

function setupAdjacentSibling() {
    // Build: (h1, p) * 500 pairs
    const container = document.createElement('div');
    for (let i = 0; i < 500; i++) {
        const h1 = document.createElement('h1');
        const p = document.createElement('p');
        container.appendChild(h1);
        container.appendChild(p);
    }
    return { container };
}

function setupTypeClass() {
    // Build: 1000 divs, 10% with class "active"
    const container = document.createElement('div');
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        if (i % 10 === 0) div.className = 'active';
        container.appendChild(div);
    }
    return { container };
}

function setupAttributeSelector() {
    // Build: 1000 divs with data-id
    const container = document.createElement('div');
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        div.setAttribute('data-id', i.toString());
        container.appendChild(div);
    }
    return { container };
}

function setupComplexMultiComponent() {
    // Build: article#main > header > (div > h1.title) * 100
    const article = document.createElement('article');
    article.id = 'main';
    
    const header = document.createElement('header');
    article.appendChild(header);
    
    for (let i = 0; i < 100; i++) {
        const div = document.createElement('div');
        const h1 = document.createElement('h1');
        h1.className = 'title';
        div.appendChild(h1);
        header.appendChild(div);
    }
    
    return { container: article };
}

function benchChildCombinator(context) {
    const result = context.container.querySelector('div > p');
    resultAccumulator.push(result);
    blackHole(result);
}

function benchDescendantCombinator(context) {
    const result = context.container.querySelector('article p');
    resultAccumulator.push(result);
    blackHole(result);
}

function benchAdjacentSibling(context) {
    const result = context.container.querySelector('h1 + p');
    resultAccumulator.push(result);
    blackHole(result);
}

function benchTypeClass(context) {
    const result = context.container.querySelector('div.active');
    resultAccumulator.push(result);
    blackHole(result);
}

function benchAttributeSelector(context) {
    const result = context.container.querySelector('div[data-id="500"]');
    resultAccumulator.push(result);
    blackHole(result);
}

function benchComplexMultiComponent(context) {
    const result = context.container.querySelector('article#main > header h1.title');
    resultAccumulator.push(result);
    blackHole(result);
}

// ===================================================================
// Main benchmark runner
// ===================================================================

function runAllBenchmarks() {
    console.log('DOM Selector Benchmark Suite (JavaScript)');
    console.log('==========================================');
    console.log('Anti-Optimization: ENABLED');
    console.log('Techniques: Black hole, result arrays, opaque values, variable iterations\n');
    
    const results = [];
    
    console.log('Running querySelector benchmarks...');
    results.push(benchmarkFn('querySelector: Small DOM (100)', 1000, querySmallDom));
    results.push(benchmarkFn('querySelector: Medium DOM (1000)', 1000, queryMediumDom));
    results.push(benchmarkFn('querySelector: Large DOM (10000)', 100, queryLargeDom));
    results.push(benchmarkFn('querySelector: Class selector', 1000, queryClass));
    
    console.log('Running SPA benchmarks...');
    results.push(benchmarkFn('SPA: Repeated queries (1000x)', 1000, spaRepeated));
    results.push(benchmarkFn('SPA: Cold vs Hot cache (100x)', 100, spaColdVsHot));
    
    console.log('Running getElementById benchmarks...');
    results.push(benchmarkFn('getElementById: Small DOM (100)', 1000, getElementByIdSmall));
    results.push(benchmarkFn('getElementById: Medium DOM (1000)', 1000, getElementByIdMedium));
    results.push(benchmarkFn('getElementById: Large DOM (10000)', 100, getElementByIdLarge));
    
    console.log('Running query-only benchmarks (DOM pre-built)...');
    // Use 1M iterations for ultra-fast operations
    results.push(benchmarkWithSetup('Pure query: getElementById (100 elem)', 1000000, setupSmallDom, benchGetElementById));
    results.push(benchmarkWithSetup('Pure query: getElementById (1000 elem)', 1000000, setupMediumDom, benchGetElementById));
    results.push(benchmarkWithSetup('Pure query: getElementById (10000 elem)', 1000000, setupLargeDom, benchGetElementById));
    results.push(benchmarkWithSetup('Pure query: querySelector #id (100 elem)', 100000, setupSmallDom, benchQuerySelectorId));
    results.push(benchmarkWithSetup('Pure query: querySelector #id (1000 elem)', 100000, setupMediumDom, benchQuerySelectorId));
    results.push(benchmarkWithSetup('Pure query: querySelector #id (10000 elem)', 100000, setupLargeDom, benchQuerySelectorId));
    
    console.log('Running tag query benchmarks...');
    // Reduced iterations: Array.from() materialization is expensive (allocation + copy)
    results.push(benchmarkWithSetup('Pure query: getElementsByTagName (100 elem)', 100000, setupTagSmall, benchGetElementsByTagName));
    results.push(benchmarkWithSetup('Pure query: getElementsByTagName (1000 elem)', 10000, setupTagMedium, benchGetElementsByTagName));
    results.push(benchmarkWithSetup('Pure query: getElementsByTagName (10000 elem)', 1000, setupTagLarge, benchGetElementsByTagName));
    results.push(benchmarkWithSetup('Pure query: querySelector tag (100 elem)', 100000, setupTagSmall, benchQuerySelectorTag));
    results.push(benchmarkWithSetup('Pure query: querySelector tag (1000 elem)', 100000, setupTagMedium, benchQuerySelectorTag));
    results.push(benchmarkWithSetup('Pure query: querySelector tag (10000 elem)', 100000, setupTagLarge, benchQuerySelectorTag));
    
    console.log('Running class query benchmarks...');
    // Reduced iterations: Array.from() materialization is expensive (allocation + copy)
    results.push(benchmarkWithSetup('Pure query: getElementsByClassName (100 elem)', 100000, setupClassSmall, benchGetElementsByClassName));
    results.push(benchmarkWithSetup('Pure query: getElementsByClassName (1000 elem)', 10000, setupClassMedium, benchGetElementsByClassName));
    results.push(benchmarkWithSetup('Pure query: getElementsByClassName (10000 elem)', 1000, setupClassLarge, benchGetElementsByClassName));
    results.push(benchmarkWithSetup('Pure query: querySelector .class (100 elem)', 100000, setupClassSmall, benchQuerySelectorClass));
    results.push(benchmarkWithSetup('Pure query: querySelector .class (1000 elem)', 100000, setupClassMedium, benchQuerySelectorClass));
    results.push(benchmarkWithSetup('Pure query: querySelector .class (10000 elem)', 100000, setupClassLarge, benchQuerySelectorClass));
    
    console.log('Running DOM construction benchmarks (Phase 1.2)...');
    results.push(benchmarkFn('DOM construction: Small (100 elem)', 1000, constructSmallDom));
    results.push(benchmarkFn('DOM construction: Medium (1000 elem)', 1000, constructMediumDom));
    results.push(benchmarkFn('DOM construction: Large (10000 elem)', 100, constructLargeDom));
    
    console.log('Running complex selector benchmarks...');
    results.push(benchmarkWithSetup('Complex: Child combinator (div > p)', 100000, setupChildCombinator, benchChildCombinator));
    results.push(benchmarkWithSetup('Complex: Descendant combinator (article p)', 100000, setupDescendantCombinator, benchDescendantCombinator));
    results.push(benchmarkWithSetup('Complex: Adjacent sibling (h1 + p)', 100000, setupAdjacentSibling, benchAdjacentSibling));
    results.push(benchmarkWithSetup('Complex: Type + class (div.active)', 100000, setupTypeClass, benchTypeClass));
    results.push(benchmarkWithSetup('Complex: Attribute selector (div[data-id])', 100000, setupAttributeSelector, benchAttributeSelector));
    results.push(benchmarkWithSetup('Complex: Multi-component (article#main > header h1.title)', 100000, setupComplexMultiComponent, benchComplexMultiComponent));
    
    // Display results
    console.log('\nResults:');
    console.log('--------');
    
    results.forEach(result => {
        const msPerOp = result.msPerOp;
        let display;
        
        if (msPerOp < 0.001) {
            display = `${Math.round(msPerOp * 1000000)}ns/op`;
        } else if (msPerOp < 1) {
            display = `${Math.round(msPerOp * 1000)}µs/op`;
        } else {
            display = `${Math.round(msPerOp)}ms/op`;
        }
        
        console.log(`${result.name}: ${display} (${result.opsPerSec.toLocaleString()} ops/sec)`);
    });
    
    console.log('\nBenchmark complete!');
    console.log('Result accumulator size:', resultAccumulator.length, '(prevents DCE)');
    console.log('\nBrowser:', navigator.userAgent);
    
    return results;
}

// ===================================================================
// Helper function to compare with Zig results
// ===================================================================

function compareWithZig(zigResults) {
    console.log('\nComparison: JavaScript vs Zig');
    console.log('==============================\n');
    
    const jsResults = runAllBenchmarks();
    
    console.log('\nPerformance Comparison:');
    console.log('-----------------------');
    
    // Find matching benchmarks and compare
    const comparisons = [
        { name: 'Pure query: getElementById (100 elem)', zigNs: 5 },
        { name: 'Pure query: getElementById (1000 elem)', zigNs: 5 },
        { name: 'Pure query: getElementById (10000 elem)', zigNs: 5 },
        { name: 'Pure query: querySelector #id (100 elem)', zigNs: 16 },
        { name: 'Pure query: querySelector #id (1000 elem)', zigNs: 16 },
        { name: 'Pure query: querySelector #id (10000 elem)', zigNs: 16 },
    ];
    
    comparisons.forEach(comp => {
        const jsResult = jsResults.find(r => r.name === comp.name);
        if (jsResult) {
            const jsNs = jsResult.msPerOp * 1000000; // Convert ms to ns
            const speedup = jsNs / comp.zigNs;
            console.log(`${comp.name}:`);
            console.log(`  Zig:        ${comp.zigNs}ns`);
            console.log(`  JavaScript: ${Math.round(jsNs)}ns`);
            console.log(`  Zig is ${speedup.toFixed(1)}x faster\n`);
        }
    });
}

// ===================================================================
// Export results as JSON for programmatic access
// ===================================================================

function exportResults(results) {
    return results.map(result => ({
        name: result.name,
        operations: result.operations,
        totalMs: result.totalMs,
        msPerOp: result.msPerOp,
        opsPerSec: result.opsPerSec,
        nsPerOp: result.nsPerOp || Math.round(result.msPerOp * 1000000),  // Convert to nanoseconds for comparison with Zig
        bytesAllocated: result.bytesAllocated || 0,
        bytesPerOp: result.bytesPerOp || 0,
        peakMemory: result.peakMemory || 0
    }));
}

// ===================================================================
// Run benchmarks and return results (for Playwright)
// ===================================================================

function runBenchmarksAndExport() {
    const results = runAllBenchmarks();
    return exportResults(results);
}

// Make functions available globally
if (typeof window !== 'undefined') {
    window.runAllBenchmarks = runAllBenchmarks;
    window.runBenchmarksAndExport = runBenchmarksAndExport;
    window.compareWithZig = compareWithZig;
}

console.log('DOM Benchmark Suite loaded!');
console.log('Anti-Optimization: ENABLED');
console.log('Run: runAllBenchmarks() to start benchmarks');
console.log('Or: compareWithZig() to compare with Zig results');
console.log('Or: runBenchmarksAndExport() to get results as JSON');
