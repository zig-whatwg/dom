// Unit Tests
//
// This file imports all test files extracted from src/ files.
// Each src/*.zig file has a corresponding *_test.zig file in tests/.

// Core DOM tests
test {
    _ = @import("node_test.zig");
    _ = @import("element_test.zig");
    _ = @import("document_test.zig");
    _ = @import("document_fragment_test.zig");
    _ = @import("text_test.zig");
    _ = @import("comment_test.zig");
    _ = @import("shadow_root_test.zig");
}

// Collection and list tests
test {
    _ = @import("node_list_test.zig");
    _ = @import("html_collection_test.zig");
}

// Event system tests
test {
    _ = @import("event_test.zig");
    _ = @import("abort_signal_test.zig");
    // TODO: event_target_test.zig needs refactoring - tests internal APIs not exported
    // _ = @import("event_target_test.zig");
}

// Selector tests
test {
    _ = @import("tokenizer_test.zig");
    _ = @import("parser_test.zig");
    _ = @import("matcher_test.zig");
    _ = @import("query_selector_test.zig");
}

// Helper and utility tests
test {
    _ = @import("tree_helpers_test.zig");
    _ = @import("element_iterator_test.zig");
    _ = @import("fast_path_test.zig");
    _ = @import("rare_data_test.zig");
    _ = @import("validation_test.zig");
}

// Specialized feature tests
test {
    _ = @import("slot_test.zig");
    _ = @import("getElementsByTagName_test.zig");
}

// Misc tests
test {
    _ = @import("main_test.zig");
}
