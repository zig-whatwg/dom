/**
 * DOM Selector Benchmark Suite - JavaScript Edition
 * 
 * Run these benchmarks in a browser console to compare performance
 * with the native Zig implementation.
 * 
 * Usage:
 *   1. Open browser console (F12)
 *   2. Copy and paste this entire file
 *   3. Run: runAllBenchmarks()
 */

// Benchmark result structure
class BenchmarkResult {
    constructor(name, operations, totalMs, msPerOp, opsPerSec) {
        this.name = name;
        this.operations = operations;
        this.totalMs = totalMs;
        this.msPerOp = msPerOp;
        this.opsPerSec = opsPerSec;
    }
}

// Run a benchmark function multiple times and collect statistics
function benchmarkFn(name, iterations, func) {
    // Warmup
    for (let i = 0; i < 10; i++) {
        func();
    }
    
    // Force garbage collection if available
    if (typeof gc === 'function') {
        gc();
    }
    
    // Actual benchmark
    const start = performance.now();
    for (let i = 0; i < iterations; i++) {
        func();
    }
    const end = performance.now();
    
    const totalMs = end - start;
    const msPerOp = totalMs / iterations;
    const opsPerSec = msPerOp > 0 ? Math.floor(1000 / msPerOp) : 0;
    
    return new BenchmarkResult(name, iterations, totalMs, msPerOp, opsPerSec);
}

// Run benchmark with setup phase (setup once, measure many iterations)
function benchmarkWithSetup(name, iterations, setup, func) {
    // Setup: build DOM once
    const context = setup();
    
    // Warmup
    for (let i = 0; i < 10; i++) {
        func(context);
    }
    
    // Force garbage collection if available
    if (typeof gc === 'function') {
        gc();
    }
    
    // Actual benchmark
    const start = performance.now();
    for (let i = 0; i < iterations; i++) {
        func(context);
    }
    const end = performance.now();
    
    const totalMs = end - start;
    const msPerOp = totalMs / iterations;
    const opsPerSec = msPerOp > 0 ? Math.floor(1000 / msPerOp) : 0;
    
    // Cleanup
    if (context.cleanup) {
        context.cleanup();
    }
    
    return new BenchmarkResult(name, iterations, totalMs, msPerOp, opsPerSec);
}

// Benchmark functions

function querySmallDom() {
    const container = document.createElement('div');
    for (let i = 0; i < 100; i++) {
        const div = document.createElement('div');
        if (i === 50) div.id = 'target';
        container.appendChild(div);
    }
    const result = container.querySelector('#target');
    if (result) globalAccumulator += 1;
}

function queryMediumDom() {
    const container = document.createElement('div');
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        if (i === 500) div.id = 'target';
        container.appendChild(div);
    }
    const result = container.querySelector('#target');
    if (result) globalAccumulator += 1;
}

function queryLargeDom() {
    const container = document.createElement('div');
    for (let i = 0; i < 10000; i++) {
        const div = document.createElement('div');
        if (i === 5000) div.id = 'target';
        container.appendChild(div);
    }
    const result = container.querySelector('#target');
    if (result) globalAccumulator += 1;
}

function queryClass() {
    const container = document.createElement('div');
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        if (i % 100 === 0) div.className = 'target';
        container.appendChild(div);
    }
    const result = container.querySelector('.target');
    if (result) globalAccumulator += 1;
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
    let found = 0;
    for (let i = 0; i < 10; i++) {
        if (container.querySelector('.component')) found++;
        if (container.querySelector('.btn')) found++;
        if (container.querySelector('.primary')) found++;
        if (container.querySelector('button')) found++;
        if (container.querySelector('div')) found++;
    }
    globalAccumulator += found;
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
    let found = 0;
    for (let i = 0; i < 100; i++) {
        if (container.querySelector('.item')) found++;
    }
    globalAccumulator += found;
}

function getElementByIdSmall() {
    const container = document.createElement('div');
    for (let i = 0; i < 100; i++) {
        const div = document.createElement('div');
        if (i === 50) div.id = 'target';
        container.appendChild(div);
    }
    const result = document.getElementById('target');
    if (result) globalAccumulator += 1;
}

function getElementByIdMedium() {
    const container = document.createElement('div');
    for (let i = 0; i < 1000; i++) {
        const div = document.createElement('div');
        if (i === 500) div.id = 'target';
        container.appendChild(div);
    }
    const result = document.getElementById('target');
    if (result) globalAccumulator += 1;
}

function getElementByIdLarge() {
    const container = document.createElement('div');
    for (let i = 0; i < 10000; i++) {
        const div = document.createElement('div');
        if (i === 5000) div.id = 'target';
        container.appendChild(div);
    }
    const result = document.getElementById('target');
    if (result) globalAccumulator += 1;
}

// Setup functions for pure query benchmarks

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

// Setup functions for tag query benchmarks

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

// Setup functions for class query benchmarks

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

// Global accumulator to prevent dead code elimination
let globalAccumulator = 0;

// Query benchmark functions
function benchGetElementById(context) {
    const result = document.getElementById('target');
    // Prevent optimizer from removing the call by using the result
    if (result) globalAccumulator += 1;
}

function benchQuerySelectorId(context) {
    const result = context.container.querySelector('#target');
    if (result) globalAccumulator += 1;
}

function benchGetElementsByTagName(context) {
    const result = context.container.getElementsByTagName('button');
    // Access length to force evaluation of live collection
    if (result && result.length > 0) globalAccumulator += 1;
}

function benchQuerySelectorTag(context) {
    const result = context.container.querySelector('button');
    if (result) globalAccumulator += 1;
}

function benchGetElementsByClassName(context) {
    const result = context.container.getElementsByClassName('btn');
    // Access length to force evaluation of live collection
    if (result && result.length > 0) globalAccumulator += 1;
}

function benchQuerySelectorClass(context) {
    const result = context.container.querySelector('.btn');
    if (result) globalAccumulator += 1;
}

// Main benchmark runner
function runAllBenchmarks() {
    console.log('DOM Selector Benchmark Suite (JavaScript)');
    console.log('==========================================\n');
    
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
    // Use 1M iterations for ultra-fast operations to get measurable timings
    results.push(benchmarkWithSetup('Pure query: getElementById (100 elem)', 1000000, setupSmallDom, benchGetElementById));
    results.push(benchmarkWithSetup('Pure query: getElementById (1000 elem)', 1000000, setupMediumDom, benchGetElementById));
    results.push(benchmarkWithSetup('Pure query: getElementById (10000 elem)', 1000000, setupLargeDom, benchGetElementById));
    results.push(benchmarkWithSetup('Pure query: querySelector #id (100 elem)', 100000, setupSmallDom, benchQuerySelectorId));
    results.push(benchmarkWithSetup('Pure query: querySelector #id (1000 elem)', 100000, setupMediumDom, benchQuerySelectorId));
    results.push(benchmarkWithSetup('Pure query: querySelector #id (10000 elem)', 100000, setupLargeDom, benchQuerySelectorId));
    
    console.log('Running tag query benchmarks...');
    // Use 1M iterations for getElementsByTagName (very fast)
    results.push(benchmarkWithSetup('Pure query: getElementsByTagName (100 elem)', 1000000, setupTagSmall, benchGetElementsByTagName));
    results.push(benchmarkWithSetup('Pure query: getElementsByTagName (1000 elem)', 1000000, setupTagMedium, benchGetElementsByTagName));
    results.push(benchmarkWithSetup('Pure query: getElementsByTagName (10000 elem)', 1000000, setupTagLarge, benchGetElementsByTagName));
    results.push(benchmarkWithSetup('Pure query: querySelector tag (100 elem)', 100000, setupTagSmall, benchQuerySelectorTag));
    results.push(benchmarkWithSetup('Pure query: querySelector tag (1000 elem)', 100000, setupTagMedium, benchQuerySelectorTag));
    results.push(benchmarkWithSetup('Pure query: querySelector tag (10000 elem)', 100000, setupTagLarge, benchQuerySelectorTag));
    
    console.log('Running class query benchmarks...');
    // Use 1M iterations for getElementsByClassName (very fast)
    results.push(benchmarkWithSetup('Pure query: getElementsByClassName (100 elem)', 1000000, setupClassSmall, benchGetElementsByClassName));
    results.push(benchmarkWithSetup('Pure query: getElementsByClassName (1000 elem)', 1000000, setupClassMedium, benchGetElementsByClassName));
    results.push(benchmarkWithSetup('Pure query: getElementsByClassName (10000 elem)', 1000000, setupClassLarge, benchGetElementsByClassName));
    results.push(benchmarkWithSetup('Pure query: querySelector .class (100 elem)', 100000, setupClassSmall, benchQuerySelectorClass));
    results.push(benchmarkWithSetup('Pure query: querySelector .class (1000 elem)', 100000, setupClassMedium, benchQuerySelectorClass));
    results.push(benchmarkWithSetup('Pure query: querySelector .class (10000 elem)', 100000, setupClassLarge, benchQuerySelectorClass));
    
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
    console.log('\nBrowser:', navigator.userAgent);
    
    // Use the global accumulator to prevent optimizer from eliminating operations
    if (globalAccumulator < 0) {
        console.log('This should never print:', globalAccumulator);
    }
    
    return results;
}

// Helper function to compare with Zig results
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

// Export results as JSON for programmatic access
function exportResults(results) {
    return results.map(result => ({
        name: result.name,
        operations: result.operations,
        totalMs: result.totalMs,
        msPerOp: result.msPerOp,
        opsPerSec: result.opsPerSec,
        nsPerOp: result.msPerOp * 1000000  // Convert to nanoseconds for comparison with Zig
    }));
}

// Run benchmarks and return results (for Playwright)
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
console.log('Run: runAllBenchmarks() to start benchmarks');
console.log('Or: compareWithZig() to compare with Zig results');
console.log('Or: runBenchmarksAndExport() to get results as JSON');
