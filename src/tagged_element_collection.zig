//! TaggedElementCollection - Live Collection for Tag/Class Queries
//!
//! Generic live collection backed by Document's tag_map or class_map.
//! This is the return type for getElementsByTagName() and getElementsByClassName().

const std = @import("std");
const Element = @import("element.zig").Element;

/// TaggedElementCollection - live collection from Document's internal maps.
///
/// This is a lightweight view into Document's tag_map or class_map.
/// Changes to the DOM automatically reflect in the collection.
pub const TaggedElementCollection = struct {
    /// List of elements (borrowed from Document's map), or null for empty collections
    elements: ?*const std.ArrayList(*Element),

    /// Creates a new collection viewing elements from a document map.
    pub fn init(elements: *std.ArrayList(*Element)) TaggedElementCollection {
        return .{ .elements = elements };
    }

    /// Creates an empty collection (for tags/classes not in the map).
    pub fn initEmpty() TaggedElementCollection {
        return .{ .elements = null };
    }

    /// Returns the number of elements in the collection.
    pub fn length(self: *const TaggedElementCollection) usize {
        if (self.elements) |list| {
            return list.items.len;
        }
        return 0;
    }

    /// Returns the element at the specified index.
    pub fn item(self: *const TaggedElementCollection, index: usize) ?*Element {
        if (self.elements) |list| {
            if (index >= list.items.len) {
                return null;
            }
            return list.items[index];
        }
        return null;
    }
};
