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
