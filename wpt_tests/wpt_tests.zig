// Web Platform Tests (WPT) for DOM implementation
// Converted from https://github.com/web-platform-tests/wpt/tree/master/dom
//
// These tests preserve the exact test structure and assertions from WPT.
// File names are kept identical (with .zig extension instead of .html/.js).
// Test setup and assertions remain unchanged to validate spec compliance.

// Node tests
test {
    _ = @import("nodes/Node-appendChild.zig");
    _ = @import("nodes/Node-baseURI.zig");
    _ = @import("nodes/Node-cloneNode.zig");
    _ = @import("nodes/Node-contains.zig");
    _ = @import("nodes/Node-insertBefore.zig");
    _ = @import("nodes/Node-isConnected.zig");
}

// Element tests
test {
    _ = @import("nodes/Element-hasAttribute.zig");
    _ = @import("nodes/Element-setAttribute.zig");
}
