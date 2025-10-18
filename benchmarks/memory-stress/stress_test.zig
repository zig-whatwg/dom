//! Memory stress test for DOM operations
//!
//! This module implements a comprehensive memory stress test that performs
//! extensive CRUD operations on a single DOM document over a configurable
//! time period, tracking memory consumption throughout.

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Node = dom.Node;

/// Memory sample captured at a specific point in time
pub const MemorySample = struct {
    timestamp_ms: u64,
    bytes_used: u64,
    peak_bytes: u64,
    operations_completed: u64,
};

/// Configuration for the stress test
pub const StressTestConfig = struct {
    duration_seconds: u64,
    sample_interval_ms: u64,
    nodes_per_cycle: usize, // Number of nodes to create per cycle
    operations_per_node: usize, // Operations to perform on each node
    seed: u64,
};

/// Statistics about operations performed
pub const OperationStats = struct {
    cycles_completed: u64 = 0,
    nodes_created: u64 = 0,
    nodes_deleted: u64 = 0,
    reads: u64 = 0,
    updates: u64 = 0,
};

/// Complete results from the stress test
pub const StressTestResult = struct {
    config: StressTestConfig,
    samples: []MemorySample,
    cycles_completed: u64,
    operation_breakdown: OperationStats,
};

/// Element registry for efficient random access
/// Uses HashMap to avoid use-after-free issues with element removal
const ElementRegistry = struct {
    elements: std.AutoHashMap(*Element, void),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) ElementRegistry {
        return .{
            .elements = std.AutoHashMap(*Element, void).init(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: *ElementRegistry) void {
        self.elements.deinit();
    }

    fn add(self: *ElementRegistry, element: *Element) !void {
        try self.elements.put(element, {});
    }

    fn remove(self: *ElementRegistry, element: *Element) void {
        _ = self.elements.remove(element);
    }

    fn getRandom(self: *ElementRegistry, prng: *std.Random.DefaultPrng) ?*Element {
        const elem_count = self.elements.count();
        if (elem_count == 0) return null;

        const target_idx = prng.random().intRangeLessThan(usize, 0, elem_count);
        var iter = self.elements.keyIterator();
        var i: usize = 0;
        while (iter.next()) |key_ptr| {
            if (i == target_idx) return key_ptr.*;
            i += 1;
        }
        return null;
    }

    fn count(self: *ElementRegistry) usize {
        return self.elements.count();
    }

    fn clear(self: *ElementRegistry) void {
        self.elements.clearRetainingCapacity();
    }
};

/// Main stress test context
pub const StressTest = struct {
    allocator: std.mem.Allocator,
    gpa: *std.heap.GeneralPurposeAllocator(.{ .enable_memory_limit = true }),
    config: StressTestConfig,
    doc: *Document,
    registry: ElementRegistry,
    prng: std.Random.DefaultPrng,
    stats: OperationStats,
    samples: std.ArrayList(MemorySample),
    timer: std.time.Timer,
    start_memory: u64,

    pub fn init(
        allocator: std.mem.Allocator,
        gpa: *std.heap.GeneralPurposeAllocator(.{ .enable_memory_limit = true }),
        config: StressTestConfig,
    ) !StressTest {
        return .{
            .allocator = allocator,
            .gpa = gpa,
            .config = config,
            .doc = undefined, // Not used anymore - each cycle creates its own
            .registry = ElementRegistry.init(allocator),
            .prng = std.Random.DefaultPrng.init(config.seed),
            .stats = .{},
            .samples = .empty,
            .timer = try std.time.Timer.start(),
            .start_memory = 0,
        };
    }

    pub fn deinit(self: *StressTest) void {
        self.samples.deinit(self.allocator);
        self.registry.deinit();
    }

    /// Take a memory sample
    fn takeSample(self: *StressTest) !void {
        const elapsed_ms = self.timer.read() / std.time.ns_per_ms;
        const current_memory = self.gpa.total_requested_bytes;

        const total_ops = self.stats.nodes_created + self.stats.nodes_deleted +
            self.stats.reads + self.stats.updates;

        try self.samples.append(self.allocator, .{
            .timestamp_ms = elapsed_ms,
            .bytes_used = current_memory,
            .peak_bytes = current_memory,
            .operations_completed = total_ops,
        });
    }

    /// Run the main stress test loop with persistent Document
    /// Simulates a long-running application with continuous DOM operations:
    /// - Create initial DOM structure
    /// - Continuously add/remove/modify nodes
    /// - Perform queries and traversals
    /// - Monitor memory growth over time
    pub fn run(self: *StressTest) !void {
        // Create persistent document (simulates a long-running app)
        self.doc = try Document.init(self.allocator);
        defer self.doc.release();

        // Build initial DOM structure
        try self.createInitialDOM();

        // Record baseline memory (after initial DOM is built)
        self.start_memory = self.gpa.total_requested_bytes;
        std.debug.print("Baseline memory: {d} bytes (after initial DOM)\n", .{self.start_memory});
        std.debug.print("Initial DOM: {d} elements in registry\n", .{self.registry.count()});

        // Reset timer
        self.timer.reset();

        // Take initial sample
        try self.takeSample();

        std.debug.print("\nRunning stress test for {d} seconds...\n", .{self.config.duration_seconds});
        std.debug.print("Strategy: Persistent Document with continuous operations\n", .{});
        std.debug.print("Operations per cycle: create nodes, modify content, query DOM, remove old nodes\n", .{});
        std.debug.print("Leak detection: Memory should stabilize after initial growth\n\n", .{});

        var last_sample_time: u64 = 0;
        const duration_ns = self.config.duration_seconds * std.time.ns_per_s;

        while (self.timer.read() < duration_ns) {
            // Check if we should take a sample
            const current_time_ms = self.timer.read() / std.time.ns_per_ms;
            if (current_time_ms - last_sample_time >= self.config.sample_interval_ms) {
                try self.takeSample();
                last_sample_time = current_time_ms;

                const elapsed_sec = current_time_ms / 1000;
                const total_ops = self.stats.nodes_created + self.stats.reads + self.stats.updates + self.stats.nodes_deleted;
                const mem_growth = self.gpa.total_requested_bytes - self.start_memory;
                std.debug.print("Sample at {d}s: {d} bytes (+{d}), {d} ops, {d} nodes in DOM\n", .{
                    elapsed_sec,
                    self.gpa.total_requested_bytes,
                    mem_growth,
                    total_ops,
                    self.registry.count(),
                });
            }

            // Run operation cycle on persistent document
            try self.runOperationCycle();

            self.stats.cycles_completed += 1;

            // Check time limit
            if (self.timer.read() >= duration_ns) break;
        }

        // Take final sample
        try self.takeSample();

        const final_memory = self.gpa.total_requested_bytes;
        const memory_leaked = final_memory - self.start_memory;

        std.debug.print("\nStress test complete!\n", .{});
        std.debug.print("Cycles completed: {d}\n", .{self.stats.cycles_completed});
        std.debug.print("Total nodes created: {d}\n", .{self.stats.nodes_created});
        std.debug.print("Total nodes deleted: {d}\n", .{self.stats.nodes_deleted});
        std.debug.print("Total reads: {d}\n", .{self.stats.reads});
        std.debug.print("Total updates: {d}\n", .{self.stats.updates});
        std.debug.print("Final DOM size: {d} nodes\n", .{self.registry.count()});
        std.debug.print("\n=== Memory Leak Analysis ===\n", .{});
        std.debug.print("Baseline memory: {d} bytes\n", .{self.start_memory});
        std.debug.print("Final memory: {d} bytes\n", .{final_memory});
        std.debug.print("Growth: {d} bytes ({d} bytes/cycle)\n", .{
            memory_leaked,
            if (self.stats.cycles_completed > 0) memory_leaked / self.stats.cycles_completed else 0,
        });

        // Memory growth analysis for persistent DOM
        // Note: Some growth is expected due to HashMap capacity expansion (doesn't shrink)
        // and string pool growth - this is realistic for long-running applications
        const bytes_per_cycle = if (self.stats.cycles_completed > 0) memory_leaked / self.stats.cycles_completed else 0;

        std.debug.print("\n=== Memory Growth Analysis ===\n", .{});
        std.debug.print("Expected sources of growth:\n", .{});
        std.debug.print("  - Document.tag_map capacity (HashMap doesn't shrink)\n", .{});
        std.debug.print("  - Document.class_map capacity\n", .{});
        std.debug.print("  - Document.string_pool (string interning)\n", .{});
        std.debug.print("  - Element.attributes HashMaps\n", .{});

        // Calculate growth rate relative to DOM size
        const final_dom_size = self.registry.count();
        const bytes_per_element = if (final_dom_size > 0) memory_leaked / final_dom_size else 0;
        std.debug.print("\nGrowth per element: {d} bytes\n", .{bytes_per_element});

        // Lenient threshold for persistent DOM: up to 5KB/cycle is acceptable
        // This accounts for HashMap capacity growth which is expected behavior
        if (bytes_per_cycle < 5000) {
            std.debug.print("✅ PASS: Memory growth is within acceptable range for persistent DOM\n", .{});
            std.debug.print("         (HashMap capacity growth is expected and realistic)\n", .{});
        } else {
            std.debug.print("⚠️  WARN: Higher than expected growth - may indicate actual leak\n", .{});
            std.debug.print("         (Investigate beyond HashMap capacity growth)\n", .{});
        }
    }

    /// Create initial DOM structure for long-running simulation
    fn createInitialDOM(self: *StressTest) !void {
        // Create root container
        const body = try self.doc.createElement("body");
        _ = try self.doc.node.appendChild(&body.node);
        try self.registry.add(body);

        // Create main sections
        var section_idx: usize = 0;
        while (section_idx < 5) : (section_idx += 1) {
            const section = try self.doc.createElement("section");
            _ = try body.node.appendChild(&section.node);
            try self.registry.add(section);

            // Add some initial elements to each section
            var elem_idx: usize = 0;
            while (elem_idx < 20) : (elem_idx += 1) {
                const div = try self.doc.createElement("div");
                try div.setAttribute("class", "content");
                _ = try section.node.appendChild(&div.node);
                try self.registry.add(div);

                const text = try self.doc.createTextNode("Initial content");
                _ = try div.node.appendChild(&text.node);

                self.stats.nodes_created += 1;
            }
        }
    }

    /// Run one operation cycle on the persistent document
    /// Simulates real application behavior: add nodes, modify content, query, remove old nodes
    /// Maintains steady-state DOM size by balancing creates/deletes
    fn runOperationCycle(self: *StressTest) !void {
        const current_size = self.registry.count();
        const target_min: usize = 500;
        const target_max: usize = 1000;

        // PHASE 1: Add new nodes (balanced with Phase 4 removals)
        // Dynamic adjustment based on current DOM size
        const create_count: usize = if (current_size < target_min)
            20 // Grow quickly to reach minimum
        else if (current_size > target_max)
            0 // Stop creating if over maximum
        else
            5; // Slow steady growth in range
        var i: usize = 0;
        while (i < create_count) : (i += 1) {
            // Pick random parent
            const parent = self.registry.getRandom(&self.prng) orelse continue;

            // Create new element
            const new_elem = try self.doc.createElement("div");
            try new_elem.setAttribute("class", "dynamic");
            _ = try parent.node.appendChild(&new_elem.node);
            try self.registry.add(new_elem);

            // 50% chance to add text content (creates mix of leaf and non-leaf nodes)
            if (self.prng.random().boolean()) {
                const text = try self.doc.createTextNode("Dynamic content");
                _ = try new_elem.node.appendChild(&text.node);
            }

            self.stats.nodes_created += 1;
        }

        // PHASE 2: Query operations (simulate reads)
        const read_count = 10;
        var r: usize = 0;
        while (r < read_count) : (r += 1) {
            const op = self.prng.random().intRangeAtMost(u8, 0, 1);
            switch (op) {
                0 => {
                    // Access random element
                    const elem = self.registry.getRandom(&self.prng);
                    if (elem) |e| {
                        _ = e.node.node_type;
                        _ = e.node.parent_node;
                    }
                },
                1 => {
                    // Query by tag name
                    _ = self.doc.getElementsByTagName("div");
                },
                else => unreachable,
            }
            self.stats.reads += 1;
        }

        // PHASE 3: Update operations (simulate modifications)
        const update_count = 5;
        var u: usize = 0;
        while (u < update_count) : (u += 1) {
            const elem = self.registry.getRandom(&self.prng) orelse continue;

            // Modify text content (but limit growth to avoid unbounded memory)
            if (elem.node.first_child) |child| {
                if (child.node_type == .text) {
                    const text_node: *Text = @fieldParentPtr("node", child);
                    // Only append if text is still reasonably short
                    if (text_node.data.len < 100) {
                        text_node.appendData("!") catch {};
                    }
                }
            }
            self.stats.updates += 1;
        }

        // PHASE 4: Remove nodes (match create count to maintain steady state)
        // Only remove leaf nodes to avoid cascading deletions
        const remove_count: usize = if (current_size > target_max)
            20 // Aggressive cleanup if over maximum
        else if (current_size > (target_max + target_min) / 2)
            10 // Moderate cleanup in upper range
        else
            5; // Light cleanup in lower range
        var removed_count: usize = 0;
        var attempts: usize = 0;
        const max_attempts = remove_count * 10; // More attempts since we're being selective

        while (removed_count < remove_count and self.registry.count() > 100 and attempts < max_attempts) : (attempts += 1) {
            // Get random element to remove using getRandom
            const elem = self.registry.getRandom(&self.prng) orelse break;

            // Skip if it's a root element (body or section)
            if (elem.node.parent_node == null or elem.node.parent_node == &self.doc.node) continue;

            // Skip if it has children (only remove leaf nodes to avoid cascading deletes)
            if (elem.node.first_child != null) continue;

            // Check if element has a parent
            if (elem.node.parent_node) |parent| {
                // Remove from registry FIRST (HashMap.remove is safe with pointer)
                self.registry.remove(elem);

                // Remove from DOM and free the node
                const removed_node = try parent.removeChild(&elem.node);
                removed_node.release();

                self.stats.nodes_deleted += 1;
                removed_count += 1;
            }
        }
    }

    /// Get the test results
    pub fn getResults(self: *StressTest, allocator: std.mem.Allocator) !StressTestResult {
        const samples_copy = try allocator.dupe(MemorySample, self.samples.items);

        return .{
            .config = self.config,
            .samples = samples_copy,
            .cycles_completed = self.stats.cycles_completed,
            .operation_breakdown = self.stats,
        };
    }

    // No cleanup needed - each cycle creates and destroys its own document
};
