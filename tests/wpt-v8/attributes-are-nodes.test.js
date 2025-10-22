// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/attributes-are-nodes.html

"use strict";

test(() => {

  const attribute = document.createAttribute("newattribute");

  assert_true(attribute instanceof Node, "attribute instances are instances of Node");
  assert_true(Attr.prototype instanceof Node, "attribute instances are instances of Node");

}, "Attrs are subclasses of Nodes");

test(() => {

  const parent = document.createElement("p");

  const attribute = document.createAttribute("newattribute");
  assert_throws_dom("HierarchyRequestError", () => {
    parent.appendChild(attribute);
  });

}, "appendChild with an attribute as the child should fail");

test(() => {

  const parent = document.createElement("p");
  parent.appendChild(document.createElement("span"));

  const attribute = document.createAttribute("newattribute");
  assert_throws_dom("HierarchyRequestError", () => {
    parent.replaceChild(attribute, parent.firstChild);
  });

}, "replaceChild with an attribute as the child should fail");

test(() => {

  const parent = document.createElement("p");
  parent.appendChild(document.createElement("span"));

  const attribute = document.createAttribute("newattribute");
  assert_throws_dom("HierarchyRequestError", () => {
    parent.insertBefore(attribute, parent.firstChild);
  });

}, "insertBefore with an attribute as the child should fail");

