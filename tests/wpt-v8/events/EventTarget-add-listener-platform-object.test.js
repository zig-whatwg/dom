// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/events/EventTarget-add-listener-platform-object.html

"use strict";
setup({ single_test: true });

class MyCustomClick extends HTMLElement {
  connectedCallback() {
    this.addEventListener("click", this);
  }

  handleEvent(event) {
    if (event.target === this) {
      this.dataset.yay = "It worked!";
    }
  }
}
window.customElements.define("my-custom-click", MyCustomClick);

const customElement = document.getElementById("click");
customElement.click();

assert_equals(customElement.dataset.yay, "It worked!");

done();

