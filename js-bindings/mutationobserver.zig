//! MutationObserver C-ABI Bindings
//!
//! This module provides C-compatible bindings for the WHATWG DOM MutationObserver interface.
//! MutationObserver allows watching for changes to the DOM tree asynchronously.
//!
//! ## WebIDL Interface
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
//! ## Spec References
//!
//! - **WHATWG DOM**: https://dom.spec.whatwg.org/#mutationobserver
//! - **MDN MutationObserver**: https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver
//! - **MDN MutationRecord**: https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord
//!
//! ## Usage Example (C)
//!
//! ```c
//! // Callback function
//! void mutation_callback(
//!     DOMMutationRecord** records,
//!     uint32_t record_count,
//!     DOMMutationObserver* observer,
//!     void* context
//! ) {
//!     for (uint32_t i = 0; i < record_count; i++) {
//!         const char* type = dom_mutationrecord_get_type(records[i]);
//!         printf("Mutation type: %s\n", type);
//!     }
//! }
//!
//! // Create observer
//! DOMMutationObserver* observer = dom_mutationobserver_new(mutation_callback, NULL);
//!
//! // Observe element for attribute changes
//! DOMMutationObserverInit opts = {0};
//! opts.attributes = 1;
//! opts.child_list = 1;
//! dom_mutationobserver_observe(observer, element_node, &opts);
//!
//! // Make changes (will be recorded)
//! dom_element_setattribute(element, "class", "active");
//!
//! // Disconnect observer
//! dom_mutationobserver_disconnect(observer);
//! dom_mutationobserver_release(observer);
//! ```

const std = @import("std");
const root = @import("root.zig");
const dom = @import("dom");
const MutationObserver = dom.MutationObserver;
const MutationRecord = dom.MutationRecord;
const MutationObserverInit = dom.MutationObserverInit;
const Node = dom.Node;
const DOMNode = root.DOMNode;
const DOMMutationObserver = root.DOMMutationObserver;
const DOMMutationRecord = root.DOMMutationRecord;
const DOMErrorCode = root.DOMErrorCode;
const zigErrorToDOMError = root.zigErrorToDOMError;

// ============================================================================
// C Callback Types
// ============================================================================

/// C-compatible mutation callback function pointer.
///
/// ## Parameters
/// - `records`: Array of mutation record pointers
/// - `record_count`: Number of records in array
/// - `observer`: The MutationObserver that triggered callback
/// - `context`: User-provided context pointer
pub const MutationCallbackFn = *const fn (
    records: [*]const *DOMMutationRecord,
    record_count: u32,
    observer: *DOMMutationObserver,
    context: ?*anyopaque,
) callconv(std.builtin.CallingConvention.c) void;

/// Wrapper to adapt C callback to Zig MutationObserver callback.
const MutationObserverWrapper = struct {
    c_callback: MutationCallbackFn,
    c_context: ?*anyopaque,
    zig_observer: *MutationObserver,

    fn zigCallback(
        records: []const *MutationRecord,
        _: *MutationObserver,
        context: ?*anyopaque,
    ) void {
        const wrapper: *MutationObserverWrapper = @ptrCast(@alignCast(context.?));

        // Convert records to DOMMutationRecord pointers
        const c_records = @as([*]const *DOMMutationRecord, @ptrCast(records.ptr));

        // Invoke C callback
        wrapper.c_callback(
            c_records,
            @intCast(records.len),
            @ptrCast(wrapper.zig_observer),
            wrapper.c_context,
        );
    }
};

// ============================================================================
// MutationObserverInit (Options Structure)
// ============================================================================

/// C-compatible MutationObserverInit options structure.
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
/// ## Notes
/// - Use 255 for "not set" (undefined), 0 for false, 1 for true
/// - attributeFilter is null-terminated array of strings
pub const DOMMutationObserverInit = extern struct {
    child_list: u8, // 0=false, 1=true
    attributes: u8, // 0=false, 1=true, 255=undefined
    character_data: u8, // 0=false, 1=true, 255=undefined
    subtree: u8, // 0=false, 1=true
    attribute_old_value: u8, // 0=false, 1=true, 255=undefined
    character_data_old_value: u8, // 0=false, 1=true, 255=undefined
    attribute_filter: ?[*]const ?[*:0]const u8, // null-terminated array of null-terminated strings (null pointer = end)
};

/// Convert C options to Zig options.
fn cOptionsToZig(
    allocator: std.mem.Allocator,
    c_opts: *const DOMMutationObserverInit,
) !MutationObserverInit {
    var zig_opts = MutationObserverInit{
        .child_list = c_opts.child_list != 0,
        .attributes = if (c_opts.attributes == 255) null else c_opts.attributes != 0,
        .character_data = if (c_opts.character_data == 255) null else c_opts.character_data != 0,
        .subtree = c_opts.subtree != 0,
        .attribute_old_value = if (c_opts.attribute_old_value == 255) null else c_opts.attribute_old_value != 0,
        .character_data_old_value = if (c_opts.character_data_old_value == 255) null else c_opts.character_data_old_value != 0,
        .attribute_filter = null,
    };

    // Convert attribute filter
    if (c_opts.attribute_filter) |filter_ptr| {
        var count: usize = 0;
        while (filter_ptr[count] != null) : (count += 1) {}

        if (count > 0) {
            const filter_array = try allocator.alloc([]const u8, count);
            for (0..count) |i| {
                const str_ptr = filter_ptr[i].?;
                filter_array[i] = std.mem.span(str_ptr);
            }
            zig_opts.attribute_filter = filter_array;
        }
    }

    return zig_opts;
}

// ============================================================================
// MutationObserver Methods
// ============================================================================

/// Create a new MutationObserver with a callback.
///
/// ## WebIDL
/// ```webidl
/// constructor(MutationCallback callback);
/// ```
///
/// ## Parameters
/// - `callback`: C function pointer to invoke when mutations occur
/// - `context`: User-provided context pointer passed to callback
///
/// ## Returns
/// Pointer to new MutationObserver, or null on allocation failure
///
/// ## Memory
/// Caller must call `dom_mutationobserver_release()` when done
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationobserver-mutationobserver
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver/MutationObserver
pub export fn dom_mutationobserver_new(
    callback: MutationCallbackFn,
    context: ?*anyopaque,
) ?*DOMMutationObserver {
    const allocator = std.heap.c_allocator;

    // Create wrapper
    const wrapper = allocator.create(MutationObserverWrapper) catch return null;
    wrapper.c_callback = callback;
    wrapper.c_context = context;

    // Create Zig observer
    const observer = MutationObserver.init(
        allocator,
        MutationObserverWrapper.zigCallback,
        wrapper,
    ) catch {
        allocator.destroy(wrapper);
        return null;
    };

    wrapper.zig_observer = observer;

    return @ptrCast(observer);
}

/// Observe a target node for mutations.
///
/// ## WebIDL
/// ```webidl
/// undefined observe(Node target, optional MutationObserverInit options = {});
/// ```
///
/// ## Parameters
/// - `observer`: MutationObserver handle
/// - `target`: Node to observe
/// - `options`: Options specifying what to observe
///
/// ## Returns
/// DOM_ERROR_SUCCESS on success, error code otherwise
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationobserver-observe
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver/observe
pub export fn dom_mutationobserver_observe(
    observer: *DOMMutationObserver,
    target: *DOMNode,
    options: *const DOMMutationObserverInit,
) DOMErrorCode {
    const obs: *MutationObserver = @ptrCast(@alignCast(observer));
    const node: *Node = @ptrCast(@alignCast(target));

    const zig_opts = cOptionsToZig(obs.allocator, options) catch |err| {
        return zigErrorToDOMError(err);
    };
    defer if (zig_opts.attribute_filter) |filter| obs.allocator.free(filter);

    obs.observe(node, zig_opts) catch |err| {
        return zigErrorToDOMError(err);
    };

    return DOMErrorCode.Success;
}

/// Stop observing all targets.
///
/// ## WebIDL
/// ```webidl
/// undefined disconnect();
/// ```
///
/// ## Parameters
/// - `observer`: MutationObserver handle
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationobserver-disconnect
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver/disconnect
pub export fn dom_mutationobserver_disconnect(observer: *DOMMutationObserver) void {
    const obs: *MutationObserver = @ptrCast(@alignCast(observer));
    obs.disconnect();
}

/// Take all pending mutation records.
///
/// ## WebIDL
/// ```webidl
/// sequence<MutationRecord> takeRecords();
/// ```
///
/// ## Parameters
/// - `observer`: MutationObserver handle
/// - `out_count`: Pointer to store number of records returned
///
/// ## Returns
/// Array of MutationRecord pointers (may be null if no records)
///
/// ## Memory
/// Caller must release each record with `dom_mutationrecord_release()`
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationobserver-takerecords
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver/takeRecords
pub export fn dom_mutationobserver_takerecords(
    observer: *DOMMutationObserver,
    out_count: *u32,
) ?[*]const *DOMMutationRecord {
    const obs: *MutationObserver = @ptrCast(@alignCast(observer));

    const records = obs.takeRecords();
    out_count.* = @intCast(records.len);

    if (records.len == 0) return null;

    // Cast to C pointers
    return @ptrCast(records.ptr);
}

/// Release a MutationObserver and free its memory.
///
/// ## Parameters
/// - `observer`: MutationObserver handle
///
/// ## Memory
/// This releases the observer and its associated wrapper
pub export fn dom_mutationobserver_release(observer: *DOMMutationObserver) void {
    const obs: *MutationObserver = @ptrCast(@alignCast(observer));
    const allocator = obs.allocator;

    // Get wrapper to free it
    if (obs.context) |ctx| {
        const wrapper: *MutationObserverWrapper = @ptrCast(@alignCast(ctx));
        allocator.destroy(wrapper);
    }

    obs.deinit();
}

// ============================================================================
// MutationRecord Methods
// ============================================================================

/// Get the mutation type.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString type;
/// ```
///
/// ## Parameters
/// - `record`: MutationRecord handle
///
/// ## Returns
/// "attributes", "characterData", or "childList"
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationrecord-type
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord/type
pub export fn dom_mutationrecord_get_type(record: *const DOMMutationRecord) [*:0]const u8 {
    const rec: *const MutationRecord = @ptrCast(@alignCast(record));
    // Type is always a compile-time string literal, so it's null-terminated
    return @ptrCast(rec.type.ptr);
}

/// Get the target node that was mutated.
///
/// ## WebIDL
/// ```webidl
/// [SameObject] readonly attribute Node target;
/// ```
///
/// ## Parameters
/// - `record`: MutationRecord handle
///
/// ## Returns
/// Node that was mutated
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationrecord-target
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord/target
pub export fn dom_mutationrecord_get_target(record: *const DOMMutationRecord) *DOMNode {
    const rec: *const MutationRecord = @ptrCast(@alignCast(record));
    return @ptrCast(rec.target);
}

/// Get the nodes added (for childList mutations).
///
/// ## WebIDL
/// ```webidl
/// [SameObject] readonly attribute NodeList addedNodes;
/// ```
///
/// ## Parameters
/// - `record`: MutationRecord handle
/// - `out_count`: Pointer to store number of nodes
///
/// ## Returns
/// Array of added Node pointers, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationrecord-addednodes
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord/addedNodes
pub export fn dom_mutationrecord_get_addednodes(
    record: *const DOMMutationRecord,
    out_count: *u32,
) ?[*]const *DOMNode {
    const rec: *const MutationRecord = @ptrCast(@alignCast(record));
    const nodes = rec.added_nodes.items;
    out_count.* = @intCast(nodes.len);
    if (nodes.len == 0) return null;
    return @ptrCast(nodes.ptr);
}

/// Get the nodes removed (for childList mutations).
///
/// ## WebIDL
/// ```webidl
/// [SameObject] readonly attribute NodeList removedNodes;
/// ```
///
/// ## Parameters
/// - `record`: MutationRecord handle
/// - `out_count`: Pointer to store number of nodes
///
/// ## Returns
/// Array of removed Node pointers, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationrecord-removednodes
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord/removedNodes
pub export fn dom_mutationrecord_get_removednodes(
    record: *const DOMMutationRecord,
    out_count: *u32,
) ?[*]const *DOMNode {
    const rec: *const MutationRecord = @ptrCast(@alignCast(record));
    const nodes = rec.removed_nodes.items;
    out_count.* = @intCast(nodes.len);
    if (nodes.len == 0) return null;
    return @ptrCast(nodes.ptr);
}

/// Get the previous sibling (for childList mutations).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Node? previousSibling;
/// ```
///
/// ## Parameters
/// - `record`: MutationRecord handle
///
/// ## Returns
/// Previous sibling node, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationrecord-previoussibling
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord/previousSibling
pub export fn dom_mutationrecord_get_previoussibling(
    record: *const DOMMutationRecord,
) ?*DOMNode {
    const rec: *const MutationRecord = @ptrCast(@alignCast(record));
    return if (rec.previous_sibling) |node| @ptrCast(node) else null;
}

/// Get the next sibling (for childList mutations).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Node? nextSibling;
/// ```
///
/// ## Parameters
/// - `record`: MutationRecord handle
///
/// ## Returns
/// Next sibling node, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationrecord-nextsibling
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord/nextSibling
pub export fn dom_mutationrecord_get_nextsibling(
    record: *const DOMMutationRecord,
) ?*DOMNode {
    const rec: *const MutationRecord = @ptrCast(@alignCast(record));
    return if (rec.next_sibling) |node| @ptrCast(node) else null;
}

/// Get the attribute name (for attributes mutations).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString? attributeName;
/// ```
///
/// ## Parameters
/// - `record`: MutationRecord handle
///
/// ## Returns
/// Attribute name, or null if not an attribute mutation
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationrecord-attributename
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord/attributeName
pub export fn dom_mutationrecord_get_attributename(
    record: *const DOMMutationRecord,
) ?[*:0]const u8 {
    const rec: *const MutationRecord = @ptrCast(@alignCast(record));
    // Attribute names are interned strings from Document's string pool (null-terminated)
    return if (rec.attribute_name) |name| @ptrCast(name.ptr) else null;
}

/// Get the attribute namespace (for attributes mutations).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString? attributeNamespace;
/// ```
///
/// ## Parameters
/// - `record`: MutationRecord handle
///
/// ## Returns
/// Attribute namespace, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationrecord-attributenamespace
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord/attributeNamespace
pub export fn dom_mutationrecord_get_attributenamespace(
    record: *const DOMMutationRecord,
) ?[*:0]const u8 {
    const rec: *const MutationRecord = @ptrCast(@alignCast(record));
    // Namespaces are interned strings (null-terminated)
    return if (rec.attribute_namespace) |ns| @ptrCast(ns.ptr) else null;
}

/// Get the old value (for attributes or characterData mutations with oldValue option).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString? oldValue;
/// ```
///
/// ## Parameters
/// - `record`: MutationRecord handle
///
/// ## Returns
/// Old value, or null if not captured
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-mutationrecord-oldvalue
/// - https://developer.mozilla.org/en-US/docs/Web/API/MutationRecord/oldValue
pub export fn dom_mutationrecord_get_oldvalue(
    record: *const DOMMutationRecord,
) ?[*:0]const u8 {
    const rec: *const MutationRecord = @ptrCast(@alignCast(record));
    // Old values are stored as interned strings (null-terminated)
    return if (rec.old_value) |val| @ptrCast(val.ptr) else null;
}

/// Release a MutationRecord and free its memory.
///
/// ## Parameters
/// - `record`: MutationRecord handle
pub export fn dom_mutationrecord_release(record: *DOMMutationRecord) void {
    const rec: *MutationRecord = @ptrCast(@alignCast(record));
    rec.deinit();
}
