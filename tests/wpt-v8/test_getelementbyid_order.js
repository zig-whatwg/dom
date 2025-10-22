// Test appendChild THEN set ID

print("=== Test: appendChild THEN set ID ===\n");

const div = document.createElement("div");
print("1. Created div");

// Append FIRST
document.appendChild(div);
print("2. Appended to document");

// Set ID AFTER appendChild
div.id = "test-id";
print("3. Set id='test-id'");
print("   div.id:", div.id);

// Now try getElementById
const found = document.getElementById("test-id");
print("\n4. getElementById('test-id'):", found);
print("   found === null:", found === null);
print("   found === div:", found === div);

print("\n=== Test Complete ===");
