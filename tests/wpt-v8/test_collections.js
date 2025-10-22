// Test collection properties and methods
print("=== Collection Properties Test ===\n");

// Create a container and add items to it
const container = document.createElement("container");
const elem1 = document.createElement("item");
const elem2 = document.createElement("item");

container.appendChild(elem1);
container.appendChild(elem2);
document.appendChild(container);

print("Created container with 2 'item' children");

// Test HTMLCollection (getElementsByTagName)
print("\n--- HTMLCollection Tests ---");
const items = document.getElementsByTagName("item");

print("1. length property:", items.length === 2 ? "✓ PASS" : "✗ FAIL");
print("   Expected: 2, Got:", items.length);

print("2. item(0) method:", items.item(0) === elem1 ? "✓ PASS" : "✗ FAIL");
print("3. item(1) method:", items.item(1) === elem2 ? "✓ PASS" : "✗ FAIL");
print("4. item(999) out of bounds:", items.item(999) === null ? "✓ PASS" : "✗ FAIL");

print("5. Indexed access [0]:", items[0] === elem1 ? "✓ PASS" : "✗ FAIL");
print("6. Indexed access [1]:", items[1] === elem2 ? "✓ PASS" : "✗ FAIL");
print("7. Indexed access [999]:", items[999] === undefined ? "✓ PASS" : "✗ FAIL");

// Test multiple collections
print("\n--- Multiple Collection Tests ---");
const allElems = document.getElementsByTagName("*");
print("1. Wildcard selector length:", allElems.length >= 3 ? "✓ PASS" : "✗ FAIL");
print("   Got:", allElems.length, "elements");

const containers = document.getElementsByTagName("container");
print("2. Container collection length:", containers.length === 1 ? "✓ PASS" : "✗ FAIL");
print("   Got:", containers.length);

// Test empty collections
print("\n--- Empty Collection Tests ---");
const noMatch = document.getElementsByTagName("nonexistent");
print("1. Empty collection length:", noMatch.length === 0 ? "✓ PASS" : "✗ FAIL");
print("2. Empty collection item(0):", noMatch.item(0) === null ? "✓ PASS" : "✗ FAIL");
print("3. Empty collection [0]:", noMatch[0] === undefined ? "✓ PASS" : "✗ FAIL");

print("\n=== All Collection Tests Complete ===");
