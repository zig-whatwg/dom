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

// ============================================================================
// UTF-16 Offset Tests
// ============================================================================

test "CharacterData.substringData - UTF-16 with BMP characters" {
    const allocator = std.testing.allocator;
    // "Hello 世界" = "Hello "(6) + "世"(1) + "界"(1) = 8 UTF-16 code units
    const data = "Hello 世界";

    // Extract "世界" starting at UTF-16 offset 6
    const result = try substringData(data, allocator, 6, 2);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("世界", result);
}

test "CharacterData.substringData - UTF-16 with supplementary characters" {
    const allocator = std.testing.allocator;
    // "Hello 𝄞" = "Hello "(6) + "𝄞"(2 UTF-16 code units) = 8 UTF-16 code units
    const data = "Hello 𝄞";

    // Extract "𝄞" starting at UTF-16 offset 6 (takes 2 UTF-16 code units)
    const result = try substringData(data, allocator, 6, 2);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("𝄞", result);
}

test "CharacterData.insertData - UTF-16 with BMP characters" {
    const allocator = std.testing.allocator;
    // "comté" = "com"(3) + "t"(1) + "é"(1) = 5 UTF-16 code units
    var data = try allocator.dupe(u8, "comté");
    defer allocator.free(data);

    // Insert " " at UTF-16 offset 3 (after "com")
    try insertData(&data, allocator, 3, " ");

    try std.testing.expectEqualStrings("com té", data);
}

test "CharacterData.insertData - UTF-16 with supplementary characters" {
    const allocator = std.testing.allocator;
    // "Hello𝄞" = "Hello"(5) + "𝄞"(2) = 7 UTF-16 code units
    var data = try allocator.dupe(u8, "Hello𝄞");
    defer allocator.free(data);

    // Insert " " at UTF-16 offset 5 (before "𝄞")
    try insertData(&data, allocator, 5, " ");

    try std.testing.expectEqualStrings("Hello 𝄞", data);
}

test "CharacterData.deleteData - UTF-16 with BMP characters" {
    const allocator = std.testing.allocator;
    // "Hello 世界" = "Hello "(6) + "世"(1) + "界"(1) = 8 UTF-16 code units
    var data = try allocator.dupe(u8, "Hello 世界");
    defer allocator.free(data);

    // Delete "世" at UTF-16 offset 6, count 1
    try deleteData(&data, allocator, 6, 1);

    try std.testing.expectEqualStrings("Hello 界", data);
}

test "CharacterData.deleteData - UTF-16 with supplementary characters" {
    const allocator = std.testing.allocator;
    // "Hello 𝄞 World" = "Hello "(6) + "𝄞"(2) + " World"(6) = 14 UTF-16 code units
    var data = try allocator.dupe(u8, "Hello 𝄞 World");
    defer allocator.free(data);

    // Delete "𝄞" at UTF-16 offset 6, count 2 (surrogate pair)
    try deleteData(&data, allocator, 6, 2);

    try std.testing.expectEqualStrings("Hello  World", data);
}

test "CharacterData.replaceData - UTF-16 with BMP characters" {
    const allocator = std.testing.allocator;
    // "comté" = "com"(3) + "t"(1) + "é"(1) = 5 UTF-16 code units
    var data = try allocator.dupe(u8, "comté");
    defer allocator.free(data);

    // Replace "té" with "puter" at UTF-16 offset 3, count 2
    try replaceData(&data, allocator, 3, 2, "puter");

    try std.testing.expectEqualStrings("computer", data);
}

test "CharacterData.replaceData - UTF-16 with supplementary characters" {
    const allocator = std.testing.allocator;
    // "Music 𝄞 Notes" = "Music "(6) + "𝄞"(2) + " Notes"(6) = 14 UTF-16 code units
    var data = try allocator.dupe(u8, "Music 𝄞 Notes");
    defer allocator.free(data);

    // Replace "𝄞" with "♪" at UTF-16 offset 6, count 2
    // "♪" is U+266A (BMP, 1 UTF-16 code unit)
    try replaceData(&data, allocator, 6, 2, "♪");

    try std.testing.expectEqualStrings("Music ♪ Notes", data);
}
