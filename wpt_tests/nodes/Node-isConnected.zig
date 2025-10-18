// META: title=Node.prototype.isConnected
// META: link=https://dom.spec.whatwg.org/#dom-node-isconnected

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;

test "Test with ordinary child nodes" {
    const allocator = std.testing.allocator;

    // Create document
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create body element to simulate document.body
    const body = try doc.createElement("body");
    _ = try doc.prototype.appendChild(&body.node);

    // Create test nodes
    const nodes = [_]*Element{
        try doc.createElement("div"),
        try doc.createElement("div"),
        try doc.createElement("div"),
    };

    // Initially all nodes should be disconnected
    try checkNodes(&[_]*Element{}, &nodes);

    // Append nodes[0]
    _ = try body.prototype.appendChild(&nodes[0].node);
    try checkNodes(&[_]*Element{nodes[0]}, &[_]*Element{ nodes[1], nodes[2] });

    // Append nodes[1] and nodes[2] together
    _ = try nodes[1].prototype.appendChild(&nodes[2].node);
    try checkNodes(&[_]*Element{nodes[0]}, &[_]*Element{ nodes[1], nodes[2] });

    _ = try nodes[0].prototype.appendChild(&nodes[1].node);
    try checkNodes(&nodes, &[_]*Element{});

    // Remove nodes[2]
    const removed2 = try nodes[1].prototype.removeChild(&nodes[2].node);
    removed2.release();
    try checkNodes(&[_]*Element{ nodes[0], nodes[1] }, &[_]*Element{nodes[2]});

    // Remove nodes[0] and nodes[1] together
    const removed0 = try body.prototype.removeChild(&nodes[0].node);
    removed0.release();
    try checkNodes(&[_]*Element{}, &nodes);
}

// Helper function to check whether nodes should be connected
fn checkNodes(connected_nodes: []const *Element, disconnected_nodes: []const *Element) !void {
    for (connected_nodes) |node| {
        try std.testing.expect(node.prototype.isConnected());
    }
    for (disconnected_nodes) |node| {
        try std.testing.expect(!node.prototype.isConnected());
    }
}
