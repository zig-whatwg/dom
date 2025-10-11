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
