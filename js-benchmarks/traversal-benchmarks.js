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
