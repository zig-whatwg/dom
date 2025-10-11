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
