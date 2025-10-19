const std = @import("std");
const character_data = @import("dom").character_data;

const substringData = character_data.substringData;
const appendData = character_data.appendData;
const insertData = character_data.insertData;
const deleteData = character_data.deleteData;
const replaceData = character_data.replaceData;

test "CharacterData.substringData - basic" {
    const allocator = std.testing.allocator;
    const data = "Hello World";

    const result = try substringData(data, allocator, 0, 5);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("Hello", result);
}

test "CharacterData.substringData - null count extracts to end" {
    const allocator = std.testing.allocator;
    const data = "Hello World";

    const result = try substringData(data, allocator, 6, null);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("World", result);
}

test "CharacterData.substringData - offset out of bounds" {
    const allocator = std.testing.allocator;
    const data = "Hello";

    try std.testing.expectError(
        error.IndexOutOfBounds,
        substringData(data, allocator, 10, 5),
    );
}

test "CharacterData.appendData - basic" {
    const allocator = std.testing.allocator;
    var data = try allocator.dupe(u8, "Hello");
    defer allocator.free(data);

    try appendData(&data, allocator, " World");

    try std.testing.expectEqualStrings("Hello World", data);
}

test "CharacterData.insertData - at beginning" {
    const allocator = std.testing.allocator;
    var data = try allocator.dupe(u8, "World");
    defer allocator.free(data);

    try insertData(&data, allocator, 0, "Hello ");

    try std.testing.expectEqualStrings("Hello World", data);
}

test "CharacterData.insertData - in middle" {
    const allocator = std.testing.allocator;
    var data = try allocator.dupe(u8, "HelloWorld");
    defer allocator.free(data);

    try insertData(&data, allocator, 5, " ");

    try std.testing.expectEqualStrings("Hello World", data);
}

test "CharacterData.insertData - at end" {
    const allocator = std.testing.allocator;
    var data = try allocator.dupe(u8, "Hello");
    defer allocator.free(data);

    try insertData(&data, allocator, 5, " World");

    try std.testing.expectEqualStrings("Hello World", data);
}

test "CharacterData.insertData - offset out of bounds" {
    const allocator = std.testing.allocator;
    var data = try allocator.dupe(u8, "Hello");
    defer allocator.free(data);

    try std.testing.expectError(
        error.IndexOutOfBounds,
        insertData(&data, allocator, 10, "World"),
    );
}

test "CharacterData.deleteData - from middle" {
    const allocator = std.testing.allocator;
    var data = try allocator.dupe(u8, "Hello World");
    defer allocator.free(data);

    try deleteData(&data, allocator, 5, 6);

    try std.testing.expectEqualStrings("Hello", data);
}

test "CharacterData.deleteData - beyond end" {
    const allocator = std.testing.allocator;
    var data = try allocator.dupe(u8, "Hello World");
    defer allocator.free(data);

    try deleteData(&data, allocator, 5, 100);

    try std.testing.expectEqualStrings("Hello", data);
}

test "CharacterData.deleteData - offset out of bounds" {
    const allocator = std.testing.allocator;
    var data = try allocator.dupe(u8, "Hello");
    defer allocator.free(data);

    try std.testing.expectError(
        error.IndexOutOfBounds,
        deleteData(&data, allocator, 10, 5),
    );
}

test "CharacterData.replaceData - in middle" {
    const allocator = std.testing.allocator;
    var data = try allocator.dupe(u8, "Hello World");
    defer allocator.free(data);

    try replaceData(&data, allocator, 6, 5, "Zig");

    try std.testing.expectEqualStrings("Hello Zig", data);
}

test "CharacterData.replaceData - beyond end" {
    const allocator = std.testing.allocator;
    var data = try allocator.dupe(u8, "Hello World");
    defer allocator.free(data);

    try replaceData(&data, allocator, 6, 100, "Zig");

    try std.testing.expectEqualStrings("Hello Zig", data);
}

test "CharacterData.replaceData - offset out of bounds" {
    const allocator = std.testing.allocator;
    var data = try allocator.dupe(u8, "Hello");
    defer allocator.free(data);

    try std.testing.expectError(
        error.IndexOutOfBounds,
        replaceData(&data, allocator, 10, 5, "World"),
    );
}
