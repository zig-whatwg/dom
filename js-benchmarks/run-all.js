/**
 * Run All Benchmarks
 * 
 * Usage in Chrome DevTools Console:
 * 1. Open Chrome DevTools (F12)
 * 2. Go to Console tab
 * 3. Copy and paste the contents of this file
 * 4. Press Enter
 * 
 * Or use the convenience function:
 * await runAllBenchmarks();
 */

async function runAllBenchmarks() {
  printHeader();
  
  // CSS Selector Queries
  await runSelectorBenchmarks();
  
  // DOM CRUD Operations
  await runCrudBenchmarks();
  
  // Tree Traversal
  await runTraversalBenchmarks();
  
  // Batch Operations
  await runBatchBenchmarks();
  
  // Event System
  await runEventBenchmarks();
  
  // MutationObserver
  await runObserverBenchmarks();
  
  // Range Operations
  await runRangeBenchmarks();
  
  // Stress Tests
  console.log('\n💥 STRESS TESTS (Expensive Operations)');
  console.log('-'.repeat(100));
  console.log('Note: These tests involve 1,000-10,000 operations per iteration');
  console.log('-'.repeat(100));
  await runStressBenchmarks();
  
  printFooter();
}

/**
 * Quick benchmark runner for single tests
 * 
 * Usage:
 *   await quickBench("Test", 1000, () => {
 *     // your code here
 *   });
 */
async function quickBench(name, iterations, fn) {
  const result = await runBenchmark(name, iterations, fn);
  result.print();
  return result;
}

// Instructions
console.log(`
╔════════════════════════════════════════════════════════════════════════╗
║              DOM BENCHMARKS - JAVASCRIPT VERSION                       ║
╚════════════════════════════════════════════════════════════════════════╝

To run all benchmarks:
  await runAllBenchmarks()

To run individual benchmark suites:
  await runSelectorBenchmarks()
  await runCrudBenchmarks()
  await runTraversalBenchmarks()
  await runBatchBenchmarks()
  await runEventBenchmarks()
  await runObserverBenchmarks()
  await runRangeBenchmarks()
  await runStressBenchmarks()

To run a quick custom benchmark:
  await quickBench("My Test", 1000, () => {
    // Your code here
  })

Note: Results will be printed to console
      Estimated time for full suite: 30-60 seconds

════════════════════════════════════════════════════════════════════════
`);
