/**
 * Batch Operations Benchmarks
 */

async function runBatchBenchmarks() {
  await runBenchmarkSuite('BATCH OPERATIONS', [
    {
      name: 'Batch insert 100 elements',
      iterations: 1000,
      fn: benchBatchInsert
    }
  ]);
}

function benchBatchInsert() {
  const container = document.createElement('div');
  const fragment = document.createDocumentFragment();
  
  // Create 100 elements
  for (let i = 0; i < 100; i++) {
    const elem = document.createElement('div');
    elem.className = 'item';
    elem.textContent = `Item ${i}`;
    fragment.appendChild(elem);
  }
  
  // Insert all at once
  container.appendChild(fragment);
}
