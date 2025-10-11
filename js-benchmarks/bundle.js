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
/**
 * DOM CRUD Operations Benchmarks
 */

async function runCrudBenchmarks() {
  await runBenchmarkSuite('DOM CRUD OPERATIONS', [
    {
      name: 'createElement',
      iterations: 100000,
      fn: benchCreateElement
    },
    {
      name: 'createElement + 3 attributes',
      iterations: 50000,
      fn: benchCreateElementWithAttributes
    },
    {
      name: 'createTextNode',
      iterations: 100000,
      fn: benchCreateTextNode
    },
    {
      name: 'appendChild (single)',
      iterations: 50000,
      fn: benchAppendChild
    },
    {
      name: 'appendChild (10 children)',
      iterations: 10000,
      fn: benchAppendMultipleChildren
    },
    {
      name: 'removeChild',
      iterations: 50000,
      fn: benchRemoveChild
    },
    {
      name: 'setAttribute',
      iterations: 100000,
      fn: benchSetAttribute
    },
    {
      name: 'getAttribute',
      iterations: 100000,
      fn: benchGetAttribute
    },
    {
      name: 'className operations',
      iterations: 100000,
      fn: benchClassOperations
    }
  ]);
}

function benchCreateElement() {
  const elem = document.createElement('div');
}

function benchCreateElementWithAttributes() {
  const elem = document.createElement('div');
  elem.setAttribute('id', 'test-id');
  elem.setAttribute('class', 'test-class');
  elem.setAttribute('data-value', '123');
}

function benchCreateTextNode() {
  const text = document.createTextNode('Hello, World!');
}

function benchAppendChild() {
  const parent = document.createElement('div');
  const child = document.createElement('span');
  parent.appendChild(child);
}

function benchAppendMultipleChildren() {
  const parent = document.createElement('div');
  for (let i = 0; i < 10; i++) {
    const child = document.createElement('span');
    parent.appendChild(child);
  }
}

function benchRemoveChild() {
  const parent = document.createElement('div');
  const child = document.createElement('span');
  parent.appendChild(child);
  parent.removeChild(child);
}

function benchSetAttribute() {
  const elem = document.createElement('div');
  elem.setAttribute('data-test', 'value');
}

function benchGetAttribute() {
  const elem = document.createElement('div');
  elem.setAttribute('data-test', 'value');
  const val = elem.getAttribute('data-test');
}

function benchClassOperations() {
  const elem = document.createElement('div');
  elem.className = 'class1 class2';
  elem.classList.add('class3');
  elem.classList.remove('class1');
  const has = elem.classList.contains('class2');
}
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
/**
 * CSS Selector Benchmarks
 */

async function runSelectorBenchmarks() {
  await runBenchmarkSuite('CSS SELECTOR QUERIES', [
    {
      name: 'Simple selector (.class)',
      iterations: 10000,
      fn: benchSimpleSelector
    },
    {
      name: 'Complex selector (article.post > p.content)',
      iterations: 5000,
      fn: benchComplexSelector
    },
    {
      name: 'querySelectorAll (10 elements)',
      iterations: 5000,
      fn: benchQuerySelectorAll
    }
  ]);
}

function benchSimpleSelector() {
  // Create test structure
  const container = document.createElement('div');
  for (let i = 0; i < 10; i++) {
    const div = document.createElement('div');
    div.className = 'test-class';
    container.appendChild(div);
  }
  
  // Benchmark the query
  const result = container.querySelector('.test-class');
}

function benchComplexSelector() {
  // Create nested structure
  const article = document.createElement('article');
  article.className = 'post';
  
  for (let i = 0; i < 5; i++) {
    const p = document.createElement('p');
    p.className = 'content';
    p.textContent = 'Test content';
    article.appendChild(p);
  }
  
  // Benchmark the query
  const result = article.querySelector('article.post > p.content');
}

function benchQuerySelectorAll() {
  // Create test structure with 10 matching elements
  const container = document.createElement('div');
  for (let i = 0; i < 10; i++) {
    const div = document.createElement('div');
    div.className = 'item';
    container.appendChild(div);
  }
  
  // Benchmark the query
  const results = container.querySelectorAll('.item');
}
/**
 * Event System Benchmarks
 */

async function runEventBenchmarks() {
  await runBenchmarkSuite('EVENT SYSTEM', [
    {
      name: 'Create Event',
      iterations: 100000,
      fn: benchCreateEvent
    },
    {
      name: 'Create CustomEvent',
      iterations: 100000,
      fn: benchCreateCustomEvent
    },
    {
      name: 'addEventListener',
      iterations: 50000,
      fn: benchAddEventListener
    },
    {
      name: 'removeEventListener',
      iterations: 50000,
      fn: benchRemoveEventListener
    },
    {
      name: 'dispatchEvent (single listener)',
      iterations: 10000,
      fn: benchDispatchEvent
    },
    {
      name: 'Event propagation (2 levels)',
      iterations: 5000,
      fn: benchEventPropagation
    },
    {
      name: 'Event capture',
      iterations: 5000,
      fn: benchEventCapture
    },
    {
      name: 'Multiple listeners (3)',
      iterations: 10000,
      fn: benchMultipleListeners
    },
    {
      name: 'stopPropagation',
      iterations: 5000,
      fn: benchStopPropagation
    }
  ]);
}

function benchCreateEvent() {
  const event = new Event('click');
}

function benchCreateCustomEvent() {
  const event = new CustomEvent('custom', { detail: { value: 42 } });
}

function benchAddEventListener() {
  const elem = document.createElement('div');
  const listener = () => {};
  elem.addEventListener('click', listener);
}

function benchRemoveEventListener() {
  const elem = document.createElement('div');
  const listener = () => {};
  elem.addEventListener('click', listener);
  elem.removeEventListener('click', listener);
}

function benchDispatchEvent() {
  const elem = document.createElement('div');
  const listener = () => {};
  elem.addEventListener('click', listener);
  
  const event = new Event('click');
  elem.dispatchEvent(event);
}

function benchEventPropagation() {
  const parent = document.createElement('div');
  const child = document.createElement('span');
  parent.appendChild(child);
  
  const listener = () => {};
  parent.addEventListener('click', listener);
  child.addEventListener('click', listener);
  
  const event = new Event('click', { bubbles: true });
  child.dispatchEvent(event);
}

function benchEventCapture() {
  const parent = document.createElement('div');
  const child = document.createElement('span');
  parent.appendChild(child);
  
  const listener = () => {};
  parent.addEventListener('click', listener, { capture: true });
  child.addEventListener('click', listener);
  
  const event = new Event('click', { bubbles: true });
  child.dispatchEvent(event);
}

function benchMultipleListeners() {
  const elem = document.createElement('div');
  const listener1 = () => {};
  const listener2 = () => {};
  const listener3 = () => {};
  
  elem.addEventListener('click', listener1);
  elem.addEventListener('click', listener2);
  elem.addEventListener('click', listener3);
  
  const event = new Event('click');
  elem.dispatchEvent(event);
}

function benchStopPropagation() {
  const parent = document.createElement('div');
  const child = document.createElement('span');
  parent.appendChild(child);
  
  const listenerStop = (e) => e.stopPropagation();
  const listenerNormal = () => {};
  
  child.addEventListener('click', listenerStop);
  parent.addEventListener('click', listenerNormal);
  
  const event = new Event('click', { bubbles: true });
  child.dispatchEvent(event);
}
/**
 * Tree Traversal Benchmarks
 */

async function runTraversalBenchmarks() {
  await runBenchmarkSuite('TREE TRAVERSAL', [
    {
      name: 'Tree traversal (5 levels, 3 children/node)',
      iterations: 1000,
      fn: benchTreeTraversal
    },
    {
      name: 'Deep tree traversal (50 levels)',
      iterations: 5000,
      fn: benchDeepTreeTraversal
    }
  ]);
}

function createBalancedTree(depth, childrenPerNode) {
  const root = document.createElement('div');
  
  function buildLevel(node, currentDepth) {
    if (currentDepth >= depth) return;
    
    for (let i = 0; i < childrenPerNode; i++) {
      const child = document.createElement('div');
      node.appendChild(child);
      buildLevel(child, currentDepth + 1);
    }
  }
  
  buildLevel(root, 0);
  return root;
}

function createDeepTree(depth) {
  const root = document.createElement('div');
  let current = root;
  
  for (let i = 0; i < depth; i++) {
    const child = document.createElement('div');
    current.appendChild(child);
    current = child;
  }
  
  return root;
}

function traverseTree(node) {
  // Visit this node
  const name = node.nodeName;
  
  // Traverse children
  for (let child of node.childNodes) {
    if (child.nodeType === Node.ELEMENT_NODE) {
      traverseTree(child);
    }
  }
}

function benchTreeTraversal() {
  const tree = createBalancedTree(5, 3);
  traverseTree(tree);
}

function benchDeepTreeTraversal() {
  const tree = createDeepTree(50);
  traverseTree(tree);
}
/**
 * MutationObserver Benchmarks
 */

async function runObserverBenchmarks() {
  await runBenchmarkSuite('MUTATION OBSERVER', [
    {
      name: 'Create observer',
      iterations: 50000,
      fn: benchCreateObserver
    },
    {
      name: 'Observe childList',
      iterations: 10000,
      fn: benchObserveChildList
    },
    {
      name: 'Observe attributes',
      iterations: 10000,
      fn: benchObserveAttributes
    },
    {
      name: 'Observe subtree',
      iterations: 10000,
      fn: benchObserveSubtree
    },
    {
      name: 'Disconnect observer',
      iterations: 10000,
      fn: benchDisconnectObserver
    },
    {
      name: 'takeRecords',
      iterations: 5000,
      fn: benchTakeRecords
    },
    {
      name: 'Multiple observers',
      iterations: 5000,
      fn: benchMultipleObservers
    }
  ]);
}

function benchCreateObserver() {
  const callback = (mutations) => {};
  const observer = new MutationObserver(callback);
}

function benchObserveChildList() {
  const target = document.createElement('div');
  const callback = (mutations) => {};
  const observer = new MutationObserver(callback);
  
  observer.observe(target, { childList: true });
  observer.disconnect();
}

function benchObserveAttributes() {
  const target = document.createElement('div');
  const callback = (mutations) => {};
  const observer = new MutationObserver(callback);
  
  observer.observe(target, { attributes: true });
  observer.disconnect();
}

function benchObserveSubtree() {
  const target = document.createElement('div');
  const callback = (mutations) => {};
  const observer = new MutationObserver(callback);
  
  observer.observe(target, { 
    childList: true,
    subtree: true 
  });
  observer.disconnect();
}

function benchDisconnectObserver() {
  const target = document.createElement('div');
  const callback = (mutations) => {};
  const observer = new MutationObserver(callback);
  
  observer.observe(target, { childList: true });
  observer.disconnect();
}

function benchTakeRecords() {
  const target = document.createElement('div');
  const callback = (mutations) => {};
  const observer = new MutationObserver(callback);
  
  observer.observe(target, { childList: true });
  
  // Trigger a mutation
  const child = document.createElement('span');
  target.appendChild(child);
  
  // Take records
  const records = observer.takeRecords();
  observer.disconnect();
}

function benchMultipleObservers() {
  const target = document.createElement('div');
  const callback = (mutations) => {};
  
  const observer1 = new MutationObserver(callback);
  const observer2 = new MutationObserver(callback);
  const observer3 = new MutationObserver(callback);
  
  observer1.observe(target, { childList: true });
  observer2.observe(target, { attributes: true });
  observer3.observe(target, { childList: true, subtree: true });
  
  observer1.disconnect();
  observer2.disconnect();
  observer3.disconnect();
}
/**
 * Range Operations Benchmarks
 */

async function runRangeBenchmarks() {
  await runBenchmarkSuite('RANGE OPERATIONS', [
    {
      name: 'Create Range',
      iterations: 100000,
      fn: benchCreateRange
    },
    {
      name: 'setStart',
      iterations: 50000,
      fn: benchSetStart
    },
    {
      name: 'setEnd',
      iterations: 50000,
      fn: benchSetEnd
    },
    {
      name: 'selectNode',
      iterations: 10000,
      fn: benchSelectNode
    },
    {
      name: 'selectNodeContents',
      iterations: 10000,
      fn: benchSelectNodeContents
    },
    {
      name: 'collapse',
      iterations: 50000,
      fn: benchCollapse
    },
    {
      name: 'cloneRange',
      iterations: 10000,
      fn: benchCloneRange
    },
    {
      name: 'extractContents',
      iterations: 5000,
      fn: benchExtractContents
    },
    {
      name: 'cloneContents',
      iterations: 5000,
      fn: benchCloneContents
    },
    {
      name: 'deleteContents',
      iterations: 5000,
      fn: benchDeleteContents
    },
    {
      name: 'insertNode',
      iterations: 5000,
      fn: benchInsertNode
    },
    {
      name: 'compareBoundaryPoints',
      iterations: 10000,
      fn: benchCompareBoundaryPoints
    }
  ]);
}

function benchCreateRange() {
  const range = document.createRange();
}

function benchSetStart() {
  const text = document.createTextNode('Hello, World!');
  const range = document.createRange();
  range.setStart(text, 0);
}

function benchSetEnd() {
  const text = document.createTextNode('Hello, World!');
  const range = document.createRange();
  range.setStart(text, 0);
  range.setEnd(text, 5);
}

function benchSelectNode() {
  const elem = document.createElement('div');
  const range = document.createRange();
  range.selectNode(elem);
}

function benchSelectNodeContents() {
  const elem = document.createElement('div');
  const text = document.createTextNode('Content');
  elem.appendChild(text);
  
  const range = document.createRange();
  range.selectNodeContents(elem);
}

function benchCollapse() {
  const text = document.createTextNode('Hello, World!');
  const range = document.createRange();
  range.setStart(text, 0);
  range.setEnd(text, 5);
  range.collapse(true);
}

function benchCloneRange() {
  const text = document.createTextNode('Hello, World!');
  const range = document.createRange();
  range.setStart(text, 0);
  range.setEnd(text, 5);
  
  const cloned = range.cloneRange();
}

function benchExtractContents() {
  const elem = document.createElement('div');
  const text = document.createTextNode('Hello, World!');
  elem.appendChild(text);
  
  const range = document.createRange();
  range.selectNodeContents(elem);
  
  const fragment = range.extractContents();
}

function benchCloneContents() {
  const elem = document.createElement('div');
  const text = document.createTextNode('Hello, World!');
  elem.appendChild(text);
  
  const range = document.createRange();
  range.selectNodeContents(elem);
  
  const fragment = range.cloneContents();
}

function benchDeleteContents() {
  const elem = document.createElement('div');
  const text = document.createTextNode('Hello, World!');
  elem.appendChild(text);
  
  const range = document.createRange();
  range.selectNodeContents(elem);
  range.deleteContents();
}

function benchInsertNode() {
  const elem = document.createElement('div');
  const text = document.createTextNode('Hello, World!');
  elem.appendChild(text);
  
  const range = document.createRange();
  range.setStart(text, 7);
  range.setEnd(text, 7);
  
  const newText = document.createTextNode('Beautiful ');
  range.insertNode(newText);
}

function benchCompareBoundaryPoints() {
  const text = document.createTextNode('Hello, World!');
  
  const range1 = document.createRange();
  range1.setStart(text, 0);
  range1.setEnd(text, 5);
  
  const range2 = document.createRange();
  range2.setStart(text, 7);
  range2.setEnd(text, 12);
  
  const result = range1.compareBoundaryPoints(Range.START_TO_START, range2);
}
/**
 * Stress Test Benchmarks
 * These tests involve 1,000-10,000 operations per iteration
 */

async function runStressBenchmarks() {
  await runBenchmarkSuite('STRESS TESTS (Expensive Operations)', [
    {
      name: 'Create 10,000 nodes',
      iterations: 10,
      fn: benchCreate10kNodes
    },
    {
      name: 'Deep tree (500 levels)',
      iterations: 100,
      fn: benchDeepTree500Levels
    },
    {
      name: 'Complex query over 10k nodes',
      iterations: 10,
      fn: benchComplexQuery10kNodes
    },
    {
      name: '1,000 elements × 10 attributes',
      iterations: 100,
      fn: benchMassiveAttributeOps
    },
    {
      name: 'Wide tree (100×100 = 10k nodes)',
      iterations: 10,
      fn: benchWideTree100x100
    }
  ]);
}

function benchCreate10kNodes() {
  const nodes = [];
  for (let i = 0; i < 10000; i++) {
    const elem = document.createElement('div');
    elem.className = 'item';
    nodes.push(elem);
  }
}

function benchDeepTree500Levels() {
  const root = document.createElement('div');
  let current = root;
  
  for (let i = 0; i < 500; i++) {
    const child = document.createElement('div');
    current.appendChild(child);
    current = child;
  }
}

function benchComplexQuery10kNodes() {
  // Create a large tree with 10k nodes
  const root = document.createElement('div');
  root.id = 'root';
  
  for (let i = 0; i < 100; i++) {
    const section = document.createElement('section');
    section.className = 'section';
    
    for (let j = 0; j < 100; j++) {
      const article = document.createElement('article');
      article.className = 'post';
      
      const p = document.createElement('p');
      p.className = 'content';
      article.appendChild(p);
      
      section.appendChild(article);
    }
    
    root.appendChild(section);
  }
  
  // Complex query
  const results = root.querySelectorAll('section.section > article.post > p.content');
}

function benchMassiveAttributeOps() {
  const elements = [];
  
  // Create 1,000 elements
  for (let i = 0; i < 1000; i++) {
    const elem = document.createElement('div');
    elements.push(elem);
  }
  
  // Set 10 attributes on each
  for (const elem of elements) {
    for (let i = 0; i < 10; i++) {
      elem.setAttribute(`data-attr${i}`, `value${i}`);
    }
  }
}

function benchWideTree100x100() {
  const root = document.createElement('div');
  
  // Create 100 sections, each with 100 children
  for (let i = 0; i < 100; i++) {
    const section = document.createElement('section');
    
    for (let j = 0; j < 100; j++) {
      const div = document.createElement('div');
      div.className = 'item';
      section.appendChild(div);
    }
    
    root.appendChild(section);
  }
}
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
