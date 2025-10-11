const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const selector = @import("selector.zig");
const Node = @import("node.zig").Node;

test "nth-child: odd keyword" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    // Create 5 li elements
    var i: usize = 0;
    while (i < 5) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test odd: should match 1st, 3rd, 5th (indices 1, 3, 5)
    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    try testing.expect(try selector.matches(first, "li:nth-child(odd)", allocator));

    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));
    try testing.expect(!try selector.matches(second, "li:nth-child(odd)", allocator));

    const third: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));
    try testing.expect(try selector.matches(third, "li:nth-child(odd)", allocator));

    const fourth: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[3]));
    try testing.expect(!try selector.matches(fourth, "li:nth-child(odd)", allocator));

    const fifth: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[4]));
    try testing.expect(try selector.matches(fifth, "li:nth-child(odd)", allocator));
}

test "nth-child: even keyword" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 5) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test even: should match 2nd, 4th (indices 2, 4)
    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    try testing.expect(!try selector.matches(first, "li:nth-child(even)", allocator));

    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));
    try testing.expect(try selector.matches(second, "li:nth-child(even)", allocator));

    const third: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));
    try testing.expect(!try selector.matches(third, "li:nth-child(even)", allocator));

    const fourth: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[3]));
    try testing.expect(try selector.matches(fourth, "li:nth-child(even)", allocator));
}

test "nth-child: simple number" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 5) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test :nth-child(3) - should match only 3rd element
    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    try testing.expect(!try selector.matches(first, "li:nth-child(3)", allocator));

    const third: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));
    try testing.expect(try selector.matches(third, "li:nth-child(3)", allocator));

    const fifth: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[4]));
    try testing.expect(!try selector.matches(fifth, "li:nth-child(3)", allocator));
}

test "nth-child: 2n formula (same as even)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test 2n: should match 2, 4, 6 (every 2nd element)
    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    try testing.expect(!try selector.matches(first, "li:nth-child(2n)", allocator));

    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));
    try testing.expect(try selector.matches(second, "li:nth-child(2n)", allocator));

    const third: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));
    try testing.expect(!try selector.matches(third, "li:nth-child(2n)", allocator));

    const fourth: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[3]));
    try testing.expect(try selector.matches(fourth, "li:nth-child(2n)", allocator));

    const sixth: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[5]));
    try testing.expect(try selector.matches(sixth, "li:nth-child(2n)", allocator));
}

test "nth-child: 2n+1 formula (same as odd)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test 2n+1: should match 1, 3, 5 (odd indices)
    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    try testing.expect(try selector.matches(first, "li:nth-child(2n+1)", allocator));

    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));
    try testing.expect(!try selector.matches(second, "li:nth-child(2n+1)", allocator));

    const third: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));
    try testing.expect(try selector.matches(third, "li:nth-child(2n+1)", allocator));

    const fifth: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[4]));
    try testing.expect(try selector.matches(fifth, "li:nth-child(2n+1)", allocator));

    const sixth: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[5]));
    try testing.expect(!try selector.matches(sixth, "li:nth-child(2n+1)", allocator));
}

test "nth-child: 3n formula" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 9) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test 3n: should match 3, 6, 9 (every 3rd element)
    var idx: usize = 0;
    const expected = [_]bool{ false, false, true, false, false, true, false, false, true };
    while (idx < 9) : (idx += 1) {
        const node: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[idx]));
        const matches_result = try selector.matches(node, "li:nth-child(3n)", allocator);
        try testing.expectEqual(expected[idx], matches_result);
    }
}

test "nth-child: 3n+2 formula" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test 3n+2: should match 2, 5, 8 (indices where (i-2)/3 is whole number)
    const expected = [_]bool{ false, true, false, false, true, false, false, true, false, false };
    var idx: usize = 0;
    while (idx < 10) : (idx += 1) {
        const node: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[idx]));
        const matches_result = try selector.matches(node, "li:nth-child(3n+2)", allocator);
        try testing.expectEqual(expected[idx], matches_result);
    }
}

test "nth-child: -n+3 formula (first 3 elements)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test -n+3: should match 1, 2, 3 (first 3 elements only)
    const expected = [_]bool{ true, true, true, false, false, false };
    var idx: usize = 0;
    while (idx < 6) : (idx += 1) {
        const node: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[idx]));
        const matches_result = try selector.matches(node, "li:nth-child(-n+3)", allocator);
        try testing.expectEqual(expected[idx], matches_result);
    }
}

test "nth-child: n+3 formula (3rd element and after)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test n+3: should match 3, 4, 5, 6 (3rd element onwards)
    const expected = [_]bool{ false, false, true, true, true, true };
    var idx: usize = 0;
    while (idx < 6) : (idx += 1) {
        const node: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[idx]));
        const matches_result = try selector.matches(node, "li:nth-child(n+3)", allocator);
        try testing.expectEqual(expected[idx], matches_result);
    }
}

test "nth-child: just 'n' (all elements)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 5) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test n: should match all elements (1, 2, 3, 4, 5)
    var idx: usize = 0;
    while (idx < 5) : (idx += 1) {
        const node: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[idx]));
        try testing.expect(try selector.matches(node, "li:nth-child(n)", allocator));
    }
}

test "nth-child: negative offset 4n-1" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 12) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test 4n-1: should match 3, 7, 11 (equivalent to 4n+3)
    // 4*0-1=-1 (invalid), 4*1-1=3, 4*2-1=7, 4*3-1=11
    const expected = [_]bool{ false, false, true, false, false, false, true, false, false, false, true, false };
    var idx: usize = 0;
    while (idx < 12) : (idx += 1) {
        const node: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[idx]));
        const matches_result = try selector.matches(node, "li:nth-child(4n-1)", allocator);
        try testing.expectEqual(expected[idx], matches_result);
    }
}

test "nth-child: whitespace handling" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test with various whitespace formats
    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    try testing.expect(try selector.matches(first, "li:nth-child( 2n + 1 )", allocator));

    const third: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));
    try testing.expect(try selector.matches(third, "li:nth-child(2n +1)", allocator));

    const fifth: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[4]));
    try testing.expect(try selector.matches(fifth, "li:nth-child(2n+ 1)", allocator));
}

test "nth-last-child: with An+B formula" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test :nth-last-child(2n+1) - counting from end, should match 6, 4, 2
    const expected = [_]bool{ false, true, false, true, false, true };
    var idx: usize = 0;
    while (idx < 6) : (idx += 1) {
        const node: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[idx]));
        const matches_result = try selector.matches(node, "li:nth-last-child(2n+1)", allocator);
        try testing.expectEqual(expected[idx], matches_result);
    }
}

test "nth-of-type: with An+B formula" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(parent);

    // Create mixed elements: p, div, p, div, p, div
    const p1 = try doc.createElement("p");
    _ = try parent.appendChild(p1);

    const div1 = try doc.createElement("div");
    _ = try parent.appendChild(div1);

    const p2 = try doc.createElement("p");
    _ = try parent.appendChild(p2);

    const div2 = try doc.createElement("div");
    _ = try parent.appendChild(div2);

    const p3 = try doc.createElement("p");
    _ = try parent.appendChild(p3);

    const div3 = try doc.createElement("div");
    _ = try parent.appendChild(div3);

    // Test p:nth-of-type(2n+1) - should match 1st and 3rd p elements (p1, p3)
    try testing.expect(try selector.matches(p1, "p:nth-of-type(2n+1)", allocator)); // 1st p
    try testing.expect(!try selector.matches(p2, "p:nth-of-type(2n+1)", allocator)); // 2nd p
    try testing.expect(try selector.matches(p3, "p:nth-of-type(2n+1)", allocator)); // 3rd p

    // Test div:nth-of-type(2) - should match only 2nd div element (div2)
    try testing.expect(!try selector.matches(div1, "div:nth-of-type(2)", allocator));
    try testing.expect(try selector.matches(div2, "div:nth-of-type(2)", allocator));
    try testing.expect(!try selector.matches(div3, "div:nth-of-type(2)", allocator));
}

test "edge cases: zero and negative results" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(parent);

    var i: usize = 0;
    while (i < 5) : (i += 1) {
        const li = try doc.createElement("li");
        _ = try parent.appendChild(li);
    }

    // Test 0n+1 (should match only first element, equivalent to just "1")
    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    try testing.expect(try selector.matches(first, "li:nth-child(0n+1)", allocator));

    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));
    try testing.expect(!try selector.matches(second, "li:nth-child(0n+1)", allocator));

    // Test -n+0 (should match nothing - all results are negative or zero)
    try testing.expect(!try selector.matches(first, "li:nth-child(-n+0)", allocator));
    try testing.expect(!try selector.matches(second, "li:nth-child(-n+0)", allocator));
}
