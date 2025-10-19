const std = @import("std");
const dom = @import("dom");

// Import all commonly used types
const Node = dom.Node;
const NodeType = dom.NodeType;
const NodeVTable = dom.NodeVTable;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;
const Document = dom.Document;
const DocumentFragment = dom.DocumentFragment;
const ShadowRoot = dom.ShadowRoot;

test "ShadowRoot - creation and basic properties" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    defer elem.prototype.release();

    const shadow = try ShadowRoot.create(allocator, elem, .{
        .mode = .open,
        .delegates_focus = false,
    });
    defer shadow.prototype.release();

    try std.testing.expect(shadow.prototype.node_type == .shadow_root);
    try std.testing.expectEqualStrings("#shadow-root", shadow.prototype.nodeName());
    try std.testing.expect(shadow.prototype.nodeValue() == null);
    try std.testing.expect(shadow.mode == .open);
    try std.testing.expect(!shadow.delegates_focus);
    try std.testing.expect(shadow.host() == elem);
}

test "ShadowRoot - closed mode" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("widget");
    defer elem.prototype.release();

    const shadow = try ShadowRoot.create(allocator, elem, .{
        .mode = .closed,
        .delegates_focus = false,
    });
    defer shadow.prototype.release();

    try std.testing.expect(shadow.mode == .closed);
    try std.testing.expect(shadow.host() == elem);
}

test "ShadowRoot - can hold children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    defer elem.prototype.release();

    const shadow = try ShadowRoot.create(allocator, elem, .{
        .mode = .open,
        .delegates_focus = false,
    });
    defer shadow.prototype.release();

    const child1 = try doc.createElement("content");
    const child2 = try doc.createElement("wrapper");

    _ = try shadow.prototype.appendChild(&child1.prototype);
    _ = try shadow.prototype.appendChild(&child2.prototype);

    try std.testing.expect(shadow.prototype.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 2), shadow.prototype.childNodes().length());
}

test "ShadowRoot - delegates_focus flag" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("focusable");
    defer elem.prototype.release();

    const shadow = try ShadowRoot.create(allocator, elem, .{
        .mode = .open,
        .delegates_focus = true,
    });
    defer shadow.prototype.release();

    try std.testing.expect(shadow.delegates_focus);
}

test "ShadowRoot - slot_assignment mode" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("slotted");
    defer elem.prototype.release();

    // Named slot assignment (default)
    const shadow1 = try ShadowRoot.create(allocator, elem, .{
        .mode = .open,
        .slot_assignment = .named,
    });
    defer shadow1.prototype.release();

    try std.testing.expect(shadow1.slot_assignment == .named);

    // Manual slot assignment
    const elem2 = try doc.createElement("manual");
    defer elem2.prototype.release();

    const shadow2 = try ShadowRoot.create(allocator, elem2, .{
        .mode = .open,
        .slot_assignment = .manual,
    });
    defer shadow2.prototype.release();

    try std.testing.expect(shadow2.slot_assignment == .manual);
}

test "ShadowRoot - clonable flag" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("clonable");
    defer elem.prototype.release();

    const shadow = try ShadowRoot.create(allocator, elem, .{
        .mode = .open,
        .clonable = true,
    });
    defer shadow.prototype.release();

    try std.testing.expect(shadow.clonable);

    // Clone should succeed
    const clone = try shadow.prototype.cloneNode(false);
    defer clone.release();

    try std.testing.expect(clone.node_type == .shadow_root);
}

test "ShadowRoot - non-clonable cannot be cloned" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("not-clonable");
    defer elem.prototype.release();

    const shadow = try ShadowRoot.create(allocator, elem, .{
        .mode = .open,
        .clonable = false,
    });
    defer shadow.prototype.release();

    try std.testing.expect(!shadow.clonable);

    // Clone should fail
    const result = shadow.prototype.cloneNode(false);
    try std.testing.expectError(error.NotSupportedError, result);
}

test "ShadowRoot - serializable flag" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("serializable");
    defer elem.prototype.release();

    const shadow = try ShadowRoot.create(allocator, elem, .{
        .mode = .open,
        .serializable = true,
    });
    defer shadow.prototype.release();

    try std.testing.expect(shadow.serializable);
}

test "ShadowRoot - ParentNode mixin methods" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("parent");
    defer elem.prototype.release();

    const shadow = try ShadowRoot.create(allocator, elem, .{
        .mode = .open,
        .delegates_focus = false,
    });
    defer shadow.prototype.release();

    // Add element children
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    const text = try doc.createTextNode("text");

    _ = try shadow.prototype.appendChild(&child1.prototype);
    _ = try shadow.prototype.appendChild(&text.prototype);
    _ = try shadow.prototype.appendChild(&child2.prototype);

    // Test firstElementChild (skips text node)
    const first = shadow.firstElementChild();
    try std.testing.expect(first != null);
    try std.testing.expectEqualStrings("child1", first.?.tag_name);

    // Test lastElementChild
    const last = shadow.lastElementChild();
    try std.testing.expect(last != null);
    try std.testing.expectEqualStrings("child2", last.?.tag_name);

    // Test childElementCount
    try std.testing.expectEqual(@as(u32, 2), shadow.childElementCount());

    // Test children collection
    const collection = shadow.children();
    try std.testing.expectEqual(@as(u32, 2), collection.length());
}

test "ShadowRoot - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple creation and cleanup
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const elem = try doc.createElement("test");
        defer elem.prototype.release();

        const shadow = try ShadowRoot.create(allocator, elem, .{
            .mode = .open,
            .delegates_focus = false,
        });
        defer shadow.prototype.release();
    }

    // Test 2: With children
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const elem = try doc.createElement("test");
        defer elem.prototype.release();

        const shadow = try ShadowRoot.create(allocator, elem, .{
            .mode = .open,
            .delegates_focus = false,
        });
        defer shadow.prototype.release();

        const child = try doc.createElement("child");
        _ = try shadow.prototype.appendChild(&child.prototype);
    }

    // Test 3: All flags enabled
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const elem = try doc.createElement("test");
        defer elem.prototype.release();

        const shadow = try ShadowRoot.create(allocator, elem, .{
            .mode = .closed,
            .delegates_focus = true,
            .slot_assignment = .manual,
            .clonable = true,
            .serializable = true,
        });
        defer shadow.prototype.release();
    }
}

test "Element.attachShadow() - basic functionality" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    defer elem.prototype.release();

    // Attach shadow root
    const shadow = try elem.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Verify shadow root properties
    try std.testing.expect(shadow.prototype.node_type == .shadow_root);
    try std.testing.expect(shadow.mode == .open);
    try std.testing.expect(!shadow.delegates_focus);
    try std.testing.expect(shadow.host() == elem);

    // Verify elem.shadowRoot() returns shadow root
    const retrieved = elem.shadowRoot();
    try std.testing.expect(retrieved == shadow);
}

test "Element.attachShadow() - open mode access" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("widget");
    defer elem.prototype.release();

    // Attach open shadow root
    const shadow = try elem.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Open mode: shadowRoot() returns the shadow root
    const retrieved = elem.shadowRoot();
    try std.testing.expect(retrieved != null);
    try std.testing.expect(retrieved.? == shadow);
}

test "Element.attachShadow() - closed mode access" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("widget");
    defer elem.prototype.release();

    // Attach closed shadow root
    const shadow = try elem.attachShadow(.{
        .mode = .closed,
        .delegates_focus = false,
    });

    // Shadow root exists
    try std.testing.expect(shadow.prototype.node_type == .shadow_root);
    try std.testing.expect(shadow.mode == .closed);

    // Closed mode: shadowRoot() returns null (hidden from JavaScript)
    const retrieved = elem.shadowRoot();
    try std.testing.expect(retrieved == null);

    // But shadow root still exists and works internally
    try std.testing.expect(shadow.host() == elem);
}

test "Element.attachShadow() - cannot attach twice" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    defer elem.prototype.release();

    // First attach succeeds
    _ = try elem.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Second attach fails
    const result = elem.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    try std.testing.expectError(error.NotSupportedError, result);
}

test "Element.attachShadow() - with children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    defer elem.prototype.release();

    // Attach shadow root
    const shadow = try elem.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Add children to shadow tree
    const content = try doc.createElement("content");
    const wrapper = try doc.createElement("wrapper");

    _ = try shadow.prototype.appendChild(&content.prototype);
    _ = try shadow.prototype.appendChild(&wrapper.prototype);

    // Verify children
    try std.testing.expect(shadow.prototype.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 2), shadow.prototype.childNodes().length());
}

test "Element.attachShadow() - with delegates_focus" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("focusable");
    defer elem.prototype.release();

    // Attach shadow root with delegates_focus
    const shadow = try elem.attachShadow(.{
        .mode = .open,
        .delegates_focus = true,
    });

    try std.testing.expect(shadow.delegates_focus);
}

test "Element.attachShadow() - manual slot assignment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("slotted");
    defer elem.prototype.release();

    // Attach shadow root with manual slot assignment
    const shadow = try elem.attachShadow(.{
        .mode = .open,
        .slot_assignment = .manual,
    });

    try std.testing.expect(shadow.slot_assignment == .manual);
}

test "Element.attachShadow() - clonable shadow root" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("clonable");
    defer elem.prototype.release();

    // Attach clonable shadow root
    const shadow = try elem.attachShadow(.{
        .mode = .open,
        .clonable = true,
    });

    try std.testing.expect(shadow.clonable);

    // Clone should succeed
    const clone = try shadow.prototype.cloneNode(false);
    defer clone.release();

    try std.testing.expect(clone.node_type == .shadow_root);
}

test "Element.attachShadow() - serializable shadow root" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("serializable");
    defer elem.prototype.release();

    // Attach serializable shadow root
    const shadow = try elem.attachShadow(.{
        .mode = .open,
        .serializable = true,
    });

    try std.testing.expect(shadow.serializable);
}

test "Element.attachShadow() - shadow root freed with element" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");

    // Attach shadow root (stored in elem's RareData)
    const shadow = try elem.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Add children to shadow tree
    const child = try doc.createElement("child");
    _ = try shadow.prototype.appendChild(&child.prototype);

    // Release element (should free shadow root via RareData.deinit)
    elem.prototype.release();

    // If we reach here with no leaks, shadow root was freed correctly
}

test "Element.shadowRoot() - null when no shadow" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("no-shadow");
    defer elem.prototype.release();

    // No shadow root attached
    const shadow = elem.shadowRoot();
    try std.testing.expect(shadow == null);
}

test "ShadowRoot - query selector in shadow tree" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    defer elem.prototype.release();

    // Attach shadow root
    const shadow = try elem.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Add button to shadow tree
    const button = try doc.createElement("button");
    try button.setAttribute("class", "primary");
    _ = try shadow.prototype.appendChild(&button.prototype);

    // Query shadow tree
    const found = try shadow.querySelector(allocator, ".primary");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);
}

test "ShadowRoot - host relationship" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("host-elem");
    defer elem.prototype.release();

    // Attach shadow root
    const shadow = try elem.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Verify bidirectional relationship
    try std.testing.expect(shadow.host() == elem);
    try std.testing.expect(elem.shadowRoot() == shadow);
}

test "Node.getRootNode() - without shadow root (composed=false)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&elem.prototype);

    const child = try doc.createElement("child");
    _ = try elem.prototype.appendChild(&child.prototype);

    // getRootNode without shadow roots returns document
    const root = child.prototype.getRootNode(false);
    try std.testing.expect(root == &doc.prototype);
}

test "Node.getRootNode() - shadow tree (composed=false)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    // Attach shadow root
    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Add child to shadow tree
    const shadow_child = try doc.createElement("shadow-child");
    _ = try shadow.prototype.appendChild(&shadow_child.prototype);

    // composed=false: stops at shadow boundary
    const root = shadow_child.prototype.getRootNode(false);
    try std.testing.expect(root == &shadow.prototype);
    try std.testing.expect(root.node_type == .shadow_root);
}

test "Node.getRootNode() - shadow tree (composed=true)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    _ = try doc.prototype.appendChild(&host.prototype);

    // Attach shadow root
    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Add child to shadow tree
    const shadow_child = try doc.createElement("shadow-child");
    _ = try shadow.prototype.appendChild(&shadow_child.prototype);

    // composed=true: pierces shadow boundary
    const root = shadow_child.prototype.getRootNode(true);
    try std.testing.expect(root == &doc.prototype);
    try std.testing.expect(root.node_type == .document);
}

test "Node.getRootNode() - nested shadow roots (composed=false)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create outer host with shadow root
    const outer_host = try doc.createElement("outer-host");
    _ = try doc.prototype.appendChild(&outer_host.prototype);

    const outer_shadow = try outer_host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Create inner host inside outer shadow
    const inner_host = try doc.createElement("inner-host");
    _ = try outer_shadow.prototype.appendChild(&inner_host.prototype);

    const inner_shadow = try inner_host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Add child to inner shadow tree
    const inner_child = try doc.createElement("inner-child");
    _ = try inner_shadow.prototype.appendChild(&inner_child.prototype);

    // composed=false: stops at inner shadow root
    const root = inner_child.prototype.getRootNode(false);
    try std.testing.expect(root == &inner_shadow.prototype);
    try std.testing.expect(root.node_type == .shadow_root);
}

test "Node.getRootNode() - nested shadow roots (composed=true)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create outer host with shadow root
    const outer_host = try doc.createElement("outer-host");
    _ = try doc.prototype.appendChild(&outer_host.prototype);

    const outer_shadow = try outer_host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Create inner host inside outer shadow
    const inner_host = try doc.createElement("inner-host");
    _ = try outer_shadow.prototype.appendChild(&inner_host.prototype);

    const inner_shadow = try inner_host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Add child to inner shadow tree
    const inner_child = try doc.createElement("inner-child");
    _ = try inner_shadow.prototype.appendChild(&inner_child.prototype);

    // composed=true: pierces both shadow boundaries to reach document
    const root = inner_child.prototype.getRootNode(true);
    try std.testing.expect(root == &doc.prototype);
    try std.testing.expect(root.node_type == .document);
}

test "Node.getRootNode() - host element in document (composed=false)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    _ = try doc.prototype.appendChild(&host.prototype);

    _ = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Host element is in document tree
    const root = host.prototype.getRootNode(false);
    try std.testing.expect(root == &doc.prototype);
}

test "Node.getRootNode() - shadow root itself (composed=false)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // getRootNode on shadow root itself
    const root = shadow.prototype.getRootNode(false);
    try std.testing.expect(root == &shadow.prototype);
}

test "Node.getRootNode() - shadow root itself (composed=true)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    _ = try doc.prototype.appendChild(&host.prototype);

    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // composed=true on shadow root traverses to document
    const root = shadow.prototype.getRootNode(true);
    try std.testing.expect(root == &doc.prototype);
}

test "Node.getRootNode() - disconnected host (composed=true)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Host not connected to document
    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    const child = try doc.createElement("child");
    _ = try shadow.prototype.appendChild(&child.prototype);

    // composed=true traverses to disconnected host
    const root = child.prototype.getRootNode(true);
    try std.testing.expect(root == &host.prototype);
}

test "Node.isConnected - shadow tree child (host connected)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Host connected to document
    const host = try doc.createElement("host");
    _ = try doc.prototype.appendChild(&host.prototype);

    // Attach shadow root
    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Shadow root should be connected (host is connected)
    try std.testing.expect(shadow.prototype.isConnected());

    // Child in shadow tree should be connected
    const child = try doc.createElement("child");
    _ = try shadow.prototype.appendChild(&child.prototype);

    try std.testing.expect(child.prototype.isConnected());
}

test "Node.isConnected - shadow tree child (host disconnected)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Host NOT connected to document
    const host = try doc.createElement("host");
    defer host.prototype.release();

    // Attach shadow root
    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Shadow root should NOT be connected (host is disconnected)
    try std.testing.expect(!shadow.prototype.isConnected());

    // Child in shadow tree should NOT be connected
    const child = try doc.createElement("child");
    _ = try shadow.prototype.appendChild(&child.prototype);

    try std.testing.expect(!child.prototype.isConnected());
}

test "Node.isConnected - shadow tree becomes connected when host connected" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create disconnected host
    const host = try doc.createElement("host");

    // Attach shadow root with child
    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    const child = try doc.createElement("child");
    _ = try shadow.prototype.appendChild(&child.prototype);

    // Initially disconnected
    try std.testing.expect(!host.prototype.isConnected());
    try std.testing.expect(!shadow.prototype.isConnected());
    try std.testing.expect(!child.prototype.isConnected());

    // Connect host to document
    _ = try doc.prototype.appendChild(&host.prototype);

    // Now everything should be connected
    try std.testing.expect(host.prototype.isConnected());
    try std.testing.expect(shadow.prototype.isConnected());
    try std.testing.expect(child.prototype.isConnected());
}

test "Node.isConnected - nested shadow roots" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Outer host connected
    const outer_host = try doc.createElement("outer");
    _ = try doc.prototype.appendChild(&outer_host.prototype);

    const outer_shadow = try outer_host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Inner host in outer shadow
    const inner_host = try doc.createElement("inner");
    _ = try outer_shadow.prototype.appendChild(&inner_host.prototype);

    const inner_shadow = try inner_host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Child in inner shadow
    const child = try doc.createElement("child");
    _ = try inner_shadow.prototype.appendChild(&child.prototype);

    // All should be connected
    try std.testing.expect(outer_host.prototype.isConnected());
    try std.testing.expect(outer_shadow.prototype.isConnected());
    try std.testing.expect(inner_host.prototype.isConnected());
    try std.testing.expect(inner_shadow.prototype.isConnected());
    try std.testing.expect(child.prototype.isConnected());
}

test "Node.isConnected - shadow root disconnection propagates" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Host connected with shadow
    const host = try doc.createElement("host");
    _ = try doc.prototype.appendChild(&host.prototype);

    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    const child = try doc.createElement("child");
    _ = try shadow.prototype.appendChild(&child.prototype);

    // Initially connected
    try std.testing.expect(child.prototype.isConnected());

    // Remove host from document
    const removed = try doc.prototype.removeChild(&host.prototype);
    defer removed.release();

    // Now disconnected
    try std.testing.expect(!host.prototype.isConnected());
    try std.testing.expect(!shadow.prototype.isConnected());
    try std.testing.expect(!child.prototype.isConnected());
}

