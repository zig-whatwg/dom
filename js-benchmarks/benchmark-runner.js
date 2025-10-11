/**
 * JavaScript Benchmark Runner for Chrome Console
 * 
 * Usage:
 *   const result = await runBenchmark("Test Name", 10000, () => {
 *     // Code to benchmark
 *   });
 *   result.print();
 */

class BenchmarkResult {
  constructor(name, iterations, totalTime) {
    this.name = name;
    this.iterations = iterations;
    this.totalTime = totalTime;
    this.avgTime = totalTime / iterations;
    this.opsPerSec = 1000 / this.avgTime;
  }

  print() {
    const name = this.name.padEnd(50);
    const timeStr = `${(this.avgTime * 1000).toFixed(2)} μs/op`;
    const opsStr = `${Math.round(this.opsPerSec).toLocaleString()} ops/sec`;
    console.log(`  ${name} ${timeStr.padStart(20)}  ${opsStr.padStart(20)}`);
  }
}

/**
 * Run a benchmark function multiple times and collect timing data
 * @param {string} name - Benchmark name
 * @param {number} iterations - Number of times to run
 * @param {Function} fn - Function to benchmark (can be async)
 * @returns {Promise<BenchmarkResult>}
 */
async function runBenchmark(name, iterations, fn) {
  // Warmup
  for (let i = 0; i < Math.min(100, iterations / 10); i++) {
    await fn();
  }

  // Force GC if available (Chrome with --expose-gc flag)
  if (typeof gc !== 'undefined') {
    gc();
  }

  // Actual benchmark
  const start = performance.now();
  for (let i = 0; i < iterations; i++) {
    await fn();
  }
  const end = performance.now();

  const totalTime = end - start;
  return new BenchmarkResult(name, iterations, totalTime);
}

/**
 * Run a suite of benchmarks
 * @param {string} title - Suite title
 * @param {Array<{name: string, iterations: number, fn: Function}>} benchmarks
 */
async function runBenchmarkSuite(title, benchmarks) {
  console.log(`\n📊 ${title}`);
  console.log('-'.repeat(100));

  for (const bench of benchmarks) {
    const result = await runBenchmark(bench.name, bench.iterations, bench.fn);
    result.print();
  }
}

/**
 * Print benchmark header
 */
function printHeader() {
  console.log('\n' + '='.repeat(100));
  console.log(' DOM PERFORMANCE BENCHMARKS - JavaScript (Chrome)');
  console.log('='.repeat(100));
  console.log('\n');
}

/**
 * Print benchmark footer
 */
function printFooter() {
  console.log('\n' + '='.repeat(100));
  console.log(' BENCHMARKS COMPLETE');
  console.log('='.repeat(100));
  console.log('\n');
}
