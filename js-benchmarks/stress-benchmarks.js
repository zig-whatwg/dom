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
