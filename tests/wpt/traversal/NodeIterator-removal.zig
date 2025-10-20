// META: title=NodeIterator removal tests
// META: link=https://dom.spec.whatwg.org/#interface-nodeiterator
// 
// NOTE: These tests require NodeIterator removal tracking, which is not yet implemented.
// The WHATWG spec requires that when nodes are removed from the DOM, all active NodeIterators
// must be notified and their reference nodes updated accordingly. This requires Document-level
// tracking of all active iterators.
//
// Implementation requirement: Document must maintain a list of all NodeIterators and call
// a preRemoveNode() method on each when removeChild() is called.
//
// FUTURE: Implement NodeIterator removal tracking per WHATWG DOM spec §6.1

const std = @import("std");
const dom = @import("dom");

// All tests commented out pending implementation of NodeIterator removal tracking
// See: https://dom.spec.whatwg.org/#nodeiterator-pre-removing-steps

// test "removing node before iterator position updates reference" {
//     // Requires NodeIterator removal tracking
// }

// test "removing node after iterator position leaves iterator unchanged" {
//     // Requires NodeIterator removal tracking  
// }

// test "removing root node does not affect iterator" {
//     // Requires NodeIterator removal tracking
// }

// test "removing reference node when pointer before reference" {
//     // Requires NodeIterator removal tracking
// }

// test "removing reference node when pointer after reference" {
//     // Requires NodeIterator removal tracking
// }

// test "removing last node updates reference to previous" {
//     // Requires NodeIterator removal tracking
// }

// test "removing subtree containing reference node" {
//     // Requires NodeIterator removal tracking
// }

// test "multiple iterators on same tree with node removal" {
//     // Requires NodeIterator removal tracking
// }
