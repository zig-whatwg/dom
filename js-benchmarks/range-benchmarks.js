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
