// Test getElementById

print("=== getElementById Test ===\n");

// Test 1: Create element and append to document
const div = document.createElement("div");
div.id = "test-id";
print("Created div with id:", div.id);

document.appendChild(div);
print("Appended div to document");

// Test 2: Try to find it
const found = document.getElementById("test-id");
print("\nSearching for 'test-id'...");
print("Result:", found);
print("Result type:", typeof found);
print("Result === div:", found === div);
print("Result === null:", found === null);

// Test 3: Non-existent ID
const notFound = document.getElementById("does-not-exist");
print("\nSearching for non-existent ID...");
print("Result:", notFound);
print("Result === null:", notFound === null);

print("\n=== Test Complete ===");
