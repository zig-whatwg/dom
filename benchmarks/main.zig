const std = @import("std");
const runner = @import("benchmark_runner.zig");
const runBenchmark = runner.runBenchmark;

// Import benchmark modules
const selector_benchmarks = @import("selector_benchmarks.zig");
const crud_benchmarks = @import("crud_benchmarks.zig");
const traversal_benchmarks = @import("traversal_benchmarks.zig");
const batch_benchmarks = @import("batch_benchmarks.zig");
const stress_benchmarks = @import("stress_benchmarks.zig");
const event_benchmarks = @import("event_benchmarks.zig");
const observer_benchmarks = @import("observer_benchmarks.zig");
const range_benchmarks = @import("range_benchmarks.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n", .{});
    std.debug.print("{s}\n", .{"=" ** 70});
    std.debug.print(" DOM PERFORMANCE BENCHMARKS\n", .{});
    std.debug.print("{s}\n", .{"=" ** 70});
    std.debug.print("\n", .{});

    // Selector Query Benchmarks
    std.debug.print("\n📊 CSS SELECTOR QUERIES\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});

    var result = try runBenchmark(allocator, "Simple selector (.class)", 10000, selector_benchmarks.benchSimpleSelector);
    result.print();

    result = try runBenchmark(allocator, "Complex selector (article.post > p.content)", 5000, selector_benchmarks.benchComplexSelector);
    result.print();

    result = try runBenchmark(allocator, "querySelectorAll (10 elements)", 5000, selector_benchmarks.benchQuerySelectorAll);
    result.print();

    // CRUD Benchmarks
    std.debug.print("\n\n📊 DOM CRUD OPERATIONS\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});

    result = try runBenchmark(allocator, "createElement", 100000, crud_benchmarks.benchCreateElement);
    result.print();

    result = try runBenchmark(allocator, "createElement + 3 attributes", 50000, crud_benchmarks.benchCreateElementWithAttributes);
    result.print();

    result = try runBenchmark(allocator, "createTextNode", 100000, crud_benchmarks.benchCreateTextNode);
    result.print();

    result = try runBenchmark(allocator, "appendChild (single)", 50000, crud_benchmarks.benchAppendChild);
    result.print();

    result = try runBenchmark(allocator, "appendChild (10 children)", 10000, crud_benchmarks.benchAppendMultipleChildren);
    result.print();

    result = try runBenchmark(allocator, "removeChild", 50000, crud_benchmarks.benchRemoveChild);
    result.print();

    result = try runBenchmark(allocator, "setAttribute", 100000, crud_benchmarks.benchSetAttribute);
    result.print();

    result = try runBenchmark(allocator, "getAttribute", 100000, crud_benchmarks.benchGetAttribute);
    result.print();

    result = try runBenchmark(allocator, "className operations", 100000, crud_benchmarks.benchClassOperations);
    result.print();

    // Tree Traversal Benchmarks
    std.debug.print("\n\n📊 TREE TRAVERSAL\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});

    result = try runBenchmark(allocator, "Tree traversal (5 levels, 3 children/node)", 1000, traversal_benchmarks.benchTreeTraversal);
    result.print();

    result = try runBenchmark(allocator, "Deep tree traversal (50 levels)", 5000, traversal_benchmarks.benchDeepTreeTraversal);
    result.print();

    // Batch Operations
    std.debug.print("\n\n📊 BATCH OPERATIONS\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});

    result = try runBenchmark(allocator, "Batch insert 100 elements", 1000, batch_benchmarks.benchBatchInsert);
    result.print();

    // Event System Benchmarks
    std.debug.print("\n\n📊 EVENT SYSTEM\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});

    result = try runBenchmark(allocator, "Create Event", 100000, event_benchmarks.benchCreateEvent);
    result.print();

    result = try runBenchmark(allocator, "Create CustomEvent", 100000, event_benchmarks.benchCreateCustomEvent);
    result.print();

    result = try runBenchmark(allocator, "addEventListener", 50000, event_benchmarks.benchAddEventListener);
    result.print();

    result = try runBenchmark(allocator, "removeEventListener", 50000, event_benchmarks.benchRemoveEventListener);
    result.print();

    result = try runBenchmark(allocator, "dispatchEvent (single listener)", 10000, event_benchmarks.benchDispatchEvent);
    result.print();

    result = try runBenchmark(allocator, "Event propagation (2 levels)", 5000, event_benchmarks.benchEventPropagation);
    result.print();

    result = try runBenchmark(allocator, "Event capture", 5000, event_benchmarks.benchEventCapture);
    result.print();

    result = try runBenchmark(allocator, "Multiple listeners (3)", 10000, event_benchmarks.benchMultipleListeners);
    result.print();

    result = try runBenchmark(allocator, "stopPropagation", 5000, event_benchmarks.benchStopPropagation);
    result.print();

    // MutationObserver Benchmarks
    std.debug.print("\n\n📊 MUTATION OBSERVER\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});

    result = try runBenchmark(allocator, "Create observer", 50000, observer_benchmarks.benchCreateObserver);
    result.print();

    result = try runBenchmark(allocator, "Observe childList", 10000, observer_benchmarks.benchObserveChildList);
    result.print();

    result = try runBenchmark(allocator, "Observe attributes", 10000, observer_benchmarks.benchObserveAttributes);
    result.print();

    result = try runBenchmark(allocator, "Observe subtree", 10000, observer_benchmarks.benchObserveSubtree);
    result.print();

    result = try runBenchmark(allocator, "Disconnect observer", 10000, observer_benchmarks.benchDisconnectObserver);
    result.print();

    result = try runBenchmark(allocator, "takeRecords", 5000, observer_benchmarks.benchTakeRecords);
    result.print();

    result = try runBenchmark(allocator, "Multiple observers", 5000, observer_benchmarks.benchMultipleObservers);
    result.print();

    // Range Benchmarks
    std.debug.print("\n\n📊 RANGE OPERATIONS\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});

    result = try runBenchmark(allocator, "Create Range", 100000, range_benchmarks.benchCreateRange);
    result.print();

    result = try runBenchmark(allocator, "setStart", 50000, range_benchmarks.benchSetStart);
    result.print();

    result = try runBenchmark(allocator, "setEnd", 50000, range_benchmarks.benchSetEnd);
    result.print();

    result = try runBenchmark(allocator, "selectNode", 10000, range_benchmarks.benchSelectNode);
    result.print();

    result = try runBenchmark(allocator, "selectNodeContents", 10000, range_benchmarks.benchSelectNodeContents);
    result.print();

    result = try runBenchmark(allocator, "collapse", 50000, range_benchmarks.benchCollapse);
    result.print();

    result = try runBenchmark(allocator, "cloneRange", 10000, range_benchmarks.benchCloneRange);
    result.print();

    result = try runBenchmark(allocator, "extractContents", 5000, range_benchmarks.benchExtractContents);
    result.print();

    result = try runBenchmark(allocator, "cloneContents", 5000, range_benchmarks.benchCloneContents);
    result.print();

    result = try runBenchmark(allocator, "deleteContents", 5000, range_benchmarks.benchDeleteContents);
    result.print();

    result = try runBenchmark(allocator, "insertNode", 5000, range_benchmarks.benchInsertNode);
    result.print();

    result = try runBenchmark(allocator, "compareBoundaryPoints", 10000, range_benchmarks.benchCompareBoundaryPoints);
    result.print();

    // Stress Tests (Expensive Operations)
    std.debug.print("\n\n💥 STRESS TESTS (Expensive Operations)\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});
    std.debug.print("Note: These tests involve 1,000-10,000 operations per iteration\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});

    result = try runBenchmark(allocator, "Create 10,000 nodes", 10, stress_benchmarks.benchCreate10kNodes);
    result.print();

    // Temporarily disabled - investigating crash
    // result = try runBenchmark(allocator, "Create + destroy 5,000 nodes", 5, benchCreateDestroy10kNodes);
    // result.print();

    result = try runBenchmark(allocator, "Deep tree (500 levels)", 100, stress_benchmarks.benchDeepTree500Levels);
    result.print();

    result = try runBenchmark(allocator, "Complex query over 10k nodes", 10, stress_benchmarks.benchComplexQuery10kNodes);
    result.print();

    result = try runBenchmark(allocator, "1,000 elements × 10 attributes", 100, stress_benchmarks.benchMassiveAttributeOps);
    result.print();

    result = try runBenchmark(allocator, "Wide tree (100×100 = 10k nodes)", 10, stress_benchmarks.benchWideTree100x100);
    result.print();

    std.debug.print("\n", .{});
    std.debug.print("{s}\n", .{"=" ** 70});
    std.debug.print(" BENCHMARKS COMPLETE\n", .{});
    std.debug.print("{s}\n", .{"=" ** 70});
    std.debug.print("\n", .{});
}
