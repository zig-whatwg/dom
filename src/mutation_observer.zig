//! MutationObserver Interface (§4.3)
//!
//! This module implements the MutationObserver interface as specified by the WHATWG DOM Standard.
//! MutationObserver provides a mechanism to observe changes to the DOM tree asynchronously.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.3 Interface MutationObserver**: https://dom.spec.whatwg.org/#mutationobserver
//! - **§4.3.1 Queuing mutation records**: https://dom.spec.whatwg.org/#queue-a-mutation-record
//! - **§4.3.2 Notifying observers**: https://dom.spec.whatwg.org/#notify-mutation-observers
//!
//! ## WebIDL
//!
//! ```webidl
//! interface MutationObserver {
//!   constructor(MutationCallback callback);
//!
//!   undefined observe(Node target, optional MutationObserverInit options = {});
//!   undefined disconnect();
//!   sequence<MutationRecord> takeRecords();
//! };
//!
//! callback MutationCallback = undefined (sequence<MutationRecord> mutations, MutationObserver observer);
//!
//! dictionary MutationObserverInit {
//!   boolean childList = false;
//!   boolean attributes;
//!   boolean characterData;
//!   boolean subtree = false;
//!   boolean attributeOldValue;
//!   boolean characterDataOldValue;
//!   sequence<DOMString> attributeFilter;
//! };
//!
//! interface MutationRecord {
//!   readonly attribute DOMString type;
//!   [SameObject] readonly attribute Node target;
//!   [SameObject] readonly attribute NodeList addedNodes;
//!   [SameObject] readonly attribute NodeList removedNodes;
//!   readonly attribute Node? previousSibling;
//!   readonly attribute Node? nextSibling;
//!   readonly attribute DOMString? attributeName;
//!   readonly attribute DOMString? attributeNamespace;
//!   readonly attribute DOMString? oldValue;
//! };
//! ```
//!
//! ## MDN Documentation
//!
//! - MutationObserver: https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver
//! - MutationObserver.observe(): https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver/observe
//! - MutationObserver.disconnect(): https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver/disconnect
//! - MutationObserver.takeRecords(): https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver/takeRecords
//! - MutationRecord: https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord
//!
//! ## Core Features
//!
//! ### Observing DOM Changes
//! MutationObserver allows you to watch for changes to the DOM:
//! ```zig
//! fn callback(records: []const *MutationRecord, observer: *MutationObserver, context: ?*anyopaque) void {
//!     _ = observer;
//!     _ = context;
//!     for (records) |record| {
//!         std.debug.print("Mutation type: {s}\n", .{record.type});
//!     }
//! }
//!
//! const observer = try MutationObserver.init(allocator, callback, null);
//! defer observer.deinit();
//!
//! const elem = try doc.createElement("div");
//! try observer.observe(&elem.prototype, .{ .child_list = true, .attributes = true });
//!
//! // Mutations will trigger callback asynchronously
//! try elem.setAttribute("class", "highlight");
//! doc.processMutationObservers();  // Deliver pending callbacks
//! ```
//!
//! ### Mutation Types
//!
//! **childList**: Child nodes added/removed
//! ```zig
//! try observer.observe(parent, .{ .child_list = true });
//! _ = try parent.appendChild(child);  // Generates "childList" record
//! ```
//!
//! **attributes**: Attribute changes
//! ```zig
//! try observer.observe(elem, .{ .attributes = true });
//! try elem.setAttribute("id", "main");  // Generates "attributes" record
//! ```
//!
//! **characterData**: Text content changes
//! ```zig
//! try observer.observe(&text.prototype, .{ .character_data = true });
//! try text.appendData(" more");  // Generates "characterData" record
//! ```
//!
//! ### Advanced Options
//!
//! **subtree**: Observe all descendants
//! ```zig
//! try observer.observe(root, .{ .child_list = true, .subtree = true });
//! // Observes changes anywhere in the tree below root
//! ```
//!
//! **attributeFilter**: Observe specific attributes
//! ```zig
//! try observer.observe(elem, .{
//!     .attributes = true,
//!     .attribute_filter = &[_][]const u8{"id", "class"},
//! });
//! // Only observes id and class attribute changes
//! ```
//!
//! **Old values**: Track previous values
//! ```zig
//! try observer.observe(elem, .{
//!     .attributes = true,
//!     .attribute_old_value = true,
//! });
//! try elem.setAttribute("id", "old");
//! try elem.setAttribute("id", "new");
//! // Record will have oldValue = "old"
//! ```
//!
//! ## Performance
//!
//! - **Lazy allocation**: Registration storage only created when needed
//! - **Fast path**: <1% overhead when node not observed
//! - **HashSet attribute filter**: O(1) lookup for filtered attributes
//! - **Batch delivery**: Multiple mutations delivered in single callback
//!
//! ## Memory Management
//!
//! MutationObserver and MutationRecord handle reference counting:
//! - Records hold strong refs to nodes (keeps them alive)
//! - Observer owns records until takeRecords() or callback
//! - Disconnect clears all records and registrations
//! - Safe to use with std.testing.allocator
//!
//! ## Implementation Notes
//!
//! Based on browser implementations (Chrome/Blink, Firefox/Gecko, WebKit):
//! - Per-node registration for fast mutation queries
//! - Microtask delivery for async callbacks (caller-driven in headless mode)
//! - Strong references prevent nodes from being freed during observation
//! - Attribute filter uses HashSet for O(1) lookup performance

const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;
const NodeList = @import("node_list.zig").NodeList;
const DOMError = @import("validation.zig").DOMError;

// ============================================================================
// MutationRecord
// ============================================================================

/// Describes a single DOM mutation.
///
/// ## WebIDL
/// ```webidl
/// interface MutationRecord {
///   readonly attribute DOMString type;
///   [SameObject] readonly attribute Node target;
///   [SameObject] readonly attribute NodeList addedNodes;
///   [SameObject] readonly attribute NodeList removedNodes;
///   readonly attribute Node? previousSibling;
///   readonly attribute Node? nextSibling;
///   readonly attribute DOMString? attributeName;
///   readonly attribute DOMString? attributeNamespace;
///   readonly attribute DOMString? oldValue;
/// };
/// ```
///
/// ## Spec Reference
/// - Interface: https://dom.spec.whatwg.org/#mutationrecord
/// - WebIDL: dom.idl lines 196-206
///
/// ## Fields
///
/// - `type`: "attributes", "characterData", or "childList"
/// - `target`: Node that was mutated
/// - `added_nodes`: Nodes added (childList only, otherwise empty)
/// - `removed_nodes`: Nodes removed (childList only, otherwise empty)
/// - `previous_sibling`: Previous sibling of added/removed nodes (childList only)
/// - `next_sibling`: Next sibling of added/removed nodes (childList only)
/// - `attribute_name`: Name of changed attribute (attributes only)
/// - `attribute_namespace`: Namespace of changed attribute (attributes only)
/// - `old_value`: Previous value if requested via options
pub const MutationRecord = struct {
    type: []const u8,
    target: *Node,
    added_nodes: std.ArrayListUnmanaged(*Node),
    removed_nodes: std.ArrayListUnmanaged(*Node),
    previous_sibling: ?*Node,
    next_sibling: ?*Node,
    attribute_name: ?[]const u8,
    attribute_namespace: ?[]const u8,
    old_value: ?[]const u8,
    allocator: Allocator,

    /// Create a new MutationRecord.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Allocator for the record and its data
    /// - `record_type`: "attributes", "characterData", or "childList"
    /// - `target`: Node that was mutated
    ///
    /// ## Returns
    ///
    /// Pointer to newly created MutationRecord
    pub fn init(
        allocator: Allocator,
        record_type: []const u8,
        target: *Node,
    ) !*MutationRecord {
        const self = try allocator.create(MutationRecord);
        errdefer allocator.destroy(self);

        // Duplicate type string
        const type_copy = try allocator.dupe(u8, record_type);
        errdefer allocator.free(type_copy);

        self.* = .{
            .type = type_copy,
            .target = target,
            .added_nodes = std.ArrayListUnmanaged(*Node){},
            .removed_nodes = std.ArrayListUnmanaged(*Node){},
            .previous_sibling = null,
            .next_sibling = null,
            .attribute_name = null,
            .attribute_namespace = null,
            .old_value = null,
            .allocator = allocator,
        };

        // Acquire target to keep it alive
        target.acquire();

        return self;
    }

    /// Free all resources associated with this record.
    pub fn deinit(self: *MutationRecord) void {
        self.allocator.free(self.type);
        self.added_nodes.deinit(self.allocator);
        self.removed_nodes.deinit(self.allocator);

        if (self.attribute_name) |name| {
            self.allocator.free(name);
        }
        if (self.attribute_namespace) |ns| {
            self.allocator.free(ns);
        }
        if (self.old_value) |val| {
            self.allocator.free(val);
        }

        self.target.release();
        self.allocator.destroy(self);
    }
};

// ============================================================================
// MutationObserverInit
// ============================================================================

/// Options for observing mutations.
///
/// ## WebIDL
/// ```webidl
/// dictionary MutationObserverInit {
///   boolean childList = false;
///   boolean attributes;
///   boolean characterData;
///   boolean subtree = false;
///   boolean attributeOldValue;
///   boolean characterDataOldValue;
///   sequence<DOMString> attributeFilter;
/// };
/// ```
///
/// ## Spec Reference
/// - Dictionary: https://dom.spec.whatwg.org/#dictdef-mutationobserverinit
/// - WebIDL: dom.idl lines 185-193
///
/// ## Validation Rules
///
/// Per WHATWG spec §4.3.3:
/// - At least one of `child_list`, `attributes`, or `character_data` must be true
/// - If `attribute_old_value` is true, `attributes` must be true (or omitted → defaults to true)
/// - If `character_data_old_value` is true, `character_data` must be true (or omitted → defaults to true)
/// - If `attribute_filter` is present, `attributes` must be true (or omitted → defaults to true)
pub const MutationObserverInit = struct {
    child_list: bool = false,
    attributes: ?bool = null,
    character_data: ?bool = null,
    subtree: bool = false,
    attribute_old_value: ?bool = null,
    character_data_old_value: ?bool = null,
    attribute_filter: ?[]const []const u8 = null,

    /// Validate options per WHATWG spec.
    ///
    /// ## Errors
    ///
    /// - `TypeError` (mapped to InvalidStateError): Invalid option combination
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-mutationobserver-observe Step 1
    pub fn validate(self: *const MutationObserverInit) !void {
        // Apply defaults per spec
        var attrs = self.attributes orelse false;
        var char_data = self.character_data orelse false;

        // If attributeOldValue is true, attributes defaults to true
        if (self.attribute_old_value orelse false) {
            attrs = self.attributes orelse true;
        }

        // If characterDataOldValue is true, characterData defaults to true
        if (self.character_data_old_value orelse false) {
            char_data = self.character_data orelse true;
        }

        // If attributeFilter is present, attributes defaults to true
        if (self.attribute_filter != null) {
            attrs = self.attributes orelse true;
        }

        // At least one of childList, attributes, or characterData must be true
        if (!self.child_list and !attrs and !char_data) {
            return DOMError.InvalidStateError;
        }
    }
};

// ============================================================================
// MutationCallback
// ============================================================================

/// User callback function invoked when mutations are delivered.
///
/// ## WebIDL
/// ```webidl
/// callback MutationCallback = undefined (sequence<MutationRecord> mutations, MutationObserver observer);
/// ```
///
/// ## Parameters
///
/// - `records`: Slice of MutationRecord pointers describing mutations
/// - `observer`: The MutationObserver instance
/// - `context`: User-provided context pointer (optional)
///
/// ## Spec Reference
/// - Callback: https://dom.spec.whatwg.org/#callbackdef-mutationcallback
/// - WebIDL: dom.idl line 183
pub const MutationCallback = *const fn (
    records: []const *MutationRecord,
    observer: *MutationObserver,
    context: ?*anyopaque,
) void;

// ============================================================================
// MutationObserver
// ============================================================================

/// Observes mutations to the DOM tree.
///
/// ## WebIDL
/// ```webidl
/// interface MutationObserver {
///   constructor(MutationCallback callback);
///
///   undefined observe(Node target, optional MutationObserverInit options = {});
///   undefined disconnect();
///   sequence<MutationRecord> takeRecords();
/// };
/// ```
///
/// ## Spec Reference
/// - Interface: https://dom.spec.whatwg.org/#mutationobserver
/// - WebIDL: dom.idl lines 175-181
///
/// ## Usage
///
/// ```zig
/// fn mutationCallback(
///     records: []const *MutationRecord,
///     observer: *MutationObserver,
///     context: ?*anyopaque,
/// ) void {
///     _ = observer;
///     _ = context;
///     for (records) |record| {
///         std.debug.print("Mutation: {s} on ", .{record.type});
///     }
/// }
///
/// const observer = try MutationObserver.init(allocator, mutationCallback, null);
/// defer observer.deinit();
///
/// const elem = try doc.createElement("div");
/// try observer.observe(&elem.prototype, .{
///     .child_list = true,
///     .attributes = true,
///     .subtree = true,
/// });
///
/// // Perform mutations
/// try elem.setAttribute("id", "main");
/// const child = try doc.createElement("span");
/// _ = try elem.prototype.appendChild(&child.prototype);
///
/// // Process mutations (caller-driven in headless mode)
/// doc.processMutationObservers();
/// ```
pub const MutationObserver = struct {
    callback: MutationCallback,
    context: ?*anyopaque,
    records: std.ArrayList(*MutationRecord),
    registrations: std.ArrayList(*MutationObserverRegistration),
    allocator: Allocator,

    /// Create a new MutationObserver with a callback.
    ///
    /// ## WebIDL
    /// ```webidl
    /// constructor(MutationCallback callback);
    /// ```
    ///
    /// ## Spec Reference
    /// - Constructor: https://dom.spec.whatwg.org/#dom-mutationobserver-mutationobserver
    /// - WebIDL: dom.idl line 176
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Allocator for the observer and its records
    /// - `callback`: Function to invoke when mutations are delivered
    /// - `context`: Optional user context passed to callback
    ///
    /// ## Returns
    ///
    /// Pointer to newly created MutationObserver
    pub fn init(
        allocator: Allocator,
        callback: MutationCallback,
        context: ?*anyopaque,
    ) !*MutationObserver {
        const self = try allocator.create(MutationObserver);
        errdefer allocator.destroy(self);

        self.* = .{
            .callback = callback,
            .context = context,
            .records = .{},
            .registrations = .{},
            .allocator = allocator,
        };

        return self;
    }

    /// Free all resources associated with this observer.
    ///
    /// Automatically disconnects from all observed nodes and clears pending records.
    pub fn deinit(self: *MutationObserver) void {
        self.disconnect();
        self.records.deinit(self.allocator);
        self.registrations.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    /// Observe mutations on a target node.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined observe(Node target, optional MutationObserverInit options = {});
    /// ```
    ///
    /// ## Algorithm (WHATWG §4.3.3)
    ///
    /// 1. Validate options
    /// 2. If target already has registered observer for this observer:
    ///    - Replace existing registration's options
    /// 3. Else:
    ///    - Create new registered observer
    ///    - Add to target's registered observer list
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-mutationobserver-observe
    /// - WebIDL: dom.idl line 178
    ///
    /// ## Parameters
    ///
    /// - `target`: Node to observe
    /// - `options`: What mutations to observe
    ///
    /// ## Errors
    ///
    /// - `InvalidStateError`: Invalid options (fails validation)
    /// - `OutOfMemory`: Allocation failure
    pub fn observe(
        self: *MutationObserver,
        target: *Node,
        options: MutationObserverInit,
    ) !void {
        // 1. Validate options
        try options.validate();

        // 2. Check if already observing this target
        for (self.registrations.items) |reg| {
            if (reg.target == target) {
                // Replace options
                try reg.updateOptions(options);
                return;
            }
        }

        // 3. Create new registration
        const reg = try MutationObserverRegistration.init(
            self.allocator,
            self,
            target,
            options,
        );
        errdefer reg.deinit();

        // 4. Add to observer's registration list
        try self.registrations.append(self.allocator, reg);

        // 5. Add to target's mutation_observers (in rare data)
        const rare = try target.ensureRareData();
        if (rare.mutation_observers == null) {
            rare.mutation_observers = .{};
        }
        try rare.mutation_observers.?.append(self.allocator, @ptrCast(reg));
    }

    /// Stop observing all nodes.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined disconnect();
    /// ```
    ///
    /// ## Algorithm (WHATWG §4.3.4)
    ///
    /// 1. For each node with a registered observer for this observer:
    ///    - Remove the registered observer
    /// 2. Empty this observer's record queue
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-mutationobserver-disconnect
    /// - WebIDL: dom.idl line 179
    pub fn disconnect(self: *MutationObserver) void {
        // 1. Remove from all observed nodes
        for (self.registrations.items) |reg| {
            const target = reg.target;
            if (target.rare_data) |rare| {
                if (rare.mutation_observers) |*list| {
                    // Remove this registration (cast from *anyopaque)
                    const reg_ptr: *anyopaque = @ptrCast(reg);
                    var i: usize = 0;
                    while (i < list.items.len) {
                        if (list.items[i] == reg_ptr) {
                            _ = list.swapRemove(i);
                            break;
                        }
                        i += 1;
                    }
                }
            }
            reg.deinit();
        }
        self.registrations.clearRetainingCapacity();

        // 2. Clear pending records
        for (self.records.items) |record| {
            record.deinit();
        }
        self.records.clearRetainingCapacity();
    }

    /// Return all pending mutation records and clear the queue.
    ///
    /// ## WebIDL
    /// ```webidl
    /// sequence<MutationRecord> takeRecords();
    /// ```
    ///
    /// ## Algorithm (WHATWG §4.3.5)
    ///
    /// 1. Let records be a copy of this observer's record queue
    /// 2. Empty this observer's record queue
    /// 3. Return records
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-mutationobserver-takerecords
    /// - WebIDL: dom.idl line 180
    ///
    /// ## Returns
    ///
    /// Slice of MutationRecord pointers (caller must free)
    pub fn takeRecords(self: *MutationObserver) []const *MutationRecord {
        return self.records.toOwnedSlice(self.allocator) catch &[_]*MutationRecord{};
    }
};

// ============================================================================
// MutationObserverRegistration
// ============================================================================

/// Per-node registration of an observer.
///
/// This is an internal type used to track which observers are watching each node.
/// Each call to observe() creates a registration linking the observer to the target.
pub const MutationObserverRegistration = struct {
    observer: *MutationObserver,
    target: *Node,
    options: MutationObserverInit,
    attribute_filter_set: ?std.StringHashMap(void),
    allocator: Allocator,

    fn init(
        allocator: Allocator,
        observer: *MutationObserver,
        target: *Node,
        options: MutationObserverInit,
    ) !*MutationObserverRegistration {
        const self = try allocator.create(MutationObserverRegistration);
        errdefer allocator.destroy(self);

        self.* = .{
            .observer = observer,
            .target = target,
            .options = options,
            .attribute_filter_set = null,
            .allocator = allocator,
        };

        // Build attribute filter HashSet for O(1) lookup
        if (options.attribute_filter) |filter| {
            var filter_set = std.StringHashMap(void).init(allocator);
            errdefer filter_set.deinit();

            for (filter) |attr_name| {
                try filter_set.put(attr_name, {});
            }

            self.attribute_filter_set = filter_set;
        }

        return self;
    }

    fn deinit(self: *MutationObserverRegistration) void {
        if (self.attribute_filter_set) |*filter_set| {
            filter_set.deinit();
        }
        self.allocator.destroy(self);
    }

    fn updateOptions(self: *MutationObserverRegistration, options: MutationObserverInit) !void {
        // Free old attribute filter if exists
        if (self.attribute_filter_set) |*filter_set| {
            filter_set.deinit();
            self.attribute_filter_set = null;
        }

        self.options = options;

        // Rebuild attribute filter if needed
        if (options.attribute_filter) |filter| {
            var filter_set = std.StringHashMap(void).init(self.allocator);
            errdefer filter_set.deinit();

            for (filter) |attr_name| {
                try filter_set.put(attr_name, {});
            }

            self.attribute_filter_set = filter_set;
        }
    }

    /// Check if this registration is interested in a specific mutation.
    ///
    /// ## Parameters
    ///
    /// - `mutation_type`: "attributes", "characterData", or "childList"
    /// - `attr_name`: Attribute name (for attributes mutations)
    ///
    /// ## Returns
    ///
    /// true if this registration should receive a record for this mutation
    pub fn matches(
        self: *const MutationObserverRegistration,
        mutation_type: []const u8,
        attr_name: ?[]const u8,
    ) bool {
        // Check mutation type
        if (std.mem.eql(u8, mutation_type, "childList")) {
            return self.options.child_list;
        } else if (std.mem.eql(u8, mutation_type, "attributes")) {
            const observing_attrs = self.options.attributes orelse false;
            if (!observing_attrs) return false;

            // Check attribute filter
            if (self.attribute_filter_set) |filter_set| {
                if (attr_name) |name| {
                    return filter_set.contains(name);
                }
                return false;
            }

            return true;
        } else if (std.mem.eql(u8, mutation_type, "characterData")) {
            return self.options.character_data orelse false;
        }

        return false;
    }
};
