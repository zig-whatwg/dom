// Simple DOM test without testharness.js
print("Starting simple DOM test...");

// Test 1: Create elements
const div = document.createElement("div");
print("✓ Test 1: createElement works");

// Test 2: Set attributes
div.id = "myDiv";
print("✓ Test 2: Setting id works:", div.id);

// Test 3: Create text node
const text = document.createTextNode("Hello");
print("✓ Test 3: createTextNode works");

// Test 4: appendChild text to div
div.appendChild(text);
print("✓ Test 4: appendChild works");

// Test 4b: Append div to document
document.appendChild(div);
print("✓ Test 4b: Appended div to document");

// Test 5: Query by ID
const found = document.getElementById("myDiv");
if (found === div) {
    print("✓ Test 5: getElementById works");
} else {
    print("✗ Test 5 FAILED: getElementById returned", found);
}

// Test 6: getElementsByTagName
const divs = document.getElementsByTagName("div");
print("✓ Test 6: getElementsByTagName returned:", typeof divs);

// Test 7: Collection length property
print("✓ Test 7: Collection length:", divs.length);

// Test 8: Collection item() method
const firstDiv = divs.item(0);
if (firstDiv === div) {
    print("✓ Test 8: Collection item() works");
} else {
    print("✗ Test 8 FAILED: item() returned", firstDiv);
}

// Test 9: Indexed access
const firstDiv2 = divs[0];
if (firstDiv2 === div) {
    print("✓ Test 9: Indexed access works");
} else {
    print("✗ Test 9 FAILED: Indexed access returned", firstDiv2);
}

// Test 10: querySelectorAll
const allDivs = document.querySelectorAll("div");
print("✓ Test 10: querySelectorAll returned:", typeof allDivs, "with length:", allDivs.length);

print("\nAll tests passed!");
