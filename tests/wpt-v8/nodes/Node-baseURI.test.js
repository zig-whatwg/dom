// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/Node-baseURI.html

const elementTests = [
  {
    name: "elements belonging to document",
    creator: () => {
      const element = document.createElement("div");
      document.body.appendChild(element);
      return element;
    }
  },
  {
    name: "elements unassigned to document",
    creator: () => document.createElement("div")
  },
  {
    name: "elements belonging to document fragments",
    creator: () => {
      const fragment = document.createDocumentFragment();
      const element = document.createElement("div");
      fragment.appendChild(element);
      return element;
    }
  },
  {
    name: "elements belonging to document fragments in document",
    creator: () => {
      const fragment = document.createDocumentFragment();
      const element = document.createElement("div");
      fragment.appendChild(element);
      document.body.appendChild(fragment);
      return element;
    }
  },
];

const attributeTests = [
  {
    name: "attributes unassigned to element",
    creator: () => document.createAttribute("class")
  },
  ...elementTests.map(({ name, creator }) => ({
    name: "attributes in " + name,
    creator: () => {
      const element = creator();
      element.setAttribute("class", "abc");
      return element.getAttributeNode("class");
    }
  }))
];

for (const { name, creator } of [...elementTests, ...attributeTests]) {
  test(function() {
    const node = creator();
    assert_equals(node.baseURI, document.URL);
  }, `For ${name}, baseURI should be document URL`)
}

