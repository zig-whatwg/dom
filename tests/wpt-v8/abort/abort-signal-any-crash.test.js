// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/abort/abort-signal-any-crash.html

// Setup HTML structure
document.body.innerHTML = `
    <p>Test passes if the browser does not crash.</p>
    
  `;

async function test() {
            let controller = new AbortController();
            let signal = AbortSignal.any([controller.signal]);
            controller = undefined;
            await garbageCollect();
            AbortSignal.any([signal]);
            document.documentElement.classList.remove('test-wait');
        }
        test();

