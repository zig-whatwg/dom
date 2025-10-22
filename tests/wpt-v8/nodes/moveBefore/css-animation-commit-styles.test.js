// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/moveBefore/css-animation-commit-styles.html

// Setup HTML structure
document.body.innerHTML = `
  <section id="old-parent">
    <div id="item"></div>
  </section>
  <section id="new-parent">
  </section>
  <style>
    @keyframes anim {
      from {
        transform: translateX(100px);
      }

      to {
        transform: translateX(400px);
      }
    }

    #item {
      position: relative;
      width: 100px;
      height: 100px;
      background: green;
      animation: 1s linear infinite alternate anim;
      animation-delay: 100ms;
    }
  </style>
  
`;

promise_test(async t => {
      const item = document.querySelector("#item");
      await new Promise(resolve => item.addEventListener("animationstart", resolve));

      // Reparent item
      document.body.querySelector("#new-parent").moveBefore(item, null);

      item.getAnimations()[0].commitStyles();
      assert_true("transform" in item.style);
      assert_not_equals(item.style.transform, "none");
    });

