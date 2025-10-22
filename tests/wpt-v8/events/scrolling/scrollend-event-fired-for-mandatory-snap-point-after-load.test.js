// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/scrolling/scrollend-event-fired-for-mandatory-snap-point-after-load.html

// Setup HTML structure
document.body.innerHTML = `
<div id="root" class="hidden">
  <h1>scrollend + mandatory scroll snap test</h1>
  <div id="scroller">
    <div class="page">
      <p>Page 1</p>
    </div>
    <div class="page">
      <p>Page 2</p>
    </div>
    <div class="page">
      <p>Page 3</p>
    </div>
  </div>

  <div class="page">
    <p>Page A</p>
  </div>
  <div class="page">
    <p>Page B</p>
  </div>
  <div class="page">
    <p>Page C</p>
  </div>
</div>


`;

function runTests() {
    const root_div = document.getElementById("root");

    promise_test(async (t) => {
      const targetScrollendPromise = createScrollendPromiseForTarget(t, root_div);

      await waitForNextFrame();
      root_div.classList.remove("hidden");
      await waitForNextFrame();

      await targetScrollendPromise;
      await verifyScrollStopped(t, root_div);
    }, "scrollend event fired after load for mandatory snap point");
  }

