/**
 * Playwright Benchmark Runner
 * 
 * Runs DOM benchmarks across Chromium, Firefox, and WebKit engines
 * and collects results for comparison with Zig implementation.
 */

const { chromium, firefox, webkit } = require('playwright');
const fs = require('fs').promises;
const path = require('path');

// Configuration
const BROWSERS = [
    { name: 'Chromium', launcher: chromium },
    { name: 'Firefox', launcher: firefox },
    { name: 'WebKit', launcher: webkit }
];

const BENCHMARK_HTML = path.join(__dirname, 'benchmark.html');
const RESULTS_DIR = path.join(__dirname, '..', '..', 'benchmark_results');

/**
 * Create a simple HTML page that loads and runs the benchmarks
 */
async function createBenchmarkHTML() {
    const benchmarkJS = await fs.readFile(path.join(__dirname, 'benchmark.js'), 'utf-8');
    
    const html = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DOM Benchmark Suite</title>
</head>
<body>
    <h1>DOM Benchmark Suite</h1>
    <p id="status">Running benchmarks...</p>
    
    <script>
    ${benchmarkJS}
    
    // Automatically run benchmarks and expose results
    window.benchmarkResults = null;
    window.benchmarkComplete = false;
    
    (async function() {
        try {
            const results = runBenchmarksAndExport();
            window.benchmarkResults = results;
            window.benchmarkComplete = true;
            document.getElementById('status').textContent = 'Benchmarks complete!';
        } catch (error) {
            console.error('Benchmark error:', error);
            window.benchmarkError = error.message;
            window.benchmarkComplete = true;
            document.getElementById('status').textContent = 'Benchmark error: ' + error.message;
        }
    })();
    </script>
</body>
</html>`;
    
    await fs.writeFile(BENCHMARK_HTML, html);
}

/**
 * Run benchmarks in a specific browser
 */
async function runBrowserBenchmarks(browserName, launcher) {
    console.log(`\n[${browserName}] Launching browser...`);
    
    const browser = await launcher.launch({
        headless: true
    });
    
    try {
        const context = await browser.newContext();
        const page = await context.newPage();
        
        // Load the benchmark page
        console.log(`[${browserName}] Loading benchmarks...`);
        await page.goto(`file://${BENCHMARK_HTML}`);
        
        // Wait for benchmarks to complete (with timeout)
        console.log(`[${browserName}] Running benchmarks...`);
        await page.waitForFunction(
            () => window.benchmarkComplete === true,
            { timeout: 300000 } // 5 minute timeout
        );
        
        // Check for errors
        const error = await page.evaluate(() => window.benchmarkError);
        if (error) {
            throw new Error(`Benchmark error: ${error}`);
        }
        
        // Get results
        const results = await page.evaluate(() => window.benchmarkResults);
        
        if (!results || results.length === 0) {
            throw new Error('No benchmark results returned');
        }
        
        console.log(`[${browserName}] Completed ${results.length} benchmarks`);
        
        return {
            browser: browserName,
            userAgent: await page.evaluate(() => navigator.userAgent),
            timestamp: new Date().toISOString(),
            results: results
        };
        
    } finally {
        await browser.close();
    }
}

/**
 * Run benchmarks across all browsers
 */
async function runAllBrowserBenchmarks() {
    console.log('DOM Benchmark Suite - Playwright Runner');
    console.log('========================================\n');
    console.log('Browsers:', BROWSERS.map(b => b.name).join(', '));
    
    // Create benchmark HTML
    await createBenchmarkHTML();
    
    const allResults = [];
    
    for (const { name, launcher } of BROWSERS) {
        try {
            const result = await runBrowserBenchmarks(name, launcher);
            allResults.push(result);
        } catch (error) {
            console.error(`[${name}] Error:`, error.message);
            allResults.push({
                browser: name,
                error: error.message,
                timestamp: new Date().toISOString(),
                results: []
            });
        }
    }
    
    return allResults;
}

/**
 * Save results to JSON file
 */
async function saveResults(results) {
    // Ensure results directory exists
    await fs.mkdir(RESULTS_DIR, { recursive: true });
    
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `browser_benchmarks_${timestamp}.json`;
    const filepath = path.join(RESULTS_DIR, filename);
    
    await fs.writeFile(filepath, JSON.stringify(results, null, 2));
    console.log(`\nResults saved to: ${filepath}`);
    
    // Also save as latest
    const latestPath = path.join(RESULTS_DIR, 'browser_benchmarks_latest.json');
    await fs.writeFile(latestPath, JSON.stringify(results, null, 2));
    console.log(`Latest results: ${latestPath}`);
    
    return filepath;
}

/**
 * Display results summary
 */
function displaySummary(results) {
    console.log('\n\nBenchmark Summary');
    console.log('=================\n');
    
    for (const browserResult of results) {
        if (browserResult.error) {
            console.log(`${browserResult.browser}: ERROR - ${browserResult.error}`);
            continue;
        }
        
        console.log(`${browserResult.browser}:`);
        console.log(`  User Agent: ${browserResult.userAgent}`);
        console.log(`  Benchmarks: ${browserResult.results.length}`);
        
        // Show a few key results
        const keyBenchmarks = [
            'Pure query: getElementById (100 elem)',
            'Pure query: querySelector #id (100 elem)',
            'Pure query: querySelector tag (100 elem)',
            'Pure query: querySelector .class (100 elem)'
        ];
        
        console.log('  Key Results:');
        for (const benchName of keyBenchmarks) {
            const result = browserResult.results.find(r => r.name === benchName);
            if (result) {
                const nsPerOp = Math.round(result.nsPerOp);
                console.log(`    ${benchName}: ${nsPerOp}ns/op`);
            }
        }
        console.log('');
    }
}

/**
 * Main entry point
 */
async function main() {
    try {
        const results = await runAllBrowserBenchmarks();
        await saveResults(results);
        displaySummary(results);
        
        console.log('\n✅ All benchmarks complete!');
        process.exit(0);
    } catch (error) {
        console.error('\n❌ Error running benchmarks:', error);
        process.exit(1);
    }
}

// Run if called directly
if (require.main === module) {
    main();
}

module.exports = {
    runAllBrowserBenchmarks,
    saveResults
};
